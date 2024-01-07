//
//  Settings.swift
//  VOCR
//
//  Created by Chi Kim on 10/14/19.
//  Copyright © 2019 Chi Kim. All rights reserved.
//

import Cocoa

enum Settings {

	static var positionReset = true
	static var positionalAudio = false
	static var moveMouse = true
	static var launchOnBoot = true
	static var autoScan = false
	static var GPTAPIKEY = ""

	static func load() {
		let defaults = UserDefaults.standard
		Settings.positionReset = defaults.bool(forKey:"positionReset")
		debugPrint("positionReset \(Settings.positionReset)")
		Settings.positionalAudio = defaults.bool(forKey:"positionalAudio")
		debugPrint("positionalAudio \(Settings.positionalAudio)")
		Settings.launchOnBoot = defaults.bool(forKey:"launchOnBoot")
		Settings.autoScan = defaults.bool(forKey:"autoScan")
		debugPrint("autoScan \(Settings.autoScan)")
		if let apikey = defaults.string(forKey: "GPTAPIKEY") {
			Settings.GPTAPIKEY = apikey
		}
	}
	
	static func save() {
		let defaults = UserDefaults.standard
		defaults.set(Settings.positionReset, forKey:"positionReset")
		defaults.set(Settings.positionalAudio, forKey:"positionalAudio")
		defaults.set(Settings.launchOnBoot, forKey:"launchOnBoot")
		defaults.set(Settings.autoScan, forKey:"autoScan")
		defaults.set(Settings.GPTAPIKEY, forKey:"GPTAPIKEY")
	}
	
}

