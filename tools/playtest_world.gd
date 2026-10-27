extends SceneTree
## Uji dunia: dialog pembuka, pindah peta lewat pintu, Dokter Zahra, boneka latih, musuh, pingsan dan bangun.
## Butuh jendela (bukan --headless) bila ingin screenshot.


var failures := 0
var GameState:Node
var Dialogue:Node
var Scenes:Node
var world
var player


func press(action:String, hold_frames := 2) -> void:
	var event := InputEventAction.new()
	event.action = action
	event.pressed = true
	Input.parse_input_event(event)
	for i in hold_frames:
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


func tile_to_world(tx:float, ty:float) -> Vector2:
	return Vector2(16+16*tx,16+16*ty)+Vector2(0,0)


func wait_until_idle(limit := 400) -> void:
	for i in limit:
		if !Scenes.busy and !Dialogue.active:
			return
		await process_frame


func _initialize() -> void:
	GameState = root.get_node("GameState")
	Dialogue = root.get_node("Dialogue")
	Scenes = root.get_node("Scenes")
	GameState.reset()
	GameState.current_map = "desa_uji"
	GameState.current_spawn = "start"
	world = load("res://world.tscn").instantiate()
	root.add_child(world)
	await frames(30)
	player = world.player
	# 1. dialog pembuka dipicu saat masuk area
	check("dialog pembuka jalan sendiri", Dialogue.active)
	await press("dash")
	await frames(10)
	check("dialog pembuka selesai (lewati)", !Dialogue.active and GameState.get_flag("act01_start_seen"))
	shot("dunia_desa")
	# 2. boneka latih
	var dummy = world.map.get_node("Tilemap/BonekaLatih1")
	player.global_position = dummy.global_position+Vector2(0,20)
	player.facing = Vector2.UP
	player.sprite.direction = Vector2.UP
	await frames(30)
	var life_before:float = dummy.life.life
	await press("attack")
	await frames(30)
	check("serangan mengenai boneka latih", dummy.life.life < life_before)
	shot("dunia_boneka")
	# 3. musuh melukai pemain (hati berkurang)
	var enemy = world.map.get_node("Tilemap/SamuraiLatihan1")
	player.global_position = enemy.global_position+Vector2(0,-30)
	var hearts_before:int = GameState.hearts
	for i in 300:
		await process_frame
		if GameState.hearts < hearts_before:
			break
	check("musuh membuat hati berkurang", GameState.hearts < hearts_before)
	shot("dunia_musuh")
	# 4. kalahkan musuh (puff)
	var guard := 0
	while is_instance_valid(enemy) and guard < 40:
		guard += 1
		if is_instance_valid(enemy):
			enemy.on_damage_received(load("res://content/weapon/katana/katana.tres").damage,player.global_position)
		await frames(20)
	check("musuh kalah dan hilang (puff)", !is_instance_valid(enemy) or enemy.is_queued_for_deletion())
	# 5. masuk rumah Hokage lewat pintu
	GameState.heal_all()
	player.invulnerable = false
	await frames(10)
	player.global_position = tile_to_world(-1.5,1.0)+Vector2(0,-4)
	player.facing = Vector2.UP
	await frames(5)
	Input.action_press("move_up")
	await frames(60)
	Input.action_release("move_up")
	await wait_until_idle()
	await frames(20)
	check("pindah ke rumah Hokage", GameState.current_map == "rumah_hokage")
	shot("dunia_rumah")
	# 6. Dokter Zahra menyembuhkan (lewat interaksi sungguhan)
	GameState.hearts = 2
	var zahra = world.map.get_node("Tilemap/DokterZahra")
	player.global_position = zahra.global_position+Vector2(0,18)
	player.facing = Vector2.UP
	await frames(20)
	await press("interact")
	await frames(10)
	check("diajak bicara memulai dialog", Dialogue.active)
	shot("dunia_zahra")
	for i in 30:
		if !Dialogue.active:
			break
		await frames(70)
		await press("interact")
		await frames(5)
	check("Zahra menyembuhkan seluruh tim", !Dialogue.active and GameState.hearts == GameState.hearts_max)
	# 7. pingsan di luar, bangun di rumah Hokage
	Scenes.change_map("desa_uji","hokage_door")
	await frames(30)
	await wait_until_idle()
	check("kembali ke desa", GameState.current_map == "desa_uji")
	player.invulnerable = false
	GameState.hearts = 1
	var damage = load("res://content/enemies/damage_enemy.tres")
	player.hitbox.take_damage(damage,player.global_position+Vector2(10,0))
	check("pingsan", player.mode == 3)
	await frames(20)
	shot("dunia_pingsan")
	await frames(120)
	for i in 400:
		if GameState.current_map == "rumah_hokage" and Dialogue.active:
			break
		await process_frame
	check("bangun di rumah Hokage", GameState.current_map == "rumah_hokage")
	check("pulih penuh setelah pingsan", GameState.hearts == GameState.hearts_max)
	check("Dokter Zahra menyapa saat bangun", Dialogue.active)
	await frames(80)
	shot("dunia_bangun")
	print("selesai, gagal=",failures)
	quit(1 if failures else 0)
