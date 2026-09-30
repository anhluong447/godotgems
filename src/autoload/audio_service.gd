extends Node
## Plays sound by id. Lookup order: assets/audio/sfx/sfx_<id>.ogg|.wav, then a synth placeholder.
## Music: assets/audio/music/bgm_<id>.ogg with crossfade.

const SFX_DIR := "res://assets/audio/sfx"
const MUSIC_DIR := "res://assets/audio/music"
const VOICES := 16

var _cache: Dictionary[StringName, AudioStream] = {}
var _players: Array[AudioStreamPlayer] = []
var _next := 0
var _music: AudioStreamPlayer
var _music_id: StringName = &""


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	for i: int in VOICES:
		var p := AudioStreamPlayer.new()
		p.bus = &"SFX"
		add_child(p)
		_players.append(p)
	_music = AudioStreamPlayer.new()
	_music.bus = &"Music"
	add_child(_music)


func play_sfx(id: StringName, pitch_variance: float = 0.06, volume_db: float = 0.0, bus: StringName = &"SFX") -> void:
	if id == &"":
		return
	var stream := _resolve_sfx(id)
	if stream == null:
		return
	var p := _players[_next]
	_next = (_next + 1) % _players.size()
	p.stream = stream
	p.bus = bus
	p.volume_db = volume_db
	p.pitch_scale = 1.0 + randf_range(-pitch_variance, pitch_variance)
	p.play()


func play_ui(id: StringName) -> void:
	play_sfx(id, 0.0, 0.0, &"UI")


func play_music(id: StringName, fade: float = 0.6) -> void:
	if id == _music_id:
		return
	_music_id = id
	var stream: AudioStream = null
	for ext: String in [".ogg", ".mp3", ".wav"]:
		var path := MUSIC_DIR.path_join("bgm_%s%s" % [id, ext])
		if ResourceLoader.exists(path):
			stream = load(path)
			break
	var tween := create_tween()
	if _music.playing:
		tween.tween_property(_music, "volume_db", -40.0, fade)
	tween.tween_callback(func() -> void:
		_music.stream = stream
		if stream != null:
			_music.volume_db = -40.0
			_music.play()
		else:
			_music.stop()
	)
	if stream != null:
		tween.tween_property(_music, "volume_db", 0.0, fade)


func stop_music(fade: float = 0.6) -> void:
	_music_id = &""
	var tween := create_tween()
	tween.tween_property(_music, "volume_db", -40.0, fade)
	tween.tween_callback(_music.stop)


func _resolve_sfx(id: StringName) -> AudioStream:
	if _cache.has(id):
		return _cache[id]
	var stream: AudioStream = null
	for ext: String in [".ogg", ".wav"]:
		var path := SFX_DIR.path_join("sfx_%s%s" % [id, ext])
		if ResourceLoader.exists(path):
			stream = load(path)
			break
	if stream == null and SfxSynth.has_recipe(id):
		stream = SfxSynth.make(id)
	if stream == null:
		push_warning("AudioService: unknown sfx '%s'" % id)
	_cache[id] = stream
	return stream
