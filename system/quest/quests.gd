extends Node
## Objektif aktif (pelacak di HUD). Quest lengkap (utama + sampingan) dibangun di Fase 6;
## Fase 2 hanya menyimpan satu kunci objektif aktif di GameState.flags["quest_objective"].


signal objective_changed(key:String)

const FLAG := "quest_objective"


func _ready() -> void:
	GameState.flag_changed.connect(on_flag_changed)


## Kunci terjemahan objektif aktif ("" = tidak ada).
func get_objective() -> String:
	return str(GameState.get_flag(FLAG,""))


func set_objective(key:String) -> void:
	GameState.set_flag(FLAG,key)


func clear_objective() -> void:
	set_objective("")


func on_flag_changed(flag:String, value:Variant) -> void:
	if flag == FLAG:
		objective_changed.emit(str(value))
