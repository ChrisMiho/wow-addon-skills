---
name: wow-api-verify
description: Confirm that a World of Warcraft API function, event, frame or CVar exists on a specific game client flavor before addon code relies on it, by reading Blizzard's interface source in Gethe/wow-ui-source on that flavor's branch. Use when someone asks "is this API available on Forever", "does C_X.Y exist on Classic Era", "can I call this on this client", "which flavor has this function", or before adding any new game API call to an addon. Also covers guarding calls that could not be confirmed and logging them with their worst case.
---

# Verify a WoW API on a client flavor

Each WoW client flavor ships a different API. Memory, wowpedia and code written
for retail are not evidence for another flavor. The evidence is Blizzard's own
interface code, mirrored per flavor in `github.com/Gethe/wow-ui-source`.

## 1. Pick the branch

One branch per flavor. Only the first row below is confirmed (branch head
build `1.60.1 (70938)`, matching the WoW Forever client). The others are
likely matches from the branch names, not checked:

| Flavor | Branch | Status |
|---|---|---|
| WoW Forever (internal name "Camelot", interface 16xxx) | `forever` | confirmed |
| Classic Era / Hardcore | `classic_era` (`classic_era_ptr`) | unconfirmed |
| Current progression Classic | `classic` (`classic_ptr`) | unconfirmed |
| Anniversary realms | `classic_anniversary` | unconfirmed |
| Retail | `live` (`ptr`, `ptr2`, `beta`) | unconfirmed |

List them fresh if unsure: `git ls-remote --heads https://github.com/Gethe/wow-ui-source.git`.
The branch's latest commit message is the client build, e.g. `1.60.1 (70938)`:
`gh api repos/Gethe/wow-ui-source/commits/forever --jq .commit.message`.
Before trusting a branch, compare that build with the client's version
(shown on the login screen, or `/dump GetBuildInfo()` in game) or with the
addon's TOC `## Interface` number. If they do not match, the branch is the
wrong flavor or out of date: say so and do not use it as evidence.
Record that build next to every fact you verify.

Do not use `gh search code` or GitHub's web search: they index only the
default branch (`live`), so a hit there says nothing about another flavor.

## 2. Look it up

For more than one lookup, keep a shallow clone per branch and grep it:

```bash
git clone --depth 1 --single-branch --branch forever \
  https://github.com/Gethe/wow-ui-source.git ~/.cache/wow-ui-source/forever
D=~/.cache/wow-ui-source/forever/Interface/AddOns
grep -rln 'Namespace = "C_QuestLog"' $D/Blizzard_APIDocumentationGenerated/
grep -n -A14 'Name = "GetInfo"' $D/Blizzard_APIDocumentationGenerated/QuestLogDocumentation.lua
```

(`git -C <clone> pull` refreshes it after a client patch.) For one lookup,
fetch the raw file: `curl -fsS https://raw.githubusercontent.com/Gethe/wow-ui-source/forever/<path>`.

If none of these can reach GitHub (offline, or the tools need approval you
do not have), say the API is unverified on that flavor and what you would
need to check it. Do not answer from memory or from another flavor's docs.

Where to look, strongest evidence first:

1. **Generated documentation**: `Blizzard_APIDocumentationGenerated/*Documentation.lua`.
   Find the file by `Namespace = "C_Name"`, then the entry by `Name = "Func"`.
   It gives arguments, returns, `Nilable`, `MayReturnNothing`, and
   `SecretArguments`. Events are under `Events` with `LiteralName = "QUEST_LOG_UPDATE"`
   and their payload. Enums and structures (for example `QuestInfo` fields)
   are in the same files.
2. **Blizzard's own calls**: `grep -rn 'FuncName' $D` across the whole branch.
   Some older globals (`RepairAllItems`, `CanMerchantRepair`,
   `GetRepairAllCost` on `forever`) are missing from the generated docs. A call in
   Blizzard's code proves the function exists and shows the argument form, but
   not its restrictions (protected, needs a hardware event, taint).
3. **Frames, templates, CVars**: grep for the frame name (`ContainerFrameCombinedBags`),
   the template in `.xml`, or the CVar string (`"combinedBags"`).

Not found on the branch means "not available on this flavor" until proven
otherwise. Check the same name on `live` only to explain the difference.

## 3. Write the code to survive being wrong

For anything not confirmed in step 2 (or confirmed only by usage, where
restrictions are unknown), guard the call so a wrong guess cannot raise a Lua
error:

```lua
-- Function may not exist on this flavor
if C_Foo and type(C_Foo.Bar) == "function" then C_Foo.Bar(x) end

-- Exists but may error or be blocked here
local ok, result = pcall(C_Foo.Bar, x)
if not ok then --[[ fall back, and log result ]] end
```

- Check `type(x) == "function"`, not just truthiness: some globals are tables
  or stubs on other flavors.
- `pcall` does not stop "action blocked by an addon" (a protected function
  called from tainted code). For protected actions the guard is calling only
  from a real button press, out of combat (`InCombatLockdown()`).
- Check `Nilable = true` returns before indexing them.

## 4. Record what could not be verified

Keep a table in the project's architecture or API notes (create one if
missing). One row per unverified item:

| What | Used by | If it is wrong |
|---|---|---|
| `C_Foo.Bar` return order (documented only by usage) | Feature X | Feature X shows the wrong value; the feature stays usable |

The third column is the worst case a player would see, in plain words. Head
the table with the branch and build you checked against. Move a row to a
"verified" list only after a real in-game test or a source confirmation, and
say which.

## Answering "is X available on <flavor>?"

State: the branch and build checked, the file and line where it appears (or
that it does not), its signature, any `SecretArguments`/`Nilable` notes, and
whether it is documented or only used by Blizzard code. If it is only used,
say its restrictions are unknown.
