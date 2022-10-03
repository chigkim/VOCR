//
//  Settings.swift
//  VOCR
//
//  Created by Chi Kim on 10/14/19.
//  Copyright © 2019 Chi Kim. All rights reserved.
//

import Cocoa

struct Settings {
	
	static var positionReset = true
	static var positionalAudio = false
    static var moveMouse = false
    
	static func load() {
		let defaults = UserDefaults.standard

			Settings.positionReset = defaults.bool(forKey:"positionReset")

		debugPrint("positionReset \(Settings.positionReset)")
		Settings.positionalAudio = defaults.bool(forKey:"positionalAudio")
		debugPrint("positionalAudio \(Settings.positionalAudio)")
        Settings.moveMouse = defaults.bool(forKey: "moveMouse")
        debugPrint("moveMouse \(Settings.moveMouse)")
	}
	
	static func save() {
		let defaults = UserDefaults.standard
		defaults.set(Settings.positionReset, forKey:"positionReset")
		defaults.set(Settings.positionalAudio, forKey:"positionalAudio")
	}
	
}

