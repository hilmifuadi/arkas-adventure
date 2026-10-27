extends Interactable
class_name Chest
## Peti sederhana: sekali dibuka memberi item. Status buka disimpan sebagai flag "chest_<id>".


@export var chest_id := ""
@export var item := "coin"
@export var count := 1

@onready var sprite: Sprite2D = $Sprite


func _ready() -> void:
	super._ready()
	update_sprite()


func is_opened() -> bool:
	return GameState.get_flag("chest_"+chest_id)


func can_interact() -> bool:
	return super.can_interact() and !is_opened()


func update_sprite() -> void:
	sprite.frame = 1 if is_opened() else 0


func _on_interact(_player:Node2D) -> void:
	GameState.set_flag("chest_"+chest_id)
	GameState.add_item(item,count)
	update_sprite()
	Audio.play_sfx("chest")
	Dialogue.show_message("MSG_ITEM_GOT",{"item":tr("ITEM_"+item.to_upper()),"count":count})
