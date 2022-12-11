//
//  PhoneNumberModel.swift
//  StringDetectorExample
//
//  Created by Uwe Tilemann on 11.12.22.
//

import SwiftUI
import Combine
import StringDetector

class PhoneNumberModel: StringDetectorModel {
    
    override var cameraZoomFactor: CGFloat { return 1.5 }
    override var cornerRadius: CGFloat { return 16 }
    override var regionOfInterest: CGSize { return CGSize(width: 0.7, height: 0.2) }
    
    override func isPossibleCanditate(string: String) -> (Range<String.Index>, String)? {
        return string.extractPhoneNumber()
    }
    
    override func detectorDidScan(string: String?) {
        self.string = string
    }
}
