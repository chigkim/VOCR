//
//  FileLogger.swift
//  VOCR
//
//  Created by Chi Kim on 1/16/24.
//  Copyright © 2024 Chi Kim. All rights reserved.
//

import Foundation

class FileLogger {
    static let shared = FileLogger()

    private let fileURL: URL
    private var fileHandle: FileHandle?
    private let queue = DispatchQueue(label: "com.yourapp.filelogger", qos: .background)

    init() {
        let documentsDirectory = FileManager.default.urls(
            for: .documentDirectory, in: .userDomainMask
        )
        .first!
        self.fileURL = documentsDirectory.appendingPathComponent("VOCR.txt")
        if FileManager.default.fileExists(atPath: self.fileURL.path) {
            try! FileManager.default.removeItem(at: self.fileURL)
        }

    }

    deinit {
        fileHandle?.closeFile()
    }

    private func setupFileHandleIfNeeded() {
        if !FileManager.default.fileExists(atPath: self.fileURL.path) {
            FileManager.default.createFile(
                atPath: self.fileURL.path, contents: nil, attributes: nil)
            fileHandle = try? FileHandle(forWritingTo: self.fileURL)
        }

        if fileHandle == nil {
            fileHandle = try? FileHandle(forWritingTo: self.fileURL)
        }
    }

    func write(_ message: String) {
        setupFileHandleIfNeeded()

        queue.async { [weak self] in
            guard let self = self, Settings.writeLog else { return }

            guard let data = message.data(using: .utf8) else { return }
            self.fileHandle?.seekToEndOfFile()
            self.fileHandle?.write(data)
        }
    }
    func log(_ message: String) {
        let timestamp = Date().description
        let logMessage = "\(timestamp)\n\(message)\n"
        print(logMessage)
        if Settings.writeLog {
            write(logMessage)
        }
    }

    func read() -> String? {
        return try? String(contentsOf: fileURL, encoding: .utf8)
    }

}
