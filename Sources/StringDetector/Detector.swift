//
//  Detector.swift
//
//
//  Created by Uwe Tilemann on 02.01.22.
//
// See LICENSE folder for this sample’s licensing information.
//

import Vision
import AVFoundation

#if canImport(UIKit)
import UIKit
#endif

extension StringDetectorViewController {
    
    func setupDetector() {
        self.request = VNRecognizeTextRequest(completionHandler: recognizeTextHandler)
    }
    
    // MARK: - Text recognition
    func recognizeTextHandler(request: VNRequest, error: Error?) {
        guard let results = request.results as? [VNRecognizedTextObservation] else {
            return
        }
        var numbers = [String]()
        var greenBoxes = [CGRect]()
        var redBoxes = [CGRect]()
        
        let maximumCandidates = 1
        let drawBoxes = self.model.drawBoxes
        
        for visionResult in results {
            guard let candidate = visionResult.topCandidates(maximumCandidates).first else { continue }
            
            var stringIsSubstring = true
            
            if let result = self.model.isPossibleCanditate(string: candidate.string) {
                let (range, string) = result
                
                numbers.append(string)
                
                if drawBoxes, let box = try? candidate.boundingBox(for: range)?.boundingBox {
                    greenBoxes.append(box)
                    stringIsSubstring = !(range.lowerBound == candidate.string.startIndex && range.upperBound == candidate.string.endIndex)
                }
            }
            if stringIsSubstring {
                redBoxes.append(visionResult.boundingBox)
            }
        }
        
        stringTracker?.logFrame(strings: numbers)
        let sureString = stringTracker?.getStableString()
        
        guard sureString != nil || drawBoxes else {
            return
        }

        DispatchQueue.main.async {
            guard self.request != nil else {
                return
            }

            if drawBoxes {
                self.show(boxGroups: [(color: UIColor.red.cgColor, boxes: redBoxes), (color: UIColor.green.cgColor, boxes: greenBoxes)])
            }
            
            if let sureString = sureString {
                self.showString(string: self.showPrettyPrinted ? self.model.prettyPrinted(string: sureString) : sureString)
                self.stringTracker?.reset(string: sureString)
            }
        }
    }

    // MARK: - Bounding box drawing

    // Draw a box on screen. Must be called from main queue.
    func draw(rect: CGRect, color: CGColor) {
        let layer = CAShapeLayer()
        layer.opacity = 0.5
        layer.borderColor = color
        layer.borderWidth = 2
        layer.frame = rect
        boxLayer.append(layer)

        previewView.videoPreviewLayer.insertSublayer(layer, at: 1)
    }

    // Remove all drawn boxes. Must be called on main queue.
    func removeBoxes() {
        for layer in boxLayer {
            layer.removeFromSuperlayer()
        }
        boxLayer.removeAll()
    }

    typealias ColoredBoxGroup = (color: CGColor, boxes: [CGRect])

    // Draws groups of colored boxes.
    func show(boxGroups: [ColoredBoxGroup]) {
        let layer = self.previewView.videoPreviewLayer
        self.removeBoxes()
        for boxGroup in boxGroups {
            let color = boxGroup.color
            for box in boxGroup.boxes {
                let rect = layer.layerRectConverted(fromMetadataOutputRect: box.applying(self.visionToAVFTransform))
                self.draw(rect: rect, color: color)
            }
        }
    }

    public func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        guard let request = self.request else {
            return
        }
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }

        request.recognitionLevel = .accurate
        request.usesLanguageCorrection = false
        request.regionOfInterest = regionOfInterest

        let imageRequestHandler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, orientation: textOrientation, options: [:])

        do {
            try imageRequestHandler.perform([request])
        } catch {
            print(error)
        }
    }
}
