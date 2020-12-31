//
//  Player.swift
//  VOCR
//
//  Created by Chi Kim on 10/12/19.
//  Copyright © 2019 Chi Kim. All rights reserved.
//

import AudioKit
import AVFoundation

class Player {

	static let shared = Player()

	let osc:PinkNoise
	let panner:Panner
	let eq:BandPassButterworthFilter
	let env:AmplitudeEnvelope
	let ramp:Float = 0.1
	let engine = AudioEngine()

	init() {
		osc = PinkNoise(amplitude: 1.0)

		env = AmplitudeEnvelope(osc)
		env.attackDuration = 0.05
		env.decayDuration = 0.05
		env.sustainLevel = 1.0
		env.releaseDuration = 0.05
		
		eq = BandPassButterworthFilter(env)
		eq.bandwidth = 100

		let mixer = Mixer(eq)
		panner = Panner(mixer)

		osc.start()
		engine.output = panner
		try! engine.start()
		mixer.volume = 1.0
	}

	func play(_ freq:Float, _ pan:Float) {
		eq.$centerFrequency.ramp(to:freq, duration:ramp)
		panner.$pan.ramp(to: pan, duration: ramp)

		env.start()
		usleep(100000)
		env.stop()
		}
}

