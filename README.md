# wow-addon-skills

AI coding agents building World of Warcraft addons tend to make the same few
mistakes:
- They assume a game function exists on every client flavor.
- They say something "works" when nobody has run it in the game.
- They break when a dependency's data isn't what they expected.
- They fumble a CurseForge release.

These Claude Code skills write down the steps that avoid those mistakes, so
every addon project gets them without explaining them again. They come from
real work on WoW Forever addons for handheld play, and they work for any flavor.

This repo is a plugin marketplace (`chrismiho-wow-addons`) that lists one
plugin, `wow-addon-skills`.

## Principles

- **Only what an agent can't work out alone.** The skills hold knowledge
  that isn't in your project's files. They leave out general coding advice.
- **Unchecked facts say "check X".** Anything not confirmed is written as a
  check to do, never as a fact.
- **Nothing works until a person has run it in the game.** Tests on the
  computer prove the logic. Only you can prove it works in the game.
- **Steps with real effects wait for you.** The release skill only starts
  when you type its command, and you always do the upload yourself.

## What's available

| Skill | Starts when | What it does |
|---|---|---|
| `wow-api-verify` | Claude decides, or `/wow-addon-skills:wow-api-verify` | Confirms an API on a flavor's branch of Gethe/wow-ui-source; guards and logs what can't be confirmed |
| `addon-offline-harness` | Claude decides, or by name | Runs addon Lua under LuaJIT with WoW stubs; loads a dependency (e.g. QuestieDB) from its TOC |
| `device-test-handoff` | Claude decides, or by name | Builds the zip, writes plain "do this, look for that" steps, asks for the error log, then waits |
| `curseforge-release` | Only `/wow-addon-skills:curseforge-release [version]` | Release checklist ending in a hand-off; never uploads |

### wow-api-verify: does this game function exist on my client?

- **For:** checking that a game function, event or setting exists on your
  game version before the addon relies on it.
- **Starts when you say things like:** "is C_QuestLog.GetInfo available on
  Forever?", "does this work on Classic Era?", or whenever Claude is about to
  use a new game function.
- **You get:** a yes or no, the game build that was checked, and where it was
  found in Blizzard's interface code. Anything that can't be confirmed gets
  a safety check in the code and a line in your project notes saying what
  would go wrong if it's missing.
- **Setup:** internet access to GitHub.

### addon-offline-harness: test the addon without the game

- **For:** running your addon's code on the computer, with stand-ins for the
  game, so Claude can catch mistakes before you install anything. It can also
  load another addon, such as QuestieDB, from its own files.
- **Starts when you say things like:** "test this against QuestieDB offline",
  "add an offline test", "run the addon without the game".
- **You get:** a test script in your project that prints a pass, or the first
  failure with its error.
- **Setup:** LuaJIT (`brew install luajit` on a Mac). Claude copies the
  helper files into your project.

### device-test-handoff: your turn to try it in game

- **For:** handing you a build to test after any change you'd notice in game.
- **Starts when you say things like:** "it's ready to try on my device",
  "what should I check in game?", or whenever Claude finishes such a change.
- **You get:** the zip's location, short numbered steps ("do this, you
  should see that, tell me…"), a request for any error messages, and a reply
  template. Claude then stops and waits for your report.
- **Setup:** none. It uses your project's build script.

### curseforge-release: getting ready to publish

- **For:** preparing a CurseForge upload: game version, zip checks, avatar,
  dependencies, changelog and release type.
- **Starts only when you type:** `/wow-addon-skills:curseforge-release 0.0.2`
  (use your version number).
- **You get:** a checked zip and a list of every form field with the exact
  value to enter. You do the upload. Claude never uploads anything.
- **Setup:** none.

## How to use them day to day

1. **Planning a feature:** Claude checks each new game function with
   `wow-api-verify`.
2. **Building it:** Claude runs the offline test as its pass/fail check.
   A Claude Code Stop hook can run the test at the end of every turn and
   block the turn if it fails.
3. **After the change:** `device-test-handoff` gives you a build and steps.
   You test in game and report back.
4. **Ready to publish:** you run `/wow-addon-skills:curseforge-release`.

They fit a spec-driven workflow (spec, then plan, then build, then device
test), but you don't have to use one.

## Install

From GitHub:

```
claude plugin marketplace add ChrisMiho/wow-addon-skills
claude plugin install wow-addon-skills@chrismiho-wow-addons
```

From a local clone: `claude plugin marketplace add /path/to/wow-addon-skills`,
then the same install command. Check with `claude plugin details wow-addon-skills`.

To enable it for everyone working in an addon repo, add to that repo's
`.claude/settings.json`:

```json
{
  "extraKnownMarketplaces": {
    "chrismiho-wow-addons": { "source": { "source": "github", "repo": "ChrisMiho/wow-addon-skills" } }
  },
  "enabledPlugins": { "wow-addon-skills@chrismiho-wow-addons": true }
}
```

## Updating and refining skills

1. Edit a skill's `SKILL.md` under `plugins/wow-addon-skills/skills/`.
2. Check both manifests:
   ```
   claude plugin validate .
   claude plugin validate ./plugins/wow-addon-skills
   ```
3. Bump `version` in `plugins/wow-addon-skills/.claude-plugin/plugin.json`,
   or installed copies won't update. Then commit and push.
4. On each machine, refresh and update, then restart Claude Code:
   ```
   claude plugin marketplace update chrismiho-wow-addons
   claude plugin update wow-addon-skills@chrismiho-wow-addons
   ```

To test a change, ask the same question in a fresh session with and without
the skill, and compare the answers. To turn the skill off for the "without"
run, use `claude plugin disable wow-addon-skills`, and turn it back on with
`claude plugin enable wow-addon-skills`.

## Status

Version 0.1.0, early. Built alongside the
[Pocket Essentials](https://github.com/ChrisMiho/wow-forever-pocket-essentials)
addon. Feedback and problems: open a GitHub issue on this repo.

## Licence

GPL-3.0 (`LICENSE`). The harness files derive from GPL-3.0 project code and
include LibDeflate under the zlib License; provenance, checksums and the zlib
notice are in `plugins/wow-addon-skills/NOTICE.md`.
