//
//  DetectorModel.swift
//  
//
//  Created by Uwe Tilemann on 02.01.22.
//

import Foundation
import Combine

/// A protocol to handle strings to detect.
public protocol StringDetecting {
    /// The detected string or `nil`.
   var string: String? { get set }
    /// number of hits to count before string will be presented
    var bestHitCount: Int { get }

    /// - Parameters:
    ///   - string: The string detected.
    /// - Returns `nil`  if the string is not of interest. Otherswise return the `Range<String.Index>`
    /// and the string to be a canditate
    func isPossibleCanditate(string: String) -> (Range<String.Index>, String)?
    
    /// - Parameters:
    ///   - string: The string detected or `nil` to reset `self.string`. This occurs when the detector is paused.
    /// `detectorDidScan(string:)` will be called if `bestHitCount` times a string is detected. If parameter An implementation can you this
    func detectorDidScan(string: String?)
}

/// A protocol to describe some UI related stuff.
public protocol StringDetectingViewModel {
    /// The corner radius of the preview area. Half of the `radius` value is used for corner radius of the
    /// background to display the recognized string. If `0` is returned, no rounding is done.
    var cornerRadius: CGFloat { get }
    
    /// The CGSize of region of interest. This region will be centered in the preview of the video stream.
    /// Return (1.0, 1.0) to use the hole screen.
    var regionOfInterest: CGSize { get }
    /// The detector use the `.buildInWideAngleCamera`.  Set the cameraZoomFactor to be displayed
    var cameraZoomFactor: CGFloat { get }
    /// if `drawBoxes` is set to `true` green boxes will be drawn for detected strings.
    /// Red boxes will be drawn to visualize partial detected strings in the `regionOfInterest` to be ignored by the detector
    var drawBoxes: Bool { get }

    /// The `String`to be displayed with the apply button for detected strings
    var applyButtonString: String { get }
    /// A tap on the preview area will pause the detector. The `String` will be displayed to restart the detector
    var pauseButtonString: String { get }
    /// The `String` to be displayed while the detector
    var pausingString: String { get }
    
    /// - Parameters:
    ///   - string: The string to display when the detector is paused.
    /// - Returns An alternate formatted `String` to display
    func prettyPrinted(string: String) -> String
}

public typealias StringDetector = StringDetecting & StringDetectingViewModel

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
