# Kurva Matematika — Puzzle Cerita Kelas 3–5 SD

> Usulan awal berdasarkan cakupan umum SD (Kurikulum Merdeka, fase B dan awal fase C). Perlu Anda cek; jika ada buku/kurikulum rujukan, saya sesuaikan.

## Prinsip
- Minimal **2 puzzle wajib per Act** + 1 **puzzle opsional** (side quest) yang memberi hadiah kecil. Target 30 soal untuk 10 Act.
- Setiap soal berbentuk **cerita di dalam dunia game** dan dipicu objek (peti berkode, katup, kasir, timer), bukan menu.
- **Kertas coretan** selalu tersedia. Tidak ada game over karena salah; ada umpan balik lucu, petunjuk 3 tingkat dari Bida, lalu penjelasan langkah.
- Satu soal = satu konsep utama; angka tidak lebih rumit dari tingkat kelas.
- Semua soal punya field `expr` yang dihitung ulang oleh `tools/validate_data.py`.
- Format angka mengikuti bahasa (ID `1.000,5`; EN `1,000.5`). Keypad menerima kedua gaya desimal.

## Kurva per Act

| Act | Kelas | Konsep | Contoh keterhubungan dengan cerita | Wajib / opsional |
|---|---|---|---|---|
| 1 | 3 | Perkalian dasar + penjumlahan; pengurangan 3 digit (meminjam); uang | Menghitung shuriken latihan; mangkuk ramen yang rusak; beli onigiri | 2 + 1 |
| 2 | 3 | Penjumlahan banyak bilangan; pembagian dasar dengan sisa; satuan volume (liter) | Liter air dari tiga pipa; membagi ember ke stan pasar | 2 + 1 |
| 3 | 3 | Satuan panjang dan berat (cm-m, g-kg); pola bilangan | Tinggi bambu; berat jamur; pola bambu bergerak | 2 + 1 |
| 4 | 3–4 | Uang dan kembalian; waktu (jam, menit); operasi campuran sederhana | Dango festival; jadwal kembang api | 2 + 1 |
| 5 | 4 | KPK/FPB sederhana; keliling dan luas persegi/persegi panjang | Kunci kombinasi arsip; ubin jebakan | 2 + 1 |
| 6 | 4 | Pecahan senilai dan penjumlahan pecahan penyebut sama; pembagian bersisa | Bagian desa yang listriknya pulih; membagi warga ke tempat perlindungan | 2 + 1 |
| 7 | 5 | Kecepatan-jarak-waktu; skala peta; perkalian bilangan besar | Panjang jembatan gantung; peta gunung | 2 + 1 |
| 8 | 5 | Rata-rata; perbandingan | Pola klon 3:2; rata-rata hit | 2 + 1 |
| 9 | 5 | Volume balok; pecahan desimal dan persen | Tangki energi; persentase inti | 2 + 1 |
| 10 | 5 | Gabungan bertingkat (operasi campuran, pembulatan, pecahan) | Tantangan inti terakhir dalam tiga langkah | 2 + 1 |

## Skema data puzzle
File `content/acts/actNN/puzzles.json` + teks `content/acts/actNN/actNN_puzzles.id.json` dan `.en.json`.

```json
{
  "id": "act01_peti_shuriken",
  "act": 1,
  "grade": 3,
  "topic": "perkalian",
  "text": "PUZ_ACT01_PETI_SHURIKEN_TEXT",
  "expr": "3*12+8",
  "answer": "44",
  "hints": ["..._HINT1", "..._HINT2", "..._HINT3"],
  "explanation": "..._EXPLAIN"
}
```

## Pemetaan interaksi (supaya matematika terasa bagian dari petualangan)
- **Peti/pintu berkode**: jawaban jadi kode.
- **Katup dan pipa**: hasil hitungan menentukan putaran katup.
- **Kasir/pedagang**: uang dan kembalian.
- **Timer festival**: waktu dan jadwal (dengan opsi tanpa tekanan waktu untuk anak yang butuh).
- **Peran tim**: Bida memberi petunjuk bertingkat, Farah menampilkan bantuan visual (gambar kotak/batang), Nadiya "membidik" jawaban pada soal pilihan angka.
