extends Marker2D
class_name SpawnPoint
## Titik muncul pemain di sebuah peta. Dipanggil lewat Scenes.change_map(map_id, spawn_id).


@export var spawn_id := "default"
@export var facing := Vector2.DOWN


func _ready() -> void:
	add_to_group("spawn_point")
