extends Control
class_name HeartBar
## Deretan hati dari GameState.hearts / hearts_max (satu hati = satu wadah, bukan angka HP).


const TEXTURE:Texture2D = preload("res://content/ui/heart.png")
const FRAME_EMPTY := 0
const FRAME_FULL := 4
const SIZE := 16


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	GameState.hearts_changed.connect(update_bar)
	update_bar()


func update_bar() -> void:
	custom_minimum_size = Vector2(SIZE*GameState.hearts_max,SIZE)
	queue_redraw()


func _draw() -> void:
	for i in GameState.hearts_max:
		var frame := FRAME_FULL if i < GameState.hearts else FRAME_EMPTY
		draw_texture_rect_region(TEXTURE,Rect2(i*SIZE,0,SIZE,SIZE),Rect2(frame*SIZE,0,SIZE,SIZE))
