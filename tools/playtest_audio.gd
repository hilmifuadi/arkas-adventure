extends SceneTree
## Uji audio: bus Music/SFX, volume dari Settings, crossfade musik, SFX. Bisa --headless.


var failures := 0


func check(label:String, condition:bool) -> void:
	print(("LULUS " if condition else "GAGAL ")+label)
	if !condition:
		failures += 1


func _initialize() -> void:
	await process_frame
	var audio = root.get_node("Audio")
	var settings = root.get_node("Settings")
	check("bus Music ada", AudioServer.get_bus_index("Music") >= 0)
	check("bus SFX ada", AudioServer.get_bus_index("SFX") >= 0)
	settings.music_volume = 0.5
	settings.sfx_volume = 0.25
	check("volume musik dari Settings", is_equal_approx(AudioServer.get_bus_volume_db(AudioServer.get_bus_index("Music")),linear_to_db(0.5)))
	check("volume SFX dari Settings", is_equal_approx(AudioServer.get_bus_volume_db(AudioServer.get_bus_index("SFX")),linear_to_db(0.25)))
	audio.play_music("village",0.2)
	await create_timer(0.4).timeout
	check("musik desa diputar", audio.current_name == "village" and audio.music_players[audio.active_music].playing)
	var first_player = audio.music_players[audio.active_music]
	audio.play_music("sunny",0.2)
	await create_timer(0.5).timeout
	check("crossfade ke musik lain", audio.current_name == "sunny" and audio.music_players[audio.active_music] != first_player and !first_player.playing)
	audio.play_sfx("slash")
	var playing := 0
	for player in audio.sfx_players:
		playing += int(player.playing)
	check("SFX diputar", playing == 1)
	audio.stop_music(0.2)
	await create_timer(0.5).timeout
	check("musik berhenti", !audio.music_players[0].playing and !audio.music_players[1].playing)
	settings.music_volume = 0.8
	settings.sfx_volume = 1.0
	print("selesai, gagal=",failures)
	quit(1 if failures else 0)
