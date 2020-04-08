//
//  ImportViewController.swift
//  VOCR
//
//  Created by Chi Kim on 4/7/20.
//  Copyright © 2020 Chi Kim. All rights reserved.
//

import Cocoa

class ImportViewController: NSViewController, NSServicesMenuRequestor {
	
	@IBOutlet var textView: NSTextView!
	@IBOutlet var imageView: NSImageView!
	
	@IBAction func chooseSource(_ sender: NSButton) {
		let menu = NSMenu()
		menu.addItem(withTitle: "File", action: #selector(importFile), keyEquivalent: "")
		NSMenu.popUpContextMenu(menu, with: NSEvent(), for: sender)
	}
	
	@objc func importFile() {
		debugPrint("Choose a file")
		let openPanel = NSOpenPanel()
		openPanel.canChooseFiles = true
		openPanel.allowsMultipleSelection = false
		openPanel.canChooseDirectories = false
		openPanel.canCreateDirectories = false
		openPanel.allowedFileTypes = ["jpg","png","pdf","pct", "bmp", "tiff"]
		openPanel.begin { response in
			if response == .OK {
				let image = NSImage(byReferencing: openPanel.url!)
				self.process(image)
			}
		}
	}
	
	override func viewDidLoad() {
		super.viewDidLoad()
		// Do view setup here.
		textView.font = NSFont(name: "Times", size: 20)
		self.view.window?.zoom(self)
	}
	
	override func validRequestor(forSendType sendType: NSPasteboard.PasteboardType?, returnType: NSPasteboard.PasteboardType?) -> Any? {
		if let pasteboardType = returnType,
			NSImage.imageTypes.contains(pasteboardType.rawValue) {
			return self
		} else {
			return super.validRequestor(forSendType: sendType, returnType: returnType)
		}
	}
	
	func readSelection(from pasteboard: NSPasteboard) -> Bool {
		// Verify that the pasteboard contains image data.
		guard pasteboard.canReadItem(withDataConformingToTypes: NSImage.imageTypes) else {
			return false
		}
		// Load the image.
		guard let image = NSImage(pasteboard: pasteboard) else {
			return false
		}
		// Incorporate the image into the app.
		process(image)
		// This method has successfully read the pasteboard data.
		return true
	}
	
	func process(_ image:NSImage) {
		if image.isValid {
			let cgImage = image.cgImage(forProposedRect: nil, context: nil, hints: nil)
			textView.string = classify(cgImage:cgImage!)
			imageView.image = image
		} else {
			textView.string = "File type is not supported!"
		}
		
	}
}
