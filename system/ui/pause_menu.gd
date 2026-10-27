extends CanvasLayer
class_name PauseMenu
## Menu jeda: Lanjut, Simpan, Pengaturan, Kembali ke judul. Memakai get_tree().paused.


const SETTINGS_SCENE := "res://content/menu/settings_screen.tscn"

@onready var resume_button: Button = %ResumeButton
@onready var save_button: Button = %SaveButton
@onready var settings_button: Button = %SettingsButton
@onready var title_button: Button = %TitleButton
@onready var status_label: Label = %StatusLabel
@onready var root_control: Control = %Root

var settings_screen:Control


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false
	resume_button.pressed.connect(close)
	save_button.pressed.connect(on_save_pressed)
	settings_button.pressed.connect(on_settings_pressed)
	title_button.pressed.connect(on_title_pressed)
	UiSounds.wire(self)


func open() -> void:
	status_label.text = ""
	visible = true
	get_tree().paused = true
	resume_button.grab_focus()


func close() -> void:
	visible = false
	get_tree().paused = false


func on_save_pressed() -> void:
	status_label.text = tr("UI_SAVED") if SaveSystem.save_game() else ""


func on_settings_pressed() -> void:
	settings_screen = load(SETTINGS_SCENE).instantiate()
	settings_screen.closed.connect(on_settings_closed)
	root_control.add_child(settings_screen)


func on_settings_closed() -> void:
	if settings_screen:
		settings_screen.queue_free()
		settings_screen = null
	settings_button.grab_focus()


func on_title_pressed() -> void:
	close()
	Scenes.back_to_title()


func _unhandled_input(event: InputEvent) -> void:
	if visible and !settings_screen and (event.is_action_pressed("pause") or event.is_action_pressed("ui_cancel")):
		close()
		get_viewport().set_input_as_handled()
