//
//  ViewController.swift
//  VOCR
//
//  Created by Chi Kim on 7/29/19.
//  Copyright © 2019 Chi Kim. All rights reserved.
//

import Cocoa

final class AboutWindowController: NSObject, NSWindowDelegate {
    static let shared = AboutWindowController()

    private let windowController: NSWindowController

    private override init() {
        let storyboard = NSStoryboard(name: "Main", bundle: nil)
        let storyboardID = NSStoryboard.SceneIdentifier("aboutWindowStoryboardID")

        guard let windowController = storyboard.instantiateController(withIdentifier: storyboardID)
            as? NSWindowController
        else {
            fatalError("Unable to load About window controller")
        }

        self.windowController = windowController
        super.init()
        windowController.window?.delegate = self
    }

    func showWindow(_ sender: Any?) {
        windowController.showWindow(sender)
        windowController.window?.center()
        windowController.window?.makeKeyAndOrderFront(sender)
    }

    func windowWillClose(_ notification: Notification) {
        NSApplication.shared.hide(nil)
    }
}

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
