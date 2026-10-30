extends Node
## Content registry: one authoritative JSON source per data kind.
## Loaded at startup; game code reads through these dictionaries, never
## hardcodes campaign data. See docs/CONTENT_MANIFEST.md.

var characters: Dictionary = {}
var jobs: Dictionary = {}
var items: Dictionary = {}
var enemies: Dictionary = {}
var encounters: Dictionary = {}
var quests: Dictionary = {}
var dialogue: Dictionary = {}

func _ready() -> void:
	characters = _load("res://content/characters.json")
	jobs = _load("res://content/jobs.json")
	items = _load("res://content/items.json")
	enemies = _load("res://content/enemies.json")
	encounters = _load("res://content/encounters.json")
	quests = _load("res://content/quests.json")
	dialogue = _load("res://content/dialogue.json")

func _load(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		push_error("Missing content file: " + path)
		return {}
	var text: String = FileAccess.get_file_as_string(path)
	var parsed = JSON.parse_string(text)
	if typeof(parsed) != TYPE_DICTIONARY:
		push_error("Invalid content JSON: " + path)
		return {}
	return parsed

func char_ids() -> Array:
	return characters.keys()

func job_abilities(job_id: String) -> Array:
	if jobs.has(job_id):
		return jobs[job_id].get("abilities", [])
	return []

func ability_by_id(job_id: String, ability_id: String) -> Dictionary:
	for a in job_abilities(job_id):
		if a.get("id", "") == ability_id:
			return a
	return {}
