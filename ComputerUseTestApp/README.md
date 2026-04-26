# Computer Use Test App

A standalone macOS app bundle for testing VOCR computer use.

Build the app bundle:

```sh
./build-app.sh
```

Install the app bundle into `~/Applications`:

```sh
./build-app.sh debug "$HOME/Applications"
```

Set your OpenAI credentials before launching from a shell:

```sh
export OPENAI_API_KEY="..."
export OPENAI_MODEL="gpt-5.5" # optional
export OPENAI_BASE_URL="https://api.openai.com/v1" # optional
```

Grant permissions before running computer use:

- System Settings > Privacy & Security > Screen Recording > enable `Computer Use Test App`
- System Settings > Privacy & Security > Accessibility > enable `Computer Use Test App`

After changing either permission, quit and relaunch the app.

Launch it as a full macOS app:

```sh
open ".build/Computer Use Test App.app"
```

Or launch the installed copy:

```sh
open "$HOME/Applications/Computer Use Test App.app"
```

Run and observe logs in Terminal:

```sh
.build/Computer\ Use\ Test\ App.app/Contents/MacOS/ComputerUseTestApp
```

Run an automatic computer-use prompt when the app opens:

```sh
.build/Computer\ Use\ Test\ App.app/Contents/MacOS/ComputerUseTestApp \
  --prompt "Click Drag Source, set the slider to 75, type hello, and press Send."
```

If launching by double-clicking in Finder, set the API key in the launch environment first:

```sh
launchctl setenv OPENAI_API_KEY "..."
```

The app logs every interaction with `debugPrint` and mirrors the same entries in the on-screen Action Log.
