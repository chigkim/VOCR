//
//  OCRTextSearch.swift
//  VOCR
//
//  Created by Victor Tsaran on 8/4/24.
//  Copyright © 2024 Chi Kim. All rights reserved.
//

import Cocoa

class OCRTextSearch {
	static let shared = OCRTextSearch()
	private init() {}
	
	private var lastSearchQuery = ""
	
	func search(query: String = "", fromBeginning: Bool = false, backward: Bool = false) {
		guard !Navigation.displayResults.isEmpty else {
			print("No OCR results to search.")
			return
		}
		
		let searchQuery = query.isEmpty ? self.getLastSearchQuery() : query
		
		// Ensure Navigation.l and Navigation.w have valid starting points
		var startIndex = (Navigation.l >= 0 && Navigation.l < Navigation.displayResults.count) ? Navigation.l : 0
		var startWordIndex = (startIndex >= 0 && startIndex < Navigation.displayResults.count && Navigation.w >= 0 && Navigation.w < Navigation.displayResults[startIndex].count) ? Navigation.w : 0
		
		if fromBeginning {
			startIndex = backward ? Navigation.displayResults.count - 1 : 0
			startWordIndex = backward ? Navigation.displayResults[startIndex].count - 1 : 0
		} else {
			if backward {
				startWordIndex -= 1
				if startWordIndex < 0 {
					startIndex -= 1
					if startIndex >= 0 {
						startWordIndex = Navigation.displayResults[startIndex].count - 1
					} else {
						startWordIndex = 0
					}
				}
			} else {
				startWordIndex += 1
				if startIndex < Navigation.displayResults.count && startWordIndex >= Navigation.displayResults[startIndex].count {
					startIndex += 1
					startWordIndex = 0
				}
			}
		}
		
		func isMatch(line: [Observation], wordIndex: Int) -> Bool {
			return line[wordIndex].value.localizedCaseInsensitiveContains(searchQuery)
		}
		
		if backward {
			var lineIndex = startIndex
			while lineIndex >= 0 {
				let line = Navigation.displayResults[lineIndex]
				let wordCount = line.count
				
				for wordIndex in stride(from: lineIndex == startIndex ? startWordIndex : wordCount - 1, through: 0, by: -1) {
					if isMatch(line: line, wordIndex: wordIndex) {
						Navigation.l = lineIndex
						Navigation.w = wordIndex
						setMouseCoordinates(x: lineIndex, y: wordIndex)
						print("Found '\(searchQuery)' at line \(lineIndex + 1), word \(wordIndex + 1)")
						Accessibility.speak("\(Navigation.displayResults[lineIndex][wordIndex].value)")
						return
					}
				}
				lineIndex -= 1
			}
		} else {
			var lineIndex = startIndex
			while lineIndex < Navigation.displayResults.count {
				let line = Navigation.displayResults[lineIndex]
				let wordCount = line.count
				
				for wordIndex in (lineIndex == startIndex ? startWordIndex : 0)..<wordCount {
					if isMatch(line: line, wordIndex: wordIndex) {
						Navigation.l = lineIndex
						Navigation.w = wordIndex
						setMouseCoordinates(x: lineIndex, y: wordIndex)
						print("Found '\(searchQuery)' at line \(lineIndex + 1), word \(wordIndex + 1)")
						Accessibility.speak("\(Navigation.displayResults[lineIndex][wordIndex].value)")
						return
					}
				}
				lineIndex += 1
			}
		}
		
		Accessibility.speak("Not found.")
	}
	
	func showSearchDialog() {
		if (!Shortcuts.navigationActive) {
			return
		}
		
		let alert = NSAlert()
		alert.messageText = "Search OCR Text"
		
		let textField = NSTextField(frame: NSRect(x: 0, y: 0, width: 200, height: 24))
		textField.stringValue = lastSearchQuery // Recall last search term
		alert.accessoryView = textField
		DispatchQueue.main.async {
			alert.window.makeFirstResponder(textField)
		}
		
		alert.addButton(withTitle: "From Beginning")
		alert.addButton(withTitle: "From Current")
		alert.addButton(withTitle: "Cancel")
		// Set "From Current" as the default button
		alert.window.defaultButtonCell = alert.buttons[1].cell as? NSButtonCell
		
		let response = alert.runModal()
		
		if response == .alertFirstButtonReturn { // From Beginning
			lastSearchQuery = textField.stringValue
			self.search(query: lastSearchQuery, fromBeginning: true)
		} else if response == .alertSecondButtonReturn { // From Current
			lastSearchQuery = textField.stringValue
			self.search(query: lastSearchQuery)
		}
		sleep(1)
	}
	
	private func getLastSearchQuery() -> String {
		return lastSearchQuery
	}
	
	private func setMouseCoordinates(x:Int, y:Int) {
		if Settings.moveMouse {
			CGWarpMouseCursorPosition(Navigation.convert2coordinates(Navigation.displayResults[x][y].boundingBox))
		}
		
	}
	
}
