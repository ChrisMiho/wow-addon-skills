# Notices

The plugin as a whole is licensed under GPL-3.0 (see `LICENSE`). The harness
files in `skills/addon-offline-harness/` have these origins.

| File | Source | Version | Licence |
|---|---|---|---|
| `LibDeflate.lua` | <https://github.com/SafeteeWoW/LibDeflate/blob/6831edcaa915154e7769d622e0de72ee5d25a882/LibDeflate.lua> | 1.0.2-release (commit `6831edc`), unmodified | zlib (below; also kept at the top of the file) |
| `metadata.lua` | <https://github.com/Questie/QuestieDB/blob/4dbb82440a27856f8dccf57094a5d792cdc7cc9b/emulator/metadata.lua> | commit `4dbb824` (the build commit of QuestieDB 1.1.1), unmodified | GPL-3.0 |
| `stubs.lua` | Generalised from `tests/questiedb/stubs.lua` in <https://github.com/ChrisMiho/wow-forever-pocket-essentials> | | GPL-3.0 |
| `decode.lua` | `tests/questiedb/decode.lua` in the same project; only the header comment changed | | GPL-3.0 |

SHA-256 of the unmodified files:
- `LibDeflate.lua` `76f2114e527c2be1ac5cf768a68084946a3e19f63592834640020b7c9b5a450f`
- `metadata.lua` `6b18286acc05352dfb5f512cd7efcceb14905aa2b46dd6e0a2501908fcabfc0d`

## metadata.lua provenance

Every commit to `emulator/metadata.lua` is by Logonz, who is listed in
QuestieDB's `LICENSE.md` as having put their contributions under GPL-3.0, so
it is compatible with this plugin's GPL-3.0. QuestieDB's own
`emulator/client.lua` is deliberately not used: its CBOR decoder
(`generator/vendor/BlizzardCBOR.lua`) could not be traced to an author or
licence. `decode.lua` is independent code written instead.

## LibDeflate (zlib License)

```
LibDeflate 1.0.2-release
@copyright LibDeflate <2018-2020> Haoqian He
@license zlib License

(C) 2018-2020 Haoqian He

This software is provided 'as-is', without any express or implied
warranty.  In no event will the authors be held liable for any damages
arising from the use of this software.

Permission is granted to anyone to use this software for any purpose,
including commercial applications, and to alter it and redistribute it
freely, subject to the following restrictions:

1. The origin of this software must not be misrepresented; you must not
   claim that you wrote the original software. If you use this software
   in a product, an acknowledgment in the product documentation would be
   appreciated but is not required.
2. Altered source versions must be plainly marked as such, and must not be
   misrepresented as being the original software.
3. This notice may not be removed or altered from any source distribution.
```
