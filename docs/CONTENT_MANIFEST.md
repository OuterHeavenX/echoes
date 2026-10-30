# CONTENT MANIFEST — implemented vs. planned (v0.2.0-slice)

Validated by `python3 tools/validate_content.py` (all checks pass on
2026-10-30). "Implemented" means it runs in the exported builds;
"planned" means data/names only, or nothing at all.

## Characters (8 planned, 4 playable)
- Rowan Vale (Wayfarer) — implemented, playable.
- Mira Fen (Artificer) — implemented, playable (joins in prologue).
- Garran Holt (Vanguard) — implemented, playable (joins in prologue).
- Sera Voss (Mender) — implemented, playable (joins in Bellweather
  after the incident; non-missable, v0.3.0-c1).
- Ilyan Reed (Arcanist), Nessa Quill (Ranger) —
  stats + job names in data, NOT recruitable yet (Milestone C).
- Orin Ash (Bellbound), Tavi Marr (Cantor) — optional recruits, planned.
- Personal quest chains: 0 of 8 implemented. Relationship scenes,
  field dialogue per character, and party-aware substitutions are
  Milestone D work. Major scenes in the slice work with the fixed
  slice party only.

## Jobs (12 planned, 4 complete)
- Complete (6 abilities + 3 passives, functional in battle):
  Vanguard, Artificer, Wayfarer, Mender (v0.3.0-c1).
- Named/described only (0 abilities): Duelist, Arcanist,
  Ranger, Cantor, Hexweaver, Sentinel, Chronist, Bellbound.
- Mastery rewards: defined in data for the 3 complete jobs; the
  mastery effects themselves are not yet applied in battle.

## Enemies / bosses
- Implemented: Canal Rat, Memory Wisp, Rust Mender, Authority Sentry
  (4 normal types), Extraction Warden (1 main boss, 2 phases).
- Planned: 41 more normal types, 11 more main bosses, 4 optional bosses
  including a final mastery challenge.

## Maps / dungeons / towns
- Implemented: Bellweather (town, shops/inn, 3 lanterns, 4 NPCs),
  station undercroft (dungeon, 3 visible encounters, 3 chests, boss).
- Planned: 7 more towns, 11 more dungeons, overworld + fast travel,
  rail passes, sky-sailer.

## Quests
- Implemented (5): main_fork, main_evidence, main_rescue,
  side_lanterns, side_ledger. Branching outcomes: 0 of 8 target yet.
- Planned: 25 more side quests, personal chains, repeatable contracts,
  bounty/arena/training activities.

## Systems status
- Done: title, 3D world + movement/collision, dialogue, shop/inn,
  menu (party/equip/jobs/inventory/journal/settings/save), ATB Wait/
  Active battle, statuses, resonance team techniques, XP/JP + reserves,
  3 slots + autosave + .bak + JSON export/import, touch D-pad/buttons,
  keyboard + gamepad InputMap, generated sprites/audio.
- Partial: front/back positioning has no effect; secondary jobs
  are not built (passive loadout UI is built; all unlocked passives
  apply); camera-shake toggle is stored but the shake effect is not
  yet implemented; music is simple generated loops, not composed
  tracks; portraits are sprite crops, not separate art.
- Not done: overworld, chapters 2–8, epilogue/postgame, New Game+,
  remapping UI, font/UI scale, in-game keyboard, bestiary, world map.
