# Welcome to VOCR
**WARNING**: USE AT YOUR OWN RISK! This is in alpha cycle. Many things may not work and change frequently without notice.

VOCR is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY, expressed or implied, of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. Please see the [GNU General Public License](http://www.gnu.org/licenses/) for more details.

## Installation
**IMPORTANT**: Installation involves few steps, and it is critical that you follow each step carefully.

VOCR relies on a third party program called Keyboard Maestro to perform its functions. Download instructions for Keyboard Maestro are below.

### Keyboard Maestro Installation
* [Download the Keyboard Maestro](https://www.keyboardmaestro.com/).
* Copy the Keyboard Maestro application from the downloads folder to the applications folder. From there, open Keyboard Maestro.
* If using Keyboard Maestro for the first time, please check the boxes for both Keyboard Maestro and Keyboard Maestro Engine in system preferences, under "Security and Privacy", "Accessibility." These must be enabled for VOCR to function correctly.
* Open Keyboard Maestro Preferences, and under the general tab, check the box labeled, "Start Keyboard Maestro Engine at log-in." Note that the Keyboard Maestro window does not need to be open for the scripts to run.

### Important Notes about Keyboard Maestro
Keyboard Maestro contains some default macro groups that conflict with common Mac OS keyboard shortcuts. These are found in the switcher group, and clipboard group, which are disabled by default after installing VOCR. If you choose to reenable them, you can do so by selecting each group and pressing the enable button.

Keyboard Maestro is limited by a 30-day trial period. After this time, a purchase of a one-time license is required to continue using the program, and subsequently, Flogic.

More information about purchasing a license can be found [here.](https://wiki.keyboardmaestro.com/manual/Purchase)

### Installing VOCR
* Open VoiceOver Utility and check "Allow VoiceOver to be controlled with AppleScript" in the General category.
* Run install.command in terminal and follow the instruction.  
    * This will install HOme Brew, Tesseract, and Image Magick.
    * When it asks for a password, you need to enter password for an administrator account with root privilage.
    * It will download large data and compile, so the Installation may take a long time depending on your internet speed and system resources.
    * Read through the terminal output and make sure there's is no error before proceeding to next step.
* Press vo+shift+m on "Import VOCR Macros.app" and choose open. This will allow the unsigned app to run.
* Rename the macro OCR Front Window to match your screen size. For example OCR Front Window 13 for Macbook Pro 13 inch.

## Getting Started
* Try performing OCR on the Keyboard Maestro Editor window first before trying on other applications.
* Make sure screen curtain is off with vo+shift+f11.
* Press command+control+shift+o to and wait for the OCR process to finish.
* Press command+control+shift+arrows to read the result and press vo+shift+space to click.

**NOTE**: Keep in mind that many app interfaces use icons, and Tesseract may recognize them as weird symbols. For example, right arrow as > sign and left arrow as < sign. Tesseract may also ignore icons entirely that cannot be recognized as a character or symbol.

## Reporting Issues
GitHub provides a convenient and reliable way to track and resolve issues. Please click [here,](https://github.com/chigkim/vocr/issues) and search for your issue. If you don't find an open issue relating to your problem, you can create a new one by clicking on "new issue" and filling out the required fields.

## Generating A Report
When troubleshooting a problem, it might occasionally be necessary to have Keyboard Maestro generate a report when a script fails. By default, VOCR will ignore errors but, for diagnostic purposes, it might be necessary to provide those results. Follow these steps to generate the error message:

* In Keyboard Maestro, navigate to the OCR Front Window and click once on the macro.
* Press Tab once and you'll be placed in the Macro Edit Detail Scroll Area. Use VoiceOver to navigate over to the Execute Java script for Automation Action Group.
* Interact with the action group and navigate over to the pop-up menu that says, "Ignore Results" and change this option to "Display Results in a Window."
* Try launching the macro again. If there's an error with the script, Keyboard Maestro will open a new window with the error result. It might look something like this:  
/var/folders/lf/hwjp9syx5ll56brrkhgr818w0000gn/T/Keyboard-Maestro-Script-7640162F-37E6-49B9-AF85-02762D598028:243:339: execution error: Error on line 10: Error: Can't get object. (-1728)
* With the error message open, press Command-a to select the message and press Command-c to copy it.

Once the issue is identified and/or resolved, you can change the results preference in the action group back to "Ignore Results."
