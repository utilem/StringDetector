//
//  StringDetectorViewController.swift
//
//
//  Created by Uwe Tilemann on 02.01.22.
//
// See LICENSE folder for this sample’s licensing information.
//

import UIKit
import SwiftUI
import AVFoundation
import Vision
import Combine

public class StringDetectorViewController: UIViewController, AVCaptureVideoDataOutputSampleBufferDelegate {
    private let textLabel = UILabel()
    private let applyButton = UIButton(type: .roundedRect)
    private let stackView = UIStackView()

    private var permissionGranted = false // Flag for permission

    private var captureSession: AVCaptureSession?
    private var sessionQueue: DispatchQueue?

    var stringTracker: StringTracker?

    // Detector
    private var videoOutput: AVCaptureVideoDataOutput?
    var request: VNRecognizeTextRequest?

    // MARK: - Region of interest (ROI) and text orientation
    // Region of video data output buffer that recognition should be run on.
    // Gets recalculated once the bounds of the preview layer are known.
    var regionOfInterest = CGRect(x: 0, y: 0, width: 1, height: 1)
    // Orientation of text to search for in the region of interest.
    var textOrientation = CGImagePropertyOrientation.up
    var currentOrientation = UIDeviceOrientation.portrait

    // MARK: - Coordinate transforms
    var bufferAspectRatio: Double!
    // Transform from UI orientation to buffer orientation.
    var uiRotationTransform = CGAffineTransform.identity
    // Transform bottom-left coordinates to top-left.
    var bottomToTopTransform = CGAffineTransform(scaleX: 1, y: -1).translatedBy(x: 0, y: -1)
    // Transform coordinates in ROI to global coordinates (still normalized).
    var roiToGlobalTransform = CGAffineTransform.identity

    // Vision -> AVF coordinate transform.
    var visionToAVFTransform = CGAffineTransform.identity

    let cutoutView = UIView()
    let previewView = PreviewView()

    var boxLayer = [CAShapeLayer]()
    var maskLayer : CAShapeLayer?
    
    @AppStorage("com.even-u.PrettyPrintedString") var showPrettyPrinted: Bool = true
    var isPausing = false
    
    var screenRect: CGRect {
        return CGRect(x: 0, y: 0, width: self.size.width, height: self.size.height)
    }

    let size: CGSize
    let model: StringDetector

    public init(model: StringDetector, size: CGSize = UIScreen.main.bounds.size) {
        self.model = model
        self.size = size

        super.init(nibName: nil, bundle: nil)
        
        self.preferredContentSize = size
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        debugPrint(#function, #file, #line)
        stringTracker = nil
    }

    func setupView() {

        view.backgroundColor = .systemBackground

        previewView.translatesAutoresizingMaskIntoConstraints = false

        view.addSubview(previewView)
        
        cutoutView.translatesAutoresizingMaskIntoConstraints = false
        cutoutView.backgroundColor = UIColor.gray.withAlphaComponent(0.5)

        view.addSubview(cutoutView)

        textLabel.translatesAutoresizingMaskIntoConstraints = false
        textLabel.text = ""
        textLabel.textColor = .black
        textLabel.numberOfLines = 0
        textLabel.font = UIFont(name: "Menlo Regular", size: showPrettyPrinted ? 17 : 20)
        textLabel.adjustsFontSizeToFitWidth = true
        textLabel.adjustsFontForContentSizeCategory = true
        textLabel.isUserInteractionEnabled = true
        textLabel.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(togglePrettyPrint(_:))))

        applyButton.translatesAutoresizingMaskIntoConstraints = false
        applyButton.setTitle(model.applyButtonString, for: .normal)
        applyButton.titleLabel?.font = .preferredFont(forTextStyle: .headline)
        applyButton.titleLabel?.adjustsFontForContentSizeCategory = true
        applyButton.isEnabled = true
        applyButton.isUserInteractionEnabled = true
        applyButton.addTarget(self, action: #selector(apply(_:)), for: .touchUpInside)

        stackView.backgroundColor = .white.withAlphaComponent(0.75)
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.addArrangedSubview(textLabel)
        stackView.addArrangedSubview(applyButton)
        stackView.axis = .vertical
        stackView.spacing = 8
        stackView.alignment = .center

        cutoutView.addSubview(stackView)
        cutoutView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(handleTap(_:))))
        
        NSLayoutConstraint.activate([
            previewView.topAnchor.constraint(equalTo: view.topAnchor),
            previewView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            previewView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            previewView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            cutoutView.topAnchor.constraint(equalTo: view.topAnchor),
            cutoutView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            cutoutView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            cutoutView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            stackView.leadingAnchor.constraint(equalTo: cutoutView.leadingAnchor, constant: 10),
            stackView.trailingAnchor.constraint(equalTo: cutoutView.trailingAnchor, constant: -10),
            stackView.bottomAnchor.constraint(equalTo: cutoutView.bottomAnchor, constant: -20),

            textLabel.heightAnchor.constraint(equalToConstant: 44),
            applyButton.heightAnchor.constraint(equalToConstant: 44)
        ])
    }

    public override func viewDidLoad() {
        super.viewDidLoad()
        
        maskLayer = CAShapeLayer()
        maskLayer?.backgroundColor = UIColor.clear.cgColor
        maskLayer?.fillRule = .evenOdd
        cutoutView.layer.mask = maskLayer
        
        self.setupView()
    }

    public override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        stringTracker = StringTracker(maxCount: self.model.bestHitCount)

        self.stackView.isHidden = true

        if self.model.cornerRadius > 0 {
            cutoutView.layer.cornerRadius = self.model.cornerRadius
            cutoutView.layer.masksToBounds = true
            cutoutView.clipsToBounds = true

            stackView.layer.cornerRadius = self.model.cornerRadius / 2
            stackView.layer.masksToBounds = true
            stackView.clipsToBounds = true
        }

        videoOutput = AVCaptureVideoDataOutput()
        captureSession = AVCaptureSession()
        sessionQueue = DispatchQueue(label: "sessionQueue")
        previewView.session = captureSession

        checkPermission()

        sessionQueue?.async { [unowned self] in
            guard permissionGranted else {
                return
            }

            self.setupCaptureSession()

            DispatchQueue.main.async {
                // Figure out initial ROI.
                self.calculateRegionOfInterest()
            }

            self.setupDetector()
        }
    }

    public override func viewWillDisappear(_ animated: Bool) {
        
        defer {
            super.viewWillDisappear(animated)
        }
        
        guard let session = self.captureSession else { return }
        
        if session.isRunning {
            session.stopRunning()
        }
        for input in session.inputs {
            session.removeInput(input)
        }
        if let output = videoOutput {
            session.removeOutput(output)
        }
        self.previewView.session = nil
        self.videoOutput = nil
        self.captureSession = nil
        self.sessionQueue = nil
        
        self.request = nil
        self.stringTracker = nil
    }
    
    public override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)

        let deviceOrientation = UIDevice.current.orientation
        if deviceOrientation.isPortrait || deviceOrientation.isLandscape {
            currentOrientation = deviceOrientation
        }

        if let videoPreviewLayerConnection = previewView.videoPreviewLayer.connection {
            if let newVideoOrientation = AVCaptureVideoOrientation(deviceOrientation: deviceOrientation) {
                videoPreviewLayerConnection.videoOrientation = newVideoOrientation
            }
        }
        // Orientation changed: figure out new region of interest (ROI).
        calculateRegionOfInterest()
    }

    public override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        updateCutout()
    }

    func calculateRegionOfInterest() {
        // In landscape orientation the desired ROI is specified as the ratio of
        // buffer width to height. When the UI is rotated to portrait, keep the
        // vertical size the same (in buffer pixels). Also try to keep the
        // horizontal size the same up to a maximum ratio.

        let size: CGSize
        let roi = self.model.regionOfInterest
        
        if currentOrientation.isPortrait || currentOrientation == .unknown {
            size = CGSize(width: min(roi.width * bufferAspectRatio, 0.8) , height: roi.height / bufferAspectRatio)
        } else {
            size = CGSize(width: roi.width, height: roi.height)
        }
        // Make it centered.
        regionOfInterest.origin = CGPoint(x: (1 - size.width) / 2, y: (1 - size.height) / 2)
        regionOfInterest.size = size
        
        // ROI changed, update transform.
        setupOrientationAndTransform()
        
        // Update the cutout to match the new ROI.
        DispatchQueue.main.async {
            // Wait for the next run cycle before updating the cutout. This
            // ensures that the preview layer already has its new orientation.
            self.updateCutout()
        }
    }

    func updateCutout() {

        // Figure out where the cutout ends up in layer coordinates.
        let roiRectTransform = bottomToTopTransform.concatenating(uiRotationTransform)
        let cutout = previewView.videoPreviewLayer.layerRectConverted(fromMetadataOutputRect: regionOfInterest.applying(roiRectTransform))

        // Create the mask.
        let path = UIBezierPath(rect: cutoutView.frame)
        path.append(UIBezierPath(rect: cutout))
        maskLayer?.path = path.cgPath
    }

    func setupOrientationAndTransform() {

        let roi = regionOfInterest
        roiToGlobalTransform = CGAffineTransform(translationX: roi.origin.x, y: roi.origin.y).scaledBy(x: roi.width, y: roi.height)

        switch currentOrientation {
            // Home button on right
        case .landscapeLeft:
            textOrientation = CGImagePropertyOrientation.up
            uiRotationTransform = CGAffineTransform.identity

            // Home button on left
        case .landscapeRight:
            textOrientation = CGImagePropertyOrientation.down
            uiRotationTransform = CGAffineTransform(translationX: 1, y: 1).rotated(by: CGFloat.pi)

            // Home button on top
        case .portraitUpsideDown:
            textOrientation = CGImagePropertyOrientation.left
            uiRotationTransform = CGAffineTransform(translationX: 1, y: 0).rotated(by: CGFloat.pi / 2)

            // Home button at bottom
        default:
            textOrientation = CGImagePropertyOrientation.right
            uiRotationTransform = CGAffineTransform(translationX: 0, y: 1).rotated(by: -CGFloat.pi / 2)

        }
        // Full Vision ROI to AVF transform.
        visionToAVFTransform = roiToGlobalTransform.concatenating(bottomToTopTransform).concatenating(uiRotationTransform)
    }

    func checkPermission() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
            // Permission has been granted before
        case .authorized:
            permissionGranted = true

            // Permission has not been requested yet
        case .notDetermined:
            requestPermission()

        default:
            permissionGranted = false
        }
    }

    func requestPermission() {
        guard let sessionQueue = sessionQueue else {
            return
        }

        sessionQueue.suspend()
        AVCaptureDevice.requestAccess(for: .video) { [unowned self] granted in
            self.permissionGranted = granted
            sessionQueue.resume()
        }
    }

    func setupCaptureSession() {
        // Camera input
        guard let videoDevice = AVCaptureDevice.default(.builtInWideAngleCamera,for: .video, position: .back) else { return }

        guard let captureSession = captureSession else {
            return
        }

        // NOTE:
        // Requesting 4k buffers allows recognition of smaller text but will
        // consume more power. Use the smallest buffer size necessary to keep
        // down battery usage.
        if videoDevice.supportsSessionPreset(.hd4K3840x2160) {
            captureSession.sessionPreset = AVCaptureSession.Preset.hd4K3840x2160
            bufferAspectRatio = 3840.0 / 2160.0
        } else {
            captureSession.sessionPreset = AVCaptureSession.Preset.hd1920x1080
            bufferAspectRatio = 1920.0 / 1080.0
        }

        guard let videoDeviceInput = try? AVCaptureDeviceInput(device: videoDevice) else { return }

        guard let videoOutput = videoOutput,
              captureSession.canAddInput(videoDeviceInput) else {
            return
        }
        captureSession.addInput(videoDeviceInput)

        // Detector
        videoOutput.alwaysDiscardsLateVideoFrames = true
        videoOutput.setSampleBufferDelegate(self, queue: DispatchQueue(label: "sampleBufferQueue"))
        videoOutput.videoSettings = [kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_420YpCbCr8BiPlanarFullRange]

        captureSession.addOutput(videoOutput)

        videoOutput.connection(with: .video)?.preferredVideoStabilizationMode = .off

        // Set zoom and autofocus to help focus on very small text.
        do {
            try videoDevice.lockForConfiguration()
            videoDevice.videoZoomFactor = self.model.cameraZoomFactor
            videoDevice.autoFocusRangeRestriction = .near
            videoDevice.unlockForConfiguration()
        } catch {
            print("Could not set zoom level due to error: \(error)")
            return
        }

        captureSession.startRunning()
    }

    func showString(string: String) {
        sessionQueue?.sync {
            if let session = self.captureSession, session.isRunning {
                session.stopRunning()
            }

            DispatchQueue.main.async {
                if !self.isPausing {
                    // init last scan in model
                    self.model.detectorDidScan(string: nil)
                }

                self.applyButton.setTitle(self.isPausing ? self.model.pauseButtonString : self.model.applyButtonString, for: .normal)
                self.stackView.isHidden = false
                self.textLabel.text = string
            }
        }
    }

    func restartSession() {
        sessionQueue?.async {
            if let session = self.captureSession, session.isRunning == false {
                session.startRunning()
            }
            DispatchQueue.main.async {
                self.stackView.isHidden = true
                self.isPausing = false
            }
        }
    }

    @IBAction func apply(_ sender: UIButton) {
        guard !isPausing else {
            restartSession()
            return
        }

        guard let text = textLabel.text else {
            return
        }
        self.model.detectorDidScan(string: text)
        self.model.actionPublisher.send(self)
    }

    @IBAction func handleTap(_ sender: UITapGestureRecognizer) {
        if let session = self.captureSession, session.isRunning {
            isPausing = true
            showString(string: self.model.pausingString)
        } else {
            restartSession()
        }
    }

    @IBAction func togglePrettyPrint(_ sender: UITapGestureRecognizer) {
        self.showPrettyPrinted = !showPrettyPrinted

        guard let text = textLabel.text else {
            return
        }

        if let result = self.model.isPossibleCanditate(string: text) {
            let (_, string) = result
            DispatchQueue.main.async {
                self.textLabel.text = self.showPrettyPrinted ? self.model.prettyPrinted(string: string) : string
            }
        }
    }
}

public struct StringDetectorView: UIViewControllerRepresentable {
    var model: StringDetector

    public init(model: StringDetector) {
        self.model = model
    }

    public func makeUIViewController(context: Context) -> UIViewController {
        return StringDetectorViewController(model: model)
    }

    public func updateUIViewController(_ uiViewController: UIViewController, context: Context) { }
}

extension AVCaptureVideoOrientation {
    init?(deviceOrientation: UIDeviceOrientation) {
        switch deviceOrientation {
        case .portrait: self = .portrait
        case .portraitUpsideDown: self = .portraitUpsideDown
        case .landscapeLeft: self = .landscapeRight
        case .landscapeRight: self = .landscapeLeft
        default: return nil
        }
    }
}
