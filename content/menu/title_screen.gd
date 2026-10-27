extends Control
## Layar judul: Mulai (game baru), Lanjutkan (aktif bila ada simpanan), Pengaturan, dan pilihan bahasa.
## Semua tata letak memakai layar virtual 320x180 yang diskalakan 4x; tombol besar dan tidak butuh hover.


const SETTINGS_SCENE := "res://content/menu/settings_screen.tscn"

@onready var start_button: Button = %StartButton
@onready var continue_button: Button = %ContinueButton
@onready var settings_button: Button = %SettingsButton
@onready var indonesian_button: Button = %IndonesianButton
@onready var english_button: Button = %EnglishButton
@onready var confirm_panel: Control = %ConfirmPanel
@onready var yes_button: Button = %YesButton
@onready var no_button: Button = %NoButton

var settings_screen:Control


func _ready() -> void:
	start_button.pressed.connect(on_start_pressed)
	continue_button.pressed.connect(on_continue_pressed)
	settings_button.pressed.connect(on_settings_pressed)
	indonesian_button.pressed.connect(on_language_pressed.bind("id"))
	english_button.pressed.connect(on_language_pressed.bind("en"))
	yes_button.pressed.connect(Scenes.start_new_game)
	no_button.pressed.connect(close_confirm)
	continue_button.disabled = !SaveSystem.has_save()
	confirm_panel.visible = false
	UiSounds.wire(self)
	Audio.play_music("title")
	(continue_button if !continue_button.disabled else start_button).grab_focus()


func on_start_pressed() -> void:
	if SaveSystem.has_save():
		confirm_panel.visible = true
		no_button.grab_focus()
	else:
		Scenes.start_new_game()


func close_confirm() -> void:
	confirm_panel.visible = false
	start_button.grab_focus()


func on_continue_pressed() -> void:
	Scenes.continue_game()


func on_settings_pressed() -> void:
	settings_screen = load(SETTINGS_SCENE).instantiate()
	settings_screen.closed.connect(on_settings_closed)
	add_child(settings_screen)


func on_settings_closed() -> void:
	if settings_screen:
		settings_screen.queue_free()
		settings_screen = null
	continue_button.disabled = !SaveSystem.has_save()
	settings_button.grab_focus()


func on_language_pressed(code:String) -> void:
	Settings.language = code


func _unhandled_input(event: InputEvent) -> void:
	if confirm_panel.visible and event.is_action_pressed("ui_cancel"):
		close_confirm()
		get_viewport().set_input_as_handled()
