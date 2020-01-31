//
//  AXUIElement Extension.swift
//  Inspector
//
//  Created by Chi Kim on 10/28/18.
//  Copyright © 2018 Chi Kim. All rights reserved.
//

import Foundation

extension AXUIElement {
	
	func attributes() -> [String] {
		var cfArray: CFArray?
		let error = AXUIElementCopyAttributeNames(self, &cfArray)
		if error == .success, let names = cfArray as? [String] {
			return names
		}
		return []
	}
	
	func parameterizedAttributes() -> [String] {
		var cfArray: CFArray?
		let error = AXUIElementCopyParameterizedAttributeNames(self, &cfArray)
		if error == .success, let names = cfArray as? [String] {
			return names
		} else if error == .attributeUnsupported {
			return ["Error attribute not supported"]
		} else if error == .noValue {
			return ["Error no value"]
		} else if error == .illegalArgument {
			return ["Error illegal arguement"]
		} else if error == .invalidUIElement {
			return ["Error invalud ui element"]
		} else if error == .cannotComplete {
			return ["Error cannot complete"]
		} else if error == .notImplemented {
			return ["Error not implemented"]
		} else {
			return ["Error Unknown"]
		}
	}



	

	func value(of:String) -> String{
		var cfValue:CFTypeRef?
		let error = AXUIElementCopyAttributeValue(self, of as CFString, &cfValue)
		if error == .success {
			/*
			let axValue = cfValue as! AXValue
			let type = AXValueGetType(axValue)
			var atrPtr:UnsafeMutableRawPointer?
			AXValueGetValue(axValue, type, &atrPtr)
			if let attribute = atrPtr as? String {
			}
			
			let attribute = ""
			var attributePtr = UnsafeMutableRawPointer(Unmanaged<AnyObject>.passUnretained(attribute as AnyObject).toOpaque())
			AXValueGetValue(axValue, type, &attributePtr)
			if let              value = Unmanaged<AnyObject>.fromOpaque(attributePtr).takeUnretainedValue() as? String {
			}
			*/
			
			guard let axValue = cfValue as? String else {
				return String( reflecting:cfValue).trimmingCharacters(in: .whitespacesAndNewlines)
			}
			return axValue
		} else if error == .attributeUnsupported {
			return "Error attribute not supported"
		} else if error == .noValue {
			return "Error no value"
		} else if error == .illegalArgument {
			return "Error illegal arguement"
		} else if error == .invalidUIElement {
			return "Error invalud ui element"
		} else if error == .cannotComplete {
			return "Error cannot complete"
		} else if error == .notImplemented {
			return "Error not implemented"
		} else {
			return "Error Unknown"
		}
	}
	
	func children() -> [AXUIElement] {
		var children:CFTypeRef?
		var error:AXError?
		if self.value(of:"AXRole") == "AXTable" {
			error = AXUIElementCopyAttributeValue(self, "AXRows" as CFString, &children)
		} else {
			error = AXUIElementCopyAttributeValue(self, "AXChildren" as CFString, &children)
		}
		if error == .success, let elements = children as? [AXUIElement] {
			return elements
		}
		return []
	}
}
