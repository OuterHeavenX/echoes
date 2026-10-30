extends CanvasLayer
## Main menu: Party / Equipment / Jobs / Inventory / Journal / Settings / Save.
## Every screen is button-driven so keyboard, gamepad focus, and touch
## all work; there is no hover-dependent control.

signal menu_closed

var _panel: PanelContainer
var _content: VBoxContainer
var _tab: String = "party"
var _equip_member: String = "rowan"
var _jobs_member: String = "rowan"
var _job_costs: Dictionary = {}

func _ready() -> void:
	layer = 12
	visible = false
	_panel = PanelContainer.new()
	_panel.set_anchors_preset(Control.PRESET_CENTER)
	_panel.size = Vector2(700, 460)
	_panel.position = Vector2(130, 40)
	add_child(_panel)
	var col: VBoxContainer = VBoxContainer.new()
	_panel.add_child(col)
	var tabs: HBoxContainer = HBoxContainer.new()
	col.add_child(tabs)
	for tab in ["party", "equipment", "jobs", "inventory", "journal", "settings", "save"]:
		var b: Button = Button.new()
		b.text = tab.capitalize()
		b.custom_minimum_size = Vector2(90, 40)
		b.pressed.connect(_set_tab.bind(tab))
		tabs.add_child(b)
	_content = VBoxContainer.new()
	col.add_child(_content)
	var close: Button = Button.new()
	close.text = "Close Menu"
	close.custom_minimum_size = Vector2(200, 44)
	close.pressed.connect(close_menu)
	col.add_child(close)

func open_menu() -> void:
	visible = true
	_refresh()

func close_menu() -> void:
	visible = false
	menu_closed.emit()

func _set_tab(tab: String) -> void:
	_tab = tab
	_refresh()

func _clear() -> void:
	for child in _content.get_children():
		child.queue_free()

func _label(text: String) -> Label:
	var l: Label = Label.new()
	l.text = text
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_content.add_child(l)
	return l

func _button(text: String, callable: Callable) -> Button:
	var b: Button = Button.new()
	b.text = text
	b.custom_minimum_size = Vector2(200, 40)
	b.pressed.connect(callable)
	_content.add_child(b)
	return b

func _refresh() -> void:
	_clear()
	match _tab:
		"party": _tab_party()
		"equipment": _tab_equipment()
		"jobs": _tab_jobs()
		"inventory": _tab_inventory()
		"journal": _tab_journal()
		"settings": _tab_settings()
		"save": _tab_save()

func _tab_party() -> void:
	for cid in GameState.data["party"]:
		var st: Dictionary = GameState.stats_for(cid)
		var nm: String = str(Content.characters.get(cid, {}).get("name", cid))
		_label("%s — Lv.%d %s | HP %d/%d MP %d/%d | ATK %d DEF %d SPD %d | XP %d/%d JP %d" % [nm, st["level"], str(Content.jobs.get(st["job"], {}).get("name", st["job"])), st["hp"], st["max_hp"], st["mp"], st["max_mp"], st["atk"], st["def"], st["spd"], st["xp"], st["xp_next"], st["jp"]])

func _tab_equipment() -> void:
	_label("Member (tap to select):")
	for cid in GameState.data["party"]:
		_button(str(Content.characters.get(cid, {}).get("name", cid)), _select_equip.bind(cid))
	var st: Dictionary = GameState.stats_for(_equip_member)
	_label("Equipping: %s — weapon: %s, armor: %s, accessory: %s" % [str(Content.characters.get(_equip_member, {}).get("name", "")), str(GameState.data["chars"][_equip_member].get("weapon", "")), str(GameState.data["chars"][_equip_member].get("armor", "")), str(GameState.data["chars"][_equip_member].get("accessory", ""))])
	for item_id in Content.items.keys():
		var it: Dictionary = Content.items[item_id]
		if str(it.get("kind", "")) not in ["weapon", "armor", "accessory"]:
			continue
		if GameState.item_count(item_id) <= 0 and str(GameState.data["chars"][_equip_member].get(str(it.get("kind", "")), "")) != item_id:
			continue
		_button("Equip %s" % str(it.get("name", item_id)), _equip.bind(_equip_member, item_id, str(it.get("kind", ""))))

func _select_equip(cid: String) -> void:
	_equip_member = cid
	_refresh()

func _equip(cid: String, item_id: String, kind: String) -> void:
	GameState.data["chars"][cid][kind] = item_id
	_refresh()

func _tab_jobs() -> void:
	_label("Member (tap to select):")
	for cid in GameState.data["party"]:
		_button(str(Content.characters.get(cid, {}).get("name", cid)), _select_jobs.bind(cid))
	var c: Dictionary = GameState.data["chars"][_jobs_member]
	var job_id: String = str(c.get("job", ""))
	_label("Job: %s — JP: %d" % [str(Content.jobs.get(job_id, {}).get("name", job_id)), int(c.get("jp", 0))])
	var abilities: Array = Content.job_abilities(job_id)
	for i in range(abilities.size()):
		var a: Dictionary = abilities[i]
		var aid: String = str(a.get("id", ""))
		var owned: bool = aid in c.get("abilities", [])
		var cost: int = 0 if i == 0 else 20 + (i - 1) * 20
		if owned:
			_label("✓ %s — %s" % [str(a.get("name", aid)), str(a.get("desc", ""))])
		else:
			_button("Unlock %s (%d JP) — %s" % [str(a.get("name", aid)), cost, str(a.get("desc", ""))], _unlock.bind(_jobs_member, aid, cost))
	_label("Passives (loadout: all unlocked passives apply):")
	var passives: Array = Content.jobs.get(job_id, {}).get("passives", [])
	for i in range(passives.size()):
		var p: Dictionary = passives[i]
		var pid: String = str(p.get("id", ""))
		var owned_p: bool = pid in c.get("passives", [])
		var pcost: int = 30 + i * 20
		if owned_p:
			_label("✓ %s — %s" % [str(p.get("name", pid)), str(p.get("desc", ""))])
		else:
			_button("Unlock passive %s (%d JP) — %s" % [str(p.get("name", pid)), pcost, str(p.get("desc", ""))], _unlock_passive.bind(_jobs_member, pid, pcost))

func _select_jobs(cid: String) -> void:
	_jobs_member = cid
	_refresh()

func _unlock(cid: String, aid: String, cost: int) -> void:
	var c: Dictionary = GameState.data["chars"][cid]
	if int(c.get("jp", 0)) < cost:
		_label("Not enough JP.")
		return
	c["jp"] = int(c["jp"]) - cost
	c["abilities"].append(aid)
	_refresh()

func _unlock_passive(cid: String, pid: String, cost: int) -> void:
	var c: Dictionary = GameState.data["chars"][cid]
	if int(c.get("jp", 0)) < cost:
		_label("Not enough JP.")
		return
	if "passives" not in c:
		c["passives"] = []
	c["jp"] = int(c["jp"]) - cost
	c["passives"].append(pid)
	_refresh()

func _tab_inventory() -> void:
	_label("Gold: %d" % int(GameState.data.get("gold", 0)))
	for item_id in GameState.data["inventory"].keys():
		var count: int = int(GameState.data["inventory"][item_id])
		if count <= 0:
			continue
		var it: Dictionary = Content.items.get(item_id, {})
		_label("%s x%d — %s" % [str(it.get("name", item_id)), count, str(it.get("desc", ""))])
		if str(it.get("kind", "")) in ["heal", "mp", "cleanse"]:
			_button("Use %s on first hurt ally" % str(it.get("name", item_id)), _use_item.bind(item_id))

func _use_item(item_id: String) -> void:
	var target: String = ""
	for cid in GameState.data["party"]:
		var st: Dictionary = GameState.stats_for(cid)
		if st["hp"] < st["max_hp"] or st["mp"] < st["max_mp"]:
			target = cid
			break
	if target == "":
		_label("Nobody needs it right now.")
		return
	if not GameState.remove_item(item_id, 1):
		return
	var it: Dictionary = Content.items[item_id]
	var c: Dictionary = GameState.data["chars"][target]
	var st: Dictionary = GameState.stats_for(target)
	match str(it.get("kind", "")):
		"heal":
			c["hp"] = mini(st["max_hp"], st["hp"] + int(it.get("power", 0)))
		"mp":
			c["mp"] = mini(st["max_mp"], st["mp"] + int(it.get("power", 0)))
		"cleanse":
			c["hp"] = st["hp"]
	AudioMgr.play_sfx("heal")
	_refresh()

func _tab_journal() -> void:
	for qid in GameState.data["quests"].keys():
		var q: Dictionary = Content.quests.get(qid, {})
		var stage: int = int(GameState.data["quests"][qid])
		var stages: Array = q.get("stages", [])
		var stage_text: String = stages[stage] if stage >= 0 and stage < stages.size() else "Complete"
		_label("[%s] %s — %s" % [str(q.get("kind", "")), str(q.get("name", qid)), stage_text])

func _tab_settings() -> void:
	_label("Battle mode: %s" % str(GameState.setting("battle_mode")))
	_button("Toggle Wait / Active", _toggle_battle_mode)
	_label("Battle speed: %.1fx" % float(GameState.setting("battle_speed")))
	_button("Cycle battle speed (0.5x / 1x / 1.5x / 2x)", _cycle_battle_speed)
	_label("Music volume: %.1f  |  SFX volume: %.1f" % [float(GameState.setting("music_volume")), float(GameState.setting("sfx_volume"))])
	_button("Music volume up / down (toggles 0.8 / 0.3)", _toggle_music_vol)
	_button("SFX volume up / down (toggles 0.8 / 0.3)", _toggle_sfx_vol)
	_label("Reduce motion: %s" % ("on" if bool(GameState.setting("reduce_motion")) else "off"))
	_button("Toggle reduce motion", _toggle_reduce_motion)
	_label("Camera shake: %s" % ("on" if bool(GameState.setting("camera_shake")) else "off"))
	_button("Toggle camera shake", _toggle_camera_shake)
	_label("UI scale: %.2fx" % float(GameState.setting("ui_scale")))
	_button("Cycle UI scale (1.0 / 1.25 / 1.5)", _cycle_ui_scale)
	_label("Quest markers: %s" % ("on" if bool(GameState.setting("quest_markers")) else "off"))
	_button("Toggle quest markers", _toggle_markers)

func _toggle_battle_mode() -> void:
	GameState.data["settings"]["battle_mode"] = "active" if str(GameState.setting("battle_mode")) == "wait" else "wait"
	_refresh()

func _cycle_battle_speed() -> void:
	var speeds: Array = [0.5, 1.0, 1.5, 2.0]
	var cur: float = float(GameState.setting("battle_speed"))
	var idx: int = speeds.find(cur)
	GameState.data["settings"]["battle_speed"] = speeds[(idx + 1) % speeds.size()] if idx >= 0 else 1.0
	_refresh()

func _toggle_camera_shake() -> void:
	GameState.data["settings"]["camera_shake"] = not bool(GameState.setting("camera_shake"))
	_refresh()

func _cycle_ui_scale() -> void:
	var scales: Array = [1.0, 1.25, 1.5]
	var cur: float = float(GameState.setting("ui_scale"))
	var idx: int = scales.find(cur)
	var next_scale: float = scales[(idx + 1) % scales.size()] if idx >= 0 else 1.0
	GameState.data["settings"]["ui_scale"] = next_scale
	get_tree().root.content_scale_factor = next_scale
	_refresh()

func _toggle_music_vol() -> void:
	GameState.data["settings"]["music_volume"] = 0.3 if float(GameState.setting("music_volume")) > 0.5 else 0.8
	AudioMgr.apply_volumes()
	_refresh()

func _toggle_sfx_vol() -> void:
	GameState.data["settings"]["sfx_volume"] = 0.3 if float(GameState.setting("sfx_volume")) > 0.5 else 0.8
	AudioMgr.apply_volumes()
	_refresh()

func _toggle_reduce_motion() -> void:
	GameState.data["settings"]["reduce_motion"] = not bool(GameState.setting("reduce_motion"))
	_refresh()

func _toggle_markers() -> void:
	GameState.data["settings"]["quest_markers"] = not bool(GameState.setting("quest_markers"))
	_refresh()

func _tab_save() -> void:
	for slot in [1, 2, 3]:
		var meta: Dictionary = SaveMgr.slot_meta(slot)
		var info: String = "empty" if meta.is_empty() else "%s | %s | playtime %.0f min" % [str(meta.get("chapter", "")), str(meta.get("location", "")), float(meta.get("playtime", 0.0)) / 60.0]
		_label("Slot %d: %s" % [slot, info])
		_button("Save to slot %d" % slot, _save_slot.bind(slot))
		if SaveMgr.slot_exists(slot):
			_button("Load slot %d" % slot, _load_slot.bind(slot))
	_button("Copy save export (slot 1) to clipboard", _export_slot)

func _save_slot(slot: int) -> void:
	if SaveMgr.save_game(slot):
		_label("Saved to slot %d." % slot)
	else:
		_label("Save failed.")
	_refresh()

func _load_slot(slot: int) -> void:
	if SaveMgr.load_game(slot):
		get_tree().change_scene_to_file("res://scenes/world.tscn")
	else:
		_label("Load failed — that save may be corrupted.")

func _export_slot() -> void:
	var text: String = SaveMgr.export_json(1)
	if text == "":
		_label("Slot 1 is empty; save there first.")
		return
	DisplayServer.clipboard_set(text)
	_label("Save JSON copied to clipboard. Paste it into a file to keep it; import is on the title screen.")
