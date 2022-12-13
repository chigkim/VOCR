//
//  Rectangle.swift
//  VOCR
//
//  Created by PPAT on 12/12/22.
//  Copyright © 2022 Chi Kim. All rights reserved.
//

import Foundation

class DetectedRectangle {
    var string: String
    var boundingBox: CGRect
    init(string: String, boundingBox: CGRect) {
        self.string = string
        self.boundingBox = boundingBox
    }
}
