//
//  OCR.swift
//  VOCR
//
//  Created by Chi Kim on 10/12/19.
//  Copyright © 2019 Chi Kim. All rights reserved.
//


import Vision

func performOCR(cgImage:CGImage) -> [VNRecognizedTextObservation] {
	let textRecognitionRequest = VNRecognizeTextRequest()
	textRecognitionRequest.recognitionLevel = VNRequestTextRecognitionLevel.accurate
	textRecognitionRequest.minimumTextHeight = 0
	textRecognitionRequest.usesLanguageCorrection = true
	textRecognitionRequest.customWords = []
	textRecognitionRequest.usesCPUOnly = false
	let requestHandler = VNImageRequestHandler(cgImage: cgImage, options: [:])
	textRecognitionRequest.cancel()
	do {
		try requestHandler.perform([textRecognitionRequest])
	} catch _ {}
	guard let results = textRecognitionRequest.results as? [VNRecognizedTextObservation] else {
		return []
	}
	return results
}

