//
//  Double Extension.swift
//  VOCR
//
//  Created by Chi Kim on 10/12/19.
//  Copyright © 2019 Chi Kim. All rights reserved.
//

public extension Double {
		func normalize(from: ClosedRange<Double>, into: ClosedRange<Double>) -> Double {
			let fromMaxMinusMin = from.upperBound - from.lowerBound
			let intoMaxMinusMin = into.upperBound - into.lowerBound
				return Swift.max(
					into.lowerBound,
					Swift.min(
						into.upperBound,
						(self - from.lowerBound) / fromMaxMinusMin * intoMaxMinusMin + into.lowerBound
					)
				)
			
	}

}

