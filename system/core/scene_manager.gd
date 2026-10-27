extends Node
## Pindah scene besar (Title, Game) lewat node Main, dan pindah peta di Fase 2.


func go_to(scene_path:String) -> void:
	var main = get_tree().get_first_node_in_group("main")
	if !main:
		push_error("Node Main tidak ditemukan")
		return
	main.launch_scene(load(scene_path))
