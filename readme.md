# Welcome to VOCR
**WARNING**: USE AT YOUR OWN RISK!

VOCR is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY, expressed or implied, of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. Please see the [GNU General Public License](http://www.gnu.org/licenses/) for more details.

This branch utilizes VisionKit on MacOS Catalina that takes advantage of machine learning for OCR.

This is a standalone app, and it does not rely on Keyboard Maestro, Imagemagick, and Tesseract which the previous VOCR utilized.

If you're using a Mac OS version earlier than Catalina 10.15, please use the older [VOCR with tesseract.](https://github.com/chigkim/VOCR/tree/tesseract)

## Download
Here is the direct link to download [VOCR v1.0.0-beta.2.](https://github.com/chigkim/VOCR/releases/download/v1.0.0-beta.2/VOCR.v1.0.0-beta.2.zip)

## Upgrade from Previous VOCR With Tesseract
You can simply remove the VOCR group from Keyboard Maestro and follow the setup instructions found below.

The following steps are only necessary if you wish to remove Imagemagick and Tesseract.

* Download the [latest commit](https://github.com/chigkim/VOCR/archive/master.zip) from master branch.
* Run the "uninstall.command" script.

## Setup
* After uncompressing the downloaded zip, simply move the application to your applications folder and run it.
* Make sure you can find VOCR running on the menu extra  by pressing vo+m twice.
* Go to VoiceOver Utility, and check Allow VoiceOver to be controlled with AppleScript under the general category.
* If active, turn off screen curtain with vo+shift+f11. Note, screen curtain must be turned off in order for this app to work properly.
* If displayed, hide VoiceOver visuals with vo+command+f11. Note, if VoiceOver visuals are not hidden, they will get recognized along with other screen content.
* Press command+shift+control+w, and you should get a notification asking you to grant accessibility permission. If VoiceOver doesn't focus on the window automatically, press vo+f1 twice which will display the list of currently running apps, the system dialog should be in this list.
* After allowing accessibility permission, press command+shift+control+w, and you should get another notification asking you to allow VOCR to take a screenshot of the frontmost window. If you don't get the alert, locate the system dialog as described in the previous step.
* * If you are unable to locate the system dialog, go to System Settings, security and privacy, unlock the setting, then go to choose screen recording under the privacy tab, and you should be able to find the VOCR app.
* * After granting the accessibility permission, you should be prompted to restart the app.
* * After restarting the app, verify that it can be found in the menu extras area which can be accessed by pressing vo+m twice.
* As a test, go back to System Settings, press command+shift+control+w, and you should hear a beep and a Voice prompt saying finished.
* At that point, you should be able to navigate the recognized results with command+control+arrows. Refer to the shortcuts section below for more information.
** When navigating results for the first time, another alert should appear prompting for permission to allow VOCR to control VoiceOver for speaking announcements.
* One further test: navigate to the Siri preference within the recognized System Settings screen Using the VOCR cursor, and then press vo+f5. VoiceOver should indicate that your mouse is  also on Siri. This is because as you navigate the recognized content, the mouse automatically follows the navigation.
* Press vo+shift+space to open the Siri preference. Note, since the mouse has followed the navigation, we use this command to simulate a mouse click at the correct on-screen location.
* Press escape to exit VOCR's navigation mode and free up navigation shortcuts.

## Using Image Recognition under VoiceOver Cursor
* Complete the setup above.
* Move your VoiceOver cursor to the element that you want to recognize.
* Press command+shift+control+v
* * If running this feature for the first time, you will get a series of alerts asking you to allow VOCR to: 1. run AppleScript; 2. control VoiceOver to take screenshots; and 3. access the desktop folder which is where VoiceOVer saves screenshots.
* After granting all permissions, press the shortcut command+shift+control+v again.
If you want to verify that this feature is working properly, search for an image on Google and try recognizing a resulting image.


If everything goes well, VOCR will report the top 5 image categories ranked by level of confidents. If VOCR categorizes the image as a document, it will apply OCR to the document text. You can review the OCR results in the same way as above, but in the image recognition mode, the mouse does not follow the VOCR cursor as it does with window recognition.

## Settings
Positional audio (command+shift+control+p): As the mouse cursor moves you will hear hear audio feedback. Frequency changes correlate to vertical movement, and audio panning correlates to horizontal movement. This feature is useful for exploring the interface and discovering the location of on-screen elements. If you don't hear the audio feedback, choose sound output for VOCR from  the menu extra.

Disable/enable reset position (command+shift+control+r): When disabled, the cursor will not reset to the top left corner after every new scan. This feature is useful when you rescan the same window in order to find any new changes without losing the previous cursor position.

## Shortcuts
* OCR Frontmost Window: command+shift+control+w
* Recognize image under VoiceOver cursor: command+shift+control+v
* Toggle reset position after scan: command+shift+control+r
* Toggle positional audio feedback: command+shift+control+p

The following shortcuts only work after a scan, I.E. on resulting content.

* Move down/up: command+control+down/up arrow
* Move left/right: command+control+left/right arrow
* Previous/next character: command+shift+control+left/right arrow
* Go to top/bottom: command+control+page up/down
* Go to beginning/end horizontally: command+control+left/right arrow
* Exit navigation: escape
* Save the OCR result to file: command+shift+control+s

## Troubleshooting
* If you hear "nothing found" or just hear the word "the", most likely you need to turn off VoiceOver screen curtain with vo+shift+f11, or fix accessibility and screen recording  permissions in security and privacy preferences.
* If you do not hear anything after using the recognize image under VoiceOver cursor feature, most likely you need to give   VOCR permissions to 1. send Apple Events, 2. control VoiceOver, and 3. access desktop folder. Usually relaunching VOCR and reissuing the command usually retriggers the alerts to reappear in the system dialogs as described above.

Lastly, please enjoy and send me your feedback!

