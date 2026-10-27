extends SceneTree
## Uji interaksi: sensor memilih target, ikon tombol muncul, peti memberi item. Butuh jendela.


var failures := 0
var GameState:Node


func press(action:String, pressed := true) -> void:
	var event := InputEventAction.new()
	event.action = action
	event.pressed = pressed
	Input.parse_input_event(event)


func frames(count:int) -> void:
	for i in count:
		await process_frame


func check(label:String, condition:bool) -> void:
	print(("LULUS " if condition else "GAGAL ")+label)
	if !condition:
		failures += 1


func _initialize() -> void:
	GameState = root.get_node("GameState")
	GameState.reset()
	GameState.set_flag("act01_start_seen")   # tanpa dialog pembuka agar pemain bebas bergerak
	var world = load("res://world.tscn").instantiate()
	root.add_child(world)
	await frames(10)
	var player = get_first_node_in_group("player")
	var chest = load("res://system/interact/chest.tscn").instantiate()
	chest.chest_id = "uji"
	chest.item = "onigiri"
	player.get_parent().add_child(chest)
	chest.global_position = player.global_position+Vector2(14,0)
	await frames(10)
	var sensor = player.get_node("InteractSensor")
	player.facing = Vector2.RIGHT
	await frames(5)
	check("sensor menemukan peti", sensor.current == chest)
	check("ikon tombol tampil", sensor.prompt.visible)
	press("interact")
	await frames(3)
	press("interact",false)
	check("peti terbuka (flag)", GameState.get_flag("chest_uji"))
	check("item masuk inventori", GameState.count_item("onigiri") == 1)
	await frames(5)
	check("ikon hilang setelah peti terbuka", !sensor.prompt.visible)
	# peti tidak memberi dua kali
	chest.interact(player)
	check("peti tidak memberi dua kali", GameState.count_item("onigiri") == 1)
	var image := root.get_texture().get_image()
	image.save_png(OS.get_environment("TEMP").path_join("interaksi.png"))
	print("selesai, gagal=",failures)
	quit(1 if failures else 0)
