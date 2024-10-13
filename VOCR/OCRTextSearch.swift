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
		var startIndex = Navigation.l
		var startWordIndex = Navigation.w
		
		if fromBeginning {
			startIndex = backward ? Navigation.displayResults.count - 1 : 0
			startWordIndex = backward ? Navigation.displayResults[startIndex].count - 1 : 0
		} else {
			if backward {
				startWordIndex -= 1
				if startWordIndex < 0 {
					startIndex -= 1
					startWordIndex = startIndex >= 0 ? Navigation.displayResults[startIndex].count - 1 : 0
				}
			} else {
				startWordIndex += 1
				if startWordIndex >= Navigation.displayResults[startIndex].count {
					startIndex += 1
					startWordIndex = 0
				}
			}
		}
		
		let lineCount = Navigation.displayResults.count
		
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
						print("Found '\(searchQuery)' at line \(lineIndex + 1), word \(wordIndex + 1)")
						Accessibility.speakWithSynthesizer("Found \(searchQuery) in \(Navigation.displayResults[lineIndex][wordIndex].value)")
						return
					}
				}
				lineIndex -= 1
			}
		} else {
			var lineIndex = startIndex
			while lineIndex < lineCount {
				let line = Navigation.displayResults[lineIndex]
				let wordCount = line.count
				
				for wordIndex in (lineIndex == startIndex ? startWordIndex : 0)..<wordCount {
					if isMatch(line: line, wordIndex: wordIndex) {
						Navigation.l = lineIndex
						Navigation.w = wordIndex
						print("Found '\(searchQuery)' at line \(lineIndex + 1), word \(wordIndex + 1)")
						Accessibility.speakWithSynthesizer("Found \(searchQuery) in \(Navigation.displayResults[lineIndex][wordIndex].value)")
						return
					}
				}
				lineIndex += 1
			}
		}
		
		Accessibility.speakWithSynthesizer("Text not found '\(searchQuery)'.")
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
	}
	
	private func getLastSearchQuery() -> String {
		return lastSearchQuery
	}
}
