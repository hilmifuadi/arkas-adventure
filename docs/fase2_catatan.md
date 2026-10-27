# Catatan Fase 2 — Inti game

> Dokumen kerja untuk branch `fase-2-inti-game`: apa yang dibuat, keputusan desain, dan yang belum.
> Diperbarui setiap butir selesai.

## Butir 0 — Rapikan temuan Fase 0

- **`tools/smoke_test.gd`** sekarang keluar dengan kode 1 bila ada skrip/resource yang gagal
  dimuat **atau** Godot mencatat `ERROR` / `SCRIPT ERROR` selama pemeriksaan. Penghitung error
  memakai kelas `Logger` bawaan Godot 4.5+ (`OS.add_logger`), jadi tidak perlu mengurai log.
  Setiap `.tscn` juga di-*instantiate* sekali untuk menangkap skrip/sub-resource yang rusak.
  `GDScript.reload()` sengaja tidak dipakai: ditolak untuk skrip autoload yang sudah punya instance.
  Diuji dengan skrip rusak sengaja (`exit 1`) dan proyek bersih (`exit 0`).
- **`tools/check_all.py`** kini juga menjalankan smoke test bila Godot ditemukan
  (`tools/godot_path.py`: env `GODOT`, build bawaan di folder induk, atau `godot` di PATH).
- **`tools/capture.gd`**: pengambil screenshot sebuah scene (butuh jendela, bukan `--headless`):
  `godot --path . --script tools/capture.gd -- res://main.tscn 30 out.png`.
- **Spasi antarkata judul**: font piksel pack tidak punya lebar untuk karakter spasi, sehingga
  kata menempel. `theme/font_pixel.tres` (`FontVariation`, `spacing_space = 3`) kini menjadi font
  default `theme_1`. Ukuran font harus kelipatan 9 (9, 18, 27, 36) agar piksel tajam.
- **`content/team/neutral_team.tres`** memakai field lama (`team_name`, `enemy_team`) yang sudah
  tidak ada di `ResourceDamageTeam`; diganti ke `team = 0`, `ally_team = Array[int]([])`.
  Error `Cannot assign contents of "Array[Object]" to "Array[int]"` hilang.
- **Warning sub-emitter (diketahui, tidak diperbaiki):** saat `world.tscn` dijalankan di renderer
  Compatibility, Godot memberi dua warning:
  `Sub-emitter modes other than SUB_EMITTER_DISABLED are not supported in the Compatibility renderer`
  dan `The Compatibility renderer does not support particle sub-emitters`.
  Penyebabnya efek **hujan** (`Rain` → `RainOnFloor`) dan **salju** di `world.tscn` yang memakai
  sub-emitter. Dampak: percikan hujan di lantai tidak muncul; hujan dan salju tetap jatuh.
  Peta Act 1 cerah sehingga tidak terpengaruh. Opsi nanti (Fase 8): ganti percikan dengan
  partikel terpisah yang dipicu skrip, atau biarkan.
- Layar judul dipindah ke tata letak "layar virtual 320x180 diskalakan 4x" (pola yang sama dengan
  HUD sample), supaya font 9 px dan tombol tema kayu tampil jelas di 1280x720.
