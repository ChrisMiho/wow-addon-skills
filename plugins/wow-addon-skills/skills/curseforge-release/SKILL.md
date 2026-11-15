---
name: curseforge-release
description: Prepare a World of Warcraft addon release for CurseForge, ending with a hand-off to the human who uploads it. Use when someone says "release to CurseForge", "prepare the CurseForge upload", "publish a new version", "make the CurseForge project page" or "what do I fill in on CurseForge". Covers flavor and game version, avatar spec, zip hygiene, relations, X-Curse-Project-ID, changelog and the Alpha/Beta/Release choice. Never uploads.
disable-model-invocation: true
argument-hint: "[version]"
---

# CurseForge release checklist

You prepare; the human uploads. Never upload, never call the CurseForge API
with a token, never push tags or create releases on the human's behalf. The
last step is always a hand-off.

Target version: `$ARGUMENTS` (if empty, read it from the TOC's `## Version`).

## 0. Preconditions (stop and say so if any fails)

- The change set passed the human's in-game test (see the device-test-handoff
  skill). An untested build may go out only as `Alpha`, and only when the
  human explicitly asks for that.
- The project's checks and offline tests pass.
- TOC `## Version` and a matching `CHANGELOG.md` section were updated
  together (semantic versioning).

## 1. Flavor and game version

| Client | CurseForge flavor | Game version | TOC `## Interface` |
|---|---|---|---|
| WoW Forever | `Forever` | `1.60.1` | `16xxx` (e.g. 16001) |

CurseForge's internal game type ID for Forever is `88568` (only automated
packagers need it). For other flavors, read the version list in the upload
form; do not guess.
The CurseForge game version is the client's patch number, not the interface
number. If the game patches, the form may offer a newer version: pick the
one matching the client the human tested on.

## 2. Build the zip and check its hygiene

Build with the project's script, then inspect the result:

```bash
zipinfo -1 dist/<Addon>-<version>.zip
zipinfo -1 dist/<Addon>-<version>.zip | LC_ALL=C grep -E '__MACOSX|\.DS_Store|\.zip$|[^ -~]' && echo "FIX THESE"
```

CurseForge rejects or flags a zip that contains:
- `__MACOSX/` folders or `.DS_Store` files (macOS Finder "Compress" adds
  them: build with `zip -qr -X out.zip <Addon> -x '*.DS_Store' '__MACOSX/*'`);
- nested `.zip` files;
- non-English (non-ASCII) file or folder names.

Also check:
- Each addon folder is at the zip root and contains `<Folder>.toc` or
  `<Folder>_<Suffix>.toc`. No `src/`, `tests/`, `vendor/`, `.git`.
- Only this project's addon is inside. A dependency that has its own
  CurseForge project goes in Relations (step 5), never bundled.
- Every file the TOC lists exists in the zip.

## 3. Project page (first release only)

- **Avatar**: PNG, exactly 400×400, not WebP, not one solid colour, and no
  copyrighted art (no game screenshots, Blizzard icons or logos). Check:
  `python3 -c "from PIL import Image; i=Image.open('avatar.png'); print(i.format, i.size, 'colours:', len(set(i.convert('RGB').getdata())))"`
  (needs Pillow; on macOS `sips -g pixelWidth -g pixelHeight -g format avatar.png`
  checks all but the colours).
- Name, one-line summary, main category plus up to 4 more, licence matching
  the repo's `LICENSE`, source URL and issues URL.
- Description: CurseForge's editor has a Markdown mode; paste Markdown there.
  Images go in the project's Images tab; use their URLs in the description.

## 4. File details

- **Display name / file**: the zip from step 2.
- **Flavor and game version**: from step 1.
- **Release type**:
  - `Release`: tested, for everyone. The CurseForge app installs only these
    by default.
  - `Beta`: tested but rough or incomplete; users opt in to see it.
  - `Alpha`: untested or work in progress; most users never see it.
  A 0.x version number already signals "early"; use `Release` for a tested
  0.x build, not `Beta`.
- **Changelog**: paste the `## [<version>]` section of `CHANGELOG.md` (Markdown).

## 5. Relations

Add each dependency that has a CurseForge project by name, slug or project ID,
marked **Required** or **Optional**. The CurseForge relation can differ from
the TOC: a TOC `OptionalDeps` (the addon loads without it) may still be a
CurseForge **Required** relation when the main features need it, so the app
installs it automatically. Say which you chose and why.

## 6. `## X-Curse-Project-ID`

Only automated packagers (BigWigs packager, CI uploads) read it. A manual
upload does not need it. Once the project exists, its ID is on the project
page; adding the line under `## Version` takes effect with the next upload,
so never re-upload just for it. If the project will use an automated
packager, read `${CLAUDE_SKILL_DIR}/packager.md` first.

## 7. Hand off

Write (or update) a values file in the repo, e.g. `curseforge/FIELDS.md`,
listing every form field in the order the form asks, with the exact value or
file path to use, then tell the human:

- the zip path and size, and the result of the hygiene check;
- the release type you recommend and why;
- the relations to add;
- that nothing has been uploaded, and that they do the upload.

Then stop. After they confirm the upload, record the release (date, version,
CurseForge project ID if new) in the project's status notes.
