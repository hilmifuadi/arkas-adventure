extends Area2D
class_name InteractSensor
## Sensor di depan Arka: memilih Interactable terdekat, menampilkan ikon tombol, dan memanggilnya.


const MASK_INTERACT := 6
const AHEAD := 8.0

var targets:Array[Interactable] = []
var current:Interactable
var use_gamepad := false

@onready var prompt: Sprite2D = $Prompt
@onready var player: Node2D = get_parent()

var key_texture:Texture2D = preload("res://assets/ui/key_e.png")
var button_texture:Texture2D = preload("res://assets/ui/button_y.png")


func _ready() -> void:
	collision_layer = 0
	collision_mask = 0
	set_collision_mask_value(MASK_INTERACT,true)
	monitorable = false
	area_entered.connect(on_area_entered)
	area_exited.connect(on_area_exited)
	prompt.top_level = true
	prompt.visible = false


func _input(event: InputEvent) -> void:
	if event is InputEventJoypadButton or (event is InputEventJoypadMotion and absf(event.axis_value) > 0.5):
		use_gamepad = true
	elif event is InputEventKey or event is InputEventMouseButton:
		use_gamepad = false


func _process(_delta: float) -> void:
	if "facing" in player:
		position = player.facing*AHEAD
	current = pick_target()
	var show_prompt:bool = current != null and !Dialogue.is_busy() and !player.locked
	prompt.visible = show_prompt
	if show_prompt:
		prompt.texture = button_texture if use_gamepad else key_texture
		var bob := sin(Time.get_ticks_msec()/180.0)*1.5
		prompt.global_position = current.global_position+current.prompt_offset+Vector2(0,bob)


func pick_target() -> Interactable:
	var best:Interactable
	var best_distance := INF
	for target in targets:
		if !is_instance_valid(target) or !target.can_interact():
			continue
		var distance := target.global_position.distance_squared_to(player.global_position)
		if distance < best_distance:
			best_distance = distance
			best = target
	return best


func interact() -> void:
	if current:
		current.interact(player)


func on_area_entered(area:Area2D) -> void:
	if area is Interactable and !targets.has(area):
		targets.append(area)


func on_area_exited(area:Area2D) -> void:
	targets.erase(area)
