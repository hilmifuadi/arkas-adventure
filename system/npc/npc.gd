extends Character
class_name NPC
## Tokoh non-pemain yang diam di tempat: menoleh ke pemain saat diajak bicara dan memulai dialognya.
## Bisa bersembunyi sementara (gurauan Pak Hilmi yang takut ayam).


@export var npc_id := ""
@export var dialog_id := ""
@export var interact_radius := 16.0
@export var prompt_height := 26.0
## Arah hadap awal.
@export var start_direction := Vector2.DOWN

var trigger:DialogTrigger
var hiding := false


func _ready() -> void:
	add_to_group("npc")
	if npc_id != "":
		add_to_group("npc_"+npc_id)
	sprite.direction = start_direction
	trigger = DialogTrigger.new()
	trigger.dialog_id = dialog_id
	trigger.prompt_offset = Vector2(0,-prompt_height)
	var shape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = interact_radius
	shape.shape = circle
	trigger.add_child(shape)
	add_child(trigger)
	trigger.interacted.connect(on_interacted)


func on_interacted(player:Node2D) -> void:
	sprite.direction = global_position.direction_to(player.global_position)


## Menghilang dengan kepulan asap kecil, muncul lagi setelah beberapa detik.
func hide_for(seconds := 5.0) -> void:
	if hiding:
		return
	hiding = true
	trigger.enabled = false
	Audio.play_sfx("puff")
	Puff.spawn(get_parent(),global_position+Vector2(0,-6))
	visible = false
	$Shape.set_deferred("disabled",true)
	await get_tree().create_timer(seconds,false).timeout
	visible = true
	$Shape.set_deferred("disabled",false)
	Puff.spawn(get_parent(),global_position+Vector2(0,-6))
	trigger.enabled = true
	hiding = false
