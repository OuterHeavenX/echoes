extends Control
## ATB battle, Wait mode by default (ATB pauses while the player picks
## a command/target; Active mode keeps it running). Simulation rules
## live in BattleSim; this scene owns presentation, menus, and flow.
## Invariants guarded here: dead units never act, queued actions
## re-validate targets, rewards are granted exactly once on victory.

var encounter_id: String = ""
var encounter: Dictionary = {}
var party_units: Array = []
var enemy_units: Array = []
var ready_queue: Array = []
var current_actor: Dictionary = {}
var pending_kind: String = ""
var pending_skill: Dictionary = {}
var pending_item: String = ""
var pending_target_kind: String = ""
var busy: bool = false
var menu_open: bool = false
var battle_over: bool = false
var rewards_given: bool = false
var resonance: int = 0
var auto_battle: bool = false
var last_action: Dictionary = {}
var taunt_target: String = ""
var taunt_turns: int = 0
var rng: RandomNumberGenerator = RandomNumberGenerator.new()

var enemy_row: HBoxContainer
var enemy_buttons: Array = []
var party_row: VBoxContainer
var party_buttons: Array = []
var command_panel: VBoxContainer
var skill_panel: VBoxContainer
var item_panel: VBoxContainer
var log_label: Label
var resonance_label: Label
var victory_panel: PanelContainer
var defeat_panel: PanelContainer
var result_label: Label

func _ready() -> void:
	get_tree().root.content_scale_factor = float(GameState.setting("ui_scale"))
	rng.randomize()
	encounter_id = GameState.pending_encounter
	if encounter_id == "":
		encounter_id = "undercroft_a"
	encounter = Content.encounters.get(encounter_id, {})
	_build_ui()
	_setup_units()
	AudioMgr.play_music("boss" if bool(encounter.get("is_boss", false)) else "battle")
	_log("Battle! %s" % _enemy_names())

func _enemy_names() -> String:
	var names: Array = []
	for e in enemy_units:
		names.append(e["name"])
	return ", ".join(names)

func _build_ui() -> void:
	var top: HBoxContainer = HBoxContainer.new()
	top.position = Vector2(20, 20)
	add_child(top)
	enemy_row = top
	var log_box: VBoxContainer = VBoxContainer.new()
	log_box.position = Vector2(20, 220)
	add_child(log_box)
	log_label = Label.new()
	log_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	log_label.custom_minimum_size = Vector2(920, 60)
	log_label.add_theme_font_size_override("font_size", 18)
	log_box.add_child(log_label)
	resonance_label = Label.new()
	resonance_label.add_theme_font_size_override("font_size", 16)
	log_box.add_child(resonance_label)
	party_row = VBoxContainer.new()
	party_row.position = Vector2(20, 300)
	add_child(party_row)
	command_panel = VBoxContainer.new()
	command_panel.position = Vector2(620, 300)
	add_child(command_panel)
	skill_panel = VBoxContainer.new()
	skill_panel.position = Vector2(620, 300)
	skill_panel.visible = false
	add_child(skill_panel)
	item_panel = VBoxContainer.new()
	item_panel.position = Vector2(620, 300)
	item_panel.visible = false
	add_child(item_panel)
	victory_panel = _end_panel("Victory!")
	defeat_panel = _end_panel("Defeat")
	victory_panel.visible = false
	defeat_panel.visible = false
	add_child(victory_panel)
	add_child(defeat_panel)

func _end_panel(title: String) -> PanelContainer:
	var p: PanelContainer = PanelContainer.new()
	p.set_anchors_preset(Control.PRESET_CENTER)
	p.size = Vector2(640, 360)
	p.position = Vector2(160, 90)
	var col: VBoxContainer = VBoxContainer.new()
	p.add_child(col)
	var t: Label = Label.new()
	t.text = title
	t.add_theme_font_size_override("font_size", 28)
	col.add_child(t)
	if title == "Victory!":
		result_label = Label.new()
		result_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		col.add_child(result_label)
		var cont: Button = Button.new()
		cont.text = "Continue"
		cont.custom_minimum_size = Vector2(200, 44)
		cont.pressed.connect(_on_victory_continue)
		col.add_child(cont)
	else:
		var retry: Button = Button.new()
		retry.text = "Retry battle"
		retry.custom_minimum_size = Vector2(200, 44)
		retry.pressed.connect(_on_retry)
		col.add_child(retry)
		var title_btn: Button = Button.new()
		title_btn.text = "Back to title"
		title_btn.custom_minimum_size = Vector2(200, 44)
		title_btn.pressed.connect(_on_to_title)
		col.add_child(title_btn)
	return p

func _setup_units() -> void:
	party_units.clear()
	for cid in GameState.active_party():
		var st: Dictionary = GameState.stats_for(cid)
		var passives: Array = GameState.data["chars"].get(cid, {}).get("passives", [])
		var start_barrier: int = 20 if "preventive_care" in passives else 0
		party_units.append({
			"id": cid, "name": str(Content.characters.get(cid, {}).get("name", cid)),
			"hp": st["hp"], "max_hp": st["max_hp"], "mp": st["mp"], "max_mp": st["max_mp"],
			"atk": st["atk"], "def": st["def"], "mag": st["mag"], "spd": st["spd"],
			"job": st["job"], "atb": 0.0, "statuses": {}, "barrier": start_barrier,
			"guarding": false, "counter": false, "is_enemy": false, "sprite": str(Content.characters.get(cid, {}).get("sprite", "rowan")),
			"passives": passives,
		})
	enemy_units.clear()
	for eid in encounter.get("enemies", []):
		var e: Dictionary = Content.enemies.get(eid, {})
		enemy_units.append({
			"id": eid, "name": str(e.get("name", eid)), "hp": int(e.get("hp", 50)), "max_hp": int(e.get("hp", 50)),
			"mp": int(e.get("mp", 0)), "max_mp": int(e.get("mp", 0)), "atk": int(e.get("atk", 10)),
			"def": int(e.get("def", 5)), "mag": int(e.get("mag", 0)), "spd": int(e.get("spd", 10)),
			"role": str(e.get("role", "aggressor")), "weak": str(e.get("weak", "")), "resist": str(e.get("resist", "")),
			"atb": 0.0, "statuses": {}, "barrier": 0, "guarding": false, "counter": false,
			"is_enemy": true, "sprite": str(e.get("sprite", "rat")), "phase2": false, "actions": 0,
		})
	_refresh_enemy_ui()
	_refresh_party_ui()

func _refresh_enemy_ui() -> void:
	for child in enemy_row.get_children():
		child.queue_free()
	enemy_buttons.clear()
	for i in range(enemy_units.size()):
		var e: Dictionary = enemy_units[i]
		var col: VBoxContainer = VBoxContainer.new()
		var btn: TextureButton = TextureButton.new()
		var tex_path: String = "res://assets/sprites/%s.png" % str(e["sprite"])
		if ResourceLoader.exists(tex_path):
			btn.texture_normal = load(tex_path)
		btn.custom_minimum_size = Vector2(96, 128)
		btn.ignore_texture_size = true
		btn.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
		btn.pressed.connect(_on_enemy_button.bind(i))
		col.add_child(btn)
		enemy_buttons.append(btn)
		var l: Label = Label.new()
		l.text = "%s\nHP %d/%d" % [str(e["name"]), int(e["hp"]), int(e["max_hp"])]
		l.add_theme_font_size_override("font_size", 15)
		col.add_child(l)
		enemy_row.add_child(col)
		_update_enemy_button(i)

func _update_enemy_button(i: int) -> void:
	if i >= enemy_buttons.size():
		return
	var e: Dictionary = enemy_units[i]
	var btn: TextureButton = enemy_buttons[i]
	btn.disabled = int(e["hp"]) <= 0
	btn.modulate = Color(0.4, 0.4, 0.4) if int(e["hp"]) <= 0 else Color(1, 1, 1)

func _refresh_party_ui() -> void:
	# Update in place: recreating buttons every frame would break clicks
	# and steal focus, so only build once and then rewrite button text.
	if party_buttons.size() != party_units.size():
		for child in party_row.get_children():
			child.queue_free()
		party_buttons.clear()
		for i in range(party_units.size()):
			var btn: Button = Button.new()
			btn.custom_minimum_size = Vector2(560, 44)
			btn.pressed.connect(_on_party_button.bind(i))
			party_row.add_child(btn)
			party_buttons.append(btn)
	for i in range(party_units.size()):
		var u: Dictionary = party_units[i]
		(party_buttons[i] as Button).text = "%s HP %d/%d MP %d/%d ATB %d%% %s" % [str(u["name"]), int(u["hp"]), int(u["max_hp"]), int(u["mp"]), int(u["max_mp"]), int(u["atb"]), _status_text(u)]

func _status_text(u: Dictionary) -> String:
	var parts: Array = []
	for k in u["statuses"].keys():
		parts.append(k)
	if int(u["barrier"]) > 0:
		parts.append("barrier")
	if bool(u["guarding"]):
		parts.append("guard")
	return "[" + ", ".join(parts) + "]" if parts.size() > 0 else ""

func _log(text: String) -> void:
	log_label.text = text
	resonance_label.text = "Resonance: %d / 100  (skills and attacks build it; team techniques cost 50)" % resonance

func _process(delta: float) -> void:
	if battle_over or busy:
		return
	var wait_mode: bool = str(GameState.setting("battle_mode")) == "wait"
	if wait_mode and menu_open:
		return
	var speed: float = float(GameState.setting("battle_speed"))
	for u in party_units + enemy_units:
		if int(u["hp"]) <= 0:
			continue
		var mult: float = 1.0
		if int(u["statuses"].get("haste", 0)) > 0:
			mult *= 1.4
		if int(u["statuses"].get("slow", 0)) > 0:
			mult *= 0.6
		u["atb"] = minf(100.0, float(u["atb"]) + float(u["spd"]) * 2.0 * mult * speed * delta)
		if float(u["atb"]) >= 100.0 and u not in ready_queue:
			ready_queue.append(u)
	_refresh_party_ui()
	if ready_queue.is_empty() or menu_open:
		return
	var actor: Dictionary = ready_queue.pop_front()
	if int(actor["hp"]) <= 0:
		return
	actor["atb"] = 0.0
	_tick_statuses(actor)
	if not BattleSim.can_act(actor["statuses"]):
		_log("%s is stunned / asleep and loses the turn." % str(actor["name"]))
		actor["statuses"].erase("stun")
		actor["statuses"].erase("sleep")
		_end_actor_turn(actor)
		return
	current_actor = actor
	if bool(actor["is_enemy"]):
		busy = true
		await _enemy_turn(actor)
		busy = false
	else:
		if auto_battle:
			busy = true
			await _auto_party_turn(actor)
			busy = false
		else:
			_open_command_menu(actor)

func _tick_statuses(u: Dictionary) -> void:
	var dmg: int = BattleSim.status_tick_damage(int(u["max_hp"]), "poison") if int(u["statuses"].get("poison", 0)) > 0 else 0
	dmg += BattleSim.status_tick_damage(int(u["max_hp"]), "burn") if int(u["statuses"].get("burn", 0)) > 0 else 0
	if dmg > 0:
		u["hp"] = maxi(0, int(u["hp"]) - dmg)
		_log("%s takes %d damage from poison/burn." % [str(u["name"]), dmg])
	if int(u["statuses"].get("regen", 0)) > 0:
		u["hp"] = mini(int(u["max_hp"]), int(u["hp"]) + int(u["max_hp"]) / 10)
	_refresh_enemy_ui()
	_refresh_party_ui()

func _end_actor_turn(u: Dictionary) -> void:
	# Decrement timed statuses at the end of the owner's own turn.
	for key in ["haste", "slow", "poison", "burn", "regen", "vulnerable", "blind", "silence"]:
		if int(u["statuses"].get(key, 0)) > 0:
			u["statuses"][key] = int(u["statuses"][key]) - 1
			if int(u["statuses"][key]) <= 0:
				u["statuses"].erase(key)
	u["guarding"] = false
	if taunt_turns > 0:
		taunt_turns -= 1
		if taunt_turns <= 0:
			taunt_target = ""

func _open_command_menu(actor: Dictionary) -> void:
	menu_open = true
	_show_command_panel()
	_log("%s, choose a command." % str(actor["name"]))

func _clear_panels() -> void:
	for child in command_panel.get_children():
		child.queue_free()
	for child in skill_panel.get_children():
		child.queue_free()
	for child in item_panel.get_children():
		child.queue_free()
	command_panel.visible = false
	skill_panel.visible = false
	item_panel.visible = false

func _cmd_button(text: String, callable: Callable) -> Button:
	var b: Button = Button.new()
	b.text = text
	b.custom_minimum_size = Vector2(280, 44)
	b.pressed.connect(callable)
	return b

func _show_command_panel() -> void:
	_clear_panels()
	command_panel.visible = true
	command_panel.add_child(_cmd_button("Attack", _on_attack_cmd))
	command_panel.add_child(_cmd_button("Skill", _on_skill_cmd))
	command_panel.add_child(_cmd_button("Item", _on_item_cmd))
	command_panel.add_child(_cmd_button("Guard", _on_guard_cmd))
	if resonance >= 50:
		command_panel.add_child(_cmd_button("Team: Resonant Beacon (50)", _on_team_beacon))
		command_panel.add_child(_cmd_button("Team: Iron Chorus (50)", _on_team_chorus))
	if not last_action.is_empty():
		command_panel.add_child(_cmd_button("Repeat last command", _on_repeat_cmd))
	command_panel.add_child(_cmd_button("Escape", _on_escape_cmd))
	var auto_btn: Button = _cmd_button("Auto: ON" if auto_battle else "Auto: OFF", _on_toggle_auto)
	command_panel.add_child(auto_btn)

func _on_toggle_auto() -> void:
	auto_battle = not auto_battle
	_show_command_panel()

func _on_attack_cmd() -> void:
	pending_kind = "attack"
	pending_target_kind = "enemy"
	_log("Choose an enemy target.")
	_refresh_enemy_ui()

func _on_skill_cmd() -> void:
	_clear_panels()
	skill_panel.visible = true
	var cid: String = str(current_actor["id"])
	var c: Dictionary = GameState.data["chars"].get(cid, {})
	for aid in c.get("abilities", []):
		var a: Dictionary = Content.ability_by_id(str(current_actor["job"]), aid)
		if a.is_empty():
			continue
		var btn: Button = _cmd_button("%s (%d MP) — %s" % [str(a.get("name", aid)), int(a.get("mp", 0)), str(a.get("desc", ""))], _on_skill_pick.bind(a))
		btn.disabled = int(current_actor["mp"]) < int(a.get("mp", 0)) or int(current_actor["statuses"].get("silence", 0)) > 0
		skill_panel.add_child(btn)
	skill_panel.add_child(_cmd_button("Back", _show_command_panel))

func _on_skill_pick(a: Dictionary) -> void:
	pending_skill = a
	pending_kind = "skill"
	var target: String = str(a.get("target", "enemy"))
	pending_target_kind = target
	if target in ["self", "allies"]:
		if target == "self":
			_execute_current([current_actor])
		else:
			_log("Choose an ally target (or tap your own row for the party effect).")
			pending_target_kind = "ally"
	else:
		_log("Choose a target for %s." % str(a.get("name", "")))

func _on_item_cmd() -> void:
	_clear_panels()
	item_panel.visible = true
	for item_id in GameState.data["inventory"].keys():
		if int(GameState.data["inventory"][item_id]) <= 0:
			continue
		var it: Dictionary = Content.items.get(item_id, {})
		if str(it.get("kind", "")) not in ["heal", "mp", "cleanse", "escape"]:
			continue
		item_panel.add_child(_cmd_button("%s x%d — %s" % [str(it.get("name", item_id)), int(GameState.data["inventory"][item_id]), str(it.get("desc", ""))], _on_item_pick.bind(item_id)))
	item_panel.add_child(_cmd_button("Back", _show_command_panel))

func _on_item_pick(item_id: String) -> void:
	pending_item = item_id
	pending_kind = "item"
	if str(Content.items.get(item_id, {}).get("kind", "")) == "escape":
		_execute_current([])
	else:
		pending_target_kind = "ally"
		_log("Choose an ally to use it on.")

func _on_guard_cmd() -> void:
	pending_kind = "guard"
	_execute_current([])

func _on_escape_cmd() -> void:
	pending_kind = "escape"
	_execute_current([])

func _on_repeat_cmd() -> void:
	if last_action.is_empty():
		return
	var kind: String = str(last_action.get("kind", "attack"))
	var targets: Array = []
	if kind == "attack":
		targets = _alive_enemies()
		if targets.is_empty():
			return
		pending_kind = "attack"
		_execute_current([targets[0]])
	else:
		_show_command_panel()

func _on_enemy_button(i: int) -> void:
	if not menu_open:
		return
	if pending_target_kind not in ["enemy", "enemies"]:
		return
	if int(enemy_units[i]["hp"]) <= 0:
		return
	if pending_kind == "skill" and str(pending_skill.get("target", "")) == "enemies":
		_execute_current(_alive_enemies())
	else:
		_execute_current([enemy_units[i]])

func _on_party_button(i: int) -> void:
	if not menu_open:
		return
	if pending_target_kind != "ally":
		return
	# Revive is the one ally skill that targets the fallen.
	var is_revive: bool = pending_kind == "skill" and str(pending_skill.get("effect", "")) == "revive"
	if int(party_units[i]["hp"]) <= 0 and not is_revive:
		return
	if int(party_units[i]["hp"]) > 0 and is_revive:
		return
	_execute_current([party_units[i]])

func _alive_enemies() -> Array:
	var out: Array = []
	for e in enemy_units:
		if int(e["hp"]) > 0:
			out.append(e)
	return out

func _alive_party() -> Array:
	var out: Array = []
	for u in party_units:
		if int(u["hp"]) > 0:
			out.append(u)
	return out

func _execute_current(targets: Array) -> void:
	menu_open = false
	_clear_panels()
	var actor: Dictionary = current_actor
	var kind: String = pending_kind
	if kind == "attack":
		if targets.is_empty():
			targets = _alive_enemies()
		if targets.is_empty():
			_end_actor_turn(actor)
			return
		last_action = {"kind": "attack"}
		busy = true
		await _do_attack(actor, targets[0])
		busy = false
	elif kind == "skill":
		var a: Dictionary = pending_skill
		var cost: int = int(a.get("mp", 0))
		if int(actor["mp"]) < cost:
			_log("Not enough MP.")
			_end_actor_turn(actor)
			return
		actor["mp"] -= cost
		if str(a.get("target", "")) == "enemies":
			targets = _alive_enemies()
		elif str(a.get("target", "")) == "allies":
			targets = _alive_party()
		busy = true
		await _do_skill(actor, a, targets)
		busy = false
		resonance = mini(100, resonance + 10)
	elif kind == "item":
		var item_id: String = pending_item
		if not GameState.remove_item(item_id, 1):
			_log("No %s left." % item_id)
			_end_actor_turn(actor)
			return
		busy = true
		await _do_item(actor, item_id, targets)
		busy = false
	elif kind == "guard":
		actor["guarding"] = true
		_log("%s guards." % str(actor["name"]))
		await get_tree().create_timer(0.4).timeout
	else:
		# Escape (pending_kind set by _on_escape_cmd with kind "escape"?)
		if kind == "":
			kind = "escape"
		busy = true
		await _do_escape(actor)
		busy = false
		if battle_over:
			return
	pending_kind = ""
	pending_skill = {}
	pending_item = ""
	pending_target_kind = ""
	if not battle_over:
		_end_actor_turn(actor)
		_check_end()

func _damage_multiplier(attacker: Dictionary, target: Dictionary, is_magic: bool, skill_id: String) -> float:
	var mult: float = 1.0
	if int(target["statuses"].get("vulnerable", 0)) > 0:
		mult *= 1.25
	if bool(target["is_enemy"]):
		var weak: String = str(target.get("weak", ""))
		var resist: String = str(target.get("resist", ""))
		if skill_id == "overcharge" and weak == "fire":
			mult *= 1.5
		if skill_id in ["stun_bomb", "overcharge"] and weak == "lightning":
			mult *= 1.5
		if skill_id == "couriers_dash" and weak == "bell":
			mult *= 1.5
		if not is_magic and resist == "physical":
			mult *= 0.5
	if bool(target["guarding"]):
		mult *= 0.5
	return mult

func _deal_damage(source: Dictionary, target: Dictionary, amount: int, is_magic: bool, skill_id: String = "") -> int:
	var mult: float = _damage_multiplier(source, target, is_magic, skill_id)
	var final_amt: int = int(float(amount) * mult)
	var absorbed: int = mini(int(target["barrier"]), final_amt)
	target["barrier"] = int(target["barrier"]) - absorbed
	final_amt -= absorbed
	target["hp"] = maxi(0, int(target["hp"]) - final_amt)
	AudioMgr.play_sfx("hit")
	if bool(target["counter"]) and not is_magic and int(target["hp"]) > 0:
		target["counter"] = false
		var back: int = BattleSim.calc_damage(float(target["atk"]), float(source["def"]), 0.8)
		source["hp"] = maxi(0, int(source["hp"]) - back)
		_log("%s counters for %d!" % [str(target["name"]), back])
	_refresh_enemy_ui()
	_refresh_party_ui()
	return final_amt

func _do_attack(actor: Dictionary, target: Dictionary) -> void:
	if int(actor["statuses"].get("blind", 0)) > 0 and rng.randf() < 0.25:
		_log("%s misses (blinded)." % str(actor["name"]))
		await get_tree().create_timer(0.4).timeout
		return
	var crit: bool = rng.randf() < 0.1
	var dmg: int = BattleSim.calc_damage(float(actor["atk"]), float(target["def"]), 1.0, crit)
	var dealt: int = _deal_damage(actor, target, dmg, false)
	_log("%s attacks %s for %d%s." % [str(actor["name"]), str(target["name"]), dealt, " CRITICAL!" if crit else ""])
	resonance = mini(100, resonance + 5)
	await get_tree().create_timer(0.5).timeout

func _heal_amount(actor: Dictionary, power: float) -> int:
	var amount: int = BattleSim.calc_heal(float(actor["mag"]), power)
	if "gentle_hands" in actor.get("passives", []):
		amount = int(float(amount) * 1.2)
	return amount

func _cleanse_unit(t: Dictionary) -> void:
	for k in ["poison", "burn", "slow", "blind", "silence", "sleep"]:
		t["statuses"].erase(k)

func _do_skill(actor: Dictionary, a: Dictionary, targets: Array) -> void:
	var effect: String = str(a.get("effect", "damage"))
	var power: float = float(a.get("power", 1.0))
	var aid: String = str(a.get("id", ""))
	if targets.is_empty():
		return
	match effect:
		"heal":
			for t in targets:
				if int(t["hp"]) <= 0:
					continue
				t["hp"] = mini(int(t["max_hp"]), int(t["hp"]) + _heal_amount(actor, power))
				_log("%s heals %s." % [str(actor["name"]), str(t["name"])])
		"heal_cleanse":
			for t in targets:
				if int(t["hp"]) <= 0:
					continue
				t["hp"] = mini(int(t["max_hp"]), int(t["hp"]) + _heal_amount(actor, power))
				_cleanse_unit(t)
				_log("%s triages %s: healed and cleansed." % [str(actor["name"]), str(t["name"])])
		"regen":
			for t in targets:
				if int(t["hp"]) <= 0:
					continue
				t["statuses"]["regen"] = 3
				_log("%s regenerates." % str(t["name"]))
		"heal_all_cleanse":
			for t in _alive_party():
				t["hp"] = mini(int(t["max_hp"]), int(t["hp"]) + _heal_amount(actor, power))
				_cleanse_unit(t)
			_log("Sanctuary heals and cleanses the party.")
		"revive":
			for t in targets:
				if int(t["hp"]) > 0:
					continue
				t["hp"] = int(t["max_hp"]) / 2
				_log("%s is revived!" % str(t["name"]))
		"damage", "damage_stun", "damage_burn", "damage_blind", "damage_haste", "damage_twice":
			var loops: int = 2 if effect == "damage_twice" else 1
			for t in targets:
				for _i in range(loops):
					if int(t["hp"]) <= 0:
						break
					var dmg: int = BattleSim.calc_damage(float(actor["atk"]), float(t["def"]), power)
					var dealt: int = _deal_damage(actor, t, dmg, false, aid)
					_log("%s uses %s on %s for %d." % [str(actor["name"]), str(a.get("name", "")), str(t["name"]), dealt])
					if effect == "damage_stun" and rng.randf() < 0.4 and str(t.get("role", "")) != "boss":
						t["statuses"]["stun"] = 1
						_log("%s is stunned!" % str(t["name"]))
					if effect == "damage_burn" and rng.randf() < 0.4:
						t["statuses"]["burn"] = 3
					if effect == "damage_blind" and rng.randf() < 0.4:
						t["statuses"]["blind"] = 2
					if effect == "damage_haste":
						actor["statuses"]["haste"] = 3
		"damage_all":
			for t in targets:
				var dmg: int = BattleSim.calc_damage(float(actor["mag"]), float(t["def"]), power)
				var dealt: int = _deal_damage(actor, t, dmg, true, aid)
				_log("%s hits %s for %d." % [str(a.get("name", "")), str(t["name"]), dealt])
		"barrier_heal":
			for t in targets:
				t["barrier"] = int(t["barrier"]) + 40
				t["hp"] = mini(int(t["max_hp"]), int(t["hp"]) + 30)
				_log("%s gains a barrier and heals." % str(t["name"]))
		"barrier_guard":
			actor["guarding"] = true
			actor["barrier"] = int(actor["barrier"]) + 40
			_log("%s raises a shield wall." % str(actor["name"]))
		"barrier_all":
			for t in _alive_party():
				t["barrier"] = int(t["barrier"]) + 30
			_log("The party gains barriers.")
		"counter":
			actor["guarding"] = true
			actor["counter"] = true
			_log("%s takes a counter stance." % str(actor["name"]))
		"taunt":
			taunt_target = str(actor["id"])
			taunt_turns = 3
			_log("%s taunts the enemy!" % str(actor["name"]))
		"slow":
			for t in targets:
				t["statuses"]["slow"] = 3
				_log("%s is slowed." % str(t["name"]))
		"vulnerable":
			for t in targets:
				t["statuses"]["vulnerable"] = 3
				_log("%s is marked vulnerable." % str(t["name"]))
		"heal_mp":
			actor["hp"] = mini(int(actor["max_hp"]), int(actor["hp"]) + 40)
			actor["mp"] = mini(int(actor["max_mp"]), int(actor["mp"]) + 15)
			_log("%s catches a second wind." % str(actor["name"]))
		"haste_all":
			for t in _alive_party():
				t["statuses"]["haste"] = 3
			_log("The party is hastened.")
		"regen_barrier":
			actor["statuses"]["regen"] = 3
			actor["barrier"] = int(actor["barrier"]) + 30
			_log("%s stands firm." % str(actor["name"]))
		"cleanse_all":
			for t in _alive_party():
				for k in ["poison", "burn", "slow", "blind", "silence", "sleep"]:
					t["statuses"].erase(k)
			_log("Debuffs are cleansed.")
		_:
			_log("%s uses %s." % [str(actor["name"]), str(a.get("name", ""))])
	AudioMgr.play_sfx("hit")
	_refresh_enemy_ui()
	_refresh_party_ui()
	await get_tree().create_timer(0.5).timeout

func _do_item(actor: Dictionary, item_id: String, targets: Array) -> void:
	var it: Dictionary = Content.items.get(item_id, {})
	var kind: String = str(it.get("kind", ""))
	if kind == "escape":
		await _do_escape(actor)
		return
	if targets.is_empty():
		return
	var t: Dictionary = targets[0]
	match kind:
		"heal":
			t["hp"] = mini(int(t["max_hp"]), int(t["hp"]) + int(it.get("power", 0)))
		"mp":
			t["mp"] = mini(int(t["max_mp"]), int(t["mp"]) + int(it.get("power", 0)))
		"cleanse":
			for k in ["poison", "burn", "slow", "blind", "silence", "sleep"]:
				t["statuses"].erase(k)
	_log("%s uses %s on %s." % [str(actor["name"]), str(it.get("name", item_id)), str(t["name"])])
	AudioMgr.play_sfx("heal")
	_refresh_party_ui()
	await get_tree().create_timer(0.4).timeout

func _do_escape(actor: Dictionary) -> void:
	if bool(encounter.get("is_boss", false)):
		_log("You cannot escape a boss battle.")
		await get_tree().create_timer(0.5).timeout
		return
	var party_spd: float = 0.0
	for u in _alive_party():
		party_spd += float(u["spd"])
	party_spd /= maxi(1, _alive_party().size())
	var enemy_spd: float = 0.0
	for e in _alive_enemies():
		enemy_spd += float(e["spd"])
	enemy_spd /= maxi(1, _alive_enemies().size())
	if rng.randf() < BattleSim.escape_chance(party_spd, enemy_spd):
		_log("Escaped!")
		_sync_party_to_state()
		battle_over = true
		await get_tree().create_timer(0.5).timeout
		get_tree().change_scene_to_file("res://scenes/world.tscn")
	else:
		_log("Could not escape!")
		await get_tree().create_timer(0.5).timeout

func _on_team_beacon() -> void:
	if resonance < 50:
		return
	resonance -= 50
	menu_open = false
	_clear_panels()
	busy = true
	for t in _alive_enemies():
		var dmg: int = BattleSim.calc_damage(20.0, float(t["def"]), 1.4)
		var dealt: int = _deal_damage(current_actor, t, dmg, true, "couriers_dash")
		t["statuses"]["vulnerable"] = 3
		_log("Resonant Beacon hits %s for %d and marks it." % [str(t["name"]), dealt])
	await get_tree().create_timer(0.5).timeout
	busy = false
	_end_actor_turn(current_actor)
	_check_end()

func _on_team_chorus() -> void:
	if resonance < 50:
		return
	resonance -= 50
	menu_open = false
	_clear_panels()
	busy = true
	for t in _alive_party():
		t["barrier"] = int(t["barrier"]) + 30
		t["hp"] = mini(int(t["max_hp"]), int(t["hp"]) + 30)
	_log("Iron Chorus shields and heals the party.")
	await get_tree().create_timer(0.5).timeout
	busy = false
	_end_actor_turn(current_actor)
	_check_end()

func _auto_party_turn(actor: Dictionary) -> void:
	var targets: Array = _alive_enemies()
	if targets.is_empty():
		return
	await _do_attack(actor, targets[rng.randi() % targets.size()])
	_end_actor_turn(actor)
	_check_end()

func _enemy_turn(actor: Dictionary) -> void:
	actor["actions"] = int(actor["actions"]) + 1
	if str(actor.get("role", "")) == "boss" and int(actor["hp"]) <= int(actor["max_hp"]) / 2 and not bool(actor["phase2"]):
		actor["phase2"] = true
		actor["spd"] = int(actor["spd"]) + 4
		_log("WARNING: The Extraction Warden overcharges! Its bell hums a second, harsher note.")
		await get_tree().create_timer(0.6).timeout
	var targets: Array = _alive_party()
	if targets.is_empty():
		return
	var target: Dictionary = targets[0]
	if taunt_target != "":
		for u in targets:
			if str(u["id"]) == taunt_target:
				target = u
	else:
		# Lowest HP first, unless the healer role needs to heal.
		target = targets[0]
		for u in targets:
			if int(u["hp"]) < int(target["hp"]):
				target = u
	if str(actor.get("role", "")) == "healer":
		var hurt: Dictionary = {}
		for e in enemy_units:
			if int(e["hp"]) > 0 and int(e["hp"]) < int(e["max_hp"]) * 0.6:
				hurt = e
				break
		if not hurt.is_empty():
			hurt["hp"] = mini(int(hurt["max_hp"]), int(hurt["hp"]) + 30)
			_log("%s mends %s." % [str(actor["name"]), str(hurt["name"])])
			await get_tree().create_timer(0.5).timeout
			_end_actor_turn(actor)
			_check_end()
			return
	if str(actor.get("role", "")) == "boss" and bool(actor["phase2"]) and int(actor["actions"]) % 3 == 0:
		for u in _alive_party():
			var dmg: int = BattleSim.calc_damage(float(actor["mag"]), float(u["def"]), 1.2)
			var dealt: int = _deal_damage(actor, u, dmg, true)
			if rng.randf() < 0.3 and "steady_pulse" not in u.get("passives", []):
				u["statuses"]["silence"] = 2
			_log("Memory Drain hits %s for %d." % [str(u["name"]), dealt])
		await get_tree().create_timer(0.6).timeout
	else:
		var dmg: int = BattleSim.calc_damage(float(actor["atk"]), float(target["def"]), 1.0)
		var dealt: int = _deal_damage(actor, target, dmg, false)
		_log("%s attacks %s for %d." % [str(actor["name"]), str(target["name"]), dealt])
		if str(actor.get("role", "")) == "disruptor" and rng.randf() < 0.3:
			target["statuses"]["slow"] = 2
			_log("%s is slowed." % str(target["name"]))
		await get_tree().create_timer(0.5).timeout
	_end_actor_turn(actor)
	_check_end()

func _sync_party_to_state() -> void:
	for u in party_units:
		var cid: String = str(u["id"])
		GameState.data["chars"][cid]["hp"] = int(u["hp"])
		GameState.data["chars"][cid]["mp"] = int(u["mp"])

func _check_end() -> void:
	if battle_over:
		return
	if _alive_enemies().is_empty():
		_on_victory()
	elif _alive_party().is_empty():
		_on_defeat()

func _on_victory() -> void:
	if rewards_given:
		return
	rewards_given = true
	battle_over = true
	_sync_party_to_state()
	var xp: int = int(encounter.get("xp", 0))
	var jp: int = int(encounter.get("jp", 0))
	var gold: int = int(encounter.get("gold", 0))
	var lines: Array = GameState.gain_rewards(xp, jp, gold)
	var key: String = str(GameState.data.get("pending_enemy_key", ""))
	if key != "":
		GameState.set_flag(key)
	if bool(encounter.get("is_boss", false)):
		GameState.set_flag("boss_defeated")
	AudioMgr.play_sfx("heal")
	result_label.text = "Victory! +%d XP, +%d JP, +%d gold.\n%s" % [xp, jp, gold, "\n".join(lines)]
	victory_panel.visible = true
	SaveMgr.autosave()

func _on_defeat() -> void:
	battle_over = true
	defeat_panel.visible = true

func _on_victory_continue() -> void:
	get_tree().change_scene_to_file("res://scenes/world.tscn")

func _on_retry() -> void:
	# Fresh battle from pre-battle state (party HP/MP were not synced).
	get_tree().change_scene_to_file("res://scenes/battle.tscn")

func _on_to_title() -> void:
	get_tree().change_scene_to_file("res://scenes/title.tscn")
