//
//  PhoneNumberModel.swift
//  StringDetectorExample
//
//  Created by Uwe Tilemann on 11.12.22.
//

import SwiftUI
import StringDetector

class PhoneNumberModel: StringDetectorModel {
    override var cameraZoomFactor: CGFloat { return 1.5 }
    override var cornerRadius: CGFloat { return 16 }
    override var regionOfInterest: CGSize { return CGSize(width: 0.7, height: 0.2) }

    override func isPossibleCanditate(string: String) -> (Range<String.Index>, String)? {
        return string.extractPhoneNumber()
    }
    override func prettyPrinted(string: String) -> String {
        guard string.count == 10 else {
            return string
        }
        func get(from: Int, to: Int) throws -> String {
            guard let start = string.index(string.startIndex, offsetBy: from, limitedBy: string.endIndex),
                  let end = string.index(string.startIndex, offsetBy: to, limitedBy: string.endIndex) else {
                fatalError("substring \(from)..<\(to) is out of range")
            }
            return String(string[start..<end])
        }
        return "(\(try! get(from: 0, to: 3)))\(try! get(from: 3, to: 6))-\(try! get(from: 6, to: string.count))"
    }
}
