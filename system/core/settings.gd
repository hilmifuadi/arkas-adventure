extends Node
## Pengaturan pemain (bahasa, volume, ukuran teks, mode santai)
## dan pemuat teks terjemahan dari file JSON.
##
## Teks game tidak boleh ditulis langsung di skrip atau scene. Semua teks memakai
## kunci (mis. "TITLE_GAME") yang diterjemahkan lewat tr() / auto-translate.
## File teks bernama "<area>.<bahasa>.json", mis. "ui.id.json" dan "ui.en.json",
## berisi objek datar { "KUNCI": "teks" }.


signal language_changed(code:String)

const SUPPORTED_LANGUAGES:Array[String] = ["id", "en"]
const TEXT_DIRS:Array[String] = ["res://translations", "res://content"]
const CONFIG_PATH := "user://settings.cfg"

var language := "id":
	set(v):
		if v not in SUPPORTED_LANGUAGES:
			push_warning("Bahasa tidak didukung: %s" % v)
			return
		language = v
		TranslationServer.set_locale(language)
		language_changed.emit(language)
		save_settings()
var music_volume := 0.8:
	set(v):
		music_volume = clampf(v, 0.0, 1.0)
		apply_volume()
var sfx_volume := 1.0:
	set(v):
		sfx_volume = clampf(v, 0.0, 1.0)
		apply_volume()
const TEXT_SCALES:Array[float] = [1.0,1.34]

var text_scale := 1.0
var easy_mode := false:
	set(v):
		easy_mode = v
		if is_node_ready() and has_node("/root/GameState"):
			GameState.refresh_hearts_max()


func _ready() -> void:
	load_translations()
	load_settings()
	TranslationServer.set_locale(language)
	apply_volume()


## Ukuran font untuk teks panjang (dialog, objektif): 9 px dikali ukuran teks pilihan pemain.
func font_size(base := 9) -> int:
	return int(round(base*text_scale))


func load_translations() -> void:
	var by_language := {}
	for code in SUPPORTED_LANGUAGES:
		var translation := Translation.new()
		translation.locale = code
		by_language[code] = translation
	for dir in TEXT_DIRS:
		for path in find_text_files(dir):
			var code := path.get_file().get_basename().get_extension()
			if not by_language.has(code):
				continue
			var data = JSON.parse_string(FileAccess.get_file_as_string(path))
			if typeof(data) != TYPE_DICTIONARY:
				push_error("File teks tidak valid: %s" % path)
				continue
			for key in data:
				by_language[code].add_message(key, str(data[key]))
	for code in by_language:
		TranslationServer.add_translation(by_language[code])


func find_text_files(dir_path:String) -> PackedStringArray:
	var result := PackedStringArray()
	var dir := DirAccess.open(dir_path)
	if !dir:
		return result
	for sub_dir in dir.get_directories():
		result.append_array(find_text_files(dir_path.path_join(sub_dir)))
	for file in dir.get_files():
		if file.ends_with(".json") and file.get_basename().get_extension() in SUPPORTED_LANGUAGES:
			result.append(dir_path.path_join(file))
	return result


func load_settings() -> void:
	var config := ConfigFile.new()
	if config.load(CONFIG_PATH) != OK:
		return
	language = config.get_value("game", "language", language)
	music_volume = config.get_value("audio", "music_volume", music_volume)
	sfx_volume = config.get_value("audio", "sfx_volume", sfx_volume)
	text_scale = config.get_value("game", "text_scale", text_scale)
	easy_mode = config.get_value("game", "easy_mode", easy_mode)


func save_settings() -> void:
	var config := ConfigFile.new()
	config.set_value("game", "language", language)
	config.set_value("game", "text_scale", text_scale)
	config.set_value("game", "easy_mode", easy_mode)
	config.set_value("audio", "music_volume", music_volume)
	config.set_value("audio", "sfx_volume", sfx_volume)
	config.save(CONFIG_PATH)


func apply_volume() -> void:
	# Bus "Music" dan "SFX" dibuat di Fase 2 (default_bus_layout.tres)
	for bus_name in ["Music", "SFX"]:
		var index := AudioServer.get_bus_index(bus_name)
		if index < 0:
			continue
		var volume := music_volume if bus_name == "Music" else sfx_volume
		AudioServer.set_bus_volume_db(index, linear_to_db(volume))
