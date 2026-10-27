extends Control
## Layar Pengaturan (dipakai dari judul dan menu jeda): bahasa, volume musik dan SFX,
## ukuran teks, Mode Santai. Perubahan langsung berlaku dan disimpan lewat Settings.


signal closed

@onready var indonesian_button: Button = %IndonesianButton
@onready var english_button: Button = %EnglishButton
@onready var music_slider: HSlider = %MusicSlider
@onready var sfx_slider: HSlider = %SfxSlider
@onready var text_normal_button: Button = %TextNormalButton
@onready var text_large_button: Button = %TextLargeButton
@onready var easy_check: CheckButton = %EasyCheck
@onready var back_button: Button = %BackButton


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	indonesian_button.pressed.connect(func(): Settings.language = "id")
	english_button.pressed.connect(func(): Settings.language = "en")
	music_slider.value = Settings.music_volume
	sfx_slider.value = Settings.sfx_volume
	music_slider.value_changed.connect(func(value:float): Settings.music_volume = value)
	sfx_slider.value_changed.connect(on_sfx_changed)
	var large := Settings.text_scale > 1.0
	text_normal_button.button_pressed = !large
	text_large_button.button_pressed = large
	text_normal_button.pressed.connect(on_text_size_chosen.bind(Settings.TEXT_SCALES[0]))
	text_large_button.pressed.connect(on_text_size_chosen.bind(Settings.TEXT_SCALES[1]))
	easy_check.button_pressed = Settings.easy_mode
	easy_check.toggled.connect(func(on:bool): Settings.easy_mode = on)
	back_button.pressed.connect(close)
	UiSounds.wire(self)
	indonesian_button.grab_focus()


func on_sfx_changed(value:float) -> void:
	Settings.sfx_volume = value
	Audio.play_sfx("coin")


func on_text_size_chosen(chosen_scale:float) -> void:
	Settings.text_scale = chosen_scale
	text_normal_button.button_pressed = chosen_scale <= 1.0
	text_large_button.button_pressed = chosen_scale > 1.0


func close() -> void:
	Settings.save_settings()
	closed.emit()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel") or event.is_action_pressed("pause"):
		close()
		get_viewport().set_input_as_handled()
