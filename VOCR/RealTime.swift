//
//  RealTime.swift
//  VOCR
//
//  Created by Chi Kim on 1/9/24.
//  Copyright © 2024 Chi Kim. All rights reserved.
//

import Cocoa
import Foundation

enum RealTime {

    static var run: Bool = false

    static func diff(old: String, new: String) -> String? {
        let oldArray = old.lowercased().components(separatedBy: .whitespaces)
        let newArray = new.lowercased().components(separatedBy: .whitespaces)
        let difference = newArray.difference(from: oldArray)
        let insertedTexts = difference.compactMap {
            if case .insert(_, let element, _) = $0 {
                return element
            } else {
                return nil
            }
        }

        if insertedTexts.isNotEmpty {
            return insertedTexts.joined(separator: " ")
        }
        return nil
    }

    static func continuousOCR() {
        DispatchQueue.global(qos: .background).async {
            var rect: CGRect?
            if Navigation.mode == .WINDOW {
                rect = Navigation.getWindow()
            } else {
                rect = Navigation.getVOCursor()
            }
            if let rect = rect {
                var oldText = ""
                while run {
                    if let cgImage = ScreenCapture.capture(rect: rect) {
                        let texts = VisionOCR.recognizedText(in: cgImage)
                        let newText = texts.map { $0.topCandidates(1)[0].string }.joined(
                            separator: " ")
                        if let insertedText = diff(old: oldText, new: newText) {
                            oldText = newText
                            Accessibility.speak(insertedText)
                        }
                    }
                    Thread.sleep(forTimeInterval: 0.5)
                    // NSSound(contentsOfFile: "/System/Library/Sounds/Tink.aiff", byReference: true)?.play()
                }
            }
        }
    }

}
