//
//  Camera.swift
//  VOCR
//
//  Created by Chi Kim on 10/12/19.
//  Copyright © 2019 Chi Kim. All rights reserved.
//

import AVFoundation
import Cocoa

class Camera:NSObject, AVCapturePhotoCaptureDelegate {

	var captureSession: AVCaptureSession!
	var cameraOutput: AVCapturePhotoOutput!

	static func askPermission() {
		let cameraPermissionStatus = AVCaptureDevice.authorizationStatus(for: .video)
		switch cameraPermissionStatus {
		case .authorized:
			print("Already Authorized")
		case .denied:
			print("denied")
		case .restricted:
			print("restricted")
		default:
			print("ok")
			AVCaptureDevice.requestAccess(for: .video) { granted in
				if granted == true {
					print("User granted")
				} else {
					print("User denied")
				}
			}

		}
	}

	func takePicture() {
		let pop = NSSound(contentsOfFile: "/System/Library/Sounds/Pop.aiff", byReference: true)
		let tink = NSSound(contentsOfFile: "/System/Library/Sounds/Tink.aiff", byReference: true)
		for _ in 1...4 {
			pop?.play()
			sleep(1)
			pop?.stop()
		}
		tink?.play()
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
		if let error = error {
			print("error occured : \(error.localizedDescription)")
		}

		if let dataImage = photo.fileDataRepresentation() {
			let dataProvider = CGDataProvider(data: dataImage as CFData)
			if let cgImage = CGImage(jpegDataProviderSource: dataProvider!, decode: nil, shouldInterpolate: true, intent: .defaultIntent) {
				NSSound(contentsOfFile: "/System/Library/Components/CoreAudio.component/Contents/SharedSupport/SystemSounds/system/Shutter.aif", byReference: true)?.play()
			}
			} else {
			print("some error here")
		}
	}



}
