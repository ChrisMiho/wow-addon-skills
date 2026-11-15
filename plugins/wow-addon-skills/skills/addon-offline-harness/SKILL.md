---
name: addon-offline-harness
description: Run World of Warcraft addon Lua off the device under LuaJIT, with stand-ins for the WoW client API, and load another addon (such as a data addon) from its TOC the way the game does. Use when someone says "test against QuestieDB offline", "run the addon without the game", "add an offline test", "check this Lua under LuaJIT", "load the addon's TOC in a test", or when an addon change needs proof beyond a syntax check and no game client is available. Ships ready stubs, base64/zlib/CBOR decoders and a TOC loader.
---

# Offline addon harness (LuaJIT + WoW stubs)

The game client embeds Lua 5.1; LuaJIT runs the same dialect, so addon files
load unchanged. What is missing is the client API. This skill bundles
stand-ins for the common load-time parts, plus a TOC loader, so a test can
load real addon code (yours and a dependency's) and drive it.

A pass proves logic, not in-game behaviour: the stubs only know what their
authors believed about the client. Say so when you report results.

## Bundled files (in `${CLAUDE_SKILL_DIR}`)

| File | What | Licence |
|---|---|---|
| `stubs.lua` | Client stand-ins and loaders; API in its header comment | GPL-3.0 |
| `decode.lua` | `C_EncodingUtil` decoding: base64, zlib, CBOR | GPL-3.0 |
| `metadata.lua` | TOC parser, `GetAddOnMetadata`, TOC-ordered file loader (from QuestieDB, unmodified) | GPL-3.0 |
| `LibDeflate.lua` | zlib, 1.0.2-release, unmodified | zlib |
| `NOTICE.md` (plugin root, `${CLAUDE_SKILL_DIR}/../../NOTICE.md`) | Provenance, commits, SHA-256s | |
| `questiedb.md` | Read when the dependency is QuestieDB | |

## Set up in a project

1. `luajit -v` (macOS: `brew install luajit`).
2. Copy the four `.lua` files into the project, e.g. `tests/lib/`, and copy
   the third-party rows of `NOTICE.md` into a `tests/lib/README.md`. Copying
   pins them: the test keeps working without the plugin and changes are
   reviewable. Keep `tests/` out of the release zip.
3. Write a runner (below) and a shell wrapper `scripts/test.sh` that exits 0
   with a notice when `luajit` is missing, so nobody without it is blocked.
4. Fetch any external addon (a release zip) by pinned version and SHA-256
   into an uncommitted `vendor/` folder; unzip to a temp dir per run.

## Runner skeleton

```lua
-- luajit tests/run.lua <lib dir> <repo root> [<dependency dir>]
local LIB, ROOT, DEP = arg[1], arg[2], arg[3]
local S = dofile(LIB .. "/stubs.lua")
S.init(LIB)
S.install({ faction = "Alliance", class = "WARRIOR" }, {
  -- client globals your code calls that stubs.lua lacks
  strsplit = function(sep, s) --[[ ... ]] end,
})

local function fail(msg) io.stdout:write("FAIL: ", msg, "\n") os.exit(1) end
local function guarded(where, fn, ...)
  local ok, a, b = xpcall(fn, debug.traceback, ...)
  if not ok then fail(where .. ": " .. tostring(a)) end
  return a, b
end

-- A dependency, loaded from its TOC like the game does:
if DEP then guarded("load dependency", S.loadAddon, DEP .. "/MyDep.toc", "MyDep",
  { gameType = "forever", reset = { "MyDepGlobal" } }) end

-- Your addon: whole TOC, or file by file into one namespace:
local ns = guarded("load addon", S.loadAddon, ROOT .. "/MyAddon/MyAddon.toc", "MyAddon")
-- local ns = S.loadFile(ROOT .. "/MyAddon/Core.lua", "MyAddon", {})

S.fire("PLAYER_LOGIN")
guarded("timers", S.runTimers)
-- assertions here
io.stdout:write("PASS\n") os.exit(0)
```

## What makes the harness catch real bugs

- **Errors the addon swallows.** If the addon wraps handlers in `pcall` and
  logs failures, replace its logger after load so every logged error is
  recorded, and fail the run on the first one. Otherwise a broken feature
  passes silently.
- **Timers.** `C_Timer.After` only queues; call `S.runTimers()` after each
  action. Code that spreads work over timers is exercised only then.
- **Whole dataset, not samples.** When reading a data addon, loop over every
  record (all quest IDs, all NPCs) through your code.
- **A baseline of counts.** Write summary counts (records processed, outputs
  produced) to a committed `baseline.txt` and fail on any difference, printing
  the delta. Data or logic drift then shows up as a number.
- **A few known values.** Pick two or three records, read their expected
  output from the raw data by hand, and assert them exactly (to 1e-4 for
  coordinates). Counts alone miss a wrong scale or a mirrored axis.
- **Personas.** If the dependency changes its data by faction or class while
  loading, load it fresh for each `persona` (`S.install` then `S.loadAddon`).
- **Prove it can fail.** Run once against a deliberately broken copy of the
  file under test and confirm the harness fails.

## Gotchas

- Unknown client functions fail loudly by design ("attempt to call a nil
  value (global 'X')"). Add a stub via `extra` with the smallest behaviour
  the code needs; do not add a catch-all `__index` that returns no-ops.
- WoW adds Lua helpers LuaJIT lacks (`strsplit`, `tinsert`, `strtrim`,
  `Mixin`, `CreateFromMixins`). Stub only those you hit. `bit` exists in both.
- `metadata.lua` skips `.xml` files in a TOC. Frames declared in XML do not
  exist; templates referenced from Lua will be missing.
- `[AllowLoadGameType ...]` lines need `opts.gameType`, one of `vanilla`,
  `tbc`, `wrath`, `cata`, `mists`, `camelot`, `forever` (the set
  `metadata.lua` knows). Unknown tokens are an error rather than silently
  included.
- `GetAddOnMetadata` answers only for the addon most recently loaded with
  `S.loadAddon`; load the one whose metadata matters last.
- The data addon's folder name is the `addonName` passed to its files. Use
  the exact name the game would use (the folder name).
- Combat lockdown, taint, secure templates, textures, sizes and performance
  cannot be tested here. Those go to a device test.
