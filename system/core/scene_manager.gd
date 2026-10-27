extends Node
## Pindah scene besar (Title, Game) lewat node Main, dan pindah peta di dalam World
## dengan transisi fade. Peta didaftarkan di MAPS (id peta -> scene).


const START_MAP := "desa_uji"
const START_SPAWN := "start"
const FAINT_MAP := "rumah_hokage"
const FAINT_SPAWN := "bed"
const WORLD_SCENE := "res://world.tscn"
const TITLE_SCENE := "res://content/menu/title_screen.tscn"

const MAPS := {
	"desa_uji": "res://content/acts/act01/map_desa_uji.tscn",
	"rumah_hokage": "res://content/acts/act01/map_rumah_hokage.tscn",
}

## True saat transisi peta berlangsung (pemain tidak boleh digerakkan).
var busy := false


func go_to(scene_path:String) -> void:
	var main = get_tree().get_first_node_in_group("main")
	if !main:
		push_error("Node Main tidak ditemukan")
		return
	main.launch_scene(load(scene_path))


func get_world() -> Node:
	return get_tree().get_first_node_in_group("world")


## Mulai permainan baru di peta awal.
func start_new_game() -> void:
	GameState.reset()
	GameState.current_map = START_MAP
	GameState.current_spawn = START_SPAWN
	GameState.restore_position = false
	Quests.set_objective("OBJ_TALK_HILMI")
	go_to(WORLD_SCENE)


## Muat slot simpanan lalu masuk ke dunia di posisi tersimpan.
func continue_game(slot := 1) -> bool:
	if !SaveSystem.load_game(slot):
		return false
	go_to(WORLD_SCENE)
	return true


func back_to_title() -> void:
	get_tree().paused = false
	busy = false
	go_to(TITLE_SCENE)


## Pindah peta dengan fade ke hitam, muat peta baru, lalu fade kembali.
func change_map(map_id:String, spawn_id := "default", autosave := true) -> void:
	var world := get_world()
	if busy or !world or !MAPS.has(map_id):
		push_warning("Tidak bisa pindah ke peta: %s" % map_id)
		return
	busy = true
	await world.transition.play(Transition.Type.FADE_IN)
	world.load_map(map_id,spawn_id)
	await get_tree().create_timer(0.2).timeout
	await world.transition.play(Transition.Type.FADE_OUT)
	busy = false
	if autosave:
		SaveSystem.autosave()


## Setelah pingsan: layar memudar, seluruh tim pulih, Arka bangun di rumah Hokage dan
## Dokter Zahra menyapa. (Tanpa kata "mati": kalah hanya berarti pingsan.)
func recover_from_faint() -> void:
	var world := get_world()
	if !world or busy:
		return
	busy = true
	await world.transition.play(Transition.Type.FADE_IN)
	GameState.heal_all()
	world.load_map(FAINT_MAP,FAINT_SPAWN)
	world.player.wake_up()
	await get_tree().create_timer(0.6).timeout
	await world.transition.play(Transition.Type.FADE_OUT)
	busy = false
	SaveSystem.autosave()
	Dialogue.start("zahra_bangun")
