//
//  StringDetectorModel.swift
//  
//
//  Created by Uwe Tilemann on 13.12.22.
//

import SwiftUI
import Combine

/// `StringDetectorModel` is the default implementation of the `StringDetecting` protocol
open class StringDetectorModel: ObservableObject, StringDetecting {
    
    public init() {
    }

    /// The detected string or `nil`. A publisher  emits the string before the object change.
    @objc open var string: String? {
        willSet {
            self.objectWillChange.send()
        }
    }

    @objc open var bestHitCount: Int {
        return 10
    }

    open func isPossibleCanditate(string: String) -> (Range<String.Index>, String)? {
         return (string.range(of: string)!, string)
    }

    @objc open func detectorDidScan(string: String?) {
        self.string = string
    }
}

/// An extension of `StringDetectingViewModel` implementing default values of the `StringDetectingViewModel` protocol.
extension StringDetectorModel: StringDetectingViewModel {
    @objc open var cameraZoomFactor: CGFloat { return 1.0 }
    @objc open var regionOfInterest: CGSize { return CGSize(width: 1.0, height: 1.0) }
    @objc open var cornerRadius: CGFloat { return 0 }
    @objc open var drawBoxes: Bool { return true }
    
    @objc open var applyButtonString: String { return "Apply" }
    @objc open var pauseButtonString: String { return "Restart" }
    
    @objc open var pausingString: String { return "Pausing" }
 
    @objc open func prettyPrinted(string: String) -> String {
        return string
    }
}
