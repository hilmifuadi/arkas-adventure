extends Area2D
class_name MapDoor
## Pintu/jalan keluar: saat pemain masuk, pindah ke peta lain dengan transisi fade.


@export var target_map := ""
@export var target_spawn := "default"
@export var enabled := true


func _ready() -> void:
	collision_layer = 0
	collision_mask = 0
	set_collision_mask_value(5,true)
	body_entered.connect(on_body_entered)


func on_body_entered(body:Node2D) -> void:
	if enabled and body.is_in_group("player") and !Scenes.busy:
		Scenes.change_map(target_map,target_spawn)
