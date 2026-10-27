extends Node
## Simpan dan muat permainan ke user:// (di web tersimpan di IndexedDB browser).
## Format JSON berversi; migrasi dari versi lama ditambahkan di migrate().
## Slot 1 dipakai untuk simpan otomatis (pindah peta, dialog penting, bangun dari pingsan)
## dan tombol Simpan di menu jeda.


const SAVE_DIR := "user://saves"
const SLOT_COUNT := 3
const AUTOSAVE_SLOT := 1

signal saved(slot:int)


func slot_path(slot:int) -> String:
	return SAVE_DIR.path_join("slot_%d.json" % slot)


func has_save(slot := AUTOSAVE_SLOT) -> bool:
	return FileAccess.file_exists(slot_path(slot))


func save_game(slot := AUTOSAVE_SLOT) -> bool:
	var world := get_tree().get_first_node_in_group("world")
	if world and world.get("player") and is_instance_valid(world.player):
		GameState.player_position = world.player.global_position
	DirAccess.make_dir_recursive_absolute(SAVE_DIR)
	var file := FileAccess.open(slot_path(slot), FileAccess.WRITE)
	if !file:
		push_error("Gagal menyimpan ke slot %d" % slot)
		return false
	var data := GameState.to_dict()
	data["saved_at"] = Time.get_datetime_string_from_system()
	file.store_string(JSON.stringify(data, "\t"))
	saved.emit(slot)
	return true


## Simpan otomatis di slot 1 (hanya bila sedang bermain di dunia).
func autosave() -> void:
	if get_tree().get_first_node_in_group("world"):
		save_game(AUTOSAVE_SLOT)


func load_game(slot := AUTOSAVE_SLOT) -> bool:
	if !has_save(slot):
		return false
	var data = JSON.parse_string(FileAccess.get_file_as_string(slot_path(slot)))
	if typeof(data) != TYPE_DICTIONARY:
		push_error("Save slot %d rusak" % slot)
		return false
	GameState.from_dict(migrate(data))
	return true


func delete_save(slot := AUTOSAVE_SLOT) -> void:
	if has_save(slot):
		DirAccess.remove_absolute(slot_path(slot))


func migrate(data:Dictionary) -> Dictionary:
	# Versi 1 adalah format awal; belum ada yang perlu dimigrasi.
	return data
