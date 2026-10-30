extends Control
## Title screen: New Game / Continue / Autosave / Save import.
## Import pastes a save JSON (exported from the in-game menu) — this is
## the manual cross-platform transfer path; there is no cloud save.

var import_edit: TextEdit
var status_label: Label

func _ready() -> void:
	get_tree().root.content_scale_factor = float(GameState.setting("ui_scale"))
	_build()
	AudioMgr.play_music("town")

func _build() -> void:
	var bg: ColorRect = ColorRect.new()
	bg.color = Color(0.08, 0.10, 0.16)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)
	var col: VBoxContainer = VBoxContainer.new()
	col.position = Vector2(280, 60)
	col.custom_minimum_size = Vector2(400, 420)
	add_child(col)
	var title: Label = Label.new()
	title.text = "ECHOES OF\nTHE LAST DAWN"
	title.add_theme_font_size_override("font_size", 44)
	col.add_child(title)
	var sub: Label = Label.new()
	sub.text = "An original JRPG about buried bells and stolen memories.\nVersion 0.3.0-c1 — Chapter 1 vertical slice."
	sub.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	sub.custom_minimum_size = Vector2(400, 60)
	col.add_child(sub)
	_add_button(col, "New Game", _on_new_game)
	_add_button(col, "Continue (Slot 1)", _on_continue)
	_add_button(col, "Load Autosave", _on_autosave)
	var help: Label = Label.new()
	help.text = "Controls: WASD / arrows to move, E or Enter to interact, Tab / M for menu.\nGamepad: stick/D-pad, A confirm, B cancel, Y menu. Touch: on-screen D-pad + Interact."
	help.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	help.custom_minimum_size = Vector2(400, 60)
	col.add_child(help)
	import_edit = TextEdit.new()
	import_edit.custom_minimum_size = Vector2(400, 80)
	import_edit.placeholder_text = "Paste a save JSON here to import it, then tap Import Save."
	col.add_child(import_edit)
	_add_button(col, "Import Save", _on_import)
	status_label = Label.new()
	status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	col.add_child(status_label)

func _add_button(parent: Control, text: String, callable: Callable) -> void:
	var b: Button = Button.new()
	b.text = text
	b.custom_minimum_size = Vector2(400, 48)
	b.pressed.connect(callable)
	parent.add_child(b)

func _on_new_game() -> void:
	GameState.new_game()
	get_tree().change_scene_to_file("res://scenes/world.tscn")

func _on_continue() -> void:
	if SaveMgr.load_game(1):
		get_tree().change_scene_to_file("res://scenes/world.tscn")
	else:
		status_label.text = "Slot 1 is empty."

func _on_autosave() -> void:
	if SaveMgr.load_game(0):
		get_tree().change_scene_to_file("res://scenes/world.tscn")
	else:
		status_label.text = "No autosave found."

func _on_import() -> void:
	var text: String = import_edit.text.strip_edges()
	if text == "":
		status_label.text = "Paste a save JSON first."
		return
	if SaveMgr.import_json(text):
		SaveMgr.save_game(1)
		status_label.text = "Save imported and stored in Slot 1. Tap Continue."
	else:
		status_label.text = "Import failed: that JSON is not a valid Echoes save (schema or character IDs)."
