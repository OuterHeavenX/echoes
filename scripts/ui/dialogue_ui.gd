extends CanvasLayer
## Dialogue box: speaker, portrait, typewriter text, advance on confirm/tap.
## Effects (applied once, at the end) are idempotent by flag checks in
## the world/battle code that consumes them; battle effects are handed
## off via GameState.pending_encounter.

signal dialogue_finished(dialogue_id: String)

var _panel: PanelContainer
var _speaker_label: Label
var _text_label: Label
var _portrait: TextureRect
var _next_button: Button
var _lines: Array = []
var _effects: Array = []
var _index: int = 0
var _full_text: String = ""
var _shown: float = 0.0
var _active: bool = false
var _dialogue_id: String = ""

func _ready() -> void:
	layer = 10
	visible = false
	_panel = PanelContainer.new()
	_panel.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	_panel.offset_top = -150
	_panel.offset_bottom = 0
	add_child(_panel)
	var box: HBoxContainer = HBoxContainer.new()
	_panel.add_child(box)
	_portrait = TextureRect.new()
	_portrait.custom_minimum_size = Vector2(96, 106)
	_portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	box.add_child(_portrait)
	var col: VBoxContainer = VBoxContainer.new()
	col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	box.add_child(col)
	_speaker_label = Label.new()
	_speaker_label.add_theme_font_size_override("font_size", 20)
	col.add_child(_speaker_label)
	_text_label = Label.new()
	_text_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_text_label.add_theme_font_size_override("font_size", 18)
	col.add_child(_text_label)
	_next_button = Button.new()
	_next_button.text = "Next  >"
	_next_button.custom_minimum_size = Vector2(110, 44)
	_next_button.pressed.connect(_on_next)
	col.add_child(_next_button)

func _process(delta: float) -> void:
	if not _active:
		return
	var speed: float = 40.0 * float(GameState.setting("text_speed"))
	if _shown < float(_full_text.length()):
		_shown += speed * delta
		_text_label.text = _full_text.substr(0, int(_shown))

func _unhandled_input(event: InputEvent) -> void:
	if not _active:
		return
	if event.is_action_pressed("confirm") or event.is_action_pressed("interact"):
		_on_next()
		get_viewport().set_input_as_handled()

func start(dialogue_id: String) -> void:
	if not Content.dialogue.has(dialogue_id):
		push_error("Unknown dialogue: " + dialogue_id)
		return
	var node: Dictionary = Content.dialogue[dialogue_id]
	_dialogue_id = dialogue_id
	_lines = node.get("lines", [])
	_effects = node.get("effects", [])
	_index = 0
	_active = true
	visible = true
	_show_line()

func _show_line() -> void:
	if _index >= _lines.size():
		_finish()
		return
	var line: Dictionary = _lines[_index]
	_speaker_label.text = str(line.get("speaker", ""))
	_full_text = str(line.get("text", ""))
	_shown = 0.0
	_text_label.text = ""
	var portrait_id: String = str(line.get("portrait", "rowan"))
	var ppath: String = "res://assets/portraits/%s.png" % portrait_id
	if ResourceLoader.exists(ppath):
		_portrait.texture = load(ppath)
	else:
		_portrait.texture = null

func _on_next() -> void:
	if not _active:
		return
	if _shown < float(_full_text.length()):
		_shown = float(_full_text.length())
		_text_label.text = _full_text
		return
	_index += 1
	_show_line()

func _finish() -> void:
	_active = false
	visible = false
	for eff in _effects:
		_apply_effect(eff)
	dialogue_finished.emit(_dialogue_id)

func _apply_effect(eff: Dictionary) -> void:
	var kind: String = str(eff.get("type", ""))
	var value: String = str(eff.get("value", ""))
	match kind:
		"flag":
			GameState.set_flag(value)
		"quest":
			var parts: PackedStringArray = value.split(":")
			if parts.size() == 2:
				GameState.quest_advance(parts[0], int(parts[1]))
		"party":
			GameState.add_party(value)
		"item":
			var parts2: PackedStringArray = value.split(":")
			if parts2.size() == 2:
				GameState.add_item(parts2[0], int(parts2[1]))
		"battle":
			GameState.pending_encounter = value
			get_tree().change_scene_to_file("res://scenes/battle.tscn")
