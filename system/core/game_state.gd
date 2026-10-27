extends Node
## Kondisi permainan yang disimpan: Act berjalan, flag cerita, inventori, party, hati.
## Flag diberi nama stabil (mis. "act01_ayam_tertangkap") karena save lama harus
## tetap terbaca saat episode berikutnya dirilis.


signal flag_changed(flag:String, value:Variant)
signal inventory_changed(item:String, count:int)
signal hearts_changed

const SAVE_VERSION := 1
const HEARTS_NORMAL := 5
## Mode Santai memberi lebih banyak hati (lihat Settings.easy_mode).
const HEARTS_EASY := 8

var current_act := 1
var current_map := ""
var flags := {}
var inventory := {}
var party:Array[String] = ["arka"]
var hearts := 5
var hearts_max := 5


func reset() -> void:
	current_act = 1
	current_map = ""
	flags = {}
	inventory = {}
	party = ["arka"]
	hearts_max = max_hearts_for_mode()
	hearts = hearts_max
	hearts_changed.emit()


func max_hearts_for_mode() -> int:
	return HEARTS_EASY if Settings.easy_mode else HEARTS_NORMAL


## Dipanggil saat Mode Santai diubah: menambah/mengurangi wadah hati tanpa memulihkan paksa.
func refresh_hearts_max() -> void:
	var new_max := max_hearts_for_mode()
	hearts = clampi(hearts + (new_max - hearts_max), 1, new_max)
	hearts_max = new_max
	hearts_changed.emit()


func damage_hearts(amount := 1) -> void:
	hearts = maxi(hearts - amount, 0)
	hearts_changed.emit()


func heal_hearts(amount := 1) -> void:
	hearts = mini(hearts + amount, hearts_max)
	hearts_changed.emit()


## Dokter Zahra dan bangun dari pingsan: seluruh tim pulih penuh.
func heal_all() -> void:
	hearts = hearts_max
	hearts_changed.emit()


func set_flag(flag:String, value:Variant = true) -> void:
	if flags.get(flag) == value:
		return
	flags[flag] = value
	flag_changed.emit(flag, value)


func get_flag(flag:String, default:Variant = false) -> Variant:
	return flags.get(flag, default)


func add_item(item:String, count := 1) -> void:
	inventory[item] = count_item(item) + count
	inventory_changed.emit(item, inventory[item])


func remove_item(item:String, count := 1) -> bool:
	if count_item(item) < count:
		return false
	inventory[item] -= count
	if inventory[item] <= 0:
		inventory.erase(item)
	inventory_changed.emit(item, count_item(item))
	return true


func count_item(item:String) -> int:
	return inventory.get(item, 0)


func to_dict() -> Dictionary:
	return {
		"version": SAVE_VERSION,
		"current_act": current_act,
		"current_map": current_map,
		"flags": flags,
		"inventory": inventory,
		"party": party,
		"hearts": hearts,
		"hearts_max": hearts_max,
	}


func from_dict(data:Dictionary) -> void:
	reset()
	current_act = data.get("current_act", current_act)
	current_map = data.get("current_map", current_map)
	flags = data.get("flags", flags)
	inventory = data.get("inventory", inventory)
	party.assign(data.get("party", party))
	hearts_max = data.get("hearts_max", hearts_max)
	hearts = data.get("hearts", hearts_max)
	hearts_changed.emit()
