extends SceneTree
## Smoke test: memuat semua scene, resource, dan skrip proyek, membuat instance tiap scene,
## lalu memeriksa teks id/en. Kode keluar 1 jika ada resource/skrip yang gagal dimuat
## ATAU Godot mencatat error (ERROR / SCRIPT ERROR) selama pemeriksaan.
## Jalankan dari folder proyek:
##   godot --headless --path . --script tools/smoke_test.gd


const EXTENSIONS := [".tscn", ".tres", ".gd"]
const SKIP_DIRS := [".godot", ".git", "tools"]
## Scene yang butuh node induk khusus sehingga tidak ikut di-instantiate sendirian.
const SKIP_INSTANTIATE := ["res://main.tscn", "res://world.tscn"]


## Penghitung error dari log Godot (Logger tersedia sejak Godot 4.5).
class ErrorCounter extends Logger:
	var count := 0
	var messages:PackedStringArray = []

	func _log_error(function:String, file:String, line:int, code:String, rationale:String, editor_notify:bool, error_type:int, script_backtraces:Array[ScriptBacktrace]) -> void:
		# Peringatan (WARNING) tidak dihitung; hanya ERROR dan SCRIPT ERROR.
		if error_type == ERROR_TYPE_WARNING:
			return
		count += 1
		messages.append("%s:%d %s %s" % [file, line, code, rationale])


var errors := 0
var counter := ErrorCounter.new()


func _initialize() -> void:
	OS.add_logger(counter)
	var count := 0
	for path in collect("res://"):
		count += 1
		check_file(path)
	print("smoke_test: %d file diperiksa, %d gagal" % [count, errors])
	check_translations()
	OS.remove_logger(counter)
	for message in counter.messages:
		printerr("LOG ERROR: ", message)
	errors += counter.count
	print("smoke_test: %d error total (termasuk log Godot)" % errors)
	quit(1 if errors else 0)


func check_file(path:String) -> void:
	var resource := ResourceLoader.load(path)
	if resource == null:
		printerr("GAGAL memuat: ", path)
		errors += 1
		return
	# Skrip yang salah sintaks/tipe: load() mengembalikan null dan Logger menghitung ERROR-nya.
	# (reload() tidak dipakai: ditolak untuk skrip autoload yang sudah punya instance.)
	if resource is PackedScene and path not in SKIP_INSTANTIATE:
		var node = resource.instantiate()
		if node == null:
			printerr("GAGAL instantiate: ", path)
			errors += 1
		else:
			node.free()


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
