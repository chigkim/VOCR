//
//  Camera.swift
//  VOCR
//
//  Created by Chi Kim on 10/12/19.
//  Copyright © 2019 Chi Kim. All rights reserved.
//

import AVFoundation
import Cocoa
import UniformTypeIdentifiers

class MacCamera:NSObject, AVCapturePhotoCaptureDelegate {
	
	static let shared = MacCamera()
	var captureSession:AVCaptureSession!
	var cameraOutput:AVCapturePhotoOutput!
	var deviceName = "Unknown Camera"
	
	func isCameraAllowed() -> Bool {
		let cameraPermissionStatus = AVCaptureDevice.authorizationStatus(for: .video)
		switch cameraPermissionStatus {
		case .authorized:
			print("Already Authorized")
			return true
		case .denied:
			print("denied")
			return false
		case .restricted:
			print("restricted")
			return false
		default:
			print("Ask permission")
			
			var access = false
			AVCaptureDevice.requestAccess(for: .video) { granted in
				if granted == true {
					print("User granted")
				} else {
					print("User denied")
				}
				access = granted
			}
			return access
		}
	}
	
	func getCamera() -> AVCaptureDevice? {
		let devices = AVCaptureDevice.DiscoverySession(deviceTypes: [.builtInWideAngleCamera,.externalUnknown], mediaType: .video, position: .unspecified).devices
		for device in devices {
			if Settings.camera == device.localizedName {
				return device
			}
		}
		if let device = AVCaptureDevice.default(for: .video) {
			return device
		}
		return nil
	}
	
	func takePicture() {
		guard let device = getCamera() else {
			Accessibility.speakWithSynthesizer("No camera available.")
			return
		}
		
		for c in stride(from: 3, to: 1, by: -1) {
			Accessibility.speak("\(c)")
			sleep(1)
		}
		Accessibility.speak("1")
		captureSession = AVCaptureSession()
		captureSession.sessionPreset = AVCaptureSession.Preset.photo
		cameraOutput = AVCapturePhotoOutput()
		if let input = try? AVCaptureDeviceInput(device: device) {
			if (captureSession.canAddInput(input)) {
				captureSession.addInput(input)
				if (captureSession.canAddOutput(cameraOutput)) {
					captureSession.addOutput(cameraOutput)
					captureSession.startRunning()
					let settings = AVCapturePhotoSettings()
					deviceName = device.localizedName
					Accessibility.speak(deviceName)
					cameraOutput.capturePhoto(with: settings, delegate: self)
				}
			} else {
				print("issue here : captureSession.canAddInput")
			}
		} else {
			print("some problem here")
		}
	}
	
	func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
		captureSession.stopRunning()
		print("photo captured")
		if let error = error {
			debugPrint(error)
		}
		
		if let dataImage = photo.fileDataRepresentation() {
			let dataProvider = CGDataProvider(data: dataImage as CFData)
			if let cgImage = CGImage(jpegDataProviderSource: dataProvider!, decode: nil, shouldInterpolate: true, intent: .defaultIntent) {
				NSSound(contentsOfFile: "/System/Library/Components/CoreAudio.component/Contents/SharedSupport/SystemSounds/system/Shutter.aif", byReference: true)?.play()
				
				Navigation.mode = .CAMERA
				Navigation.appName = deviceName
				Navigation.cgImage = cgImage
				
				// Present menu to the user
				let alert = NSAlert()
				alert.messageText = "Choose an action"
				alert.addButton(withTitle: "Recognize Image")
				alert.addButton(withTitle: "Recognize image with LLM")
				alert.addButton(withTitle: "Recognize text in image")
				alert.addButton(withTitle: "Close")
				alert.window.defaultButtonCell = alert.buttons[0].cell as? NSButtonCell
				let response = alert.runModal()
				
				if let clickedButton = alert.buttons.first(where: { $0.title == "Recognize Image" }) {
					// Handle Recognize Image button
					let message = classify(cgImage: cgImage)
					sleep(1)
					Accessibility.speak(message)
				} else if let clickedButton = alert.buttons.first(where: { $0.title == "Recognize image with LLM" }) {
					// Handle Recognize image with LLM button
					ask(image: cgImage)
				} else if let clickedButton = alert.buttons.first(where: { $0.title == "Recognize text in image" }) {
					// Handle Recognize text in image button
					Navigation.displayResults = []
					Navigation.cgImage = cgImage
					Navigation.startOCR()
					if Navigation.displayResults.count == 0 {
						sleep(1)
						Accessibility.speak("Nothing found!")
					} else {
						sleep(1)
						Accessibility.speak("Recognition finished.")
						NSSound(contentsOfFile: "/System/Library/Sounds/Pop.aiff", byReference: true)?.play()
					}
				} else if let clickedButton = alert.buttons.first(where: { $0.title == "Close" }) {
					alert.window.close()
					return
				} else {
					print("Invalid menu choice")
				}
			}
		} else {
			print("some error here")
		}
	}
	
	@discardableResult func writeCGImage(_ image: CGImage, to destinationURL: URL) -> Bool {
		guard let destination = CGImageDestinationCreateWithURL(destinationURL as CFURL, UTType.png.identifier as CFString, 1, nil) else { return false }
		CGImageDestinationAddImage(destination, image, nil)
		return CGImageDestinationFinalize(destination)
	}
	
}
