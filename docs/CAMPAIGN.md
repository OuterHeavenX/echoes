# CAMPAIGN — chapter graph and pacing budgets

Playtime targets (design targets, NOT measured claims): 20–25h main
story first play, 35–50h with substantial optional content. No full
playthrough has been measured yet; the slice below is the only timed
material, and even that has not been device-timed.

## Implemented
- **Prologue — Lanternwake (Bellweather).** Festival town, deliver the
  sealed tuning fork, scheduled extraction goes wrong, a whole street
  forgets Rowan's sister, Rowan escapes with Mira and Garran.
  Implemented: town exploration, festival dialogue, incident scene,
  party joins. Estimated slice play: 25–40 minutes for town + undercroft
  + boss on a first run (estimate, not a measurement).
- **Chapter 1 — Bellweather: disappearance, rescue, local investigation.**
  Implemented: evidence quest (Tomas → ledger chest), undercroft
  dungeon (3 visible encounters, 3 chests), Extraction Warden boss
  (2 phases, Memory Drain tell in phase 2), survivors freed,
  chapter-end transition to Chapter 2. Side quests implemented:
  Lanterns for the Old Pier (3 lanterns), A Second Page (second ledger).
  Chapter-end state: chapter="chapter2", party = Rowan/Mira/Garran,
  Bellweather re-enterable. Chapters 2–8 content is NOT built; the
  chapter-2 flag only marks the slice's end.

## Planned (not implemented — do not present as content)
1. Bellweather (above, done in slice form).
2. The Rainward Line — rail journey, displaced communities, first major choice.
3. Glass Orchard — industrial farming region, extraction tradeoffs.
4. The Salt Archive — coastal city, flooded library.
5. Crown Without a King — political fracture, multi-party operation,
   betrayal grounded in earlier behavior.
6. The Quiet Season — failed stabilization, overlapping remembered
   locations, new routes. (Distinct from any FF6 world event; no
   imitation of its villain sequence.)
7. Roads We Remember — open recruitment, character arcs, travel tools
   (rail passes, restored sky-sailer).
8. The Last Dawn — final dungeon, multi-role boss phases, resolution.
Epilogue — authored scenes reflecting quest/relationship outcomes,
postgame state (challenge area, boss rematches, superboss) clearly marked.

## Production targets (accountable, from the master prompt)
8 chapters + prologue + epilogue · 6 regions · 8 towns · 12 dungeons ·
8 characters · 8 personal quest chains · 30 side quests (8+ branching) ·
45 enemy types · 12 main + 4 optional bosses · 12 jobs · 3 repeatable
activities. Current implemented counts are in CONTENT_MANIFEST.md.
Structure must vary per chapter; not every chapter is town → fetch →
dungeon → boss.
