# QA — actual tests and unverified checks (v0.2.0-slice, 2026-10-30)

## Run and passing
- `python3 tools/validate_content.py` — all reference/duplicate/target
  checks pass; 3 jobs complete, 8 characters, 5 enemies, 4 encounters,
  5 quests, 11 dialogue nodes.
- `godot --headless --path . -s tests/test_battle.gd` — 13/13 pass
  (damage, crit, floor, XP curve, escape bounds, status ticks, can_act).
- `godot --headless --path . tests/test_save.tscn` — save round trip,
  corrupted-save rejection, wrong-schema rejection all pass.
- `godot --headless --path . --import` — clean after fixing
  `InputMap.action_add_event` and `sin()` API mistakes found by the
  import itself.
- Headless scene smoke runs (timeout, no script errors): title, world,
  battle. World initially failed on `sinf()` and camera `look_at`
  before `add_child` — both fixed and re-verified.
- Web export: `index.pck` starts with GDPC magic; served locally with
  `python3 -m http.server`, index.html returned HTTP 200.
- Linux export: exe (71 MB) + .pck (GDPC) boots under `xvfb-run`,
  stays running, no script errors. Audio warnings in the log are the
  VM's missing sound card (ALSA), not game errors.

## NOT verified (pending, do not claim)
- iPhone Safari, iPad, Android Chrome, desktop browser playthrough:
  touch targets, safe areas, and IndexedDB persistence in an itch.io
  iframe are untested. Touch code paths exist (D-pad, Interact/Menu
  buttons, tappable battle targets) but are emulation-free only in the
  sense that no device was available to test them on.
- Steam Deck hardware: no Deck run; do NOT call this Steam Deck
  Verified (only Valve grants that). Desktop Mode launch + non-Steam
  game steps are documented in RELEASE.md but untested on hardware.
- Full route playthrough (title → incident → undercroft → boss →
  chapter end) by a human: the systems were smoke-run, not played
  end-to-end by a person in this session. Battle balance (boss HP 340,
  XP curve) is tuned by formula, not by playtest.
- Performance: no FPS, draw-call, texture-memory, or load-time
  measurements yet. Targets (60 FPS Deck at 1280x800, 30 FPS minimum
  mobile browser) are targets, not results.
- Save persistence across a real browser reload / itch.io iframe:
  untested; export/import is the documented fallback.
