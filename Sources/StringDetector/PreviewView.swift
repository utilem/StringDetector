//
//  PreviewView.swift
//
//
//  Created by Uwe Tilemann on 02.01.22.
//
// See LICENSE folder for this sample’s licensing information.
//


import UIKit
import AVFoundation

public class PreviewView: UIView {
	var videoPreviewLayer: AVCaptureVideoPreviewLayer {
		guard let layer = layer as? AVCaptureVideoPreviewLayer else {
			fatalError("Expected `AVCaptureVideoPreviewLayer` type for layer. Check PreviewView.layerClass implementation.")
		}
		
		return layer
	}
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        videoPreviewLayer.videoGravity = AVLayerVideoGravity.resizeAspectFill
        videoPreviewLayer.cornerRadius = 16
        videoPreviewLayer.masksToBounds = true
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    var session: AVCaptureSession? {
		get {
			return videoPreviewLayer.session
		}
		set {
			videoPreviewLayer.session = newValue
		}
	}
	
	// MARK: UIView
	
    public override class var layerClass: AnyClass {
		return AVCaptureVideoPreviewLayer.self
	}
}
