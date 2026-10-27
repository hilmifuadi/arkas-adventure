@icon("../map/icon_map.png")
extends Node2D
class_name Map
## Satu peta: tilemap (tempat semua tokoh, agar urutan gambar benar), titik muncul, dan lingkungan.


@export var map_id := ""
## Nama musik di Audio.MUSIC yang diputar saat peta dimuat.
@export var music := ""
## Kunci terjemahan nama tempat (untuk HUD/objektif).
@export var title_key := ""

@onready var screen_grid_ref: TextureRect = $ScreenGridRef
@onready var environment_area: EnvironmentArea = %EnvironmentArea
@onready var tilemap: TileMap = $Tilemap


func _ready() -> void:
	screen_grid_ref.visible = false


## Induk untuk pemain, NPC, musuh, dan objek yang ikut diurutkan berdasarkan y.
func get_entities_root() -> Node2D:
	return tilemap


func find_spawn(spawn_id:String) -> SpawnPoint:
	var fallback:SpawnPoint
	for point in find_children("*","SpawnPoint",true,false):
		if point.spawn_id == spawn_id:
			return point
		fallback = fallback if fallback else point
	return fallback
