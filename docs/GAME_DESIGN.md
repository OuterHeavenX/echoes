# GAME DESIGN — Echoes of the Last Dawn (concise reference)

## Identity
Original 2.5D JRPG. Pixel billboard characters (Sprite3D) over low-poly
coloured 3D geometry, orthographic camera, Compatibility renderer.
Sprite size: 48x64 PNG (16x21 pixel grid at 3x), portraits 96x106.
No Godot branding player-facing. No paid assets. No backend, account,
subscription, or Steamworks dependency.

## Combat (ATB, Wait default)
- 4 party slots, front/back is a future tuning item (not yet implemented;
  positioning currently has no effect — do not claim otherwise).
- Commands: Attack, Skill, Item, Guard, Escape (never from bosses).
- ATB fills by SPD (haste x1.4, slow x0.6), 100 = ready. Wait mode pauses
  ATB while the player picks a command/target; Active keeps it running.
- Damage: `max(1, ATK x power - DEF x 0.5)`, crit x1.5 (10% base).
  Vulnerable x1.25, guard x0.5, barrier absorbs first, weak x1.5.
- Statuses (turns counted on the owner's own turns): poison (HP/20),
  burn (HP/16), slow, haste, sleep, silence, blind (25% physical miss),
  regen (HP/10), barrier (flat absorb), stun (1 turn, then cleared —
  no stun locks), vulnerable. Bosses are immune to stun (selective
  resistance, not universal immunity).
- Resonance: attacks +5, skills +10, cap 100. Team techniques cost 50:
  Resonant Beacon (damage all + vulnerable), Iron Chorus (barrier +
  heal all). Not required for ordinary encounters.
- Pacing targets (unmeasured in this slice): common 30–90s, elites 2–4m,
  bosses 4–8m at default speed.

## Progression
- XP → level (1–99; story target finish 45–55, not required for 99).
  `xp_next = 80 x level^1.5`. JP → job abilities.
- Victory shows exact XP/JP/gold per character. Active party full;
  reserves 80% (catch-up, no recovery grind).
- Each character: unique personal command (implemented as their job's
  signature ability in this slice), one main job, secondary command set
  and passive loadout are Milestone C work (data fields exist, UI for
  secondary/passive loadout is not yet built).
- Jobs (12 planned): Vanguard, Duelist, Arcanist, Mender, Ranger,
  Artificer, Cantor, Hexweaver, Wayfarer, Sentinel, Chronist, Bellbound.
  Implemented with 6 abilities + 3 passives each: Vanguard, Artificer,
  Wayfarer, Mender (v0.3.0-c1). The other 8 have names/descriptions
  only — see manifest. Passive unlocks live in the Jobs menu; all
  unlocked passives apply.
  JP costs in the menu: first ability free (starter), then 20/40/60/80/100.
  No refunds yet (respec rules are Milestone C).

## Exploration / quests
- Overworld is Milestone C; this slice has two connected maps
  (Bellweather town, station undercroft) with door transitions.
- No random encounters in town. Undercroft uses visible enemies;
  touching one starts battle. No entrance encounters, no immediate
  re-battle after victory (defeated visible enemies stay defeated).
- Journal distinguishes main / side quests with stage text.
- Shops, inn (rest 20G, full heal), one-time chests (flag-gated),
  quest markers toggleable in Settings.

## Interface / accessibility
- Menu: Party, Equipment, Jobs, Inventory, Journal, Settings, Save.
  All button-driven (keyboard / gamepad / touch, no hover dependency).
- Settings now: battle Wait/Active, battle-speed cycle
  (0.5x/1x/1.5x/2x, drives ATB fill), music/SFX volume toggles,
  reduce motion, camera-shake toggle (stored; effect pending),
  UI-scale cycle (applied on scene load), quest markers. Text speed
  applies to dialogue typewriter. Font scaling and remapping are
  still Milestone C.
