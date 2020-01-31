//
//  Camera.swift
//  VOCR
//
//  Created by Chi Kim on 10/12/19.
//  Copyright © 2019 Chi Kim. All rights reserved.
//

import AVFoundation
import Cocoa

class MacCamera:NSObject, AVCapturePhotoCaptureDelegate {

	static let shared = MacCamera()
	var captureSession:AVCaptureSession!
	var cameraOutput:AVCapturePhotoOutput!
	
	
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

	func takePicture() {
		for c in stride(from: 3, to: 1, by: -1) {
			Accessibility.speak("\(c)")
			sleep(1)
		}
			Accessibility.speak("1")
		captureSession = AVCaptureSession()
		captureSession.sessionPreset = AVCaptureSession.Preset.photo
		cameraOutput = AVCapturePhotoOutput()

		if let device = AVCaptureDevice.default(for: .video),
		   let input = try? AVCaptureDeviceInput(device: device) {
			if (captureSession.canAddInput(input)) {
				captureSession.addInput(input)
				if (captureSession.canAddOutput(cameraOutput)) {
					captureSession.addOutput(cameraOutput)
					captureSession.startRunning()
					let settings = AVCapturePhotoSettings()
					cameraOutput.capturePhoto(with: settings, delegate: self)
				}
			} else {
				print("issue here : captureSesssion.canAddInput")
			}
		} else {
			print("some problem here")
		}
	}

	func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
		print("photo captured")
		if let error = error {
			debugPrint(error)
		}

		if let dataImage = photo.fileDataRepresentation() {
			let dataProvider = CGDataProvider(data: dataImage as CFData)
			if let cgImage = CGImage(jpegDataProviderSource: dataProvider!, decode: nil, shouldInterpolate: true, intent: .defaultIntent) {
				NSSound(contentsOfFile: "/System/Library/Components/CoreAudio.component/Contents/SharedSupport/SystemSounds/system/Shutter.aif", byReference: true)?.play()
				let fileManager = FileManager.default
				let home = fileManager.homeDirectoryForCurrentUser
				let file = home.appendingPathComponent("Desktop/camera.png")
				let url = file.absoluteURL
				if Settings.saveCameraImage {
					writeCGImage(cgImage, to:url)
				}
					classify(cgImage:cgImage)
			}
			} else {
			print("some error here")
		}
	}

	@discardableResult func writeCGImage(_ image: CGImage, to destinationURL: URL) -> Bool {
		guard let destination = CGImageDestinationCreateWithURL(destinationURL as CFURL, kUTTypePNG, 1, nil) else { return false }
		CGImageDestinationAddImage(destination, image, nil)
		return CGImageDestinationFinalize(destination)
	}
	
}
