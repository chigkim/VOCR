# VOCR Translation Guide

Welcome, and thank you for your interest in translating VOCR! This guide will help you localize VOCR into your language, whether or not you have access to Xcode.

## Table of Contents

1. [Overview](#overview)
2. [Translation Options](#translation-options)
3. [Method 1: Using CSV Files (Recommended)](#method-1-using-csv-files-recommended)
4. [Method 2: Using Xcode](#method-2-using-xcode)
5. [String Context and Guidelines](#string-context-and-guidelines)
6. [Testing Your Translation](#testing-your-translation)
7. [Submitting Your Translation](#submitting-your-translation)

## Overview

VOCR is an accessibility application for macOS that provides OCR and AI-powered screen recognition. Making it available in multiple languages helps users worldwide access their computers more effectively.

### What Needs Translation

- **~150 strings** including:
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
| **CSV** | Python 3, spreadsheet app | Easy | Anyone |
| **Xcode** | Mac with Xcode 15+ | Easy | macOS developers |

## Method 1: Using CSV Files (Recommended)

This is the easiest method. You edit translations in a spreadsheet (Excel, Google Sheets, Numbers, etc.) and use scripts to convert between CSV and the xcstrings format.

### Prerequisites

- Python 3
- A spreadsheet application or text editor
- Git (optional, but helpful)

### Updating an Existing Language

#### 1. Get the Files

```bash
git clone https://github.com/chigkim/VOCR.git
cd VOCR
```

#### 2. Export to CSV

```bash
python3 translations/export.py fr    # Export a single language
python3 translations/export.py       # Export all languages + template
```

This creates CSV files in `translations/csv/`. Each CSV has these columns:

| key | comment | en | translation |
|-----|---------|-----|-------------|
| app.ready | Message when app is ready | VOCR Ready! | VOCR prêt ! |

#### 3. Edit the CSV

Open the CSV in your spreadsheet app and edit the **translation** column. The **comment** and **en** columns give you context.

#### 4. Import Back

```bash
python3 translations/import.py translations/csv/fr.csv
```

The script creates a backup of the xcstrings files before making changes.

### Adding a New Language

#### 1. Generate a Template

```bash
python3 translations/export.py template
```

This creates `translations/csv/template.csv` with all keys and English strings, but empty translations.

#### 2. Copy and Rename

Copy `template.csv` to `<language_code>.csv` (e.g., `it.csv` for Italian).

See [ISO 639-1 Language Codes](https://www.loc.gov/standards/iso639-2/php/English_list.php) for more information.

#### 3. Fill In Translations

Open the CSV and fill in the **translation** column. You don't need to translate every string at once — empty rows are skipped during import.

#### 4. Import

```bash
python3 translations/import.py translations/csv/it.csv
```

## Method 2: Using Xcode

This method works if you have access to a Mac with Xcode.

### Prerequisites

- macOS 12.0 or later
- Xcode 15 or later (free from the App Store)
- Basic familiarity with Xcode (helpful but not required)

### Step-by-Step Instructions

#### 1. Open the Project

```bash
git clone https://github.com/chigkim/VOCR.git
cd VOCR
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

#### 5. Build and Test

1. Press ⌘B to build the project
2. If there are no errors, press ⌘R to run
3. Change VOCR language to your target language:
    - VOCR Settings > Languages
    - Restart VOCR
4. Verify your translations appear correctly

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

#### 3. Common Terms

Maintain consistency for these technical terms:

| English | Keep consistent in your language |
|---------|-----------------------------------|
| OCR | May stay as "OCR" or translate to your language |
| VoiceOver | Usually stays "VoiceOver" (Apple product name) |
| Scan/Scanning | Use consistent verb form |
| Window | GUI window (not glass window!) |
| Preset | Saved configuration/template |
| Shortcut | Keyboard shortcut |

#### 4. Length Considerations

- **Menu items**: Try to keep similar length to English (UI space is limited)
- **Buttons**: Short! Usually 1-2 words
- **Dialog messages**: Can be longer, but be concise

If your translation is much longer, consider:
- Using abbreviations (if common in your language)
- Splitting into multiple lines (for dialogs)
- Using shorter synonyms

#### 5. Punctuation and Formatting

- **Ellipsis (…)**: Used in menu items to indicate "more steps required"
  - Example: "Save File…" means a dialog will appear
  - Keep or use equivalent in your language
- **Colons (:)**: Used for form labels
  - Example: "Name:", "API Key:"
  - Use appropriate punctuation for your language
- **Quotation marks**: Use your language's standard quotes
- **Capitalization**: Follow your language's rules for titles and buttons

## Testing Your Translation

Make sure your translation doesn't break functionality:

- Format specifiers are present and correct
- JSON syntax is valid
- No missing translations (untranslated strings will show key names)

## Submitting Your Translation

#### Option 1: Pull Request (Preferred)

If you used the CSV workflow, import your CSV first, then submit:

```bash
python3 translations/import.py translations/csv/<language>.csv
git checkout -b translation-<language>
git commit -m "Add <Language> translation"
git push origin translation-<language>
```

Then open a Pull Request on GitHub.

#### Option 2: Send Your CSV

If you don't have Git set up, you can submit your CSV file directly:

1. Go to the VOCR GitHub repository
2. Create a new Issue titled "[Language] Translation"
3. Attach your CSV file
4. Mention your language code and any notes

## Frequently Asked Questions

### Q: What encoding should I use?

**A:** Always use **UTF-8** encoding. Most modern text editors use this by default. This ensures characters from your language display correctly.

### Q: Do I need to edit JSON files directly?

**A:** No! Use the CSV workflow (Method 1) to work with a simple spreadsheet instead. The scripts handle all the JSON conversion for you.

## Resources

### Language Codes
- [Apple Language Codes](https://www.ibabbleon.com/iOS-Language-Codes-ISO-639.html)
- [ISO 639-1 Language Codes](https://www.loc.gov/standards/iso639-2/php/English_list.php)

### Localization References
- [Apple Human Interface Guidelines - Localization](https://developer.apple.com/design/human-interface-guidelines/localization)
- [Microsoft Localization Style Guides](https://docs.microsoft.com/en-us/globalization/localization/styleguides) - Good general principles

## Thank You!

Your contribution makes VOCR accessible to more people around the world. Thank you for taking the time to translate!

If you have any questions not covered in this guide, please open an issue on GitHub
