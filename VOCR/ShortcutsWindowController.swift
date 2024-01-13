//
//  ShortcutWindowController.swift
//  VOCR
//
//  Created by Chi Kim on 1/10/24.
//  Copyright © 2024 Chi Kim. All rights reserved.
//

import Foundation
import Cocoa
import HotKey

class ShortcutsWindowController: NSWindowController, NSTableViewDelegate, NSTableViewDataSource {

	static let shared = ShortcutsWindowController()
	var tableView: NSTableView!


	init() {
		super.init(window: nil)
		setupWindow()
		setupTableView()
		refreshTable()
		window?.contentView?.needsDisplay = true
	}
	
	required init?(coder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}

	private func setupWindow() {
		let window = NSWindow(contentRect: NSRect(x: 0, y: 0, width: 400, height: 300),
							  styleMask: [.titled, .closable],
							  backing: .buffered, defer: false)
		self.window = window
		self.window?.title = "Customize Shortcuts"
	}
	
	private func setupTableView() {
		tableView = NSTableView(frame: self.window!.contentView!.bounds)
		tableView.delegate = self
		tableView.dataSource = self
		let nameColumn = NSTableColumn(identifier: NSUserInterfaceItemIdentifier("NameColumn"))
		nameColumn.title = "Name"
		tableView.addTableColumn(nameColumn)
		let hotkeyColumn = NSTableColumn(identifier: NSUserInterfaceItemIdentifier("HotkeyColumn"))
		hotkeyColumn.title = "Hotkey"
		tableView.addTableColumn(hotkeyColumn)
		self.window?.contentView?.addSubview(tableView)
		refreshTable()
	}

	func refreshTable() {
		DispatchQueue.main.async {
			self.tableView.reloadData()
		}
	}

	func numberOfRows(in tableView: NSTableView) -> Int {
		return Shortcuts.shortcuts.count
	}
	
	func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
		let shortcut = Shortcuts.shortcuts[row]
//		debugPrint(tableColumn!.title, row)
		switch tableColumn?.identifier {
		case NSUserInterfaceItemIdentifier("NameColumn"):
			let cellView = NSTableCellView(frame: NSRect(x: 0, y: 0, width: tableColumn!.width, height: tableView.rowHeight))
			let textField = NSTextField(frame: cellView.bounds)
			textField.stringValue = shortcut.name
			textField.isEditable = false
			textField.isBezeled = false
			textField.drawsBackground = false
			textField.autoresizingMask = [.width, .height] // Resize with the cell view
			cellView.addSubview(textField)
//			debugPrint("Cell Name:", shortcut.name)
			return cellView

		case NSUserInterfaceItemIdentifier("HotkeyColumn"):
			let cellView = NSTableCellView(frame: NSRect(x: 0, y: 0, width: tableColumn!.width, height: tableView.rowHeight))
			let button = NSButton(frame: NSRect(x: 0, y: 0, width: tableColumn!.width, height: tableView.rowHeight))
			button.title = shortcut.keyName
			button.tag = row
			button.target = self
			button.action = #selector(reassignShortcut(_:))
			cellView.addSubview(button)
//			debugPrint("Cell Hotkey", shortcut.keyName)
			return cellView

		default:
			return nil
		}
	}

	@objc func reassignShortcut(_ sender: NSButton) {
		let shortcutIndex = sender.tag
		let recorder = ShortcutRecorderView(frame: self.window!.contentView!.bounds)
		recorder.onShortcutRecorded = { [weak self] event in
			guard let strongSelf = self else { return }
			Shortcuts.shortcuts[shortcutIndex].key = UInt32(event.keyCode)
			Shortcuts.shortcuts[shortcutIndex].modifiers = event.modifierFlags.carbonFlags
			Shortcuts.shortcuts[shortcutIndex].keyName = event.modifierFlags.description+event.charactersIgnoringModifiers!
			strongSelf.refreshTable()
			let data = try? JSONEncoder().encode(Shortcuts.shortcuts)
			UserDefaults.standard.set(data, forKey: "userShortcuts")
			Shortcuts.register()
		}
		
		self.window!.contentView!.addSubview(recorder)
		self.window!.makeFirstResponder(recorder)
	}


	override func keyDown(with event: NSEvent) {
		super.keyDown(with: event)

		if event.keyCode == 51 { // 51 is the key code for the Delete key
			deleteSelectedRow()
		}
	}

	func deleteSelectedRow() {
		guard tableView.selectedRow >= 0 else { return }
		let row = tableView.selectedRow

		// Remove the shortcut from the array and update UserDefaults
		Shortcuts.shortcuts.remove(at: row)
		let data = try? JSONEncoder().encode(Shortcuts.shortcuts)
		UserDefaults.standard.set(data, forKey: "userShortcuts")
		Shortcuts.register()
		refreshTable()
	}

}


class ShortcutRecorderView: NSView {
	var onShortcutRecorded: ((NSEvent) -> Void)?

	override var acceptsFirstResponder: Bool { return true }

	override func keyDown(with event: NSEvent) {
		onShortcutRecorded?(event)
		self.removeFromSuperview() // Remove the view once the key is captured
	}
}

