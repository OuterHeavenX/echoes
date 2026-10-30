extends Node
## Save slots: 0 = rotating autosave, 1-3 = manual. Previous save kept as .bak.
## Format is GameState.to_dict() plus a metadata block; import validates
## schema version and character IDs before anything is applied.

const DIR: String = "user://echoes"
const VERSION: String = "0.3.0-c1"

func _ready() -> void:
	var d: DirAccess = DirAccess.open("user://")
	if d != null:
		d.make_dir_recursive("echoes")

func slot_path(slot: int) -> String:
	return DIR + "/slot%d.json" % slot

func save_game(slot: int) -> bool:
	var path: String = slot_path(slot)
	if FileAccess.file_exists(path):
		var old: String = FileAccess.get_file_as_string(path)
		var bak: FileAccess = FileAccess.open(path + ".bak", FileAccess.WRITE)
		if bak != null:
			bak.store_string(old)
			bak.close()
	var payload: Dictionary = GameState.to_dict()
	payload["meta"] = {
		"location": str(GameState.data.get("map", "")),
		"chapter": str(GameState.data.get("chapter", "")),
		"party": GameState.data.get("party", []),
		"playtime": float(GameState.data.get("playtime", 0.0)),
		"timestamp": Time.get_datetime_string_from_system(),
		"build": VERSION,
	}
	var f: FileAccess = FileAccess.open(path, FileAccess.WRITE)
	if f == null:
		return false
	f.store_string(JSON.stringify(payload))
	f.close()
	return true

func autosave() -> bool:
	return save_game(0)

func load_game(slot: int) -> bool:
	var path: String = slot_path(slot)
	if not FileAccess.file_exists(path):
		return false
	var text: String = FileAccess.get_file_as_string(path)
	return import_json(text)

func slot_exists(slot: int) -> bool:
	return FileAccess.file_exists(slot_path(slot))

func slot_meta(slot: int) -> Dictionary:
	var path: String = slot_path(slot)
	if not FileAccess.file_exists(path):
		return {}
	var parsed = JSON.parse_string(FileAccess.get_file_as_string(path))
	if typeof(parsed) != TYPE_DICTIONARY:
		return {}
	return parsed.get("meta", {})

func export_json(slot: int) -> String:
	if not FileAccess.file_exists(slot_path(slot)):
		return ""
	return FileAccess.get_file_as_string(slot_path(slot))

func import_json(text: String) -> bool:
	var parsed = JSON.parse_string(text)
	if typeof(parsed) != TYPE_DICTIONARY:
		return false
	if int(parsed.get("schema", 0)) != GameState.SCHEMA_VERSION:
		return false
	var chars: Dictionary = parsed.get("chars", {})
	if chars.is_empty():
		return false
	for cid in chars.keys():
		if cid not in Content.characters:
			return false
	return GameState.from_dict(parsed)
