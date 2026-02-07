//
//  ViewController.swift
//  VOCR
//
//  Created by Chi Kim on 7/29/19.
//  Copyright © 2019 Chi Kim. All rights reserved.
//

import Cocoa

class AboutViewController: NSViewController, NSWindowDelegate {

    @IBOutlet var info: NSTextField!

    override func viewDidLoad() {
        super.viewDidLoad()
        info.stringValue = "\(Bundle.main.version)"
        // Do any additional setup after loading the view.
    }

    override func viewDidAppear() {
        super.viewDidAppear()
        if let window = self.view.window {
            window.delegate = self
        }
    }

    override var representedObject: Any? {
        didSet {
            // Update the view, if already loaded.
        }
    }

    func windowWillClose(_ notification: Notification) {
        NSApplication.shared.hide(nil)
    }

}
