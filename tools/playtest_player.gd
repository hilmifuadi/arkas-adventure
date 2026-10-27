extends SceneTree
## Uji gameplay Arka secara otomatis (butuh jendela, bukan --headless):
##   godot --path . --script tools/playtest_player.gd
## Menekan input lewat Input.parse_input_event, mencetak hasilnya, dan menyimpan screenshot.


var world:Node
var player


func press(action:String, pressed := true) -> void:
	var event := InputEventAction.new()
	event.action = action
	event.pressed = pressed
	Input.parse_input_event(event)


func frames(count:int) -> void:
	for i in count:
		await process_frame


func shot(name:String) -> void:
	var image := root.get_texture().get_image()
	image.save_png(OS.get_environment("TEMP").path_join(name+".png"))


func check(label:String, condition:bool) -> void:
	print(("LULUS " if condition else "GAGAL ")+label)
	if !condition:
		failures += 1


var failures := 0
var GameState:Node


func _initialize() -> void:
	GameState = root.get_node("GameState")
	GameState.reset()
	world = load("res://world.tscn").instantiate()
	root.add_child(world)
	await frames(10)
	player = get_first_node_in_group("player")
	check("pemain ada", player != null)
	var start_pos:Vector2 = player.global_position
	# gerak ke kanan
	press("move_right")
	await frames(30)
	press("move_right",false)
	check("bergerak ke kanan", player.global_position.x > start_pos.x+5)
	# serang
	press("attack")
	await frames(2)
	press("attack",false)
	check("mode serang", player.mode == 1)
	await frames(3)
	shot("serang")
	await frames(30)
	check("kembali normal setelah serang", player.mode == 0)
	# dash
	var before:Vector2 = player.global_position
	press("move_right")
	press("dash")
	await frames(3)
	press("dash",false)
	check("mode dash dan kebal", player.mode == 2 and player.invulnerable)
	await frames(2)
	shot("dash")
	await frames(20)
	press("move_right",false)
	check("dash menempuh jarak", player.global_position.distance_to(before) > 25)
	check("cooldown dash aktif", player.dash_cooldown_left > 0.0)
	# hati
	var hearts_before:int = GameState.hearts
	var damage := ResourceDamage.new()
	damage.amount = 1
	await frames(40)
	player.hitbox.take_damage(damage,player.global_position+Vector2(10,0))
	check("hati berkurang", GameState.hearts == hearts_before-1)
	check("kebal sesaat setelah terluka", player.invulnerable)
	player.hitbox.take_damage(damage,player.global_position+Vector2(10,0))
	check("tidak terluka dua kali saat kebal", GameState.hearts == hearts_before-1)
	await frames(90)
	# pingsan
	player.invulnerable = false
	GameState.hearts = 1
	player.hitbox.take_damage(damage,player.global_position+Vector2(10,0))
	check("pingsan saat hati habis", player.mode == 3)
	await frames(10)
	shot("pingsan")
	await frames(70)
	check("bangun dan pulih", player.mode == 0 and GameState.hearts == GameState.hearts_max)
	print("selesai, gagal=",failures)
	quit(1 if failures else 0)
