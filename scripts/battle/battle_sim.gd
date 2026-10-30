class_name BattleSim
extends RefCounted
## Pure battle math, separated from presentation so headless tests can
## exercise it without a scene. Deterministic except for the explicit
## crit/variance inputs the battle scene supplies from a seeded RNG.

static func calc_damage(atk: float, def: float, power: float, crit: bool = false) -> int:
	var raw: float = max(1.0, atk * power - def * 0.5)
	if crit:
		raw *= 1.5
	return int(raw)

static func calc_heal(mag: float, power: float) -> int:
	return int(max(1.0, mag * power))

static func xp_to_next(level: int) -> int:
	return int(80.0 * pow(float(level), 1.5))

static func escape_chance(party_spd: float, enemy_spd: float) -> float:
	# Bounded 25%-90%; normal attacks never hit an accuracy wall, and
	# escape is never guaranteed or impossible.
	return clampf(0.5 + (party_spd - enemy_spd) * 0.02, 0.25, 0.9)

static func status_tick_damage(max_hp: int, kind: String) -> int:
	if kind == "poison":
		return maxi(1, max_hp / 20)
	if kind == "burn":
		return maxi(1, max_hp / 16)
	return 0

static func can_act(statuses: Dictionary) -> bool:
	# Stun and sleep skip a turn. Stun is capped at 1 turn by the battle
	# scene (see battle.gd); this predicate is what tests assert.
	if int(statuses.get("stun", 0)) > 0:
		return false
	if int(statuses.get("sleep", 0)) > 0:
		return false
	return true
