extends SceneTree
## Ambil screenshot layar UI untuk dokumentasi: judul, pengaturan, jeda, HUD. Butuh jendela.
## Argumen: folder keluaran.


var out_dir := ""


func frames(count:int) -> void:
	for i in count:
		await process_frame


func shot(name:String) -> void:
	root.get_texture().get_image().save_png(out_dir.path_join(name+".png"))
	print("tersimpan: ", name)


func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	out_dir = args[0] if args.size() > 0 else OS.get_environment("TEMP")
	var settings = root.get_node("Settings")
	var game_state = root.get_node("GameState")
	var save_system = root.get_node("SaveSystem")
	settings.language = "id"
	# 1. judul tanpa simpanan
	save_system.delete_save(1)
	var main = load("res://main.tscn").instantiate()
	root.add_child(main)
	await frames(30)
	shot("01_judul")
	# 2. pengaturan dari judul
	main.current_scene.on_settings_pressed()
	await frames(20)
	shot("02_pengaturan")
	main.current_scene.settings_screen.close()
	await frames(5)
	# 3. mulai game baru, HUD + objektif
	main.current_scene.on_start_pressed()
	await frames(60)
	var world = main.current_scene
	root.get_node("Dialogue").skipping = true
	await frames(5)
	shot("03_hud_desa")
	# 4. jeda
	world.pause_menu.open()
	await frames(20)
	shot("04_jeda")
	world.pause_menu.on_settings_pressed()
	await frames(20)
	shot("05_pengaturan_dari_jeda")
	world.pause_menu.settings_screen.close()
	world.pause_menu.close()
	quit()
