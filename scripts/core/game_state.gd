extends Node
## Central game state. Serializable: to_dict()/from_dict() are the save format.
## No scene nodes are stored here, only stable IDs and numbers (schema v1).

const SCHEMA_VERSION: int = 1
const SETTINGS_DEFAULT: Dictionary = {
	"text_speed": 1.0, "battle_speed": 1.0, "battle_mode": "wait",
	"music_volume": 0.8, "sfx_volume": 0.8, "reduce_motion": false,
	"camera_shake": true, "ui_scale": 1.0, "quest_markers": true,
}

var data: Dictionary = {}
var pending_encounter: String = ""
var return_map: String = "bellweather"
var return_pos: Vector2 = Vector2(0, 0)
var last_battle_result: Dictionary = {}

func _ready() -> void:
	_setup_input()
	new_game()

func _setup_input() -> void:
	var defs: Dictionary = {
		"move_up": [[KEY_W, KEY_UP], [JOY_BUTTON_DPAD_UP]],
		"move_down": [[KEY_S, KEY_DOWN], [JOY_BUTTON_DPAD_DOWN]],
		"move_left": [[KEY_A, KEY_LEFT], [JOY_BUTTON_DPAD_LEFT]],
		"move_right": [[KEY_D, KEY_RIGHT], [JOY_BUTTON_DPAD_RIGHT]],
		"confirm": [[KEY_ENTER, KEY_SPACE, KEY_Z], [JOY_BUTTON_A]],
		"cancel": [[KEY_ESCAPE, KEY_X], [JOY_BUTTON_B]],
		"menu": [[KEY_TAB, KEY_M], [JOY_BUTTON_Y]],
		"interact": [[KEY_E, KEY_ENTER, KEY_SPACE], [JOY_BUTTON_A]],
		"map": [[KEY_Q], [JOY_BUTTON_BACK]],
	}
	for action in defs.keys():
		if not InputMap.has_action(action):
			InputMap.add_action(action)
		for keys in defs[action][0]:
			var ev: InputEventKey = InputEventKey.new()
			ev.keycode = keys
			if not InputMap.action_has_event(action, ev):
				InputMap.action_add_event(action, ev)
		for btn in defs[action][1]:
			var ev2: InputEventJoypadButton = InputEventJoypadButton.new()
			ev2.button_index = btn
			if not InputMap.action_has_event(action, ev2):
				InputMap.action_add_event(action, ev2)
	# Analog sticks for movement.
	for action in ["move_up", "move_down", "move_left", "move_right"]:
		var ev3: InputEventJoypadMotion = InputEventJoypadMotion.new()
		ev3.axis = JOY_AXIS_LEFT_Y if action in ["move_up", "move_down"] else JOY_AXIS_LEFT_X
		ev3.axis_value = -1.0 if action in ["move_up", "move_left"] else 1.0
		InputMap.action_add_event(action, ev3)

func new_game() -> void:
	data = {
		"schema": SCHEMA_VERSION,
		"chapter": "prologue",
		"map": "bellweather",
		"player_pos": [0.0, 6.0],
		"party": ["rowan"],
		"chars": {},
		"inventory": {"potion": 3},
		"gold": 50,
		"flags": {},
		"quests": {"main_fork": 0},
		"playtime": 0.0,
		"settings": SETTINGS_DEFAULT.duplicate(true),
	}
	for cid in Content.char_ids():
		var st: Dictionary = stats_base(cid, 1)
		data["chars"][cid] = {
			"level": 1, "xp": 0, "jp": 0, "hp": st["max_hp"], "mp": st["max_mp"],
			"job": Content.characters[cid].get("job", "wayfarer"),
			"abilities": [], "passives": [], "weapon": "", "armor": "", "accessory": "",
		}
	# Slice starters: each hero starts with one signature job ability.
	data["chars"]["rowan"]["abilities"] = ["couriers_dash"]
	data["chars"]["mira"]["abilities"] = ["stun_bomb"]
	data["chars"]["garran"]["abilities"] = ["shield_wall"]
	data["chars"]["sera"]["abilities"] = ["triage"]

func stats_base(cid: String, level: int) -> Dictionary:
	var b: Dictionary = Content.characters.get(cid, {})
	var g: int = level - 1
	return {
		"max_hp": int(b.get("hp", 100)) + int(b.get("hp_growth", 10)) * g,
		"max_mp": int(b.get("mp", 30)) + int(b.get("mp_growth", 4)) * g,
		"atk": int(b.get("atk", 10)) + int(b.get("atk_growth", 1)) * g,
		"def": int(b.get("def", 8)) + int(b.get("def_growth", 1)) * g,
		"mag": int(b.get("mag", 10)) + int(b.get("mag_growth", 2)) * g,
		"spd": int(b.get("spd", 10)) + int(b.get("spd_growth", 1)) * g,
	}

func stats_for(cid: String) -> Dictionary:
	var c: Dictionary = data["chars"].get(cid, {})
	var st: Dictionary = stats_base(cid, int(c.get("level", 1)))
	for slot in ["weapon", "armor", "accessory"]:
		var item_id: String = str(c.get(slot, ""))
		if item_id != "" and Content.items.has(item_id):
			var it: Dictionary = Content.items[item_id]
			st["atk"] += int(it.get("atk", 0))
			st["def"] += int(it.get("def", 0))
			st["spd"] += int(it.get("spd", 0))
	st["level"] = int(c.get("level", 1))
	st["hp"] = int(c.get("hp", st["max_hp"]))
	st["mp"] = int(c.get("mp", st["max_mp"]))
	st["jp"] = int(c.get("jp", 0))
	st["xp"] = int(c.get("xp", 0))
	st["xp_next"] = xp_to_next(st["level"])
	st["job"] = str(c.get("job", ""))
	return st

func xp_to_next(level: int) -> int:
	return int(80.0 * pow(float(level), 1.5))

func active_party() -> Array:
	var out: Array = []
	for cid in data["party"]:
		if out.size() < 4:
			out.append(cid)
	return out

func add_party(cid: String) -> void:
	if cid not in data["party"]:
		data["party"].append(cid)

func set_flag(flag: String) -> void:
	data["flags"][flag] = true

func has_flag(flag: String) -> bool:
	return bool(data["flags"].get(flag, false))

func quest_stage(qid: String) -> int:
	return int(data["quests"].get(qid, -1))

func quest_start(qid: String) -> void:
	if qid not in data["quests"]:
		data["quests"][qid] = 0

func quest_advance(qid: String, stage: int) -> void:
	data["quests"][qid] = stage

func add_item(item_id: String, count: int = 1) -> void:
	data["inventory"][item_id] = int(data["inventory"].get(item_id, 0)) + count

func remove_item(item_id: String, count: int = 1) -> bool:
	var have: int = int(data["inventory"].get(item_id, 0))
	if have < count:
		return false
	data["inventory"][item_id] = have - count
	return true

func item_count(item_id: String) -> int:
	return int(data["inventory"].get(item_id, 0))

func heal_party() -> void:
	for cid in data["party"]:
		var st: Dictionary = stats_for(cid)
		data["chars"][cid]["hp"] = st["max_hp"]
		data["chars"][cid]["mp"] = st["max_mp"]

func gain_rewards(xp: int, jp: int, gold: int) -> Array:
	# Returns per-character gain lines for the victory screen.
	# Active party: full. Reserves: 80% (catch-up, no grinding to recover).
	var lines: Array = []
	data["gold"] = int(data["gold"]) + gold
	for cid in data["party"]:
		var active: bool = cid in active_party()
		var gx: int = xp if active else int(xp * 0.8)
		var gj: int = jp if active else int(jp * 0.8)
		var c: Dictionary = data["chars"][cid]
		c["xp"] = int(c["xp"]) + gx
		c["jp"] = int(c["jp"]) + gj
		var leveled: int = 0
		while int(c["xp"]) >= xp_to_next(int(c["level"])):
			c["xp"] -= xp_to_next(int(c["level"]))
			c["level"] += 1
			leveled += 1
		if leveled > 0:
			var st: Dictionary = stats_for(cid)
			c["hp"] = st["max_hp"]
			c["mp"] = st["max_mp"]
		var nm: String = str(Content.characters.get(cid, {}).get("name", cid))
		lines.append("%s: +%d XP, +%d JP%s" % [nm, gx, gj, ("  LEVEL UP! Lv.%d" % int(c["level"])) if leveled > 0 else ""])
	return lines

func setting(key: String):
	return data["settings"].get(key, SETTINGS_DEFAULT.get(key))

func to_dict() -> Dictionary:
	var d: Dictionary = data.duplicate(true)
	d["schema"] = SCHEMA_VERSION
	return d

func from_dict(d: Dictionary) -> bool:
	if int(d.get("schema", 0)) != SCHEMA_VERSION:
		return false
	if not d.has("chars") or not d.has("party"):
		return false
	data = d.duplicate(true)
	return true
