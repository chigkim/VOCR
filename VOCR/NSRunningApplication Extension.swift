//
//  NSRunningApplication Extension.swift
//  Inspector
//
//  Created by Chi Kim on 10/28/18.
//  Copyright © 2018 Chi Kim. All rights reserved.
//

import Cocoa

extension NSRunningApplication {
	func windows() -> [AXUIElement] {
		let appRef = AXUIElementCreateApplication(self.processIdentifier)
		var windowList:CFTypeRef?
		AXUIElementCopyAttributeValue(appRef, "AXWindows" as CFString, &windowList)
		return windowList as! [AXUIElement]
	}
}
