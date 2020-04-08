//
//  ContinuityViewController.swift
//  VOCR
//
//  Created by Chi Kim on 4/7/20.
//  Copyright © 2020 Chi Kim. All rights reserved.
//

import Cocoa

class ContinuityViewController: NSViewController, NSServicesMenuRequestor {
	
	@IBOutlet var textView: NSTextView!
	@IBOutlet var imageView: NSImageView!
	
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
		debugPrint(image.alignmentRect)
		// self.imageView.image = image
		let cgImage = image.cgImage(forProposedRect: nil, context: nil, hints: nil)
		textView.string = classify(cgImage:cgImage!)
		imageView.image = image
		// This method has successfully read the pasteboard data.
		return true
	}

}
