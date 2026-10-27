extends CanvasLayer
class_name DialogBox
## Kotak dialog di bawah layar: faceset, nama, teks yang diketik (dengan bunyi voice),
## emote, dan pilihan. Dikendalikan oleh autoload Dialogue.
## Tombol interaksi melanjutkan; tombol dash / tombol "Lewati" melewati sisa dialog;
## pilihan bisa dipilih dengan keyboard, gamepad, atau mouse/sentuh.


signal confirmed
signal skip_requested
signal choice_made(index:int)

const CHARS_PER_SECOND := 45.0
const BLIP_EVERY := 3
const BOX_FACE := preload("res://assets/ui/dialog_box_faceset.png")
const BOX_PLAIN := preload("res://assets/ui/dialog_box.png")
const VOICES := {
	"voice1": preload("res://audio/voice/voice1.wav"),
	"voice2": preload("res://audio/voice/voice2.wav"),
	"voice3": preload("res://audio/voice/voice3.wav"),
	"voice5": preload("res://audio/voice/voice5.wav"),
	"voice6": preload("res://audio/voice/voice6.wav"),
	"voice7": preload("res://audio/voice/voice7.wav"),
	"voice8": preload("res://audio/voice/voice8.wav"),
	"voice9": preload("res://audio/voice/voice9.wav"),
}
const EMOTE_DIR := "res://assets/ui/emotes/"

var typing := false
var typed := 0.0
var waiting_confirm := false
var waiting_choice := false
var ready_msec := 0
var voice_stream:AudioStream
var voice_pitch := 1.0
var choice_buttons:Array[Button] = []
var arrow_phase := 0.0
var skip_pending := false

@onready var box: TextureRect = %Box
@onready var face: TextureRect = %Face
@onready var emote: TextureRect = %Emote
@onready var name_label: Label = %NameLabel
@onready var text_label: Label = %Text
@onready var arrow: TextureRect = %Arrow
@onready var choices: VBoxContainer = %Choices
@onready var skip_button: Button = %SkipButton
@onready var voice_player: AudioStreamPlayer = %Voice


func _ready() -> void:
	visible = false
	skip_button.pressed.connect(request_skip)
	box.gui_input.connect(on_box_gui_input)


## Tampilkan satu baris. speaker: {name, faceset, voice, pitch}. Mengembalikan indeks pilihan atau -1.
func show_line(speaker:Dictionary, text:String, emote_name:String, choice_texts:Array[String]) -> int:
	visible = true
	var faceset:Texture2D = speaker.get("faceset")
	face.texture = faceset
	face.visible = faceset != null
	box.texture = BOX_FACE if faceset else BOX_PLAIN
	text_label.position.x = 52.0 if faceset else 10.0
	text_label.size.x = 242.0 if faceset else 284.0
	var speaker_name:String = speaker.get("name","")
	name_label.text = speaker_name
	name_label.get_parent().visible = speaker_name != ""
	set_emote(emote_name)
	voice_stream = VOICES.get(speaker.get("voice","voice2"),VOICES["voice2"])
	voice_pitch = speaker.get("pitch",1.0)
	text_label.label_settings.font_size = Settings.font_size()
	text_label.text = text
	text_label.visible_characters = 0
	typed = 0.0
	typing = true
	arrow.visible = false
	clear_choices()
	await get_tree().process_frame
	ready_msec = Time.get_ticks_msec()
	while typing:
		await get_tree().process_frame
	if choice_texts.is_empty():
		if skip_pending:
			skip_pending = false
			return -1
		waiting_confirm = true
		arrow.visible = true
		await confirmed
		waiting_confirm = false
		arrow.visible = false
		return -1
	return await ask_choice(choice_texts)


func set_emote(emote_name:String) -> void:
	var path := EMOTE_DIR+emote_name+".png"
	if emote_name != "" and ResourceLoader.exists(path):
		emote.texture = load(path)
		emote.visible = true
	else:
		emote.visible = false


func ask_choice(choice_texts:Array[String]) -> int:
	for i in choice_texts.size():
		var button := Button.new()
		button.text = choice_texts[i]
		button.custom_minimum_size = Vector2(0,18)
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		button.pressed.connect(func(): choice_made.emit(i))
		choices.add_child(button)
		choice_buttons.append(button)
	choice_buttons[0].grab_focus()
	waiting_choice = true
	var index:int = await choice_made
	waiting_choice = false
	clear_choices()
	return index


func clear_choices() -> void:
	for button in choice_buttons:
		button.queue_free()
	choice_buttons.clear()


func close() -> void:
	visible = false
	typing = false
	skip_pending = false
	waiting_confirm = false
	waiting_choice = false
	clear_choices()


func _process(delta: float) -> void:
	if !visible:
		return
	if typing:
		var before := int(typed)
		typed += CHARS_PER_SECOND*delta
		var shown := mini(int(typed),text_label.text.length())
		text_label.visible_characters = shown
		if shown != before and shown % BLIP_EVERY == 0 and shown > 0:
			play_blip(text_label.text[shown-1])
		if shown >= text_label.text.length():
			typing = false
			text_label.visible_characters = -1
	if arrow.visible:
		arrow_phase += delta*6.0
		arrow.position.y = 44.0+sin(arrow_phase)*1.5


func play_blip(character:String) -> void:
	if character == " " or character == "." or character == ",":
		return
	voice_player.stream = voice_stream
	voice_player.pitch_scale = voice_pitch*randf_range(0.96,1.04)
	voice_player.play()


## Lewati sisa dialog: baris yang sedang tampil langsung selesai; Dialogue menjalankan efek sisa baris.
func request_skip() -> void:
	if waiting_choice:
		return
	skip_requested.emit()
	skip_pending = true
	finish_typing()
	if waiting_confirm:
		skip_pending = false
		confirmed.emit()


func finish_typing() -> void:
	typed = float(text_label.text.length())
	text_label.visible_characters = -1
	typing = false


func confirm() -> void:
	# Mengabaikan tekan yang sama dengan yang membuka baris ini.
	if Time.get_ticks_msec()-ready_msec < 120:
		return
	if typing:
		finish_typing()
	elif waiting_confirm:
		confirmed.emit()


func on_box_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		confirm()
		box.accept_event()
	elif event is InputEventScreenTouch and event.pressed:
		confirm()
		box.accept_event()


func _input(event: InputEvent) -> void:
	if !visible:
		return
	if waiting_choice:
		if event.is_action_pressed("move_up") or event.is_action_pressed("move_down"):
			var step := -1 if event.is_action_pressed("move_up") else 1
			var focused := choice_buttons.find(get_viewport().gui_get_focus_owner())
			var target := wrapi(focused+step,0,choice_buttons.size())
			choice_buttons[target].grab_focus()
			get_viewport().set_input_as_handled()
		elif event.is_action_pressed("interact"):
			var focus_owner := get_viewport().gui_get_focus_owner()
			if focus_owner is Button:
				focus_owner.pressed.emit()
			get_viewport().set_input_as_handled()
		return
	if event.is_action_pressed("interact"):
		confirm()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("dash"):
		request_skip()
		get_viewport().set_input_as_handled()
