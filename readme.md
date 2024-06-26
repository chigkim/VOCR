Enhancing Accessibility with Seamless Screen Recognition

## Welcome to VOCR

Discover the cutting-edge capabilities of VOCR, your ultimate OCR and AI-powered screen recognition tool designed to enhance your digital accessibility experience. Beyond the simple navigation feature with OCR, VOCR seamlessly integrates with VoiceOver, enabling users to effortlessly capture and recognize screen content with intuitive and customizable shortcuts. With features like Real-Time OCR, users can continuously monitor and read live content, such as subtitles. The ASK AI functionality allows you to leverage advanced AI models, including OpenAI GPT to ask detailed questions about images and receive insightful answers. It also supports local vision language models via Ollama for your privacy. Explore with AI takes it a step further by analyzing images, identifying different areas, and providing comprehensive descriptions.

VOCR's robust suite of features offers unparalleled control and precision, making it an indispensable tool for users seeking a seamless, efficient, and highly functional OCR solution. Whether you're navigating inaccessible applications or curious about images, VOCR empowers you to do more with ease and confidence.

[![Youtube Demo: VOCR 2.0 for Mac w/Chi Kim](https://img.youtube.com/vi/_9EIYUPyXao/maxresdefault.jpg)](https://www.youtube.com/watch?v=_9EIYUPyXao)

## **WARNING**: USE AT YOUR OWN RISK!

VOCR is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY, expressed or implied, of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. Please see the [GNU General Public License](http://www.gnu.org/licenses/) for more details.

## Download

Here is the direct link to download [VOCR v2.0.1](https://github.com/chigkim/VOCR/releases/download/v2.0.1/VOCR_v2.0.1.zip).

## Setup

To ensure VOCR works properly, it is crucial to follow every step precisely. Missing even one step could prevent VOCR from functioning correctly.

1. After uncompressing the downloaded zip file, move the application to your Applications folder and run it.
2. Confirm VOCR is running in the menu bar by pressing vo+m twice.
3. In VoiceOver Utility, under the General category, check the box for "Allow VoiceOver to be controlled with AppleScript."
4. If active, turn off the screen curtain with vo+shift+f11. Note that the screen curtain must be off for the app to work properly.
5. Hide VoiceOver visuals with vo+command+f11 if they are displayed. If not hidden, elements like the VoiceOver caption panel will be recognized along with other screen content.
6. Press command+shift+control+w. You should receive a notification asking for accessibility permission. If VoiceOver does not automatically focus on the window, press vo+f1 twice to display the list of currently running apps; the system dialog should be in this list.
7. After granting accessibility permission, press command+shift+control+w again to receive a notification requesting permission for VOCR to take a screenshot. If you do not receive the alert, locate the system dialog as described previously.
8. If you cannot locate the system dialog, go to System Settings, Privacy & Security, then choose Screen Recording, and find the VOCR app.
9. After granting accessibility permission, restart the app as prompted.
10. Verify the app is in the menu bar by pressing vo+m twice.
11. Press command+shift+control+w. You should hear a beep and a voice prompt saying "finished."
12. You can now navigate the recognized results using command+control+arrows. Refer to the shortcuts section below for more information.
13. When navigating results for the first time, an alert will prompt you to allow VOCR to control VoiceOver for speaking announcements.
14. Press Escape to exit VOCR's navigation mode and free up navigation shortcuts.

## OCR VoiceOver Cursor

This feature is useful for capturing specific portions of a screen, such as a video player on a webpage or images on social media.

1. Move your VoiceOver cursor to the element you want to recognize.
2. Press command+shift+control+v.
   * The first time you use this feature, you will receive an alert to allow VOCR to run AppleScript.
3. After granting permission, press command+shift+control+v again.

## Real-Time OCR

Press Command+Shift+Control+R after scanning a window or using VOCursor to start or stop real-time OCR. When activated, VOCR will continuously scan and report only new content. This is useful for reading live content such as subtitles.

## Setup AI Model

You can host your own vision language model using Ollama or utilize OpenAI GPT to ask questions about images captured with VOCR.

### To use the OpenAI GPT model:

1. [Purchase API credits](https://platform.openai.com/settings/organization/billing/overview) for your account.
2. Create an [OpenAI API key](https://platform.openai.com/account/api-keys).
3. Enter your OpenAI API key in the VOCR Menu: Settings > Engine > OpenAI API Key.

Note: It may take several hours for your API to become active after purchasing credits.

The usage cost from VOCR is an estimate. For the official usage and cost, please refer to the [Usage Dashboard](https://platform.openai.com/usage) on OpenAI website.

### To utilize a local vision language model with Ollama:

Ollama is free and private, but it is less accurate and requires a lot of computing power. I recommend M1 chip or later with minimum 16GB memory.

1. Download and install [Ollama](https://ollama.ai/).
2. Download a multimodal (vision-language) model by executing the following command in your terminal:

    ```
    ollama pull llava
    ```

Note that there are also `llava:13b` and `llava:34b` models, which offer higher accuracy but require more storage, memory, and computing power.

You may also want to try a related app called [VOLlama](https://chigkim.github.io/VOLlama/). It is an accessible chat client for Ollama, allowing you to easily interact with an open-source large language model that runs locally on your computer.

## ASK AI

After the setting up OpenAI and/or Ollama:

1. Choose Ollama or GPT in VOCR Menu > Settings > Engine.
2. Scan a window/VOCursor or capture an image from a camera.
3. Press Command+Shift+Control+A to ask the selected model a question about the image.

The response will be copied to the clipboard so you can review in case you miss it.

Also you can select an image file in Finder, bring up the contextual menu with VO+Shift+M, go to 'Open with,' and choose VOCR to ask a question about the image.

## Explore with AI

1. Choose GPT in the VOCR Menu > Settings > Engine.
2. Provide your OpenAI API key in VOCR Menu > Settings > Engine > OpenAI API Key.
3. Scan a window or use VOCursor.
4. Press Command+Shift+Control+E.

VOCR will ask GPT to analyze the image, identify various areas, and describe the contents of each. You can navigate the results using the shortcuts Command + Control + Arrows.

Note: This feature is experimental and often produces inaccurate descriptions of locations and content.

## Global Shortcuts

These shortcuts work at all times:

* VOCR Menu: Command+Shift+Control+S
* OCR Window: Command+Shift+Control+W
* OCR VoiceOver Cursor: Command+Shift+Control+V
* Camera Capture: Command+Shift+Control+C
* Toggle Real-Time OCR: Command+Shift+Control+R
* Ask AI: Command+Shift+Control+A
* Explore with AI: Command+Shift+Control+E

## Navigation Shortcuts

These shortcuts only work when navigation is active after a scan:

* Move down/up: Command+Control+Down/Up Arrow
* Move left/right: Command+Control+Left/Right Arrow
* Previous/next character: Command+Shift+Control+Left/Right Arrow
* Go to top/bottom: Command+Control+Page Up/Down
* Go to beginning/end horizontally: Command+Control+Home/End
* Exit navigation: Escape
* Location: Command+Control+L (Reports current coordinates)
* Identify Object: Command+Control+I (Identifies current object with AI when object detection is enabled in settings)

## Settings

Access the VOCR Menu with Command+Control+Shift+S. This menu contains all settings and operations.

* Target Window: Allows you to scan a different window than the current one.
* Autoscan: Automatically scans after clicking an item with VO+Shift+Space.
* Detect Object: Locates objects with no text such as icons.
* Use Last Prompt: Reuses the last prompt when asking AI with Command+Shift+Control+A.
* Move Mouse: Moves the mouse cursor when you navigate.
* Positional Audio: Provides audio feedback as the mouse cursor moves. Frequency changes correspond to vertical location, and audio panning corresponds to horizontal position. If you don't hear the audio feedback, go to Settings > Sound Output.
* Reset Position: When disabled, the cursor will not reset to the top-left corner after every new scan.
* Launch on Login: Automatically runs VOCR when you log in.
* Log: Starts writing logs to VOCR.txt in your Documents folder.
* Sound Output: Choose a sound device for audio positional feedback.
* Choose Camera: Select the camera to use for capturing an image.
* Shortcuts: Customize shortcuts.
* Engine: Choose between GPT or Ollama.

Note that Llama.cpp temporarily suspended support for the vision language model on their server.

## Operation

When you open the VOCR menu, few operations are available after a scan:

* Save Last Image
* Save OCR Result
* Updates

## Troubleshooting

* If you hear "nothing found" you likely need to turn off the VoiceOver screen curtain with vo+shift+f11 or adjust accessibility and screen recording permissions in System Settings > Privacy & Security.
* If you do not hear anything after using the "OCR VoiceOver Cursor" feature, you probably need to grant VOCR permissions to: send Apple Events.

Usually, relaunching VOCR and reissuing the command retriggers the alerts to reappear in the system dialogs as described above.

Lastly, please enjoy using VOCR!