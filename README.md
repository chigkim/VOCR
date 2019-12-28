# Welcome to VOCR
If you're running Catalina, check out [new VOCR](https://github.com/chigkim/VOCR/tree/VK).

**WARNING**: USE AT YOUR OWN RISK! This is in alpha cycle. Many things may not work and change frequently without notice.

VOCR is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY, expressed or implied, of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. Please see the [GNU General Public License](http://www.gnu.org/licenses/) for more details.

## Installation
**IMPORTANT**: Installation involves several steps, and it is critical that you follow each step carefully.

VOCR relies on a third party program called Keyboard Maestro to perform its functions. Download instructions for Keyboard Maestro are below.

### Keyboard Maestro Installation
* [Download the Keyboard Maestro](https://www.keyboardmaestro.com/).
* Copy the Keyboard Maestro application from the downloads folder to the applications folder. From there, open Keyboard Maestro.
* If using Keyboard Maestro for the first time, in System Preferences, go to the Security and Privacy pane and select the Privacy tab. Under the Accessibility category, check the boxes for both Keyboard Maestro and Keyboard Maestro Engine. These must be enabled for Keyboard Maestro to work correctly.
* Open Keyboard Maestro Preferences, and under the general tab, check the box labeled, "Start Keyboard Maestro Engine at log-in." Note that the Keyboard Maestro window does not need to be open for the scripts to run.

### Important Notes about Keyboard Maestro
Keyboard Maestro contains some default macro groups that conflict with common Mac OS keyboard shortcuts. These are found in the switcher group, and clipboard group, which are disabled by default after installing VOCR. If you choose to reenable them, you can do so by selecting each group and pressing the enable button.

Keyboard Maestro is limited by a 30-day trial period. After  which a purchase of a one-time license is required to continue using Keyboard Maestro.

More information about purchasing a license can be found [here.](https://wiki.keyboardmaestro.com/manual/Purchase)

### Installing VOCR
* Open VoiceOver Utility and check "Allow VoiceOver to be controlled with AppleScript" in the General category.
* Run install.command in terminal and follow the instructions.  
    * This will install HOme Brew, Tesseract, and Image Magick.
    * When it asks for a password, you need to enter the password for an administrator account with root privilege.
    * The download is large and will compile, so the Installation may take a long time depending on your internet speed and system resources.
    * Make sure your computer does not go to sleep while installing.
    * Read through the terminal output and make sure there's no error before proceeding to the next step.
* Press vo+shift+m on "Import VOCR Macros.app" and choose open. This will allow the unsigned app to run.
* Rename the macro OCR Front Window to match your screen size. For example OCR Front Window 13 for a Macbook Pro 13 inch.
    * Make sure Keyboard Maestro is set to edit macros by selecting "Start Editing Macros" from the View menu.
    * Press vo+j until you jump to the macro groups scroll area.
    * Navigate to the VOCR macro group and select it with vo+Space.
    * Press vo+j to jump to the Macros scroll area.
    * Navigate to the OCR FrontWindow 27 macro, and select it with vo+Space Bar.
    * Press vo+j to jump to the Macro edit detail scroll area.
    * Press vo+Right Arrow to move to the macro name edit field.
    * Delete the existing number 27 and type the number that matches your screen size in inches.

## Getting Started
* Try performing OCR on the Keyboard Maestro Editor window first before trying it in other applications.
* Make sure the screen curtain is off with vo+shift+f11.
* Press command+control+shift+o and wait for the OCR process to finish. VOCR will prompt you with a "Ready" message when it's done with the OCR process.
* Press command+control+shift+arrows to read the result and press vo+shift+space to click.
* To choose different language, press vo+shift+l. Vo+command+return will allow you to selecte multiple items from the table. Make sure you only select the languages that you're trying to OCR.

**NOTE**: Keep in mind that many app interfaces use icons, and Tesseract may recognize them as weird symbols. For example, a right arrow might appear as a "> than"  sign and a left arrow as a "< than"  sign. Tesseract may also ignore icons entirely that cannot be recognized as a character or symbol.
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
