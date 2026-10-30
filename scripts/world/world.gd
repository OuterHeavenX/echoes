extends Node3D
## Bellweather + station undercroft, in one 3D scene.
## Characters are Sprite3D billboards over low-poly coloured geometry
## (Compatibility renderer, orthographic camera). Movement, collision,
## interaction, visible enemies, and the Chapter 1 quest chain live here.
## Battle, menu, shop, and dialogue are separate UI/scene systems.

@onready var dialogue_ui: CanvasLayer = $DialogueUI
@onready var menu_ui: CanvasLayer = $MenuUI
@onready var shop_ui: CanvasLayer = $ShopUI

var camera: Camera3D
var player_sprite: Sprite3D
var player_pos: Vector2 = Vector2(0, 6)
var move_dir: Vector2 = Vector2.ZERO
var touch_move: Vector2 = Vector2.ZERO
var interactables: Array = []
var colliders: Array = []
var enemies: Array = []
var followers: Array = []
var markers: Array = []
var hud_labels: Array = []
var prompt_label: Label
var nearest: Dictionary = {}
var pending_shop: bool = false
var time_accum: float = 0.0
var boss_return_pending: bool = false

func _ready() -> void:
	get_tree().root.content_scale_factor = float(GameState.setting("ui_scale"))
	var map_id: String = str(GameState.data.get("map", "bellweather"))
	var saved_pos: Array = GameState.data.get("player_pos", [0.0, 6.0])
	player_pos = Vector2(float(saved_pos[0]), float(saved_pos[1]))
	AudioMgr.play_music("town" if map_id == "bellweather" else "dungeon")
	_build_camera()
	_build_map(map_id)
	_spawn_player()
	_build_touch_ui()
	dialogue_ui.dialogue_finished.connect(_on_dialogue_finished)
	if map_id == "undercroft":
		GameState.quest_start("side_ledger")
	# Post-boss chain: battle returns here, then the victory scenes play.
	if GameState.has_flag("boss_defeated") and not GameState.has_flag("chapter1_end_shown"):
		boss_return_pending = true
		call_deferred("_post_boss")

func _post_boss() -> void:
	dialogue_ui.start("boss_victory")

func _build_camera() -> void:
	camera = Camera3D.new()
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.size = 13.0
	camera.position = Vector3(player_pos.x, 16.0, player_pos.y + 11.0)
	add_child(camera)
	camera.look_at(Vector3(player_pos.x, 0, player_pos.y), Vector3.UP)

func _box(x: float, z: float, w: float, h: float, d: float, color: Color, emissive: Color = Color(0, 0, 0)) -> void:
	var m: MeshInstance3D = MeshInstance3D.new()
	var box: BoxMesh = BoxMesh.new()
	box.size = Vector3(w, h, d)
	m.mesh = box
	var mat: StandardMaterial3D = StandardMaterial3D.new()
	mat.albedo_color = color
	if emissive != Color(0, 0, 0):
		mat.emission_enabled = true
		mat.emission = emissive
	m.material_override = mat
	m.position = Vector3(x, h / 2.0, z)
	add_child(m)

func _sprite_at(x: float, z: float, sprite_id: String, scale_v: float = 3.0) -> Sprite3D:
	var s: Sprite3D = Sprite3D.new()
	var path: String = "res://assets/sprites/%s.png" % sprite_id
	if ResourceLoader.exists(path):
		s.texture = load(path)
	s.position = Vector3(x, 1.1, z)
	s.scale = Vector3(scale_v, scale_v, scale_v)
	s.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	add_child(s)
	return s

func _build_map(map_id: String) -> void:
	interactables.clear()
	colliders.clear()
	enemies.clear()
	markers.clear()
	if map_id == "bellweather":
		_box(0, 0, 46, 0.4, 32, Color(0.42, 0.38, 0.33))
		_box(0, 3, 46, 0.2, 4, Color(0.15, 0.35, 0.55))
		for bx in [-12.0, 0.0, 12.0]:
			_box(bx, 3, 4, 0.5, 5, Color(0.55, 0.45, 0.30))
		_box(-16, 10, 7, 4, 6, Color(0.55, 0.42, 0.30))
		_box(-16, 10, 7, 0.6, 6, Color(0.35, 0.22, 0.15))
		_box(16, 10, 7, 4, 6, Color(0.60, 0.50, 0.38))
		_box(0, -11, 11, 6, 6, Color(0.45, 0.42, 0.50))
		_box(0, -11, 11, 0.6, 6, Color(0.25, 0.22, 0.30))
		colliders.append({"x": -16.0, "z": 10.0, "w": 7.0, "d": 6.0})
		colliders.append({"x": 16.0, "z": 10.0, "w": 7.0, "d": 6.0})
		colliders.append({"x": 0.0, "z": -11.0, "w": 11.0, "d": 6.0})
		_add_npc(-8, 10, "npc_tomas", "old_tomas", "Old Tomas")
		_add_npc(-12, 7, "npc_shop", "shopkeeper", "Shopkeeper")
		_add_npc(12, 7, "npc_inn", "innkeeper", "Innkeeper Dara")
		_add_npc(2, 8, "mira", "festival_greeting", "Mira")
		# Sera arrives after the incident, tending the shaken street.
		# She is not missable: she stays here until recruited, and she
		# never appears as an NPC once she is in the party.
		if GameState.has_flag("incident_done") and "sera" not in GameState.data["party"]:
			_add_npc(8, 12, "sera", "sera_recruit", "Sera Voss")
		_add_door(0, -7.5, "station")
		if not GameState.has_flag("lantern_1"):
			_add_lantern(-18, 5, "lantern_1")
		if not GameState.has_flag("lantern_2"):
			_add_lantern(18, -2, "lantern_2")
		if not GameState.has_flag("lantern_3"):
			_add_lantern(-4, -4, "lantern_3")
	else:
		_box(0, 0, 40, 0.4, 28, Color(0.20, 0.20, 0.26))
		for px in [-14.0, -7.0, 0.0, 7.0, 14.0]:
			_box(px, -6, 2, 6, 2, Color(0.30, 0.30, 0.38))
			_box(px, 6, 2, 6, 2, Color(0.30, 0.30, 0.38))
		_add_enemy(-10, -8, "undercroft_a", "wisp", "Memory Wisp")
		_add_enemy(10, -8, "undercroft_b", "sentry", "Authority Sentry")
		_add_enemy(0, 8, "undercroft_c", "rat", "Canal Rat")
		_add_chest(-14, 10, "chest_ledger", "Ledger chest")
		_add_chest(14, 10, "chest_ledger2", "Second ledger chest")
		_add_chest(0, -11, "chest_treasure", "Supply chest")
		_add_boss(0, -12, "warden", "Extraction Warden")
		_add_door(0, 13.5, "exit")

func _add_npc(x: float, z: float, sprite_id: String, dialogue_id: String, label_text: String) -> void:
	_sprite_at(x, z, sprite_id)
	interactables.append({"pos": Vector2(x, z), "kind": "npc", "dialogue": dialogue_id, "label": label_text})

func _add_door(x: float, z: float, door_id: String) -> void:
	_box(x, z, 3, 0.6, 1, Color(0.90, 0.75, 0.30), Color(0.90, 0.75, 0.30))
	interactables.append({"pos": Vector2(x, z), "kind": "door", "id": door_id, "label": "Station door" if door_id == "station" else "Stairs up"})

func _add_lantern(x: float, z: float, lantern_id: String) -> void:
	_box(x, z, 0.7, 0.7, 0.7, Color(0.95, 0.80, 0.30), Color(0.95, 0.80, 0.30))
	interactables.append({"pos": Vector2(x, z), "kind": "lantern", "id": lantern_id, "label": "Lost lantern"})

func _add_chest(x: float, z: float, chest_id: String, label_text: String) -> void:
	_box(x, z, 1.6, 1.0, 1.2, Color(0.50, 0.35, 0.20))
	interactables.append({"pos": Vector2(x, z), "kind": "chest", "id": chest_id, "label": label_text})

func _add_enemy(x: float, z: float, encounter_id: String, sprite_id: String, label_text: String) -> void:
	var key: String = "enemy_defeated_%s_%d_%d" % [encounter_id, int(x), int(z)]
	if GameState.has_flag(key):
		return
	var s: Sprite3D = _sprite_at(x, z, sprite_id, 2.6)
	enemies.append({"pos": Vector2(x, z), "encounter": encounter_id, "sprite": s, "key": key, "label": label_text, "t": randf() * 10.0})

func _add_boss(x: float, z: float, sprite_id: String, label_text: String) -> void:
	if GameState.has_flag("boss_defeated"):
		return
	_sprite_at(x, z, sprite_id, 4.0)
	interactables.append({"pos": Vector2(x, z), "kind": "boss", "label": label_text})

func _spawn_player() -> void:
	var leader: String = str(GameState.data["party"][0]) if GameState.data["party"].size() > 0 else "rowan"
	var sprite_id: String = str(Content.characters.get(leader, {}).get("sprite", "rowan"))
	player_sprite = _sprite_at(player_pos.x, player_pos.y, sprite_id, 3.0)
	followers.clear()
	var idx: int = 0
	for cid in GameState.data["party"]:
		if idx == 0:
			idx += 1
			continue
		var fs: Sprite3D = _sprite_at(player_pos.x, player_pos.y + 1.5 + float(idx), str(Content.characters.get(cid, {}).get("sprite", "rowan")), 3.0)
		followers.append(fs)
		idx += 1

func _build_touch_ui() -> void:
	var layer: CanvasLayer = CanvasLayer.new()
	layer.layer = 5
	add_child(layer)
	var hud_box: VBoxContainer = VBoxContainer.new()
	hud_box.position = Vector2(12, 12)
	layer.add_child(hud_box)
	for cid in GameState.data["party"]:
		var l: Label = Label.new()
		l.add_theme_font_size_override("font_size", 16)
		hud_box.add_child(l)
		hud_labels.append(l)
	prompt_label = Label.new()
	prompt_label.position = Vector2(360, 480)
	prompt_label.add_theme_font_size_override("font_size", 18)
	layer.add_child(prompt_label)
	# Touch D-pad (bottom-left) + Interact/Menu (bottom-right). Buttons
	# use button_down/up so holding works; keyboard/gamepad are unaffected.
	var dpad: Dictionary = {"U": Vector2(0, -1), "D": Vector2(0, 1), "L": Vector2(-1, 0), "R": Vector2(1, 0)}
	var positions: Dictionary = {"U": Vector2(90, 400), "D": Vector2(90, 470), "L": Vector2(30, 435), "R": Vector2(150, 435)}
	for key in dpad.keys():
		var b: Button = Button.new()
		b.text = key
		b.position = positions[key]
		b.custom_minimum_size = Vector2(52, 48)
		b.button_down.connect(_touch_dir.bind(dpad[key], true))
		b.button_up.connect(_touch_dir.bind(dpad[key], false))
		layer.add_child(b)
	var interact_btn: Button = Button.new()
	interact_btn.text = "Interact"
	interact_btn.position = Vector2(780, 435)
	interact_btn.custom_minimum_size = Vector2(120, 48)
	interact_btn.pressed.connect(_activate_nearest)
	layer.add_child(interact_btn)
	var menu_btn: Button = Button.new()
	menu_btn.text = "Menu"
	menu_btn.position = Vector2(780, 490)
	menu_btn.custom_minimum_size = Vector2(120, 48)
	menu_btn.pressed.connect(_open_menu)
	layer.add_child(menu_btn)

func _touch_dir(vec: Vector2, down: bool) -> void:
	if down:
		touch_move += vec
	else:
		touch_move -= vec
	touch_move.x = clampf(touch_move.x, -1.0, 1.0)
	touch_move.y = clampf(touch_move.y, -1.0, 1.0)

func _ui_open() -> bool:
	return dialogue_ui.visible or menu_ui.visible or shop_ui.visible

func _process(delta: float) -> void:
	if not _ui_open():
		GameState.data["playtime"] = float(GameState.data.get("playtime", 0.0)) + delta
	time_accum += delta
	_update_hud()
	if _ui_open():
		return
	_handle_movement(delta)
	_update_camera(delta)
	_update_nearest()
	_update_enemies(delta)
	if Input.is_action_just_pressed("interact") or Input.is_action_just_pressed("confirm"):
		_activate_nearest()
	if Input.is_action_just_pressed("menu"):
		_open_menu()

func _update_hud() -> void:
	var i: int = 0
	for cid in GameState.data["party"]:
		if i >= hud_labels.size():
			break
		var st: Dictionary = GameState.stats_for(cid)
		var nm: String = str(Content.characters.get(cid, {}).get("name", cid))
		(hud_labels[i] as Label).text = "%s Lv.%d HP %d/%d MP %d/%d" % [nm, st["level"], st["hp"], st["max_hp"], st["mp"], st["max_mp"]]
		i += 1

func _handle_movement(delta: float) -> void:
	var iv: Vector2 = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	if touch_move != Vector2.ZERO:
		iv = touch_move
	if iv.length() > 1.0:
		iv = iv.normalized()
	move_dir = iv
	var speed: float = 6.0
	var next_pos: Vector2 = player_pos + iv * speed * delta
	next_pos = _collide_move(player_pos, next_pos)
	player_pos = next_pos
	player_pos.x = clampf(player_pos.x, -21.0, 21.0)
	player_pos.y = clampf(player_pos.y, -13.5, 14.5)
	player_sprite.position = Vector3(player_pos.x, 1.1 + (0.08 * absf(sin(time_accum * 10.0)) if iv != Vector2.ZERO else 0.0), player_pos.y)
	var fi: int = 1
	for f in followers:
		var target: Vector2 = player_pos - (move_dir * float(fi) * 1.4 if move_dir != Vector2.ZERO else Vector2(0, float(fi) * 1.4))
		(f as Sprite3D).position = Vector3(target.x, 1.1, target.y)
		fi += 1
	GameState.data["player_pos"] = [player_pos.x, player_pos.y]

func _collide_move(from_pos: Vector2, to_pos: Vector2) -> Vector2:
	# Axis-separated slide: canal is blocked except at the three bridges.
	var result: Vector2 = to_pos
	var map_id: String = str(GameState.data.get("map", "bellweather"))
	if map_id == "bellweather":
		if result.y > 1.0 and result.y < 5.0:
			var on_bridge: bool = false
			for bx in [-12.0, 0.0, 12.0]:
				if absf(result.x - bx) < 2.2:
					on_bridge = true
			if not on_bridge:
				result.y = from_pos.y
	for c in colliders:
		var hw: float = float(c["w"]) / 2.0 + 0.5
		var hd: float = float(c["d"]) / 2.0 + 0.5
		if absf(result.x - float(c["x"])) < hw and absf(result.y - float(c["z"])) < hd:
			# Push back on the axis that moved into the rect.
			if absf(to_pos.x - float(c["x"])) >= hw:
				result.x = from_pos.x
			if absf(to_pos.y - float(c["z"])) >= hd:
				result.y = from_pos.y
	return result

func _update_camera(delta: float) -> void:
	var target: Vector3 = Vector3(player_pos.x, 16.0, player_pos.y + 11.0)
	camera.position = camera.position.lerp(target, 1.0 - pow(0.001, delta))

func _update_nearest() -> void:
	nearest = {}
	var best: float = 2.2
	for it in interactables:
		var d: float = player_pos.distance_to(it["pos"])
		if d < best:
			best = d
			nearest = it
	if nearest.is_empty():
		prompt_label.text = ""
	else:
		prompt_label.text = "Interact: %s  (E / tap Interact)" % str(nearest.get("label", ""))

func _update_enemies(delta: float) -> void:
	for e in enemies:
		e["t"] = float(e["t"]) + delta
		var s: Sprite3D = e["sprite"]
		var wob: float = sin(float(e["t"]) * 0.7) * 1.5
		var pos: Vector2 = e["pos"] + Vector2(wob * delta * 2.0, 0)
		# Wander is visual only, clamped to the undercroft floor.
		pos.x = clampf(pos.x, -19.0, 19.0)
		s.position.x = pos.x
		s.position.z = pos.y
		e["pos"] = pos
		if player_pos.distance_to(pos) < 1.3:
			GameState.pending_encounter = str(e["encounter"])
			GameState.data["pending_enemy_key"] = str(e["key"])
			GameState.data["player_pos"] = [player_pos.x, player_pos.y]
			get_tree().change_scene_to_file("res://scenes/battle.tscn")
			return

func _activate_nearest() -> void:
	if nearest.is_empty():
		return
	var kind: String = str(nearest.get("kind", ""))
	match kind:
		"npc":
			var did: String = str(nearest.get("dialogue", ""))
			# Tomas gives the evidence quest stage only once; dialogue
			# itself is repeatable, effects are guarded by quest stage.
			dialogue_ui.start(did)
		"door":
			_on_door(str(nearest.get("id", "")))
		"lantern":
			_on_lantern(str(nearest.get("id", "")))
		"chest":
			_on_chest(str(nearest.get("id", "")))
		"boss":
			dialogue_ui.start("boss_intro")

func _on_door(door_id: String) -> void:
	if door_id == "station":
		if not GameState.has_flag("incident_done"):
			dialogue_ui.start("prologue_incident")
		else:
			_change_map("undercroft", Vector2(0, 12))
	else:
		_change_map("bellweather", Vector2(0, -6))

func _change_map(map_id: String, spawn: Vector2) -> void:
	GameState.data["map"] = map_id
	GameState.data["player_pos"] = [spawn.x, spawn.y]
	SaveMgr.autosave()
	get_tree().change_scene_to_file("res://scenes/world.tscn")

func _on_lantern(lantern_id: String) -> void:
	GameState.set_flag(lantern_id)
	GameState.quest_start("side_lanterns")
	var count: int = 0
	for lid in ["lantern_1", "lantern_2", "lantern_3"]:
		if GameState.has_flag(lid):
			count += 1
	GameState.data["lantern_count"] = count
	if count >= 3 and not GameState.has_flag("lanterns_done"):
		GameState.set_flag("lanterns_done")
		GameState.quest_advance("side_lanterns", 1)
		GameState.data["gold"] = int(GameState.data["gold"]) + 60
		GameState.add_item("potion", 2)
	dialogue_ui.start("lantern_found")
	# Refresh the map so the collected lantern disappears.
	call_deferred("_reload_world")

func _reload_world() -> void:
	# Only reload after the lantern dialogue closes.
	await dialogue_ui.dialogue_finished
	get_tree().change_scene_to_file("res://scenes/world.tscn")

func _on_chest(chest_id: String) -> void:
	if GameState.has_flag("opened_" + chest_id):
		dialogue_ui.start("lantern_found")
		return
	GameState.set_flag("opened_" + chest_id)
	match chest_id:
		"chest_ledger":
			GameState.quest_advance("main_evidence", 2)
			GameState.quest_start("main_rescue")
			dialogue_ui.start("chest_ledger")
		"chest_ledger2":
			dialogue_ui.start("chest_ledger")
		"chest_treasure":
			GameState.data["gold"] = int(GameState.data["gold"]) + 40
			GameState.add_item("potion", 2)
			dialogue_ui.start("lantern_found")

func _open_menu() -> void:
	if _ui_open():
		return
	menu_ui.open_menu()

func _on_dialogue_finished(dialogue_id: String) -> void:
	match dialogue_id:
		"shopkeeper", "innkeeper":
			shop_ui.open_shop()
		"chest_ledger":
			# Second ledger chest rewards on close (the first chest's
			# reward is the main-quest advance, applied on open).
			if GameState.has_flag("opened_chest_ledger2") and not GameState.has_flag("side_ledger_done"):
				GameState.set_flag("side_ledger_done")
				GameState.quest_advance("side_ledger", 1)
				GameState.data["gold"] = int(GameState.data["gold"]) + 80
				GameState.add_item("ether", 1)
		"boss_victory":
			dialogue_ui.start("end_chapter")
		"end_chapter":
			GameState.set_flag("chapter1_end_shown")
			GameState.data["chapter"] = "chapter2"
			SaveMgr.autosave()
			_change_map("bellweather", Vector2(0, -6))
