# Welcome to VOCR
**WARNING**: USE AT YOUR OWN RISK! This is in alpha cycle. Many things may not work and change frequently without notice.

VOCR is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY, expressed or implied, of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. Please see the [GNU General Public License](http://www.gnu.org/licenses/) for more details.

## ***HIGHLY EXPERIMENTAL***
This branch utilizes VisionKit on MacOS Catalina that take advantage of machine learning for OCR.

This is a standalone app, and it does not rely on Keyboard Maestro, Imagemagick, and Tesseract that the previous VOCR utilized.

## Download
Here is the direct link to download [VOCR v0.1.0-alpha.6.](https://github.com/chigkim/VOCR/releases/download/v0.1.0-alpha.6/VOCR.v0.1.0-alpha.6.zip)  

## Upgrade
You can simply remove VOCR group from Keyboard Maestro and follow the instruction for setup below.

The following steps are optional if you want to remove Imagemagick and Tesseract.

* Download the [latest commit](https://github.com/chigkim/VOCR/archive/master.zip) from master branch.
* Run "uninstall.command" script.

## Setup
1. After uncompress, just move the app to your application folder and run it.
2. You should get a notification asking you to grant accessibility permission. If VoiceOver doesn't focus on the window automatically, press vo+f1 twice to find system dialog, and you should be able to find it.
3. After allowing accessibility permission, and run the app again.
4. Make sure you can find the app on the menu extra .
5. Make sure screen curtain is off by pressing vo+shift+f11.
6. Go to system preference, and press command+shift+control+o, and you should get another notification asking you to allow VOCR to take screenshot. If you don't get the alert, see if you can find it in the system dialog as you did in the previous step.
7. If you can't find it from the system dialog, go to security and privacy, unlock, then go to choose screen recording under privacy tab, and you should be able to find VOCR app.
8. When you check it to allow, it should tell you to quit.
9. After restarting the app, and make sure you can find it on the menu extra again.
10. As a test, go back to the system preference, and press command+shift+control+o, and you should hear a beep and a Voice prompt saying finished.
11. At that point, you should be able to navigate the result with command+control+arrows, and your mouse should be also moving. Use command+control+shift+left/right to navigate between characters within the focused words.
12. Try to navigate to Siri preference Using VOCR cursor, and then press vo+f5. VoiceOver should say your mouse is also under Siri.
13. Press vo+shift+apce to open Siri preference.
14. Press escape to exit navigation mode and free up navigation shortcuts.

VOCR just looks for front most window of front most app, so don't try VOCR on a system window. For example, desktop and menu bar app like Dropbox that opens its window in System.

## Using Image Recognition under VoiceOver Cursor
1. Complete the setup above.
2. Move your VoiceOver cursor to the element that you want to recognize.
3. Press command+shift+control+v
4. If you use this feature for the first time, you will get a series of alerts asking you to allow VOCR to: 1. run AppleScript; 2. control VoiceOver to take screenshots; and 3. access desktop folder where VoiceOVer saves screenshots.
5. After granting the permission, press the shortcut command+shift+control+v again.

If you want to verify if it works properly, search images on Google image using Safari and try recognize them.

If everything goes well, VOCR will report the top 5 image categories in confidence order. If VOCR categorizes the image as a document, it will apply OCR. You can review the OCR result the same way as the section above, but this does not work with mouse movement.

## Recognize picture from camera
* Press command+shift+control+c
* If running  this feature for the first time, it will display an alert to give VOCR access to your camera

## Settings
Positional audio (command+shift+control+p): As mouse cursor moves you will hear hear audio feedback. Frequency changes responds to vertical move, and pan responds to horizontal move. This feature is useful to explore the interface and discover elements' locations.

Disable/enable reset position (command+shift+control+r): When disabled, the cursor will not reset to the top left corner after every new scan. This feature is useful when you rescan the same window to find new change without losing previous cursor.

## Shortcuts
* OCR Frontost Window: command+shift+control+w
* Recognize image under VoiceOver cursor: command+shift+control+v
* Recognize picture from camera: command+shift+control+c
* Toggle reset position at scan: command+shift+control+r
* Toggle positional audio feedback: command+shift+control+p

The following shortcuts only works after a scan.

* Move down/up: command+control+down/up arrow
* Move left/right: command+control+left/right arrow
* Previous/next character: command+shift+control+left/right arrow
* Exit navigation: escape

## Troubleshooting
* If you hear nothing found, most likely either you need to turn off VoiceOver screen curtain with vo+shift+f11, or fix accessibility and screen recording  permission in security and privacy preference.
* If you do not hear anything after recognize image under VoiceOVer, most likely you need to give   VOCR permissions to 1. send Apple Events, 2. control VoiceOver, and 3. access desktop folder. Usually relaunching VOCR and reissuing the command usually retrigger the alerts to reappear in the system dialogs.

Lastly, please enjoy and send me your feedback!

