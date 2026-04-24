# VOCR

VOCR is an OCR and AI-powered screen recognition tool for macOS, designed to help VoiceOver users navigate inaccessible interfaces and understand visual content. It integrates directly with VoiceOver, allowing for seamless navigation of recognized text and AI-driven image analysis.

[![Youtube Demo: VOCR 2.0 for Mac w/Chi Kim](https://img.youtube.com/vi/_9EIYUPyXao/maxresdefault.jpg)](https://www.youtube.com/watch?v=_9EIYUPyXao)

---

## **WARNING**: USE AT YOUR OWN RISK!

VOCR is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY, expressed or implied, of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. Please see the [GNU General Public License](http://www.gnu.org/licenses/) for more details.

---

## Download

Get the latest version here: [VOCR v3.0.0-beta.3](https://github.com/chigkim/VOCR/releases/download/v3.0.0-beta.3/VOCR_v3.0.0-beta.3.zip).

---

## Setup

To ensure VOCR works properly, follow these steps in order:

1. **Install:** Unzip the downloaded file and move the VOCR application to your **Applications** folder.
2. **Launch & Grant Permissions:** Launch VOCR. A permissions window will appear. Click the action buttons for each row in the table  to grant the following:
   - **Accessibility:** Required for OCR and window interaction.
   - **Screen Recording:** Required to capture screen content.
   - **VoiceOver (Automation):** Required for cursor control and speaking results.
   - **Notifications:** Optional for update alerts.
   - Please note that for each permission you will be sent to the SYstem Settings window per Apple's requirements.
3. **Screen Configuration:** 
   - Ensure the **Screen Curtain** is OFF (`VO + Shift + F11`).
   - Hide **VoiceOver Visuals** (`VO + Command + F11`) to prevent them from interfering with scans.
4. **Restart & Verify:** Once Accessibility and Screen Recording permissions are granted, restart VOCR. Press `Command + Shift + Control + W` to perform your first scan. You should hear a beep followed by "finished."

---

## Features

### OCR Modes
- **Scan Window (`Cmd + Shift + Control + W`):** Recognizes text in the currently focused window.
- **Scan VO Cursor (`Cmd + Shift + Control + V`):** Recognizes the specific element under the VoiceOver cursor (useful for video players or social media images).
- **Real-Time OCR (`Cmd + Shift + Control + R`):** Continuously monitors the screen and reports new content, such as live subtitles.

### AI Integration
VOCR supports several AI models (Claude, Gemini, OpenAI, and local Ollama) via a flexible **Preset** system.

- **Ask AI (`Cmd + Shift + Control + A`):** Ask a question about the last scan or an image file in Finder.
- **Explore with AI (`Cmd + Shift + Control + E`):** Analyzes the image to identify and describe different layout areas.
- **Camera Capture (`Cmd + Shift + Control + C`):** Take a photo with your webcam and analyze it with AI.

To manage models and API keys, go to the **VOCR Menu > Presets > Preset Manager**.

---

## Keyboard Shortcuts

### Global Shortcuts
| Shortcut | Action |
| :--- | :--- |
| `Cmd + Shift + Control + S` | Open VOCR Menu / Settings |
| `Cmd + Shift + Control + W` | Scan Window |
| `Cmd + Shift + Control + V` | Scan VoiceOver Cursor |
| `Cmd + Shift + Control + A` | Ask AI a Question |
| `Cmd + Shift + Control + R` | Toggle Real-Time OCR |
| `Cmd + Shift + Control + E` | Explore with AI |
| `Cmd + Shift + Control + C` | Camera Capture |

### Navigation Shortcuts (Active after a scan)
| Shortcut | Action |
| :--- | :--- |
| `Cmd + Control + Arrows` | Move through elements |
| `Cmd + Shift + Control + Arrows` | Move by character |
| `Cmd + Control + L` | Report current coordinates |
| `Cmd + Control + I` | Identify current object with AI |
| `Escape` | Exit navigation |

---

## Settings

Access the VOCR Menu with `Cmd + Control + Shift + S` to customize:
- **Autoscan:** Automatically scan after clicking an item.
- **Detect Object:** Locate icons and objects without text.
- **Positional Audio:** Audio feedback that maps mouse location to sound frequency and panning.
- **Launch on Login:** Automatically start VOCR when you log in.

---

## Troubleshooting

- **"Nothing Found":** Ensure the **Screen Curtain** is turned OFF.
- **No Speech during Navigation:** Ensure the **VoiceOver (Automation)** permission is granted in the Permissions window.
- **Permission Issues:** If permissions are not being recognized after a macOS update, use the **Reset** option in the VOCR menu or run the reset script from the terminal:
  ```bash
  cd /path/to/vocr/folder
  ./reset_permissions.sh
  ```
  Alternatively, you can manually reset via terminal:
  ```bash
  tccutil reset All com.chikim.VOCR
  ```
- **Local AI:** If using Ollama, ensure you have pulled a vision model first: `ollama pull qwen3-vl`.

---
Enjoy using VOCR!
