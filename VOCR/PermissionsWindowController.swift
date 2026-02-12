//
//  PermissionsWindowController.swift
//  VOCR
//
//  Created by Claude Code on 2/11/26.
//  Copyright © 2026 Chi Kim. All rights reserved.
//

import Cocoa

final class PermissionsWindowController: NSWindowController {

    static let shared = PermissionsWindowController()

    private let rootVC = PermissionsViewController()

    private init() {
        let window = NSWindow(
            contentRect: NSRect(x: 200, y: 200, width: 600, height: 500),
            styleMask: [.titled, .closable, .resizable],
            backing: .buffered,
            defer: false
        )
        window.title = NSLocalizedString(
            "window.permissions.title",
            value: "Permissions",
            comment: "Window title for permissions window")

        super.init(window: window)

        window.contentViewController = rootVC
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func showWindow(_ sender: Any?) {
        super.showWindow(sender)
        window?.center()
        window?.makeKeyAndOrderFront(sender)
    }
}
