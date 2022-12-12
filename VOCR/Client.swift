//
//  Client.swift
//  VOCR
//
//  Created by Chi Kim on 12/11/22.
//  Copyright © 2022 Chi Kim. All rights reserved.
//

import Foundation
import Socket

class Client {
	
	static let shared = Client()
	var s:Socket?
	
	init() {
		do {
			print("Connecting...")
			s = try Socket.create()
			try s?.connect(to:"localhost", port:12345)
			print("Connected.")
		} catch {
			print("Error connecting.")
		}
	}
	
	func send(_ data:Data) {
		do {
			var length = UInt32(data.count)
			print("Sending", length)
			var packet = Data(bytes: &length, count: MemoryLayout.size(ofValue: length))
			packet.append(data)
			try s?.write(from: packet)
		} catch {
		}
	}

	func recv() -> Data? {
		do {
			var p = UnsafeMutablePointer<CChar>.allocate(capacity: 4)
			try s?.read(into: p, bufSize: 4, truncate:true)
			var packet = Data(bytes: p, count: 4)
			p.deallocate()
			let buf:Int = packet.withUnsafeBytes {$0.pointee}
			print("Receiving", buf)
			p = UnsafeMutablePointer<CChar>.allocate(capacity: buf)
			try s?.read(into: p, bufSize: buf, truncate:true)
			packet = Data(bytes: p, count: buf)
			p.deallocate()
			return packet
		} catch {
			print("Receiving error")
			return nil
		}
	}

}
