//
//  Camera.swift
//  VOCR
//
//  Created by Chi Kim on 10/12/19.
//  Copyright © 2019 Chi Kim. All rights reserved.
//

import AVFoundation
import Cocoa

class MacCamera: NSObject, AVCapturePhotoCaptureDelegate {

    static let shared = MacCamera()
    var captureSession: AVCaptureSession!
    var cameraOutput: AVCapturePhotoOutput!
    var deviceName = "Unknown Camera"

    func requestAccessThenTakePicture() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            takePicture()
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { granted in
                DispatchQueue.main.async {
                    if granted { self.takePicture() }
                }
            }
        case .denied, .restricted:
            if let url = URL(
                string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Camera")
            {
                NSWorkspace.shared.open(url)
            }
        @unknown default:
            break
        }
    }

    func getCamera() -> AVCaptureDevice? {
        let devices = AVCaptureDevice.DiscoverySession(
            deviceTypes: [.builtInWideAngleCamera, .externalUnknown], mediaType: .video,
            position: .unspecified
        ).devices
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
            Accessibility.speakWithSynthesizer(
                NSLocalizedString("camera.error.no_camera", value: "No camera available.", comment: "Error message when no camera is found"))
            return
        }
        deviceName = device.localizedName
        Accessibility.speak(
            String(format: NSLocalizedString("camera.using_camera", value: "Using %@", comment: "Speech message indicating which camera is being used"), deviceName))
        captureSession = AVCaptureSession()
        captureSession.sessionPreset = AVCaptureSession.Preset.photo
        cameraOutput = AVCapturePhotoOutput()
        if let input = try? AVCaptureDeviceInput(device: device) {
            if captureSession.canAddInput(input) {
                captureSession.addInput(input)
                if captureSession.canAddOutput(cameraOutput) {
                    captureSession.addOutput(cameraOutput)
                    captureSession.startRunning()
                    let settings = AVCapturePhotoSettings()
                    for c in stride(from: 3, to: 1, by: -1) {
                        Accessibility.speak("\(c)")
                        sleep(1)
                    }
                    Accessibility.speak("1")
                    cameraOutput.capturePhoto(with: settings, delegate: self)
                }
            } else {
                log("issue here : captureSession.canAddInput")
            }
        } else {
            log("some problem here")
        }
    }

    func photoOutput(
        _ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto,
        error: Error?
    ) {
        captureSession.stopRunning()
        log("photo captured")
        if let error = error {
            log(error)
        }

        if let dataImage = photo.fileDataRepresentation() {
            let dataProvider = CGDataProvider(data: dataImage as CFData)
            if let cgImage = CGImage(
                jpegDataProviderSource: dataProvider!, decode: nil, shouldInterpolate: true,
                intent: .defaultIntent)
            {
                NSSound(
                    contentsOfFile:
                        "/System/Library/Components/CoreAudio.component/Contents/SharedSupport/SystemSounds/system/Shutter.aif",
                    byReference: true)?.play()

                Navigation.mode = .CAMERA
                Navigation.appName = deviceName
                Navigation.cgImage = cgImage

                // Present menu to the user
                let alert = NSAlert()
                alert.messageText = NSLocalizedString("camera.action_menu.title", value: "Choose an action", comment: "Title for camera action selection dialog")
                alert.addButton(withTitle: NSLocalizedString("camera.action.recognize_image", value: "Recognize Image", comment: "Button to classify image using Vision"))
                alert.addButton(withTitle: NSLocalizedString("camera.action.recognize_llm", value: "Recognize image with LLM", comment: "Button to describe image using AI"))
                alert.addButton(withTitle: NSLocalizedString("camera.action.recognize_text", value: "Recognize text in image", comment: "Button to perform OCR on image"))
                alert.addButton(withTitle: NSLocalizedString("button.close", value: "Close", comment: "Close button title"))
                alert.window.defaultButtonCell = alert.buttons[0].cell as? NSButtonCell
                let response = alert.runModal()

                switch response {
                case .alertFirstButtonReturn:
                    log("Recognizing image using VisionKit")
                    let message = classify(cgImage: cgImage)
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        Accessibility.speak(message)
                    }

                case .alertSecondButtonReturn:
                    log("Recognizing image with LLM")
                    ask(image: cgImage)

                case .alertThirdButtonReturn:
                    log("Recognizing text in an image using VisionKit")
                    Navigation.displayResults = []
                    Navigation.cgImage = cgImage
                    Navigation.startOCR()
                    if !Navigation.displayResults.isEmpty || !Navigation.detectedQRCodes.isEmpty {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                            NSSound(
                                contentsOfFile: "/System/Library/Sounds/Pop.aiff", byReference: true
                            )?.play()
                        }
                    }

                case NSApplication.ModalResponse(rawValue: 1003):
                    log("Close button selected")
                    return

                default:
                    log("Invalid or unexpected menu response: \(response.rawValue)")
                }

            } else {
                log("Error: could not create CGIImage from photo.")
            }

        } else {
            log("Error getting file data representation from photo")
        }
    }
}
