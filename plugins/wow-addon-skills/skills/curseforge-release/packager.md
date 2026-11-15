# Automated packaging (BigWigs packager)

Read this only when the project will upload through the BigWigs packager
(`BigWigsMods/packager`, usually as a GitHub Action on tag push) instead of
by hand. Setting that up uploads releases automatically, so it needs the
human's explicit approval; propose it, do not add it unasked.

- **Forever detection.** The packager maps `## Interface: 16xxx` to the
  `forever` game type, CurseForge game type ID `88568`.
- **TOC suffix.** For multi-flavor TOCs the packager recognises only the
  `_Camelot` suffix for this client, not `_Forever`, although the game
  itself accepts both. A project that relies on the packager's per-flavor
  TOC handling should name the file `<Addon>_Camelot.toc` (or use a single
  `<Addon>.toc`).
- **Project ID.** The packager finds the CurseForge project from
  `## X-Curse-Project-ID: <id>` in the TOC. Manual uploads ignore this line.
- **Token.** The CurseForge upload token goes in the repository secret
  `CF_API_TOKEN`. `CF_API_KEY` is the deprecated name; do not use it in new
  workflows. The human creates the token on CurseForge and adds the secret;
  never ask them to paste it into the chat.
- **Release type** comes from the tag: a plain version tag is a Release;
  tags containing `beta` or `alpha` produce those types. Confirm against the
  packager's README for the version pinned in the workflow.
- The zip hygiene rules in SKILL.md still apply; check the packager's
  `.pkgmeta` ignore list keeps `tests/`, `vendor/` and dev files out.
