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

    func search(query: String) {
	guard !Navigation.displayResults.isEmpty else {
	    print("No OCR results to search.") 
	    return 
	}

	for (lineIndex, line) in Navigation.displayResults.enumerated() {
	    let lineText = line.map { $0.value }.joined(separator: " ")

	    if lineText.localizedCaseInsensitiveContains(query) {
		// Found the query! Probably OK to move VOCR cursor there!
		Navigation.l = lineIndex
			Accessibility.speakWithSynthesizer("Found '\(query)' on line \(lineIndex + 1)")
				return
	    }
	}
		
				Accessibility.speakWithSynthesizer("Not found '\(query)'.")
    }

    func showSearchDialog() {
		if (!Shortcuts.navigationActive) {
			return
		}
		
	let alert = NSAlert()
	alert.messageText = "Search OCR Text"
	alert.addButton(withTitle: "Search")
	alert.addButton(withTitle: "Cancel")

	let textField = NSTextField(frame: NSRect(x: 0, y: 0, width: 200, height: 24))
	alert.accessoryView = textField
		DispatchQueue.main.async {
			alert.window.makeFirstResponder(textField)
		}
		
	let response = alert.runModal()

	if response == .alertFirstButtonReturn {
	    let searchQuery = textField.stringValue 
	    self.search(query: searchQuery) 
	} 
    }
}
