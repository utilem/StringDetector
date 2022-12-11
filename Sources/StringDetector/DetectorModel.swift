//
//  DetectorModel.swift
//  
//
//  Created by Uwe Tilemann on 02.01.22.
//

import Foundation

public protocol StringDetecting {
    var string: String? { get set }
    var bestHitCount: Int { get }
    
    func isPossibleCanditate(string: String) -> (Range<String.Index>, String)?
    func detectorDidScan(string: String?)
    
    func prettyPrinted(string: String) -> String
}

public protocol StringDetectingViewModel {
    var cornerRadius: CGFloat { get }
    var regionOfInterest: CGSize { get }
    var cameraZoomFactor: CGFloat { get }
    var drawBoxes: Bool { get }

    var applyButtonString: String { get }
    var pauseButtonString: String { get }
    
    var pausingString: String { get }
}

public typealias StringDetector = StringDetecting & StringDetectingViewModel

open class StringDetectorModel: ObservableObject, StringDetecting {
    
    public init() {
        
    }
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
    
    @objc open func prettyPrinted(string: String) -> String {
        return string
    }
}

extension StringDetectorModel: StringDetectingViewModel {
    @objc open var cameraZoomFactor: CGFloat { return 1.0 }
    @objc open var regionOfInterest: CGSize { return CGSize(width: 1.0, height: 1.0) }
    @objc open var cornerRadius: CGFloat { return 0 }
    @objc open var drawBoxes: Bool { return true }
    
    @objc open var applyButtonString: String { return "Apply" }
    @objc open var pauseButtonString: String { return "Restart" }
    
    @objc open var pausingString: String { return "Pausing" }
}

