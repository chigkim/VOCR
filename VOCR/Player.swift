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

	let osc:AKPinkNoise
	let panner:AKPanner
	let eq:AKBandPassButterworthFilter
		let env:AKAmplitudeEnvelope
	let ramp = 0.1
	
	init() {
		osc = AKPinkNoise(amplitude: 1.0)
		osc.rampDuration = ramp
		env = AKAmplitudeEnvelope(osc)
		env.rampDuration = ramp
		env.attackDuration = 0.05
		env.decayDuration = 0.05
		env.sustainLevel = 0.5
		env.releaseDuration = 0.05
		
		eq = AKBandPassButterworthFilter(env)
		eq.bandwidth = 100
		eq.rampDuration = ramp
		let mixer = AKMixer(eq)
		mixer.volume = 2.0
		panner = AKPanner(mixer)
		panner.rampDuration = ramp
		AudioKit.output = panner
		try! AudioKit.start()
	}

	func play(_ freq:Double, _ pan:Double) {
		eq.centerFrequency = freq
		panner.pan = pan
		env.start()
		usleep(100000)
		env.stop()
		}
}

