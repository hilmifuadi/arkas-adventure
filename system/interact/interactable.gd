extends Area2D
class_name Interactable
## Objek yang bisa diajak berinteraksi dengan tombol "interact" ketika Arka berada di dekatnya.
## Subkelas (DialogTrigger, Chest, ...) mengisi _on_interact().


signal interacted(player)

const INTERACT_LAYER := 6

@export var enabled := true
## Posisi ikon petunjuk tombol relatif terhadap objek.
@export var prompt_offset := Vector2(0,-24)
## Bila diisi: hanya aktif jika flag ini bernilai true / tidak aktif jika hide_if_flag true.
@export var require_flag := ""
@export var hide_if_flag := ""


func _ready() -> void:
	collision_layer = 0
	collision_mask = 0
	set_collision_layer_value(INTERACT_LAYER,true)
	monitoring = false


func can_interact() -> bool:
	if !enabled:
		return false
	if require_flag != "" and !GameState.get_flag(require_flag):
		return false
	if hide_if_flag != "" and GameState.get_flag(hide_if_flag):
		return false
	return true


func interact(player:Node2D) -> void:
	if !can_interact():
		return
	interacted.emit(player)
	_on_interact(player)


func _on_interact(_player:Node2D) -> void:
	pass
