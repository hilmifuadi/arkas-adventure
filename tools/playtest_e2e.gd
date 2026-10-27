extends SceneTree
## Uji ujung-ke-ujung Fase 2 lewat alur nyata (Main -> judul -> Mulai -> ... -> Lanjutkan).
## Mulai -> jalan -> bicara Dokter Zahra -> bertarung/terluka -> pingsan dan bangun -> jeda -> ganti bahasa
## -> simpan -> keluar ke judul -> Lanjutkan memulihkan kondisi. Butuh jendela. Argumen: folder screenshot.


var failures := 0
var out_dir := ""
var GameState:Node
var Dialogue:Node
var Scenes:Node
var SaveSystem:Node
var Settings:Node
var main:Node


func frames(count:int) -> void:
	for i in count:
		await process_frame


func tap(action:String, hold := 3) -> void:
	var event := InputEventAction.new()
	event.action = action
	event.pressed = true
	Input.parse_input_event(event)
	await frames(hold)
	event = InputEventAction.new()
	event.action = action
	event.pressed = false
	Input.parse_input_event(event)
	await frames(2)


func shot(name:String) -> void:
	root.get_texture().get_image().save_png(out_dir.path_join(name+".png"))


func check(label:String, condition:bool) -> void:
	print(("LULUS " if condition else "GAGAL ")+label)
	if !condition:
		failures += 1


func wait_idle(limit := 600) -> void:
	for i in limit:
		if !Scenes.busy and !Dialogue.active:
			return
		await process_frame


func world():
	return main.current_scene


func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	out_dir = args[0] if args.size() > 0 else OS.get_environment("TEMP")
	GameState = root.get_node("GameState")
	Dialogue = root.get_node("Dialogue")
	Scenes = root.get_node("Scenes")
	SaveSystem = root.get_node("SaveSystem")
	Settings = root.get_node("Settings")
	Settings.language = "id"
	Settings.easy_mode = false
	SaveSystem.delete_save(1)
	main = load("res://main.tscn").instantiate()
	root.add_child(main)
	await frames(30)
	check("layar judul tampil", main.current_scene.name == "TitleScreen")
	check("Lanjutkan nonaktif tanpa simpanan", main.current_scene.continue_button.disabled)
	# Mulai
	main.current_scene.start_button.pressed.emit()
	await frames(60)
	check("dunia dimuat setelah Mulai", world().name == "World")
	var player = world().player
	check("objektif awal", root.get_node("Quests").get_objective() == "OBJ_TALK_HILMI")
	await wait_idle(30)
	await tap("dash")   # lewati dialog pembuka
	await frames(20)
	check("dialog pembuka selesai", !Dialogue.active)
	# jalan
	var start_x:float = player.global_position.x
	Input.action_press("move_right")
	await frames(30)
	Input.action_release("move_right")
	check("Arka berjalan", player.global_position.x > start_x+5)
	shot("06_desa_uji")
	# bicara Pak Hilmi lewat interaksi, mengubah objektif
	var hilmi = world().map.get_node("Tilemap/PakHilmi")
	player.global_position = hilmi.global_position+Vector2(0,18)
	player.facing = Vector2.UP
	await frames(20)
	await tap("interact")
	await frames(10)
	check("bicara dengan Pak Hilmi", Dialogue.active)
	await tap("dash")   # lewati sampai pilihan
	await frames(100)
	shot("07_dialog_hilmi")
	check("pilihan tampil", Dialogue.box.choice_buttons.size() == 3)
	await tap("move_down")
	await tap("interact")  # pilih "ayam"
	await frames(30)
	await tap("dash")
	await frames(30)
	await wait_idle()
	check("objektif berubah setelah bicara", root.get_node("Quests").get_objective() == "OBJ_TRAIN")
	# terluka oleh musuh
	var enemy = world().map.get_node("Tilemap/SamuraiLatihan2")
	player.global_position = enemy.global_position+Vector2(0,28)
	var before:int = GameState.hearts
	for i in 400:
		await process_frame
		if GameState.hearts < before:
			break
	check("hati berkurang karena musuh", GameState.hearts < before)
	await frames(30)
	shot("08_terluka")
	# pingsan -> bangun di rumah Hokage
	player.invulnerable = false
	GameState.hearts = 1
	player.hitbox.take_damage(load("res://content/enemies/damage_enemy.tres"),player.global_position+Vector2(8,0))
	await frames(25)
	shot("09_pingsan")
	for i in 600:
		await process_frame
		if GameState.current_map == "rumah_hokage" and Dialogue.active:
			break
	check("bangun di rumah Hokage dan pulih", GameState.current_map == "rumah_hokage" and GameState.hearts == GameState.hearts_max)
	await frames(60)
	shot("10_bangun")
	await tap("dash")
	await wait_idle()
	# Dokter Zahra menyembuhkan
	GameState.hearts = 2
	var zahra = world().map.get_node("Tilemap/DokterZahra")
	player.global_position = zahra.global_position+Vector2(0,18)
	player.facing = Vector2.UP
	await frames(20)
	await tap("interact")
	await frames(80)
	shot("11_dokter_zahra")
	await tap("dash")
	await wait_idle()
	check("Zahra menyembuhkan tim", GameState.hearts == GameState.hearts_max)
	# jeda, ganti bahasa
	await tap("pause")
	await frames(10)
	check("menu jeda terbuka", world().pause_menu.visible and paused)
	shot("12_jeda")
	world().pause_menu.settings_button.pressed.emit()
	await frames(10)
	world().pause_menu.settings_screen.english_button.pressed.emit()
	await frames(10)
	check("bahasa diganti ke Inggris", Settings.language == "en")
	shot("13_pengaturan_en")
	world().pause_menu.settings_screen.close()
	await frames(5)
	world().pause_menu.close()
	await frames(5)
	check("game berjalan lagi", !paused)
	# simpan
	GameState.set_flag("e2e_penanda",true)
	GameState.add_item("onigiri",3)
	var saved_map:String = GameState.current_map
	var saved_hearts:int = GameState.hearts
	var saved_position:Vector2 = player.global_position
	await tap("pause")
	world().pause_menu.save_button.pressed.emit()
	await frames(5)
	check("simpanan dibuat", SaveSystem.has_save(1))
	# keluar ke judul
	world().pause_menu.title_button.pressed.emit()
	await frames(40)
	check("kembali ke judul", main.current_scene.name == "TitleScreen")
	check("Lanjutkan aktif", !main.current_scene.continue_button.disabled)
	shot("14_judul_lanjutkan")
	GameState.reset()   # buang kondisi lama agar pemulihan benar-benar dari berkas
	main.current_scene.continue_button.pressed.emit()
	await frames(60)
	check("dunia dimuat dari simpanan", main.current_scene.name == "World")
	player = world().player
	check("peta pulih", GameState.current_map == saved_map)
	check("posisi pulih", player.global_position.distance_to(saved_position) < 2.0)
	check("hati pulih", GameState.hearts == saved_hearts)
	check("flag dan inventori pulih", GameState.get_flag("e2e_penanda") and GameState.count_item("onigiri") == 3)
	check("bahasa tetap Inggris", Settings.language == "en" and root.get_node("Quests").get_objective() == "OBJ_TRAIN")
	await frames(10)
	shot("15_lanjutkan_pulih")
	Settings.language = "id"
	SaveSystem.delete_save(1)
	print("selesai, gagal=",failures)
	quit(1 if failures else 0)
