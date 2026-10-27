extends Sprite2D
class_name Puff
## Kepulan asap "puff" sekali putar. Dipakai saat musuh kalah atau tokoh bersembunyi (tanpa darah).


const SCENE_FRAMES := 6
const TEXTURE:Texture2D = preload("res://assets/fx/smoke.png")


static func spawn(parent:Node, at:Vector2) -> void:
	var puff := Puff.new()
	puff.texture = TEXTURE
	puff.hframes = SCENE_FRAMES
	puff.z_index = 20
	parent.add_child(puff)
	puff.global_position = at


func _ready() -> void:
	var tween := create_tween()
	tween.tween_property(self,"frame",SCENE_FRAMES-1,0.45).from(0)
	tween.tween_callback(queue_free)
