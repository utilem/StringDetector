//
//  ScannerView.swift
//  StringDetectorExample
//
//  Created by Uwe Tilemann on 13.12.22.
//

import SwiftUI
import StringDetector

struct ScannerView: View {
    var model: PhoneNumberModel
    var scannerView: StringDetectorView

    init(model: PhoneNumberModel) {
        self.model = model
        self.scannerView = StringDetectorView(model: model)
   }

    var body: some View {
        scannerView
    }
}
