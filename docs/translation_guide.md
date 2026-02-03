# VOCR Translation Guide

Welcome, and thank you for your interest in translating VOCR! This guide will help you localize VOCR into your language, whether or not you have access to Xcode.

## Table of Contents

1. [Overview](#overview)
2. [Translation Options](#translation-options)
3. [Method 1: Using Xcode (Recommended)](#method-1-using-xcode-recommended)
4. [Method 2: Without Xcode (Manual Translation)](#method-2-without-xcode-manual-translation)
5. [String Context and Guidelines](#string-context-and-guidelines)
6. [Testing Your Translation](#testing-your-translation)
7. [Submitting Your Translation](#submitting-your-translation)

## Overview

VOCR is an accessibility application for macOS that provides OCR and AI-powered screen recognition. Making it available in multiple languages helps users worldwide access their computers more effectively.

### What Needs Translation

- **~300-400 strings** including:
  - Menu items and settings
  - Dialog messages and alerts
  - Button labels
  - Error messages
  - Status announcements (spoken by VoiceOver)
  - Update notifications
  - Permission descriptions

### What Should NOT Be Translated

- Log messages (debugging text)
- Technical identifiers
- URL paths
- JSON keys
- HTTP status codes

## Translation Options

Choose the method that works best for you:

| Method | Requirements | Difficulty | Best For |
|--------|--------------|------------|----------|
| **Xcode** | Mac with Xcode 15+ | Easy | macOS developers |
| **Manual** | Text editor | Medium | Anyone |

## Method 1: Using Xcode (Recommended)

This is the easiest method if you have access to a Mac with Xcode.

### Prerequisites

- macOS 12.0 or later
- Xcode 15 or later (free from the App Store)
- Basic familiarity with Xcode (helpful but not required)

### Step-by-Step Instructions

#### 1. Open the Project

```bash
# Clone the repository
git clone https://github.com/chigkim/VOCR.git
cd VOCR

# Switch to the localization branch
git checkout localization

# Open in Xcode
open VOCR.xcodeproj
```

#### 2. Add Your Language

1. In Xcode, select the **VOCR project** in the Project Navigator (left sidebar)
2. Select the **VOCR target**
3. Click the **Info** tab
4. Under **Localizations**, click the **+** button
5. Choose your language from the list
6. In the dialog that appears, make sure both:
   - ✅ `Localizable.xcstrings`
   - ✅ `InfoPlist.xcstrings`
   
   are checked
7. Click **Finish**

#### 3. Translate Strings in Localizable.xcstrings

1. In the Project Navigator, find and click **`Localizable.xcstrings`**
2. In the Editor pane, you'll see a table with columns:
   - **Key** - The string identifier (don't change this)
   - **English (Development Language)** - The original text
   - **Your Language** - Where you enter the translation
   - **Comment** - Context about how the string is used

3. Click on each row and enter your translation in your language column
4. Use the **Comment** column to understand the context

**Tips:**
- Press ⌘F to search for specific strings
- Filter by **Needs Review** to see untranslated strings
- Pay attention to **format specifiers** like `%@` and `%d` (see below)

#### 4. Translate Strings in InfoPlist.xcstrings

1. In the Project Navigator, find and click **`InfoPlist.xcstrings`**
2. This file contains only 3 strings:
   - Camera permission description
   - AppleScript permission description
   - File type name
3. Translate these following the same process

#### 5. Translate Storyboard (Optional)

If the Main.storyboard is localizable:
1. Find **`Main.storyboard`** in the Project Navigator
2. In the File Inspector (right sidebar), under **Localization**, check your language
3. Xcode will create a `.strings` file for your language
4. Translate the menu items in this file

#### 6. Build and Test

1. Press ⌘B to build the project
2. If there are no errors, press ⌘R to run
3. Change your system language to your target language:
   - System Preferences → Language & Region → Add your language
   - Restart VOCR
4. Verify your translations appear correctly

#### 7. Export Your Translation

**Option A: Commit to Git (if you have permission)**
```bash
git add VOCR/Localizable.xcstrings VOCR/InfoPlist.xcstrings
git commit -m "Add [Your Language] translation"
git push origin localization
```

**Option B: Export as .xcloc (recommended for contributors)**
1. In Xcode: **Product → Export Localizations...**
2. Select your language
3. Choose a save location
4. This creates a `.xcloc` bundle you can send to the maintainers

## Method 2: Without Xcode (Manual Translation)

If you don't have access to Xcode, you can still translate by editing the `.xcstrings` files directly.

### Prerequisites

- Text editor (VS Code, Sublime Text, or any editor that can handle JSON)
- Basic understanding of JSON format
- Git (optional, but helpful)

### Understanding .xcstrings Format

String catalog files (`.xcstrings`) are JSON files with this structure:

```json
{
  "sourceLanguage" : "en",
  "strings" : {
    "menu.settings.targetWindow" : {
      "comment" : "Menu item for selecting target window",
      "extractionState" : "manual",
      "localizations" : {
        "en" : {
          "stringUnit" : {
            "state" : "translated",
            "value" : "Target Window"
          }
        }
      }
    }
  },
  "version" : "1.0"
}
```

### Step-by-Step Instructions

#### 1. Get the Files

```bash
# Clone the repository
git clone https://github.com/chigkim/VOCR.git
cd VOCR

# Switch to the localization branch
git checkout localization
```

Or download the branch as a ZIP from GitHub.

#### 2. Create Your Language Code

First, determine your language code. Common codes:
- Spanish: `es`
- French: `fr`
- German: `de`
- Japanese: `ja`
- Chinese (Simplified): `zh-Hans`
- Chinese (Traditional): `zh-Hant`
- Portuguese: `pt-BR` (Brazil) or `pt-PT` (Portugal)
- Italian: `it`
- Korean: `ko`
- Arabic: `ar`
- Russian: `ru`

[Full list of language codes](https://www.ibabbleon.com/iOS-Language-Codes-ISO-639.html)

#### 3. Edit Localizable.xcstrings

Open `VOCR/Localizable.xcstrings` in your text editor.

**For each string entry**, add your language translation:

```json
"menu.settings.targetWindow" : {
  "comment" : "Menu item for selecting target window",
  "extractionState" : "manual",
  "localizations" : {
    "en" : {
      "stringUnit" : {
        "state" : "translated",
        "value" : "Target Window"
      }
    },
    "es" : {
      "stringUnit" : {
        "state" : "translated",
        "value" : "Ventana de Destino"
      }
    }
  }
}
```

**Important JSON Rules:**
- Keep all quotes, brackets, and commas
- Don't change the key names (e.g., `"menu.settings.targetWindow"`)
- Don't change the `"comment"` field
- Only add your language code and translation
- Make sure each entry is separated by commas

#### 4. Edit InfoPlist.xcstrings

Open `VOCR/InfoPlist.xcstrings` and translate the 3 permission strings:

```json
{
  "sourceLanguage" : "en",
  "strings" : {
    "NSCameraUsageDescription" : {
      "comment" : "Permission description for camera access",
      "extractionState" : "manual",
      "localizations" : {
        "en" : {
          "stringUnit" : {
            "state" : "translated",
            "value" : "Capture a photo to VOCR to use."
          }
        },
        "es" : {
          "stringUnit" : {
            "state" : "translated",
            "value" : "Capturar una foto para usar en VOCR."
          }
        }
      }
    }
  },
  "version" : "1.0"
}
```

#### 5. Validate Your JSON

**Option A: Use an online JSON validator**
- Copy your edited JSON to [JSONLint](https://jsonlint.com/)
- Click "Validate JSON"
- Fix any errors shown

**Option B: Use command line (if you have Python)**
```bash
python3 -m json.tool VOCR/Localizable.xcstrings > /dev/null
```

If there are no errors, your JSON is valid.

#### 6. Create a .lproj Folder (Optional for Storyboard)

If you want to translate the storyboard menu items:

1. Create a folder: `VOCR/[YourLanguageCode].lproj/`
   - Example: `VOCR/es.lproj/` for Spanish

2. Copy `VOCR/Base.lproj/Main.storyboard` to your folder

3. Edit the copied file and translate the visible strings (menu items)

#### 7. Submit Your Translation

**Option A: Create a Pull Request (recommended)**
```bash
# Create a new branch for your translation
git checkout -b translation-[language]

# Add your changes
git add VOCR/Localizable.xcstrings VOCR/InfoPlist.xcstrings

# Commit
git commit -m "Add [Your Language] translation"

# Push and create pull request
git push origin translation-[language]
```

**Option B: Send Files to Maintainers**
- Email the edited `.xcstrings` files to the project maintainers
- Include your language code and name

## String Context and Guidelines

### Understanding String Keys

Keys follow a hierarchical naming pattern:

| Prefix | Usage | Example |
|--------|-------|---------|
| `menu.*` | Menu items | `menu.settings.autoScan` |
| `button.*` | Button labels | `button.save`, `button.cancel` |
| `dialog.*` | Dialog text | `dialog.reset.title` |
| `error.*` | Error messages | `error.connection.title` |
| `alert.*` | Alert messages | `alert.asking.message` |
| `navigation.*` | Navigation status | `navigation.finished_scanning` |
| `shortcut.*` | Keyboard shortcuts | `shortcut.ocr_window` |

### Format Specifiers

Some strings contain format specifiers that will be replaced with values at runtime:

| Specifier | Meaning | Example |
|-----------|---------|---------|
| `%@` | String | `"Asking %@"` → `"Asking GPT-4"` |
| `%d` | Integer | `"Status code %d"` → `"Status code 404"` |
| `%%` | Literal % | `"100%%"` → `"100%"` |

**Important Rules:**
- **Keep format specifiers** in your translation
- **Keep them in order** unless your language requires different word order
- **Don't change** `%@` to `%d` or vice versa

**Examples:**

✅ **Good:**
```json
"en": "Finished scanning %@, %@"
"es": "Escaneo completado %@, %@"
"ja": "%@、%@ のスキャンが完了しました"
```

❌ **Bad:**
```json
"es": "Escaneo completado"  // Missing format specifiers!
"ja": "スキャンが完了しました %d, %d"  // Wrong type (%d instead of %@)
```

### Multiple Format Specifiers

For strings with multiple `%@`, they're replaced in order. If your language needs a different order, you can use **positional specifiers**:

```json
"en": "Finished scanning %@, %@"  // App name, window name
"ar": "انتهى المسح %2$@, %1$@"   // Reversed order for Arabic
```

Where `%1$@` refers to the first parameter and `%2$@` to the second.

### Translation Guidelines

#### 1. Context Matters

Always read the **comment** field to understand where and how the string is used:

```json
"comment" : "Menu item for selecting target window"
```

This tells you:
- It's a menu item (should be short and action-oriented)
- It's related to window selection
- Users will click it to choose a target window

#### 2. Maintain Tone and Style

- **Menu items**: Short, imperative (e.g., "Save File", "Quit")
- **Dialogs**: Informative, complete sentences
- **Errors**: Clear, helpful, not overly technical
- **Buttons**: Action verbs (e.g., "Cancel", "Continue")

#### 3. Accessibility Considerations

Remember that VOCR is an **accessibility application**. Many strings will be:
- **Spoken by VoiceOver**: Keep them natural and easy to understand when heard
- **Read by screen readers**: Avoid abbreviations that sound awkward
- **Used by visually impaired users**: Be descriptive and clear

#### 4. Common Terms

Maintain consistency for these technical terms:

| English | Keep consistent in your language |
|---------|-----------------------------------|
| OCR | May stay as "OCR" or translate to your language |
| VoiceOver | Usually stays "VoiceOver" (Apple product name) |
| Scan/Scanning | Use consistent verb form |
| Window | GUI window (not glass window!) |
| Preset | Saved configuration/template |
| Shortcut | Keyboard shortcut |

#### 5. Length Considerations

- **Menu items**: Try to keep similar length to English (UI space is limited)
- **Buttons**: Short! Usually 1-2 words
- **Dialog messages**: Can be longer, but be concise

If your translation is much longer, consider:
- Using abbreviations (if common in your language)
- Splitting into multiple lines (for dialogs)
- Using shorter synonyms

#### 6. Punctuation and Formatting

- **Ellipsis (…)**: Used in menu items to indicate "more steps required"
  - Example: "Save File…" means a dialog will appear
  - Keep or use equivalent in your language
- **Colons (:)**: Used for form labels
  - Example: "Name:", "API Key:"
  - Use appropriate punctuation for your language
- **Quotation marks**: Use your language's standard quotes
- **Capitalization**: Follow your language's rules for titles and buttons

### Translation Examples by Category

#### Menu Items
```json
// Short, action-oriented, often with hotkey
"menu.settings.autoScan": "Auto Scan"
"menu.saveLatestImage": "Save Latest Image"
"menu.quit": "Quit"
```

#### Dialogs
```json
// Longer, informative, complete sentences
"dialog.reset.message": "This will erase all the settings and presets. This cannot be undone."
"dialog.soundOutput.message": "Choose an Output for positional audio feedback."
```

#### Buttons
```json
// Very short, imperative
"button.save": "Save"
"button.cancel": "Cancel"
"button.create": "Create"
```

#### Errors
```json
// Clear, helpful, not blaming the user
"error.connection.title": "Connection error"
"error.http.message": "Status code %d: %@"
"error.nodata.message": "No data received from server."
```

#### Status Messages (Spoken)
```json
// Natural language, as if speaking to user
"navigation.finished_scanning": "Finished scanning %@, %@"
"message.realtime_ocr_started": "RealTime OCR started."
"app.ready": "VOCR Ready!"
```

## Testing Your Translation

### Visual Testing

1. **Build the app** (with Xcode or maintainer help)
2. **Change system language**:
   - System Preferences → Language & Region
   - Add your language and move it to the top
   - Restart VOCR
3. **Check all UI elements**:
   - Open every menu
   - Trigger all dialogs
   - Check button labels
   - Verify no text is cut off

### Screen Reader Testing

If you use VoiceOver or can test with it:

1. Enable VoiceOver: ⌘F5
2. Navigate through VOCR's interface
3. Listen to how your translations sound:
   - Are they natural when spoken?
   - Are they clear and understandable?
   - Do they make sense out of context?

### Functional Testing

Make sure your translation doesn't break functionality:
- Format specifiers are present and correct
- JSON syntax is valid
- No missing translations (untranslated strings will show key names)

## Submitting Your Translation

### Before Submission

**Checklist:**
- [ ] All strings in `Localizable.xcstrings` are translated
- [ ] All strings in `InfoPlist.xcstrings` are translated
- [ ] Format specifiers (`%@`, `%d`) are preserved
- [ ] JSON is valid (no syntax errors)
- [ ] Translations tested (if possible)
- [ ] Consistent terminology throughout
- [ ] No machine translation without human review

### How to Submit

#### Option 1: Pull Request (Preferred)

1. Fork the VOCR repository on GitHub
2. Clone your fork
3. Create a branch: `git checkout -b translation-[language]`
4. Make your changes
5. Commit: `git commit -m "Add [Language] translation by [Your Name]"`
6. Push: `git push origin translation-[language]`
7. Open a Pull Request on GitHub

#### Option 2: Issue Attachment

1. Go to the VOCR GitHub repository
2. Create a new Issue
3. Title: "[Language] Translation"
4. Attach your `.xcstrings` files
5. Mention your language code and any notes

#### Option 3: Email

Contact the project maintainers (check README for contact info) with:
- Your translated `.xcstrings` files
- Language code
- Your name/username for credits
- Any questions or notes

### Getting Credit

Your contribution will be acknowledged in:
- The project README
- Release notes
- Contributors list

Please let us know how you'd like to be credited!

## Frequently Asked Questions

### Q: Can I use machine translation tools?

**A:** Machine translation (Google Translate, DeepL, etc.) can be a starting point, but you **must review and correct** the output. Machine translations often:
- Miss context
- Use awkward phrasing
- Translate technical terms incorrectly
- Don't consider accessibility needs

Always review and edit machine translations to ensure they're natural and accurate.

### Q: What if I don't understand a string's context?

**A:** 
1. Check the **comment** field in the `.xcstrings` file
2. Search for the key in the Swift source files to see usage
3. Ask in the GitHub Issues or contact maintainers
4. Look at screenshots or run the app to see where it appears

### Q: Can I translate only part of the app?

**A:** Partial translations are better than none! However:
- Prioritize the most visible strings (menus, main dialogs)
- Mark incomplete translations so users know to expect English fallbacks
- Try to complete it eventually for the best user experience

### Q: My language has formal and informal forms. Which should I use?

**A:** Generally, use the form that's most appropriate for:
- Software applications in your region
- Accessibility tools (often slightly more formal/professional)
- Apple's style (check how macOS is translated in your language)

Consistency is key—choose one form and stick with it throughout.

### Q: Can I update my translation later?

**A:** Yes! Translation is an ongoing process. You can:
- Submit updates to improve existing translations
- Translate new strings when features are added
- Fix errors or awkward phrasing

### Q: How do I translate technical terms?

**A:**
1. Check how Apple translates them in macOS (your language)
2. Use standard terms from accessibility community in your language
3. If no standard exists, transliterate or use English with explanation
4. Be consistent throughout

### Q: What encoding should I use?

**A:** Always use **UTF-8** encoding. Most modern text editors use this by default. This ensures characters from your language display correctly.

### Q: The JSON format is confusing. Can someone help?

**A:** Absolutely! 
- Create an issue on GitHub explaining what you're stuck on
- Contact the maintainers
- Consider Method 1 (Xcode) which handles JSON automatically
- Share your work-in-progress so others can help fix formatting

## Resources

### Language Codes
- [Apple Language Codes](https://www.ibabbleon.com/iOS-Language-Codes-ISO-639.html)
- [ISO 639-1 Language Codes](https://en.wikipedia.org/wiki/List_of_ISO_639-1_codes)

### JSON Tools
- [JSONLint](https://jsonlint.com/) - Validate JSON syntax
- [JSON Formatter](https://jsonformatter.curiousconcept.com/) - Format and validate

### Localization References
- [Apple Human Interface Guidelines - Localization](https://developer.apple.com/design/human-interface-guidelines/localization)
- [Microsoft Localization Style Guides](https://docs.microsoft.com/en-us/globalization/localization/styleguides) - Good general principles

### Testing
- [VoiceOver User Guide](https://support.apple.com/guide/voiceover/welcome/mac)
- Change language: System Preferences → Language & Region

## Thank You!

Your contribution makes VOCR accessible to more people around the world. Thank you for taking the time to translate!

If you have any questions not covered in this guide, please:
- Open an issue on GitHub
- Contact the maintainers
- Ask in the community forums

We're here to help and appreciate your efforts! 🌍🎉

---

**Last Updated:** January 28, 2026  
**VOCR Version:** 2.3.1  
**Localization Branch:** `localization`
