---
name: device-test-handoff
description: Hand a World of Warcraft addon change to the human for an in-game test, then stop and wait for their report. Use after any change that affects what the addon does in the game, or when someone says "ready to test on my device", "give me a build to try", "what should I check in game", "I'll test it on the handheld", or before claiming an addon feature works. Covers building the zip, writing numbered plain-language test steps, asking for the in-game error log, and recording the result.
---

# Device test hand-off

There is no game client where you run. Syntax checks and offline harnesses
prove logic only. **Nothing counts as working until the human has run it in
the game.** Until their report arrives, describe the change as "built, not
yet tested in game", never as "works" or "fixed".

## When

After every change that alters what happens in game: new or changed Lua,
TOC edits, bundled addon updates, saved-variable format changes. Not for
docs-only or test-only changes. One change per hand-off: if two things changed,
a failure cannot be pinned on either.

## 1. Build and check

- Run the project's checks and offline tests first; do not hand over a build
  that fails them.
- Build the zip with the project's build script (look in `scripts/`, the
  README or CLAUDE.md). Confirm each addon folder sits at the zip root, so it
  extracts straight into `Interface/AddOns`, and that the TOC's `## Version`
  changed if the human keeps several builds.
- Give the zip's full path and size.

## 2. Write the steps

The tester is usually a player, not a developer, often on a handheld with no
keyboard. Write for that:

- **Install step first**: where to extract, what to delete (old folders of
  renamed or merged addons), and to fully restart the game if a TOC or new
  file was added (`/reload` does not pick up new files).
- **Numbered steps, one action each**, in the form
  *do this* → *you should see that* → *report back*:

  ```
  2. Open your bags.
     You should see: one window with all bags, and a big "Sort" button below it.
     Tell me: does the Sort button appear, and is it easy to tap?
  ```

- Start with a **baseline step**: log in with the new feature off and confirm
  nothing else broke (no error popup, login not slower).
- Say where things are on screen and what they look like. Name buttons by
  their visible label. No code, no API names, no file paths in steps.
- Include what must **not** happen when that is the main risk, e.g. "only grey
  items are sold: if anything else is sold, stop and tell me at once".
- Cover combat if the change touches frames, bindings or bags: "do the same
  in combat; watch for an *action blocked by an addon* message".
- Ask for an off-switch check: turn the feature off and confirm the game
  returns to normal.
- Keep it short: 3 to 8 steps. Ask them to stop at the first step that fails.

## 3. Ask for the error log

Every hand-off ends by asking for errors, even if nothing looked wrong:

- If the addon has its own error page or log, say exactly how to open it.
- Otherwise ask for the text or a screenshot (a phone photo of the screen is
  fine) of any Lua error popup. If error popups are off, the addon project
  should provide an in-game way to see errors; propose one rather than asking
  the tester to type console commands.

End with a fill-in template they can copy:

```
Step 1: yes / no — notes
Step 2: yes / no — notes
Errors shown: none / (paste or photo)
Anything else odd:
```

## 4. Stop

Send the hand-off, then end your turn. Do not start the next feature, polish,
or "while we wait" work. The next action depends on the report.

## 5. When the report comes back

- Record the outcome where the project keeps facts and status (an
  architecture note, a status section, a changelog entry). Move confirmed
  items from "unverified" to "verified (tested in game, <date>, <device>)".
- For a failure: restate what the tester saw in plain words, give your best
  explanation, propose one fix, and hand off again with steps that target
  exactly that failure.
- Only a feature that passed its device test may be switched on by default
  or released.
