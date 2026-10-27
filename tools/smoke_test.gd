extends SceneTree
## Smoke test: memuat semua scene, resource, dan skrip proyek lalu memeriksa teks id/en.
## Jalankan dari folder proyek:
##   godot --headless --path . --script tools/smoke_test.gd
## Kode keluar 1 jika ada resource yang gagal dimuat.


const EXTENSIONS := [".tscn", ".tres", ".gd"]
const SKIP_DIRS := [".godot", ".git", "tools"]

var errors := 0


func _initialize() -> void:
	var count := 0
	for path in collect("res://"):
		count += 1
		if ResourceLoader.load(path) == null:
			printerr("GAGAL memuat: ", path)
			errors += 1
	print("smoke_test: %d file dimuat, %d gagal" % [count, errors])
	check_translations()
	quit(1 if errors else 0)


func collect(dir_path:String) -> PackedStringArray:
	var result := PackedStringArray()
	var dir := DirAccess.open(dir_path)
	if !dir:
		return result
	for sub_dir in dir.get_directories():
		if sub_dir in SKIP_DIRS:
			continue
		result.append_array(collect(dir_path.path_join(sub_dir)))
	for file in dir.get_files():
		for extension in EXTENSIONS:
			if file.ends_with(extension):
				result.append(dir_path.path_join(file))
	return result


func check_translations() -> void:
	# Autoload belum tentu aktif pada mode --script; periksa file JSON secara langsung.
	for code in ["id", "en"]:
		var path := "res://translations/ui.%s.json" % code
		var data = JSON.parse_string(FileAccess.get_file_as_string(path))
		if typeof(data) != TYPE_DICTIONARY or not data.has("TITLE_GAME"):
			printerr("Teks ", code, " tidak valid: ", path)
			errors += 1
