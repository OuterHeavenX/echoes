# PROGRESS — v0.3.0-c1 (2026-10-30)

## Completed and tested (Milestone C, first increment — 2026-10-30)
- Sera Voss recruited in Bellweather after the incident (NPC at the
  south side, stays until recruited, never missable, not duplicated
  once in the party). Party can now reach 4 members.
- Mender job complete: 6 abilities (Triage, Mend Wounds, Ward, Renew,
  Sanctuary, Second Chance revive) + 3 passives (Gentle Hands +20%
  healing, Preventive Care starting barrier, Steady Pulse silence
  immunity), all functional in battle; passive unlock UI added to the
  Jobs menu (JP costs 30/50/70; all unlocked passives apply).
- Settings menu: battle-speed cycle (0.5x/1x/1.5x/2x, actually drives
  ATB fill), camera-shake toggle (setting stored; shake effect itself
  is not yet implemented in the world camera), UI-scale cycle
  (1.0/1.25/1.5, applied on every scene load).
- New tests: tests/test_mender.tscn (6 checks, all pass), heal-math
  check in test_battle.gd (14 checks total, all pass). Full build.sh
  re-run: validator, import, both exports, packages + checksums all OK.
  A Linux preset-options warning seen during import was fixed by
  giving the preset a real options section; the export itself was
  never broken by it.

## Completed and tested (v0.2.0-slice)
- Milestone A: Godot 4.7.2 project (Compatibility renderer, single-thread
  Web), title screen, new/continue/autosave/import, controllable
  character in Bellweather, keyboard/gamepad/touch input, NPC dialogue,
  collision, save/load skeleton.
- Milestone B slice: Lanternwake prologue, disappearance incident,
  Bellweather exploration, station undercroft, 3 playable heroes,
  3 visible encounter groups + boss (Extraction Warden, 2 phases),
  shop/inn, equipment, initial job selection via JP unlocks, 2 complete
  side quests, XP/JP victory + defeat/retry, reliable saves, chapter-end
  transition to Chapter 2 flag.
- Tests run 2026-10-30 (all pass): headless battle-math tests (13 checks),
  save round-trip + corrupted/wrong-schema rejection, content validator
  (all reference checks), title/world/battle headless scene smoke runs
  (no script errors after fixes).
- Exports built 2026-10-30: Web (dist/web, index.html + index.pck with
  GDPC magic, served locally over HTTP 200) and Linux x86_64 (exe + .pck
  with GDPC magic, boots under xvfb and stays running, no script errors).

## Remaining (in priority order)
1. Milestone C (in progress): 8-character party (4 of 8 playable),
   remaining 8 jobs (4 of 12 complete), secondary command sets,
   overworld, map screen, save migration tests, accessibility
   (font scaling, remapping, camera-shake effect), front/back
   positioning effects. Done in this increment: Sera, Mender,
   passive loadout UI, battle-speed control, UI scale.
2. Milestone D: chapters 2–8 in validated batches, each with regression
   checks (access, balance, prerequisites, return paths, save/reload,
   legal party states, next transition).
3. Milestone E: personal chains, optional recruits (Orin, Tavi), 25 more
   side quests, optional dungeons/bosses, repeatable activities,
   ending variants, postgame.
4. Milestone F: full-path validation, performance pass, browser/
   controller smoke tests, clean-machine import/build, license review,
   release packages + checksums, itch.io/GitHub publishing (requires
   Jimmy's confirmed destination + explicit authorization — NOT done).

## Blockers / pending decisions (none block the slice)
- No blocker stopped Milestone A/B. Publishing is intentionally not
  attempted: no confirmed GitHub repo or itch.io project/channel, no
  token. Packages are local-only until Jimmy confirms a destination.
- Device checks pending (see QA.md): iPhone Safari, iPad, Android
  Chrome, desktop browser playthrough, Steam Deck hardware.

## Playtest pending (2026-10-30)
Jimmy is playtesting v0.3.0-c1 first. Milestone C second increment is
PAUSED until his feedback lands — do not resume Ilyan/Arcanist work
until he reports back or explicitly says to continue.

## GitHub Pages playtest setup (2026-10-30, in progress)
- GitHub connected as OuterHeavenX; no Echoes repo exists yet.
- MCP create_repository FAILED with 403 "Resource not accessible by
  integration" (approved attempt, 2026-10-30): the GitHub App cannot
  create repos, same limit as the old token. Legacy gh.py credential
  is also dead (401 Bad credentials).
- MCP file tools are text-only and cannot push the 38 MB binary
  index.wasm, so the Pages route is CI-based, not a binary push:
  source (39 text files, 144 KB) + .github/workflows/pages.yml are
  ready to push once the repo exists; Actions regenerates assets,
  imports, exports Web (single-threaded), and deploys to Pages.
- BLOCKED on push method (repo name chosen 2026-10-30: echoes):
  repo created with an empty README (Initial commit f5cfe6f).
  Access grant given, but push_files STILL fails with 403 on the
  Git Data API trees endpoint ("Resource not accessible by
  integration"). Diagnosis 2026-10-30: read access works, and a
  single-file write via create_or_update_file DID succeed (test
  file PUSH_TEST.txt, commit f9e4083 — to be removed on the real
  push). So the App can write individual files but not bulk trees.
  Chosen 2026-10-30: push one by one. Landed by 15:37 CDT:
  project.godot, export_presets.cfg, .gitignore, README.md;
  test file removed. BLOCKER on workflow file only:
  .github/workflows/pages.yml returns 403 via single-file API —
  workflow files need a Workflows permission the App does not
  have. Workaround: Jimmy creates that file via GitHub web UI,
  or Venom creates it via his browser session. Source files can
  still go up one by one in the meantime.
  After a successful push: Jimmy sets repo Settings > Pages >
  Source to GitHub Actions; Venom verifies
  https://outerheavenx.github.io/echoes/
  Push manifest ready: 57 text files (source + workflow, no binaries;
  PNG/WAV regenerated by CI), /tmp/echoes_paths.txt.
- Prepared locally: dist/pages/ (full web build + .nojekyll) as a
  fallback if a binary-capable push route is restored later.

## Exact next task (after playtest feedback)
Milestone C, second increment: recruit Ilyan Reed in a Bellweather-side
scene (same non-missable pattern as Sera), implement the Arcanist job's
6 abilities + 3 passives in content/jobs.json and battle.gd, then
re-run tests + both exports before any further content.
