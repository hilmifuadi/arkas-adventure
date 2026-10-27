extends Interactable
class_name DialogTrigger
## Memulai dialog dari content/acts/<act>/dialogs.json. Dua mode:
##  - INTERACT: pemain menekan tombol interaksi di dekatnya (NPC, papan, objek).
##  - ENTER: dialog jalan sendiri saat pemain masuk area (adegan pembuka); sekali saja bila once_flag diisi.


enum Mode {INTERACT,ENTER}

@export var dialog_id := ""
@export var mode:Mode = Mode.INTERACT
## Flag yang di-set setelah dialog dipicu; mode ENTER tidak memicu lagi bila flag ini sudah true.
@export var once_flag := ""


func _ready() -> void:
	super._ready()
	if mode == Mode.ENTER:
		monitoring = true
		set_collision_mask_value(5,true)
		body_entered.connect(on_body_entered)


func on_body_entered(body:Node2D) -> void:
	if body.is_in_group("player") and can_interact() and !Dialogue.is_busy():
		_on_interact(body)


func can_interact() -> bool:
	if once_flag != "" and mode == Mode.ENTER and GameState.get_flag(once_flag):
		return false
	return super.can_interact()


func _on_interact(_player:Node2D) -> void:
	if once_flag != "":
		GameState.set_flag(once_flag)
	Dialogue.start(dialog_id,{"source":self})
