//
//  Player.swift
//  VOCR
//
//  Created by Chi Kim on 10/12/19.
//  Copyright © 2019 Chi Kim. All rights reserved.
//

import AudioKit

class Player {

	static let shared = Player()
	let osc = AKOscillator()
	let env:AKAmplitudeEnvelope
	var panner = AKPanner()

	init() {
		osc.amplitude = 0.3
		env = AKAmplitudeEnvelope(osc)
		env.attackDuration = 0.05
		env.decayDuration = 0.1
		env.sustainLevel = 0.01
		env.releaseDuration = 0.05
		panner = AKPanner(env)
		AudioKit.output = panner
		try! AudioKit.start()
		osc.start()
		panner.start()
	}

	func play(_ freq:Double, _ pan:Double) {
		osc.frequency = freq
		panner.pan = pan
		env.start()
		usleep(200000)
		env.stop()
	}

	func change() {
			osc.frequency = random(100, 5000)
			panner.pan = random(-1, 1)
			env.start()
			usleep(200000)
			env.stop()
		}



}
