//
//  ViewController.swift
//  VOCR
//
//  Created by Chi Kim on 7/29/19.
//  Copyright © 2019 Chi Kim. All rights reserved.
//

import Cocoa


class AboutViewController: NSViewController {

	@IBOutlet var info: NSTextField!
	
	override func viewDidLoad() {
		super.viewDidLoad()
		info.stringValue = "\(Bundle.main.version)"
		// Do any additional setup after loading the view.
	}

	override var representedObject: Any? {
		didSet {
		// Update the view, if already loaded.
		}
	}


}

