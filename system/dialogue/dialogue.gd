extends Node
## Sistem dialog: kotak teks, faceset, emote, pilihan, kondisi flag. Diisi penuh di butir Dialog (Fase 2).

signal started(dialog_id:String)
signal finished(dialog_id:String)

var active := false
var last_finished_msec := 0


## True selama dialog berjalan dan sesaat setelahnya (mencegah tombol interaksi yang sama terpakai dua kali).
func is_busy() -> bool:
	return active or Time.get_ticks_msec() - last_finished_msec < 250
