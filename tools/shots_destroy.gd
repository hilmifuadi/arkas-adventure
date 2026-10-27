extends SceneTree
## Screenshot sebelum/sesudah menghancurkan benda (pot/peti) di peta desa_uji. Butuh jendela.
##   godot --path . --script tools/shots_destroy.gd -- <folder> <awalan> <tx> <ty>
## (tx, ty = petak benda; Arka menyerang dari bawahnya.) Dipakai untuk memeriksa pohon yang tertimpa benda.


func frames(count:int) -> void:
	for i in count:
		await process_frame


func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	var out_dir:String = args[0]
	var prefix:String = args[1]
	var target := Vector2(16+16*float(args[2]),16+16*float(args[3]))
	var game_state = root.get_node("GameState")
	game_state.reset()
	game_state.set_flag("act01_start_seen")
	game_state.current_map = "desa_uji"
	var world = load("res://world.tscn").instantiate()
	root.add_child(world)
	await frames(20)
	var player = world.player
	var best:Node2D
	var best_distance := INF
	for node in world.map.get_node("Tilemap").find_children("*","CharacterBody2D",true,false):
		if node.get_script() and node.get_script().get_global_name() == "Destroyable":
			var distance:float = node.global_position.distance_to(target)
			if distance < best_distance:
				best_distance = distance
				best = node
	print("benda terdekat: ", best.name if best else "tidak ada", " jarak=", best_distance)
	player.global_position = target+Vector2(0,22)
	player.facing = Vector2.UP
	player.sprite.direction = Vector2.UP
	await frames(40)
	root.get_texture().get_image().save_png(out_dir.path_join(prefix+"_sebelum.png"))
	Input.action_press("attack")
	await frames(3)
	Input.action_release("attack")
	await frames(120)
	root.get_texture().get_image().save_png(out_dir.path_join(prefix+"_sesudah.png"))
	quit()
