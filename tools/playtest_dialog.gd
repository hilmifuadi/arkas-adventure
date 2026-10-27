extends SceneTree
## Uji dialog: Dokter Zahra menyembuhkan, pilihan Pak Hilmi, kondisi flag, efek. Butuh jendela.


var failures := 0
var GameState:Node
var Dialogue:Node


func press(action:String) -> void:
	var event := InputEventAction.new()
	event.action = action
	event.pressed = true
	Input.parse_input_event(event)
	await process_frame
	event = InputEventAction.new()
	event.action = action
	event.pressed = false
	Input.parse_input_event(event)


func frames(count:int) -> void:
	for i in count:
		await process_frame


func shot(name:String) -> void:
	root.get_texture().get_image().save_png(OS.get_environment("TEMP").path_join(name+".png"))


func check(label:String, condition:bool) -> void:
	print(("LULUS " if condition else "GAGAL ")+label)
	if !condition:
		failures += 1


## Lanjutkan dialog sampai selesai dengan menekan interact.
func advance_all(limit := 20) -> void:
	for i in limit:
		if !Dialogue.active:
			return
		await frames(8)
		await press("interact")   # selesaikan ketikan
		await frames(8)
		await press("interact")   # lanjut


func _initialize() -> void:
	GameState = root.get_node("GameState")
	Dialogue = root.get_node("Dialogue")
	GameState.reset()
	var world = load("res://world.tscn").instantiate()
	root.add_child(world)
	await frames(10)
	# 1. Dokter Zahra menyembuhkan (pertemuan pertama)
	GameState.hearts = 2
	Dialogue.start("zahra_sembuhkan")
	await frames(20)
	check("dialog aktif", Dialogue.active)
	check("pemain terkunci saat dialog", get_first_node_in_group("player").locked)
	await frames(40)
	shot("dialog_zahra")
	await advance_all()
	check("dialog selesai", !Dialogue.active)
	check("tim pulih penuh", GameState.hearts == GameState.hearts_max)
	check("flag zahra_met", GameState.get_flag("zahra_met"))
	# 2. diajak bicara lagi: varian 'lagi', tetap menyembuhkan
	GameState.hearts = 1
	await frames(30)
	Dialogue.start("zahra_sembuhkan")
	await advance_all()
	check("sembuh lagi setiap diajak bicara", GameState.hearts == GameState.hearts_max)
	# 3. pilihan Pak Hilmi (kata 'ayam')
	await frames(30)
	Dialogue.start("hilmi_sapa")
	await frames(10)
	await frames(60)
	await press("interact")
	await frames(80)
	shot("dialog_pilihan")
	check("pilihan muncul", Dialogue.box.choice_buttons.size() == 3)
	await press("move_down")
	await frames(3)
	check("pilihan bisa digeser dengan keyboard", Dialogue.box.choice_buttons[1].has_focus())
	await press("interact")
	await frames(5)
	await advance_all()
	check("dialog pilihan selesai", !Dialogue.active)
	# 4. pesan singkat dan bahasa Inggris
	root.get_node("Settings").language = "en"
	Dialogue.show_message("MSG_ITEM_GOT",{"item":"onigiri","count":2})
	await frames(30)
	check("pesan item (en)", Dialogue.box.text_label.text == "You got 2 onigiri!")
	shot("dialog_pesan_en")
	await advance_all()
	root.get_node("Settings").language = "id"
	# 5. lewati: efek tetap berjalan
	GameState.hearts = 1
	await frames(30)
	Dialogue.start("zahra_sembuhkan")
	await frames(20)
	await press("dash")
	await frames(20)
	check("lewati menutup dialog dan efek tetap jalan", !Dialogue.active and GameState.hearts == GameState.hearts_max)
	print("selesai, gagal=",failures)
	quit(1 if failures else 0)
