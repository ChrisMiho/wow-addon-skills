# QuestieDB under the offline harness

Read this when the dependency being loaded is QuestieDB
(<https://github.com/Questie/QuestieDB>), the quest/NPC/object/item data addon
that exposes the global `LibQuestieDB`. Facts below were checked against
release 1.1.1 (Forever build, contract 4, 5,914 quests). Re-check them when
pinning a newer release.

## Getting it

- Use the official release zip, not a source checkout:
  `https://github.com/Questie/QuestieDB/releases/download/v<ver>/QuestieDB-<ver>-<Flavor>.zip`.
  Pin the version and its SHA-256 in one script that downloads into an
  uncommitted `vendor/` and verifies with `shasum -a 256 -c`.
- Unzip per run into a temp dir. The zip's root folder is `QuestieDB`; that
  exact name is also the `addonName` its files expect.
- Licence: the Questie team permits copying under GPL-3.0 but cannot speak for
  all past contributors. Ship it unmodified with its licence files, and re-read
  its `LICENSE.md` before shipping a trimmed copy.

## Loading it

```lua
local RESET = { "QuestDB", "NpcDB", "ItemDB", "ObjectDB", "LibQuestieDB",
  "QuestieLoader", "Questie", "QuestieDBSourceModeIndicator" }
S.install({ faction = "Horde", class = "SHAMAN" })
S.loadAddon(dir .. "/QuestieDB_Forever.toc", "QuestieDB", { gameType = "forever", reset = RESET })
local L = _G.LibQuestieDB
assert(L.RequireContract(4) == true)
```

- **The data lives inside the TOC.** It is stored as chunked `## X-...`
  metadata lines and read back through `C_AddOns.GetAddOnMetadata`, then
  base64-decoded, zlib-inflated and CBOR-decoded through `C_EncodingUtil`.
  `stubs.lua` + `decode.lua` provide all of that. This is why the folder name
  must stay exactly `QuestieDB` in a release zip.
- **Two identical TOCs.** The Forever zip ships `QuestieDB_Forever.toc` and
  `QuestieDB_Camelot.toc` (Camelot is the client's internal name), byte-
  identical in 1.1.1. Load either offline; which one the client picks was not
  confirmed, so a release should keep both.
- **`gameType = "forever"`** is required: the TOC has `[AllowLoadGameType ...]`
  lines.
- **`RESET`** is the list of globals a previous load leaves behind (the same
  list as QuestieDB's own `emulator/client.lua` reset). Clear it before each
  reload.
- **Personas.** While loading, QuestieDB applies corrections by faction and
  class (`UnitFactionGroup`, `UnitClassBase`); Shaman has Horde-specific ones.
  Load once per persona, e.g. Alliance Warrior and Horde Shaman.
- Loading the whole database and putting every quest through a consumer
  twice (in log, complete) for two personas took about 2 s.

## API surface (contract 4)

- `L.RequireContract(n)` true when the data format is `n`.
- `L.Quest`, `L.Npc`, `L.Object`, `L.Item`: tables of field functions taking
  an id, e.g. `L.Quest.GetAllIds()`, `L.Quest.Exists(id)`, `L.Quest.name(id)`,
  `L.Quest.objectives(id)`, `L.Quest.finishedBy(id)`, `L.Quest.triggerEnd(id)`,
  `L.Npc.name(id)`, `L.Npc.spawns(id)`, `L.Object.spawns(id)`. Wrap each read
  in `pcall`; a bad id can raise.
- `objectives(id)` is `{ creatures, objects, items, _, killCredit }`:
  `[1]` = `{ {npcId, text?}, ... }`, `[2]` = `{ {objectId, text?} }`,
  `[3]` = `{ {itemId, text?} }`, `[5]` = `{ {_, npcId, text?} }`.
  `finishedBy(id)` is `{ {npcId, ...}, {objectId, ...} }`.
- `spawns(id)` is `{ [areaId] = { {x, y}, ... } }` with x, y in **0..100**
  (map pins usually want 0..1).
- Zones: `L.Support.Get("ZoneDB").private` holds `areaIdToUiMapId` and
  `areaIdToUiMapIdOverride` (the override wins), sometimes as text of the form
  `return { [12] = 1429, ... }` that needs parsing, and `dungeons`. Source:
  `support/Forever/Zones/areaIdToUiMapId.lua` in the release.

## Known values for exact assertions (1.1.1)

- Quest 2 "Sharptalon's Claw", turn-in NPC 12696 "Senani Thunderheart" at
  area 331 (Ashenvale, uiMap 1440), 73.78, 61.46.
- Quest 55 "Morbent Fel", kill NPC 1200 "Morbent Fel" at area 10 (Duskwood,
  uiMap 1431), 16.9, 33.4.

## Building quest-log objectives for the stub

The stub quest log needs `objectives` like the game's
`C_QuestLog.GetQuestObjectives`: `{ text, type, finished }` with type
`"monster"`, `"object"`, `"item"` or `"event"`. Build them from
`L.Quest.objectives(id)` (names via `L.Npc.name` etc.) and `triggerEnd(id)[1]`
for an `"event"` objective, e.g. `"Morbent Fel slain: 0/1"`.
