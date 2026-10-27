extends Node
## Sistem dialog berbasis data. Dialog ada di content/**/dialogs.json, penutur di
## content/characters/speakers.json, semua teks lewat kunci terjemahan (tidak ada teks di kode).
##
## Format satu dialog:
##   "id_dialog": { "lines": [ baris, ... ] }
## Satu baris (semua field opsional kecuali yang disebut):
##   "id": "label"               label untuk goto
##   "speaker": "arka"           kunci di speakers.json (kosong = narator tanpa faceset)
##   "text": "KUNCI_TEKS"        teks baris (boleh memakai {param})
##   "emote": "happy"            nama emote (assets/ui/emotes)
##   "condition": {...}          baris dilewati jika kondisi salah
##   "effects": [ {...} ]        dijalankan saat baris mulai tampil
##   "choices": [ {"text": "KUNCI", "goto": "label", "end": true, "effects": [...], "condition": {...}} ]
##   "goto": "label"             setelah baris ini lompat ke label (baris tanpa "text" = hanya lompat)
##   "end": true                 akhiri dialog setelah baris ini
## Kondisi: {"flag": "x"}, {"not_flag": "x"}, {"has_item": "x"}, {"all": [...]}, {"any": [...]}
## Efek: set_flag, clear_flag, give_item (+count), take_item, heal_all, hide_npc (+seconds), sfx, objective, autosave.


signal started(dialog_id:String)
signal finished(dialog_id:String)

const DIALOG_BOX_SCENE := preload("res://system/dialogue/dialog_box.tscn")
const SPEAKERS_PATH := "res://content/characters/speakers.json"
const CONTENT_DIR := "res://content"

var active := false
var last_finished_msec := 0
var dialogs := {}
var speakers := {}
var box:DialogBox
var skipping := false


func _ready() -> void:
	load_data()
	box = DIALOG_BOX_SCENE.instantiate()
	add_child(box)
	box.skip_requested.connect(func(): skipping = true)


func load_data() -> void:
	dialogs.clear()
	for path in find_files(CONTENT_DIR,"dialogs.json"):
		var data = JSON.parse_string(FileAccess.get_file_as_string(path))
		if typeof(data) != TYPE_DICTIONARY:
			push_error("Dialog tidak valid: %s" % path)
			continue
		for id in data:
			dialogs[id] = data[id]
	var speaker_data = JSON.parse_string(FileAccess.get_file_as_string(SPEAKERS_PATH))
	if typeof(speaker_data) == TYPE_DICTIONARY:
		speakers = speaker_data


func find_files(dir_path:String, file_name:String) -> PackedStringArray:
	var result := PackedStringArray()
	var dir := DirAccess.open(dir_path)
	if !dir:
		return result
	for sub_dir in dir.get_directories():
		result.append_array(find_files(dir_path.path_join(sub_dir),file_name))
	if dir.file_exists(file_name):
		result.append(dir_path.path_join(file_name))
	return result


## True selama dialog berjalan dan sesaat setelahnya (mencegah tombol interaksi yang sama terpakai dua kali).
func is_busy() -> bool:
	return active or Time.get_ticks_msec() - last_finished_msec < 250


## Jalankan dialog; selesai (await) ketika dialog ditutup.
func start(dialog_id:String, context := {}) -> void:
	if active:
		return
	var data:Dictionary = dialogs.get(dialog_id,{})
	if data.is_empty():
		push_error("Dialog tidak ditemukan: %s" % dialog_id)
		return
	begin(dialog_id)
	await run_lines(data.get("lines",[]),context.get("params",{}))
	end(dialog_id)


## Satu baris info singkat (mis. "Kamu mendapat 1 onigiri!") tanpa faceset.
func show_message(text_key:String, params := {}, speaker := "") -> void:
	if active:
		return
	begin("message")
	var line := {"text":text_key,"speaker":speaker}
	await run_lines([line],params)
	end("message")


func begin(dialog_id:String) -> void:
	active = true
	skipping = false
	started.emit(dialog_id)


func end(dialog_id:String) -> void:
	box.close()
	active = false
	last_finished_msec = Time.get_ticks_msec()
	finished.emit(dialog_id)


func run_lines(lines:Array, params:Dictionary) -> void:
	var labels := {}
	for i in lines.size():
		if lines[i].has("id"):
			labels[lines[i]["id"]] = i
	var index := 0
	while index >= 0 and index < lines.size():
		var line:Dictionary = lines[index]
		index += 1
		if line.has("condition") and !check_condition(line["condition"]):
			continue
		apply_effects(line.get("effects",[]))
		var next_label:String = line.get("goto","")
		var finish:bool = line.get("end",false)
		if line.has("text"):
			var choice_index := await present(line,params)
			if choice_index >= 0:
				var choice:Dictionary = visible_choices(line)[choice_index]
				apply_effects(choice.get("effects",[]))
				next_label = choice.get("goto","")
				finish = choice.get("end",false)
		if finish:
			return
		if next_label != "":
			if !labels.has(next_label):
				push_error("Label dialog tidak ditemukan: %s" % next_label)
				return
			index = labels[next_label]


func present(line:Dictionary, params:Dictionary) -> int:
	var choice_texts:Array[String] = []
	for choice in visible_choices(line):
		choice_texts.append(translate(choice["text"],params))
	if skipping and choice_texts.is_empty():
		return -1
	skipping = false
	return await box.show_line(speaker_info(line.get("speaker","")),translate(line["text"],params),line.get("emote",""),choice_texts)


func visible_choices(line:Dictionary) -> Array:
	var result := []
	for choice in line.get("choices",[]):
		if !choice.has("condition") or check_condition(choice["condition"]):
			result.append(choice)
	return result


func translate(key:String, params:Dictionary) -> String:
	var text := tr(key)
	return text.format(params) if !params.is_empty() else text


func speaker_info(speaker_id:String) -> Dictionary:
	if speaker_id == "" or !speakers.has(speaker_id):
		return {}
	var data:Dictionary = speakers[speaker_id]
	var info := {
		"name": tr(data.get("name","")) if data.get("name","") != "" else "",
		"voice": data.get("voice","voice2"),
		"pitch": data.get("pitch",1.0),
	}
	if data.get("faceset","") != "":
		info["faceset"] = load(data["faceset"])
	return info


func check_condition(condition:Dictionary) -> bool:
	if condition.has("flag") and !GameState.get_flag(condition["flag"]):
		return false
	if condition.has("not_flag") and GameState.get_flag(condition["not_flag"]):
		return false
	if condition.has("has_item") and GameState.count_item(condition["has_item"]) <= 0:
		return false
	if condition.has("all"):
		for sub in condition["all"]:
			if !check_condition(sub):
				return false
	if condition.has("any"):
		var any_true := false
		for sub in condition["any"]:
			any_true = any_true or check_condition(sub)
		if !any_true:
			return false
	return true


func apply_effects(effects:Array) -> void:
	for effect in effects:
		if effect.has("set_flag"):
			GameState.set_flag(effect["set_flag"],effect.get("value",true))
		if effect.has("clear_flag"):
			GameState.set_flag(effect["clear_flag"],false)
		if effect.has("give_item"):
			GameState.add_item(effect["give_item"],effect.get("count",1))
		if effect.has("take_item"):
			GameState.remove_item(effect["take_item"],effect.get("count",1))
		if effect.get("heal_all",false):
			GameState.heal_all()
			Audio.play_sfx("heal")
		if effect.has("hide_npc"):
			for npc in get_tree().get_nodes_in_group("npc_"+str(effect["hide_npc"])):
				npc.hide_for(effect.get("seconds",5.0))
		if effect.has("sfx"):
			Audio.play_sfx(effect["sfx"])
		if effect.has("objective"):
			Quests.set_objective(effect["objective"])
		if effect.get("autosave",false):
			SaveSystem.autosave()
