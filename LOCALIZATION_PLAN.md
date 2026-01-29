# VOCR Localization Plan

## Executive Summary

VOCR is a macOS accessibility application written entirely in Swift using AppKit (Cocoa) framework. Currently, it has **no localization infrastructure** - all user-facing strings are hardcoded. This plan outlines the steps needed to make VOCR fully localization-ready.

## Current State

### Findings
- **Language**: Swift (100%)
- **UI Framework**: AppKit/Cocoa (not SwiftUI)
- **Localization Status**: None (all strings hardcoded)
- **Existing Localization Files**: Only `Base.lproj` folder exists (English)
- **No `NSLocalizedString()` calls**: All strings are literal values

### User-Facing String Locations

The application contains user-facing strings in the following files (ordered by volume):

1. **Settings.swift** - Menu items, dialogs, settings labels (HIGH PRIORITY)
2. **Navigation.swift** - Status messages, mode names, error messages
3. **Utils.swift** - Alert titles, prompts, save dialogs
4. **Shortcuts.swift** - Shortcut names, navigation messages
5. **PresetEditorWindowController.swift** - Form labels, buttons, placeholders
6. **PresetManagerViewController.swift** - Table columns, buttons
7. **ShortcutsWindowController.swift** - Window title, column headers
8. **OCRTextSearch.swift** - Search dialog, buttons, status messages
9. **OpenAIAPI.swift** - Error messages
10. **AutoUpdateManager.swift** - Update notifications
11. **AppDelegate.swift** - Status bar text, startup messages
12. **Info.plist** - Usage permission descriptions
13. **Main.storyboard** - Standard macOS menu structure

## Localization Strategy

### Recommended Approach: Modern String Catalogs (.xcstrings)

Since this is an active project on macOS, we should use **Xcode's modern String Catalogs** (.xcstrings) introduced in Xcode 15+, rather than legacy .strings files.

**Advantages**:
- Single file per table vs. multiple .lproj folders
- Built-in validation and completion checking
- Better merge conflict handling in version control
- IDE integration for translators
- Automatic extraction of strings from code
- Supports pluralization and string variations

**Fallback**: If older Xcode versions need to be supported, use traditional `.strings` files.

## Implementation Plan

### Phase 1: Setup Localization Infrastructure

#### Task 1.1: Create String Catalog
- Add `Localizable.xcstrings` to the VOCR project
- Configure base language (English) in Xcode project settings
- Add target localizations (Spanish, French, German, Japanese, etc. - as needed)

#### Task 1.2: Configure Info.plist Localization
- Create `InfoPlist.xcstrings` or `InfoPlist.strings` for each language
- Localize usage permission descriptions:
  - `NSAppleEventsUsageDescription`
  - `NSCameraUsageDescription`
  - `CFBundleTypeName`

#### Task 1.3: Configure Storyboard Localization
- Export `Main.storyboard` for localization
- Create localized versions for each target language
- Alternatively, move away from storyboard menus to programmatic creation

### Phase 2: Wrap Hardcoded Strings

This is the most labor-intensive phase. We need to replace all hardcoded strings with `NSLocalizedString()` calls.

#### Task 2.1: Settings.swift (~100+ strings)
Replace strings like:
```swift
// Before:
menuItem.title = "Target Window"

// After:
menuItem.title = NSLocalizedString("menu.targetWindow", 
                                   value: "Target Window",
                                   comment: "Menu item for selecting target window")
```

**Categories to localize**:
- Menu items and submenus
- Dialog titles and messages
- Button labels
- Alert messages
- Preference descriptions

#### Task 2.2: Navigation.swift (~30+ strings)
**Categories to localize**:
- Mode names ("Window", "VOCursor", "Camera")
- Status announcements ("Finished scanning...", "Nothing found")
- Error messages
- VoiceOver announcements

#### Task 2.3: Utils.swift (~20+ strings)
**Categories to localize**:
- Alert titles and messages
- Dialog prompts
- Save/cancel button labels
- Error messages
- Status notifications

#### Task 2.4: Shortcuts.swift (~25+ strings)
**Categories to localize**:
- Shortcut action names (visible in UI)
- Navigation messages
- Status announcements

#### Task 2.5: Preset Management Files (~40+ strings)
Files: `PresetEditorWindowController.swift`, `PresetManagerViewController.swift`

**Categories to localize**:
- Form labels ("Name:", "API Key:", "Model:", etc.)
- Button labels ("Add", "Edit", "Delete", "Save", "Cancel")
- Window titles
- Table column headers
- Placeholder text
- Error messages

#### Task 2.6: Other UI Files (~30+ strings)
Files: `ShortcutsWindowController.swift`, `OCRTextSearch.swift`, `AppDelegate.swift`, `AutoUpdateManager.swift`

**Categories to localize**:
- Window titles
- Search dialog text
- Status bar messages
- Update notifications
- Miscellaneous UI elements

#### Task 2.7: Error Messages (~15+ strings)
File: `OpenAIAPI.swift` and others

**Categories to localize**:
- API error messages
- JSON parsing errors
- Connection errors

### Phase 3: Handle Dynamic Strings with String Interpolation

Many strings contain dynamic values that need special handling:

```swift
// Before:
"Finished scanning \(app), \(window)"

// After:
String(format: NSLocalizedString("navigation.finishedScanning",
                                 value: "Finished scanning %@, %@",
                                 comment: "Announcement after scan completes. First %@ is app name, second is window name"),
       app, window)
```

**Files with dynamic strings**:
- Navigation.swift (status messages with app/window names)
- Utils.swift (alerts with variable content)
- AutoUpdateManager.swift (version numbers)
- OCRTextSearch.swift (found text with line/word positions)

### Phase 4: Localize Storyboard Elements

#### Task 4.1: Menu Structure
Localize standard menu items in `Main.storyboard`:
- Application menu (About, Preferences, Quit)
- File menu
- Edit menu
- Window menu
- Help menu

These can either be:
1. Exported and localized via .storyboard localization
2. Migrated to programmatic menu creation (more maintainable)

### Phase 5: String Catalog Population

#### Task 5.1: Extract All Strings
- Use Xcode's "Export for Localization" feature
- Generate .xcloc packages for translators
- Alternatively, manually populate `Localizable.xcstrings` with all keys

#### Task 5.2: Provide Translation Context
For each string, add:
- **Key**: Unique identifier (e.g., "menu.targetWindow")
- **Default Value**: English text
- **Comment**: Context for translators explaining where/how the string is used
- **Character Limit**: If UI space is constrained

### Phase 6: Testing & Quality Assurance

#### Task 6.1: Pseudo-localization Testing
- Create a pseudo-localization to test:
  - String truncation issues
  - Layout breaking
  - Missing localizations (fallback to English)

#### Task 6.2: Enable Language Switching
- Test changing system language
- Verify all strings update correctly
- Check for hardcoded strings that slipped through

#### Task 6.3: Test with Screen Readers
- Verify VoiceOver reads localized strings correctly
- Test all accessibility announcements
- Ensure audio feedback doesn't break

### Phase 7: Documentation Updates

#### Task 7.1: Update README
- Add section on supported languages
- Document how to contribute translations
- Explain how to add new languages

#### Task 7.2: Create Translation Guide
- Document string key conventions
- Provide context for common terms
- Explain technical terms specific to accessibility/OCR

#### Task 7.3: Update Build/Release Process
- Document how to export/import localizations
- Add localization validation to CI/CD (if applicable)

## String Key Naming Convention

Recommend using hierarchical naming:

```
category.subcategory.identifier

Examples:
- menu.settings.targetWindow
- menu.settings.autoScan
- dialog.reset.title
- dialog.reset.message
- button.save
- button.cancel
- error.connection
- error.invalidResponse
- navigation.finishedScanning
- navigation.nothingFound
- shortcut.ocrWindow
- shortcut.exitNavigation
```

## Estimated String Count

Based on the exploration:
- **Total strings**: ~300-400 unique user-facing strings
- **High-priority strings**: ~200 (UI elements, menus, common messages)
- **Medium-priority**: ~100 (error messages, less-common dialogs)
- **Low-priority**: ~50 (developer messages, edge cases)

## Priority Languages (Recommended)

For initial localization:
1. **Spanish (es)** - Large user base
2. **French (fr)** - Common in accessibility community
3. **German (de)** - Strong accessibility market
4. **Japanese (ja)** - Large macOS user base
5. **Chinese Simplified (zh-Hans)** - Growing accessibility market

## Risk Assessment

### Challenges
1. **Volume of Work**: 300+ strings to wrap and localize
2. **Dynamic Strings**: Many strings use interpolation requiring format specifiers
3. **VoiceOver Integration**: Must ensure localized strings work with screen reader
4. **Testing Complexity**: Need native speakers or good pseudo-localization
5. **Maintenance**: New features must follow localization pattern

### Mitigations
1. Use automated tools (Xcode string extraction)
2. Create helper functions for common patterns
3. Implement comprehensive testing
4. Document localization process clearly
5. Use linters to catch hardcoded strings

## Success Criteria

- [ ] All user-facing strings wrapped with `NSLocalizedString()`
- [ ] String catalog created and populated with English base
- [ ] Info.plist strings localized
- [ ] Storyboard elements localized (or migrated to code)
- [ ] At least one additional language fully translated (pilot)
- [ ] No hardcoded strings detectable by pseudo-localization testing
- [ ] VoiceOver correctly announces all localized strings
- [ ] Documentation updated for translators and developers
- [ ] Build process supports exporting/importing localizations

## Timeline Estimate (Development Only)

- **Phase 1** (Infrastructure): 4-6 hours
- **Phase 2** (Wrap strings): 16-24 hours (most intensive)
- **Phase 3** (Dynamic strings): 4-6 hours
- **Phase 4** (Storyboard): 2-4 hours
- **Phase 5** (String catalog): 4-6 hours
- **Phase 6** (Testing): 6-8 hours
- **Phase 7** (Documentation): 3-4 hours

**Total**: ~40-60 hours of development work (not including actual translation)

## Next Steps

1. **Decision**: Choose between String Catalogs (.xcstrings) vs. legacy .strings files
2. **Decision**: Determine initial target languages
3. **Review**: User approval of this plan
4. **Execute**: Begin Phase 1 implementation

## Questions for Consideration

1. What languages should be prioritized for initial release?
2. Will translations be done internally or via community contributors?
3. Should we keep the storyboard or move menus to programmatic creation?
4. What is the minimum macOS/Xcode version to support (affects String Catalog availability)?
5. Is there a preference for string key naming convention?
