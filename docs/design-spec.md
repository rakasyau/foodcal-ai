# Spesifikasi Desain FoodCal AI
Sumber: `FoodCal AI — Desain UI UX.html` (17 layar, terurai dari mockup). Dokumen ini adalah acuan implementasi Flutter.

## Token warna

| Token | Terang | Gelap | Pemakaian |
|---|---|---|---|
| `bg` | `#FAF9F5` | `#0E0E0E` | Latar halaman |
| `surface` | `#FFFFFF` | `#1A1A1A` | Kartu |
| `surfaceAlt` | `#F2F2F2` | `#2A2A2A` | Chip, ikon, bidang sekunder |
| `ink` | `#1A1A1A` | `#F5F5F5` | Teks utama, kartu grafik, tombol utama |
| `inkSoft` | `#5F5F5F` | `#B5B5B5` | Teks sekunder |
| `muted` | `#A3A3A3` | `#8A8A8A` | Label kecil, sumbu |
| `line` | `#D9D9D9` | `#2A2A2A` | Garis pemisah |
| `accent` | `#D6382F` | `#FF8A80` | Aksi utama, kemajuan, kelebihan kalori |
| `accentDark` | `#C0322B` | `#D6382F` | Keadaan ditekan |
| `maroon` | `#2A1215` | `#2A1215` | Kartu grafik gelap, teks pada aksen terang |
| `maroonSoft` | `#5C2B2E` | `#5C2B2E` | Kartu gelap sekunder |

Huruf: **Poppins** (Google Fonts), angka memakai `tabular` agar tidak bergeser.

## Skala tipografi

| Peran | Ukuran | Bobot |
|---|---|---|
| Angka utama | 44 | 700 |
| Judul layar | 20 | 600 |
| Judul seksi | 14 | 600 |
| Isi | 14 | 400 |
| Label kecil | 12 | 400 |
| Angka daftar | 14 | 600 |

Radius: kartu besar 24, kartu kecil 16, chip dan tombol pill 999. Margin halaman 20. Jarak antar kartu 12.

## Teks dan isi tiap layar

### Beranda
`Halo, Raka` · angka besar `1.240` · `kkal hari ini · target 2.000` · cincin `62%` · kartu hitam `7 hari terakhir` + `9.840 kkal` + sumbu `Kam Jum Sab Min Sen Sel Rab` · chip `Hari Ini / 7 Hari / 30 Hari` · `Catatan Hari Ini` + `Lihat semua` · baris: `Gado-gado`, `Porsi 250 g · 15.10`, `- 452 kkal`; `Nasi Goreng`, `Porsi 250 g · 12.30`, `- 468 kkal`; `Soto Ayam`, `Porsi 300 g · 07.45`, `- 320 kkal`.

### Hasil
`Pratinjau foto (tidak disimpan)` · `Nasi Goreng` · `92% yakin` · `Masakan Indonesia · porsi referensi 250 g` · `468` + `kkal` + `perkiraan` · tiga kolom `Protein 21 g`, `Lemak 18 g`, `Karbo 55 g` · `Porsi` `250 g` dengan tombol `−` `+` dan batas `50 g` sampai `300 g` · tombol utama `Simpan ke Catatan` · tombol sekunder `Foto Ulang`.

### Catatan & Grafik
`Catatan Harian` · aksi `Ekspor CSV` · chip `Hari Ini / 7 Hari / 30 Hari` · `Target 2.000` · grafik batang `Kam Jum Sab Min Sen Sel Rab` · ringkasan `1.240` `kkal · P 54 g · L 41 g · K 148 g` · `Riwayat` · baris dengan aksi `Ubah` dan `Hapus` · tab bawah `Grafik`.

### Belum Dikenali
Ikon `?` · `Makanan belum dikenali` · `Keyakinan model hanya 41%, di bawah ambang 60%. Coba foto dari atas piring dengan cahaya yang cukup.` · `Foto Ulang` · `Pilih dari Galeri` · `Foto tidak disimpan dan tidak diunggah.`

### Kamera
`Kamera` · `Letakkan satu makanan di dalam bingkai` · bingkai pemandu · tombol jepret · `Galeri`.

### Onboarding
`Atur target kalori harianmu` · `Foto makananmu dianalisis di ponsel, tanpa internet. Foto tidak pernah disimpan atau diunggah.` · `Target kalori per hari` + `kkal` · `Model pengenal makanan`: `Bawaan` `EfficientNet-B0 · 9,67 MB · akurasi 0,90`, `Hemat` `MobileNetV3 · 2,77 MB · RAM di bawah 3 GB` · `Simpan dan Mulai`.

### Pengaturan
`Pengaturan` · `Target kalori harian` `Dapat diubah kapan saja` `2.000 kkal` · `Ambang keyakinan` `0,60` `Di bawah ambang, hasil ditolak` · `TTA cermin` `Lebih akurat, dua kali inferensi` · `Model aktif` `EfficientNet-B0 FP16 · 9,67 MB` `Bawaan` · `Ekspor catatan` `Bagikan sebagai berkas CSV` `CSV` · `Hapus semua data` `Perlu konfirmasi dua kali` · `FoodCal AI v1.0 · berjalan sepenuhnya luring`.

### Beranda Mode Gelap
Sama dengan Beranda, angka `2.120`, teks `Melebihi target 120 kkal`, cincin `106%`, kartu `10.720 kkal`.

### Catatan Kosong
`0` `kkal hari ini · target 2.000` · `Belum ada catatan hari ini` · `Foto makananmu, lalu simpan. Catatan muncul di sini.` · tombol `Buka Kamera`.

### Memproses
`Sedang menganalisis…` · `Batalkan`.

### Izin Kamera Ditolak
`Kamera belum bisa dipakai` · `Izin kamera ditolak. Nyalakan di pengaturan ponsel, atau pilih satu foto dari galeri tanpa memberi akses ke seluruh galeri.` · `Buka Pengaturan` · `Pilih dari Galeri`.

### Ubah Entri
`Ubah Entri` · `Gado-gado` · `Keyakinan 88% · dari kamera` · `452 kkal` · `Porsi` `250 g` dengan `−` `+` · `Waktu makan` `−` `15.10` `+` · `Simpan Perubahan` · `Batal`.

### Konfirmasi Hapus
`Hapus entri ini?` · `Gado-gado, 452 kkal pada 15.10 akan dihapus. Total hari ini berubah dari 1.240 menjadi 788 kkal.` · `Batal` · `Hapus`.

### Widget Layar Utama
`Sisa kalori hari ini` · `FoodCal AI` · `760 kkal` · `62%` · `1.240 / 2.000 kkal` · `Catat makanan`.

### Profil
`R` `Raka` `Data tersimpan hanya di ponsel ini` · `7 hari` `berturut-turut mencatat` · `Rata-rata 7 hari` `1.406 kkal` · `Target harian` `2.000 kkal` · `Saran target kalori` `Dari berat, tinggi, usia (opsional)` `Isi data` · `Pengaturan` `Model, ambang, TTA` · `Ekspor catatan (CSV)` · `Privasi` `Foto tidak disimpan, tanpa izin internet` · tab `Profil`.

## Catatan implementasi

- Navigasi bawah berbentuk pill mengambang dengan tiga tab (Beranda, Grafik, Profil) dan tombol bulat aksen di kanan untuk kamera.
- Kartu grafik memakai latar `maroon` atau `ink` dengan grid garis putus-putus dan label putih.
- Cincin kemajuan memakai `CircularProgressIndicator` kustom atau `CustomPainter` dengan gradien `accent` ke `#FF8A80`.
- Angka besar memakai `FontFeature.tabularFigures()`.
- Semua layar punya versi terang dan gelap; warna diambil dari token, jangan menulis kode warna langsung di widget.
