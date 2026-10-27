extends CanvasLayer
class_name Hud
## HUD: deretan hati (layar virtual 320x180 diskalakan 4x) dan teks objektif aktif yang ringkas
## (lapisan terpisah tanpa skala: satu baris kecil, semi-transparan, lebar menyesuaikan teks).
## Objektif tampil penuh saat berubah, memudar setelah beberapa detik, dan tampil penuh lagi
## selama tombol "objective" (O / Back) ditahan.


const FULL_ALPHA := 1.0
const DIM_ALPHA := 0.25
const SHOW_SECONDS := 4.0
const FADE_SECONDS := 1.0
## Ukuran font objektif (px layar): kelipatan 9 agar font piksel tetap tajam.
const FONT_NORMAL := 18
const FONT_LARGE := 27
## Lebar maksimum objektif = 40% lebar layar; lebih panjang dari itu dibungkus.
const MAX_WIDTH_RATIO := 0.4

var tween:Tween
var shown_until_msec := 0

@onready var objective_panel: PanelContainer = %ObjectivePanel
@onready var objective_label: Label = %ObjectiveLabel


func _ready() -> void:
	Quests.objective_changed.connect(on_objective_changed)
	Settings.language_changed.connect(func(_code): refresh_objective(false))
	refresh_objective(true)


func on_objective_changed(_key:String) -> void:
	refresh_objective(true)


func refresh_objective(highlight:bool) -> void:
	var key := Quests.get_objective()
	objective_panel.visible = key != ""
	if key == "":
		return
	var font_size := FONT_LARGE if Settings.text_scale > 1.0 else FONT_NORMAL
	var text := tr(key)
	objective_label.add_theme_font_size_override("font_size",font_size)
	var max_width := get_viewport().get_visible_rect().size.x*MAX_WIDTH_RATIO
	var text_width := objective_label.get_theme_font("font").get_string_size(text,HORIZONTAL_ALIGNMENT_LEFT,-1,font_size).x
	if text_width > max_width:
		objective_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		objective_label.custom_minimum_size = Vector2(max_width,0)
	else:
		objective_label.autowrap_mode = TextServer.AUTOWRAP_OFF
		objective_label.custom_minimum_size = Vector2.ZERO
	objective_label.text = text
	objective_panel.reset_size()
	if highlight:
		show_full(SHOW_SECONDS)


## Tampil penuh selama `seconds`, lalu memudar ke DIM_ALPHA.
func show_full(seconds:float) -> void:
	shown_until_msec = Time.get_ticks_msec()+int(seconds*1000.0)
	objective_panel.modulate.a = FULL_ALPHA
	if tween:
		tween.kill()
	tween = create_tween()
	tween.tween_interval(seconds)
	tween.tween_property(objective_panel,"modulate:a",DIM_ALPHA,FADE_SECONDS)


func _process(_delta: float) -> void:
	if !objective_panel.visible:
		return
	if Input.is_action_just_pressed("objective"):
		show_full(SHOW_SECONDS)
	elif Input.is_action_pressed("objective"):
		# Selama ditahan, tetap penuh; memudar lagi 1 dtk setelah dilepas.
		show_full(1.0)
