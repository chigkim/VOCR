# UI Challenge

A standalone macOS app bundle for testing VOCR computer use.

Build the app bundle:

```sh
./build-app.sh
```

Set your OpenAI credentials before launching from a shell:

```sh
export OPENAI_API_KEY="..."
export OPENAI_MODEL="gpt-5.5" # optional
export OPENAI_BASE_URL="https://api.openai.com/v1" # optional
```

Grant permissions before running computer use:

- System Settings > Privacy & Security > Screen Recording > enable `UI Challenge`
- System Settings > Privacy & Security > Accessibility > enable `UI Challenge`

After changing either permission, quit and relaunch the app.

Launch it as a full macOS app:

```sh
open ".build/UI Challenge.app"
```

Or launch the installed copy:

```sh
open "$HOME/Applications/UI Challenge.app"
```

Run and observe logs in Terminal:

```sh
.build/UI\ Challenge.app/Contents/MacOS/UIChallenge
```

Run an automatic computer-use prompt when the app opens:

```sh
.build/UI\ Challenge.app/Contents/MacOS/UIChallenge \
  --prompt "Click Drag Source, set the slider to 75, type hello, and press Send."
```

If launching by double-clicking in Finder, set the API key in the launch environment first:

```sh
launchctl setenv OPENAI_API_KEY "..."
```

The app presents one validation level at a time. Each level shows an instruction at the top, a task UI, and a Next button. Clicking Next advances only when the current level's requirements are complete; otherwise the visible log shows a terse failure message so the model must infer what is missing from the instruction, UI state, and visible history.

Human debugging controls are in the Levels menu:

- Restart from Level 1
- Reset Current Level
- Show Validation Details in UI

The on-screen Visible Log is model-facing and intentionally concise. Full validation failures and internal state are written with `debugPrint` in the console.
