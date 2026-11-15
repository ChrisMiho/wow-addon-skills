# wow-addon-skills

Claude Code skills for building World of Warcraft addons, written with WoW
Forever (handheld play) in mind but usable for any flavor. This repo is both a
plugin marketplace (`chrismiho-wow-addons`) and the one plugin it lists
(`wow-addon-skills`).

| Skill | Starts when | What it does |
|---|---|---|
| `wow-api-verify` | Claude decides, or `/wow-addon-skills:wow-api-verify` | Confirms an API on a flavor's branch of Gethe/wow-ui-source; guards and logs what can't be confirmed |
| `addon-offline-harness` | Claude decides, or by name | Runs addon Lua under LuaJIT with WoW stubs; loads a dependency (e.g. QuestieDB) from its TOC |
| `device-test-handoff` | Claude decides, or by name | Builds the zip, writes plain "do this, look for that" steps, asks for the error log, then waits |
| `curseforge-release` | Only `/wow-addon-skills:curseforge-release [version]` | Release checklist ending in a hand-off; never uploads |

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

## Develop

```
claude plugin validate .
claude plugin validate ./plugins/wow-addon-skills
```

Bump `version` in `plugins/wow-addon-skills/.claude-plugin/plugin.json` with
every change, or installed copies will not update.

## Licence

GPL-3.0 (`LICENSE`). The harness files derive from GPL-3.0 project code and
include LibDeflate under the zlib License; provenance, checksums and the zlib
notice are in `plugins/wow-addon-skills/NOTICE.md`.
