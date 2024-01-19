//
//  KeychainManager.swift
//  VOCR
//
//  Created by Chi Kim on 1/19/24.
//  Copyright © 2024 Chi Kim. All rights reserved.
//

import Foundation
import Security

class KeychainManager {
	
	@discardableResult
	static func store(key: String, data: Data) -> OSStatus {
		let query = [
			kSecClass as String: kSecClassGenericPassword,
			kSecAttrAccount as String: key,
			kSecValueData as String: data,
			kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlocked] as [String : Any]

		SecItemDelete(query as CFDictionary) // Remove any existing item with the same key
		return SecItemAdd(query as CFDictionary, nil)
	}

	static func retrieve(key: String) -> Data? {
		let query = [
			kSecClass as String: kSecClassGenericPassword,
			kSecAttrAccount as String: key,
			kSecReturnData as String: kCFBooleanTrue as Any,
			kSecMatchLimit as String: kSecMatchLimitOne] as [String : Any]

		var itemCopy: AnyObject?
		let status = SecItemCopyMatching(query as CFDictionary, &itemCopy)

		if status == noErr, let data = itemCopy as? Data {
			return data
		} else {
			return nil
		}
	}
}
