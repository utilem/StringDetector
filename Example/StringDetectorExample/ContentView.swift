//
//  ContentView.swift
//  StringDetectorExample
//
//  Created by Uwe Tilemann on 02.01.22.
//

import SwiftUI
import StringDetector

#if canImport(UIKit)
extension View {
    func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}
#endif

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

struct ContentView: View {
    @ObservedObject var model: PhoneNumberModel
    
    @State private var showScanner = false
    @State private var phone: String = ""
    
    init() {
        self.model = PhoneNumberModel()
    }
    
    @ViewBuilder
    var scanner: some View {
        if showScanner {
            ScannerView(model: model)
        } else {
            Spacer()
        }
    }
    
    @ViewBuilder
    var content: some View {
        VStack {
            ZStack {
                RoundedRectangle(cornerRadius: 16)
                    .foregroundColor(.white)
                    .frame(height:200)
                    .shadow(radius: 6)
                VStack {
                    HStack {
                        TextField("Phone number:", text: $phone)
                        Spacer()
                        Button(action: {
                            if !showScanner {
                                hideKeyboard()
                            }
                            withAnimation {
                                showScanner.toggle()
                            }
                        }) {
                            Image(systemName: "camera")
                                .font(.title2)
                        }
                    }
                    .onChange(of: model.string) { newString in
                        if let string = newString {
                            withAnimation {
                                phone = string
                                showScanner.toggle()
                            }
                        }
                    }
                }
                .padding()
            }
            scanner
        }
        .padding()
    }
    
    var body: some View {
        // ScannerView(model: model)
        content
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
