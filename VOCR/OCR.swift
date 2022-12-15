//
//  OCR.swift
//  VOCR
//
//  Created by Chi Kim on 10/12/19.
//  Copyright © 2019 Chi Kim. All rights reserved.
//


import Vision

func performOCR(cgImage:CGImage) -> [VNRecognizedTextObservation] {
	let requestHandler = VNImageRequestHandler(cgImage: cgImage, options: [:])
	let textRecognitionRequest = VNRecognizeTextRequest()
	textRecognitionRequest.recognitionLevel = VNRequestTextRecognitionLevel.accurate
	textRecognitionRequest.minimumTextHeight = 0
	textRecognitionRequest.usesLanguageCorrection = true
	textRecognitionRequest.customWords = []
	textRecognitionRequest.usesCPUOnly = false
	textRecognitionRequest.cancel()
	let rectDetectRequest = VNDetectRectanglesRequest()
	rectDetectRequest.maximumObservations = 16
	rectDetectRequest.minimumConfidence = 0.6
	rectDetectRequest.minimumAspectRatio = 0.3
	rectDetectRequest.cancel()
	do {
		try requestHandler.perform([textRecognitionRequest, rectDetectRequest])
	} catch _ {}
	for r in rectDetectRequest.results! {
		let tl = Navigation.shared.convertPoint(r.topLeft)
		let tr = Navigation.shared.convertPoint(r.topRight)
		let bl = Navigation.shared.convertPoint(r.bottomLeft)
		let br = Navigation.shared.convertPoint(r.bottomRight)
		let box = CGRect(x: tl.x, y: tl.y, width: br.x-bl.x, height: br.y-tr.y)
		debugPrint("Box: \(box)")
	}
	guard let results = textRecognitionRequest.results else {
		return []
	}
	return results
}

