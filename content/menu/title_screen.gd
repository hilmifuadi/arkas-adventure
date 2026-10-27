extends Control
## Layar judul: mulai permainan dan pilih bahasa (Indonesia / Inggris).


@onready var start_button: Button = %StartButton
@onready var indonesian_button: Button = %IndonesianButton
@onready var english_button: Button = %EnglishButton


func _ready() -> void:
	start_button.pressed.connect(on_start_pressed)
	indonesian_button.pressed.connect(on_language_pressed.bind("id"))
	english_button.pressed.connect(on_language_pressed.bind("en"))
	start_button.grab_focus()


func on_start_pressed() -> void:
	GameState.reset()
	Scenes.go_to("res://world.tscn")


func on_language_pressed(code:String) -> void:
	Settings.language = code
