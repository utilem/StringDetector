//
//  StringDetecting.swift
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
    /// `detectorDidScan(string:)` will be called if `bestHitCount` times a string is detected or with `nil` to reset string.
    func detectorDidScan(string: String?)
    
    /// Emits if the apply button is tapped
    var actionPublisher: PassthroughSubject<AnyObject, Never> { get }
}

/// A protocol to describe some UI related stuff.
public protocol StringDetectingViewModel {
    /// The corner radius of the preview area. Half of the `cornerRadius` value is used for corner radius of the
    /// hud display. If `0` is returned, no rounding is done.
    var cornerRadius: CGFloat { get }
    
    /// The corner radius of the hud area.  The `hudRadius` value is used for corner radius of the
    /// hud display. If `0` is returned and `cornerRadius != 0` then `cornerRadius / 2` is used for rounding, If both are `0` no rounding is done.
   var hudRadius: CGFloat { get }

    /// The CGSize of region of interest. This region will be centered in the preview of the video stream.
    /// Return (1.0, 1.0) to use the hole screen.
    var regionOfInterest: CGSize { get }
    /// The detector use the `.buildInWideAngleCamera`.  Set the cameraZoomFactor to be displayed
    var cameraZoomFactor: CGFloat { get }
    /// if `drawBoxes` is set to `true` green boxes will be drawn for detected strings.
    /// Red boxes will be drawn to visualize partial detected strings in the `regionOfInterest` to be ignored by the detector
    var drawBoxes: Bool { get }

    /// The `String` to be displayed with the apply button for detected strings
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
