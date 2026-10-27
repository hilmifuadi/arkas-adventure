extends Node
## Pindah scene besar (Title, Game) lewat node Main, dan pindah peta di dalam World.

## True saat transisi peta berlangsung (pemain tidak boleh digerakkan).
var busy := false


func go_to(scene_path:String) -> void:
	var main = get_tree().get_first_node_in_group("main")
	if !main:
		push_error("Node Main tidak ditemukan")
		return
	main.launch_scene(load(scene_path))


## Setelah pingsan: pulihkan tim dan bangunkan Arka. (Pindah ke rumah Hokage ditambah di butir Peta.)
func recover_from_faint() -> void:
	GameState.heal_all()
	for player in get_tree().get_nodes_in_group("player"):
		player.wake_up()
