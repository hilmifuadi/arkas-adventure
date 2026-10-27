extends Node
## Pemutar musik per area (dengan crossfade) dan efek suara. Bus: "Music" dan "SFX"
## (default_bus_layout.tres); volumenya diatur Settings.apply_volume().


const MUSIC := {
	"title": preload("res://audio/music/intro.ogg"),
	"village": preload("res://audio/music/calm_village.ogg"),
	"sunny": preload("res://audio/music/sunny.ogg"),
}
const SFX := {
	"slash": preload("res://audio/sfx/slash.wav"),
	"dash": preload("res://audio/sfx/dash.wav"),
	"hurt": preload("res://audio/sfx/hurt.wav"),
	"enemy_hit": preload("res://audio/sfx/enemy_hit.wav"),
	"puff": preload("res://audio/sfx/puff.wav"),
	"chest": preload("res://audio/sfx/chest.wav"),
	"heal": preload("res://audio/sfx/heal.wav"),
	"coin": preload("res://audio/sfx/coin.wav"),
	"menu_move": preload("res://audio/sfx/menu_move.wav"),
	"menu_accept": preload("res://audio/sfx/menu_accept.wav"),
	"menu_cancel": preload("res://audio/sfx/menu_cancel.wav"),
}
## Jingle singkat (diputar di bus SFX).
const JINGLES := {
	"faint": preload("res://audio/sfx/faint.wav"),
	"success": preload("res://audio/sfx/success.wav"),
}
const SFX_VOICES := 8
const SILENT_DB := -60.0

var music_players:Array[AudioStreamPlayer] = []
var sfx_players:Array[AudioStreamPlayer] = []
var active_music := 0
var current_stream:AudioStream
var current_name := ""
var fade_tween:Tween


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	for i in 2:
		var player := AudioStreamPlayer.new()
		player.bus = &"Music"
		player.volume_db = SILENT_DB
		player.finished.connect(on_music_finished.bind(player))
		add_child(player)
		music_players.append(player)
	for i in SFX_VOICES:
		var player := AudioStreamPlayer.new()
		player.bus = &"SFX"
		add_child(player)
		sfx_players.append(player)
	Settings.apply_volume()


## Musik berdasarkan nama di MUSIC (mis. "village"). Nama yang sama tidak diputar ulang.
func play_music(track:String, fade := 1.0) -> void:
	if !MUSIC.has(track):
		push_warning("Musik tidak dikenal: %s" % track)
		return
	crossfade_to(MUSIC[track],fade,track)


## Musik dari resource langsung (dipakai EnvironmentArea per peta).
func play_music_stream(stream:AudioStream, fade := 1.0) -> void:
	crossfade_to(stream,fade,stream.resource_path)


func crossfade_to(stream:AudioStream, fade:float, track_name:String) -> void:
	if stream == null:
		stop_music(fade)
		return
	if track_name == current_name and music_players[active_music].playing:
		return
	current_name = track_name
	current_stream = stream
	var old := music_players[active_music]
	active_music = 1-active_music
	var incoming := music_players[active_music]
	incoming.stream = stream
	incoming.volume_db = SILENT_DB if fade > 0.0 else 0.0
	incoming.play()
	if fade_tween:
		fade_tween.kill()
	fade_tween = create_tween().set_parallel(true)
	if fade > 0.0:
		fade_tween.tween_property(incoming,"volume_db",0.0,fade)
		fade_tween.tween_property(old,"volume_db",SILENT_DB,fade)
	fade_tween.chain().tween_callback(old.stop)


func stop_music(fade := 1.0) -> void:
	current_name = ""
	current_stream = null
	if fade_tween:
		fade_tween.kill()
	fade_tween = create_tween().set_parallel(true)
	for player in music_players:
		if player.playing:
			fade_tween.tween_property(player,"volume_db",SILENT_DB,maxf(fade,0.01))
	fade_tween.chain().tween_callback(func():
		for player in music_players:
			player.stop())


## Berkas OGG dari pack tidak berulang secara bawaan; ulangi sendiri.
func on_music_finished(player:AudioStreamPlayer) -> void:
	if player == music_players[active_music] and current_stream:
		player.play()


func play_sfx(sfx_name:String, volume_db := 0.0) -> void:
	var stream:AudioStream = SFX.get(sfx_name,JINGLES.get(sfx_name))
	if stream == null:
		push_warning("SFX tidak dikenal: %s" % sfx_name)
		return
	for player in sfx_players:
		if !player.playing:
			player.stream = stream
			player.volume_db = volume_db
			player.pitch_scale = 1.0
			player.play()
			return
	# Semua suara terpakai: ganti yang paling lama.
	sfx_players[0].stream = stream
	sfx_players[0].play()


func play_jingle(jingle_name:String) -> void:
	play_sfx(jingle_name)
