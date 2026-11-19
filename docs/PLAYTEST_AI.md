# Duel dasar melawan AI

Jalankan `res://scene/tests/battle_test.tscn` dengan F6.

1. Pilih Jana di tangan dan klik Mainkan Kartu. AI membayar untuk memainkan unitnya.
2. Saat Panji milikmu, pilih unit Bench bawah dan klik Serang. AI memilih blocker.
3. Klik Pass pada respons combat. Setelah dua Pass, damage diterapkan.
4. Pass pada fase aksi hingga ronde berikutnya. Saat Panji musuh, AI dapat menyerang.
5. Ketika diserang, pilih unit Bench bawah dan Konfirmasi Block, atau Tanpa Block.
6. Selesaikan respons dengan Pass. Reset mengulang pertandingan dari awal.

Pemain 0 = manusia, pemain 1 = AI. Kedua Bench mulai kosong. Pemilihan blocker
musuh tidak lagi dikendalikan melalui klik pengguna. AI memprioritaskan serangan
satu unit, lalu memainkan unit terjangkau pertama, dan akhirnya Pass. Blocker
yang sudah digunakan dilewati. Semua aksi AI melewati RulesEngine yang sama.

## Batas tahap saat ini

- Ronde masih dibatasi sampai 6 untuk pengujian; belum ada overtime.
- Serangan dan block masih satu pasangan; Mantra, Lokasi, dan Warisan belum tersedia.
- Damage dan Heal adalah tombol uji, bukan aksi pertandingan normal.
- Deck lawan masih memakai definisi Anoman/Jana latihan yang sama.
- AI bergerak langsung tanpa jeda animasi dan belum menilai strategi.

## Tes tanpa UI

Dari folder project, dengan executable Godot tersedia di PATH:

```powershell
godot --headless --path . --script res://tests/test_base_classes.gd
godot --headless --path . --script res://tests/test_round_system.gd
godot --headless --path . --script res://tests/test_ai_battle.gd
```

Tes AI menggunakan scene dan signal asli untuk menguji deploy, pembayaran,
block dua pihak, damage simultan, discard kedua pihak, serangan tanpa blocker,
hasil menang/kalah, pencegahan aksi setelah game over, dan Reset.
