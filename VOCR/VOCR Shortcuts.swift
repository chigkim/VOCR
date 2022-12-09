//
//  Shortcuts.swift
//  VOCR
//
//  Created by Chi Kim on 10/12/19.
//  Copyright © 2019 Chi Kim. All rights reserved.
//

import Cocoa
import HotKey
import Socket
import AVFoundation
import Foundation
struct Shortcuts {
	
	let window = HotKey(key:.w, modifiers:[.command,.shift, .control])
	let vo = HotKey(key:.v, modifiers:[.command,.shift, .control])
	let resetPosition = HotKey(key:.r, modifiers:[.command,.shift, .control])
	let positionalAudio = HotKey(key:.p, modifiers:[.command,.shift, .control])
	let moveMouse = HotKey(key:.m, modifiers:[.command, .shift, .control])
	let socketTest = HotKey(key:.s, modifiers:[.command, .shift, .control])
	
	init() {
		window.keyDownHandler = {
			if !Accessibility.isTrusted(ask:true) {
				print("Accessibility not enabled.")
				return
			}
			
			if let  cgImage = TakeScreensShots() {
				Navigation.shared.startOCR(cgImage:cgImage)
			}
		}
		
		vo.keyDownHandler = {
			recognizeVOCursor()
		}
		
		resetPosition.keyDownHandler = {
			if Settings.positionReset {
				Settings.positionReset = false
				Accessibility.speak("Disable reset position.")
			} else {
				Settings.positionReset = true
				Accessibility.speak("Enable reset position.")
			}
			Settings.save()
		}
		
		positionalAudio.keyDownHandler = {
			if Settings.positionalAudio {
				Settings.positionalAudio = false
				Accessibility.speak("Disable positional audio.")
			} else {
				Settings.positionalAudio = true
				Accessibility.speak("Enable positional audio.")
			}
			Settings.save()
		}
		moveMouse.keyDownHandler = {
			if Settings.moveMouse {
				Settings.moveMouse = false
				Accessibility.speak("Disabled mouse movement")
			} else {
				Settings.moveMouse = true
				Accessibility.speak("Enabled mouse movement.")
			}
		}
		
		socketTest.keyDownHandler = {
			if let url = chooseFile() {
				do {
					let s = try Socket.create()
					try s.connect(to: "localhost", port: 12345)
					let cicontext = CIContext()
					let ciimage = CIImage(cgImage: loadImage(url)!)
					let imageData = cicontext.jpegRepresentation(of: ciimage, colorSpace: ciimage.colorSpace!)
					var length = imageData!.count
					var data = Data(bytes: &length, count: MemoryLayout.size(ofValue: length))
					data.append(imageData!)
					try s.write(from: data)
					if var message = try s.readString() {
						message += " Detected."
						print(message)
						Accessibility.speakWithSynthesizer(message)
					}
				} catch {
				}
			}
		}
		
	}
}

