extends Node
## Simpan dan muat permainan ke user:// (di web tersimpan di IndexedDB browser).
## Format JSON berversi; migrasi dari versi lama ditambahkan di migrate().


const SAVE_DIR := "user://saves"
const SLOT_COUNT := 3


func slot_path(slot:int) -> String:
	return SAVE_DIR.path_join("slot_%d.json" % slot)


func has_save(slot:int) -> bool:
	return FileAccess.file_exists(slot_path(slot))


func save_game(slot:int) -> bool:
	DirAccess.make_dir_recursive_absolute(SAVE_DIR)
	var file := FileAccess.open(slot_path(slot), FileAccess.WRITE)
	if !file:
		push_error("Gagal menyimpan ke slot %d" % slot)
		return false
	file.store_string(JSON.stringify(GameState.to_dict(), "\t"))
	return true


func load_game(slot:int) -> bool:
	if !has_save(slot):
		return false
	var data = JSON.parse_string(FileAccess.get_file_as_string(slot_path(slot)))
	if typeof(data) != TYPE_DICTIONARY:
		push_error("Save slot %d rusak" % slot)
		return false
	GameState.from_dict(migrate(data))
	return true


func delete_save(slot:int) -> void:
	if has_save(slot):
		DirAccess.remove_absolute(slot_path(slot))


func migrate(data:Dictionary) -> Dictionary:
	# Versi 1 adalah format awal; belum ada yang perlu dimigrasi.
	return data
