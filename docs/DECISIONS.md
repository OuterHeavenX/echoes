# DECISIONS

- **Godot 4.7.2, Compatibility renderer, single-threaded Web** (2026-10-30).
  Already installed here with matching export templates; Compatibility
  is the shared baseline for web + Steam Deck; nothreads Web needs no
  cross-origin headers in the default itch.io embed.
- **Code-generated sprites/audio via tools/gen_assets.py** (2026-10-30).
  Pillow rectangles + sine/triangle WAV loops: fully original, fully
  reproducible, no paid or third-party assets, imports cleanly headless
  (verified). Portraits are crops of the same sprites for now.
- **2.5D = Sprite3D billboards + low-poly coloured geometry, orthographic
  camera** (2026-10-30). Achieves the brief's hybrid look without
  Forward+, heavy postprocessing, or desktop-only effects.
- **Content in JSON, one file per kind, loaded by Content autoload**
  (2026-10-30). Validators check references; game code never hardcodes
  campaign data. Save format is GameState.to_dict() (schema v1).
- **Battle math separated (BattleSim) from presentation (battle.gd)**
  (2026-10-30). Headless tests exercise the math without a scene.
- **Visible enemies, no random encounters in the slice** (2026-10-30).
  Prevents entrance encounters and post-victory re-battles; repeatable
  grinding areas are a Milestone E item, not a slice promise.
- **No public repo / itch.io page created** (2026-10-30). The master
  prompt requires a confirmed destination + explicit authorization;
  neither exists yet, so delivery stops at local packages + commands.
- **Not claimed:** 20–25h playtime, Steam Deck Verified, iPhone/iPad/
  Android/Deck device testing, composed music, full campaign. All are
  labelled pending/unmeasured in QA.md and PROGRESS.md.
