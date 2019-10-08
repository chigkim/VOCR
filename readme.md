# ***HIGHLY EXPERIMENTAL***

This branch utilizes VisionKit on MacOS Catalina that take advantage of machine learning for OCR.

This is a standalone app, and it does not rely on Keyboard Maestro, Imagemagick, and Tesseract that the previous VOCR utilized.

## Download

Here is the direct link to download [VOCR v0.1.0-alpha.1](https://github.com/chigkim/VOCR/releases/download/v0.1.0-alpha.1/VOCR.v0.1.0-alpha.1.zip).  

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
6. Go to system preference, and press command+shift+o, and you should get another notification asking you to allow VOCR to take screenshot. If you don't get the alert, see if you can find it in the system dialog as you did in the previous step.
7. If you can't find it from the system dialog, go to security and privacy, unlock, then go to choose screen recording under privacy tab, and you should be able to find VOCR app.
8. When you check it to allow, it should tell you to quit.
9. After restarting the app, and make sure you can find it on the menu extra.
10. As a test, go back to the system preference, and press command+shift+o, and you should hear a beep and a Voice prompt saying finished.
11. At that point, you should be able to navigate the result with command+shift+arrows, and your mouse should be also moving. Use command+option+shift+left/right to navigate between characters within the focussed word.
12. Try to navigate to Siri preference Using VOCR cursor, and then press vo+f5. VoiceOver should say your mouse is also under Siri.
13. Press escape to exit navigation mode and free up navigation shortcuts.

VOCR just looks for front most window of front most app, so don't try VOCR on a window that's not attached to a regular app. For example, desktop and menu bar app like Dropbox that opens its window in System dialog.

Please enjoy and send me your feedback!
