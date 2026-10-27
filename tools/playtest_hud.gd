extends SceneTree
## Uji HUD objektif: ringkas, memudar, tampil penuh saat tombol "objective" ditahan, lebar terbatas.
## Butuh jendela untuk screenshot. Argumen: folder screenshot.


var failures := 0
var out_dir := ""


func frames(count:int) -> void:
	for i in count:
		await process_frame


func check(label:String, condition:bool) -> void:
	print(("LULUS " if condition else "GAGAL ")+label)
	if !condition:
		failures += 1


func shot(name:String) -> void:
	root.get_texture().get_image().save_png(out_dir.path_join(name+".png"))


func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	out_dir = args[0] if args.size() > 0 else OS.get_environment("TEMP")
	var game_state = root.get_node("GameState")
	var quests = root.get_node("Quests")
	var settings = root.get_node("Settings")
	settings.language = "id"
	game_state.reset()
	game_state.set_flag("act01_start_seen")
	game_state.current_map = "desa_uji"
	quests.set_objective("OBJ_TALK_HILMI")
	var world = load("res://world.tscn").instantiate()
	root.add_child(world)
	await frames(30)
	var hud = world.get_node("Hud")
	var panel:PanelContainer = hud.objective_panel
	check("objektif tampil", panel.visible)
	check("tampil penuh saat objektif berubah", panel.modulate.a > 0.95)
	check("satu baris kecil (tinggi < 60 px)", panel.size.y < 60.0)
	shot("20_hud_objektif_id")
	await frames(330)
	check("memudar setelah beberapa detik", panel.modulate.a < 0.35)
	shot("21_hud_objektif_pudar")
	Input.action_press("objective")
	await frames(10)
	check("tahan tombol: tampil penuh lagi", panel.modulate.a > 0.95)
	Input.action_release("objective")
	await frames(120)
	check("lepas tombol: memudar lagi", panel.modulate.a < 0.5)
	# bahasa Inggris dan teks panjang: lebar maksimum 40% layar
	settings.language = "en"
	quests.set_objective("OBJ_TRAIN")
	await frames(20)
	var screen_width:float = root.get_visible_rect().size.x
	check("tampil penuh saat objektif berubah (EN)", panel.modulate.a > 0.95)
	check("lebar objektif <= 40%% layar + margin", panel.size.x <= screen_width*0.4+16.0)
	shot("22_hud_objektif_en")
	settings.language = "id"
	print("selesai, gagal=",failures)
	quit(1 if failures else 0)
