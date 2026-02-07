//
//  Observation.swift
//  VOCR
//
//  Created by Chi Kim on 1/5/24.
//  Copyright © 2024 Chi Kim. All rights reserved.
//

import Foundation
import Vision

struct GPTBoundingBox: Decodable {
    let top_left_x: Float
    let top_left_y: Float
    let width: Float
    let height: Float
}

struct GPTObservation: Decodable {
    let label: String
    let uid: Int
    let description: String
    let content: String
    let boundingBox: GPTBoundingBox

    // Coding keys to match the JSON property names
    enum CodingKeys: String, CodingKey {
        case label
        case uid
        case description
        case content
        case boundingBox
    }
}

struct GPTObservations: Decodable {
    let elements: [GPTObservation]

    // Coding keys to match the JSON property names
    enum CodingKeys: String, CodingKey {
        case elements
    }
}

struct Observation {

    var boundingBox: CGRect
    var value: String
    var vnObservation: VNRecognizedTextObservation?
    var gptObservation: GPTObservation?

    init(_ obs: GPTObservation) {
        self.gptObservation = obs
        self.value = obs.label + "\n" + obs.content + "\n" + obs.description
        let x = CGFloat(obs.boundingBox.top_left_x)
        let y_topLeft = CGFloat(obs.boundingBox.top_left_y)
        let width = CGFloat(obs.boundingBox.width)
        let height = CGFloat(obs.boundingBox.height)
        let y_bottomLeft = 1 - y_topLeft - height
        let rect = CGRect(x: x, y: y_bottomLeft, width: width, height: height)
        self.boundingBox = rect
    }

    init(_ obs: VNRecognizedTextObservation) {
        self.vnObservation = obs
        self.value = obs.topCandidates(1)[0].string
        self.boundingBox = obs.boundingBox
    }

    init(_ obs: VNRectangleObservation, value: String) {
        self.boundingBox = obs.boundingBox
        self.value = value
    }

}
