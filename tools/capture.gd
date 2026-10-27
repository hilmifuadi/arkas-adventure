extends SceneTree
## Ambil screenshot sebuah scene (butuh jendela, bukan --headless):
##   godot --path . --script tools/capture.gd -- res://main.tscn 60 out.png
## Argumen: scene, jumlah frame yang ditunggu, file keluaran (PNG).


func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	var scene_path:String = args[0] if args.size() > 0 else "res://main.tscn"
	var frames := int(args[1]) if args.size() > 1 else 60
	var out_path:String = args[2] if args.size() > 2 else "capture.png"
	var scene:Node = load(scene_path).instantiate()
	root.add_child(scene)
	print("autoloads: ", root.has_node("Settings"), root.has_node("GameState"))
	for i in frames:
		await process_frame
	var image := root.get_texture().get_image()
	image.save_png(out_path)
	print("tersimpan: ", out_path, " ", image.get_size())
	quit()
