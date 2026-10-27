extends CanvasLayer
class_name Hud
## HUD: deretan hati dan teks objektif aktif. Semua dalam layar virtual 320x180 (skala 4x).


@onready var objective_panel: Control = %ObjectivePanel
@onready var objective_label: Label = %ObjectiveLabel


func _ready() -> void:
	Quests.objective_changed.connect(on_objective_changed)
	Settings.language_changed.connect(func(_code): refresh_objective())
	refresh_objective()


func on_objective_changed(_key:String) -> void:
	refresh_objective()


func refresh_objective() -> void:
	var key := Quests.get_objective()
	objective_panel.visible = key != ""
	objective_label.text = tr(key) if key != "" else ""
	objective_label.add_theme_font_size_override("font_size",Settings.font_size())
