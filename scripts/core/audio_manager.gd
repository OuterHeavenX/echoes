extends Node
## Music/SFX: original generated WAV loops (tools/gen_assets.py).
## Volumes follow GameState settings; music restarts only on track change.

var music_player: AudioStreamPlayer
var sfx_player: AudioStreamPlayer
var current_track: String = ""

func _ready() -> void:
	music_player = AudioStreamPlayer.new()
	music_player.name = "Music"
	add_child(music_player)
	sfx_player = AudioStreamPlayer.new()
	sfx_player.name = "SFX"
	add_child(sfx_player)
	apply_volumes()

func apply_volumes() -> void:
	var mv: float = float(GameState.setting("music_volume"))
	var sv: float = float(GameState.setting("sfx_volume"))
	music_player.volume_db = linear_to_db(clampf(mv, 0.0, 1.0))
	sfx_player.volume_db = linear_to_db(clampf(sv, 0.0, 1.0))

func play_music(track: String) -> void:
	if track == current_track and music_player.playing:
		return
	var path: String = "res://assets/audio/%s.wav" % track
	if not ResourceLoader.exists(path):
		return
	var stream: AudioStreamWAV = load(path)
	stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
	music_player.stream = stream
	music_player.play()
	current_track = track

func stop_music() -> void:
	music_player.stop()
	current_track = ""

func play_sfx(name: String) -> void:
	var path: String = "res://assets/audio/%s.wav" % name
	if not ResourceLoader.exists(path):
		return
	sfx_player.stream = load(path)
	sfx_player.play()
