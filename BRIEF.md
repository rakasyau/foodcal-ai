# BRIEF: Bangun aplikasi Flutter FoodCal AI

Kamu bekerja di folder proyek Flutter yang sudah dibuat (`aplikasi_foodcal`). Tugasmu: mengimplementasikan aplikasi lengkap sesuai dua dokumen acuan dan aset yang sudah tersedia di folder ini.

## Berkas acuan (wajib dibaca lebih dulu)

- `docs/PRD.md` — kebutuhan fungsional FR-01 sampai FR-19, model data, arsitektur, kriteria penerimaan.
- `docs/design-spec.md` — token warna, tipografi, dan teks persis tiap layar hasil ekstraksi mockup.

## Aset yang sudah ada (jangan dihapus, jangan dibuat ulang)

- `assets/models/efficientnet_fp16.tflite` (9,67 MB) — model utama.
- `assets/models/mobilenetv3_fp16.tflite` (2,77 MB) — model hemat.
- `assets/data/foodcal.db` (32 KB) — basis data siap pakai, sudah berisi 32 baris `kelas_makanan` dan tabel `log_makan`, `pengaturan`, indeks `idx_log_tanggal`.

Skema `foodcal.db`:

```sql
kelas_makanan(id INTEGER PK, kode TEXT, nama_id TEXT, nama_en TEXT, kelompok TEXT,
              kkal_100g REAL, protein_g REAL, lemak_g REAL, kh_g REAL, serat_g REAL,
              porsi_ref_g REAL, gram_per_cm2 REAL, sumber TEXT)
log_makan(id INTEGER PK AUTOINCREMENT, kelas_id INTEGER, nama_snapshot TEXT, porsi_g REAL,
          kalori REAL, protein_g REAL, lemak_g REAL, kh_g REAL, keyakinan REAL,
          waktu TEXT, tanggal TEXT, sumber_foto TEXT, dibuat_pada TEXT)
pengaturan(kunci TEXT PK, nilai TEXT)
```

`kelas_makanan.id` 0 sampai 31 sama persis dengan urutan keluaran model. Jangan mengubah urutan ini.

## Kontrak inferensi (paling mudah salah, ikuti persis)

- Input tensor: `[1, 224, 224, 3]`, **float32**, nilai **0 sampai 255**. Normalisasi sudah ada di dalam graf. Jangan membagi 255.
- Praproses: ambil citra RGB, potong persegi di tengah (`center crop`, sisi = min(lebar, tinggi)), ubah ukuran ke 224 x 224 dengan interpolasi bikubik, ubah ke float32, susun menjadi `[1, 224, 224, 3]`.
- Output: `[1, 32]` float32, sudah softmax. `argmax` = `kelas_makanan.id`.
- Ambang keyakinan bawaan 0,60 diambil dari tabel `pengaturan`; bila probabilitas tertinggi di bawah ambang, tampilkan layar "Belum Dikenali", jangan simpan.
- Inferensi harus berjalan di isolate terpisah (`Isolate.run`) agar UI tidak membeku.

Sudah diuji di Python: dengan input 0 sampai 255 model memberi 40/40 benar pada 40 citra uji; dengan input 0 sampai 1 hasilnya 0/40. Kesalahan skala ini fatal, jangan diubah.

## Dependensi yang perlu ditambahkan

`flutter_riverpod`, `sqflite`, `path`, `path_provider`, `tflite_flutter`, `image`, `fl_chart`, `google_fonts`, `share_plus`, `intl`, `camera`, `image_picker`.

## Struktur yang diharapkan

```
lib/
  main.dart
  app/app.dart, app/router.dart, app/theme.dart (token dari design-spec)
  core/formatter.dart (angka ribuan Indonesia, tanggal, jam)
  data/db.dart (salin aset, buka, migrasi), data/kelas_dao.dart, data/log_dao.dart, data/pengaturan_dao.dart
  domain/kalkulator_gizi.dart, domain/model.dart (KelasMakanan, EntriLog, HasilPrediksi), domain/rekap.dart
  services/inferensi_service.dart, services/praproses.dart, services/ekspor_csv.dart
  features/onboarding/, features/beranda/, features/kamera/, features/hasil/, features/catatan/, features/pengaturan/, features/profil/
```

## Layar yang wajib ada (teks persis mengikuti design-spec)

Onboarding, Beranda, Kamera, Memproses, Hasil, Belum Dikenali, Izin Kamera Ditolak, Catatan Harian (termasuk keadaan kosong), Ubah Entri, Konfirmasi Hapus, Pengaturan, Profil, Grafik. Dukung tema terang dan gelap mengikuti sistem.

Poin perilaku penting:

1. Tombol `Simpan ke Catatan` menulis satu baris ke `log_makan`; **tidak ada kolom foto dan tidak ada berkas gambar yang ditulis**. Setelah simpan, tampilkan SnackBar dengan aksi "Lihat Catatan".
2. Penggeser porsi pada layar Hasil mengubah kalori dan makro seketika, batas 50 sampai 300 gram, nilai awal `porsi_ref_g`.
3. Beranda menghitung total dan sisa kalori dari `SUM` per `tanggal` hari ini, bukan dari state sementara.
4. Menghapus entri memakai dialog konfirmasi yang menyebut nama, kalori, dan total baru.
5. Ekspor CSV membuat berkas di direktori sementara lalu membagikannya lewat `share_plus`.
6. TTA cermin (opsional, dibaca dari `pengaturan`): jalankan inferensi dua kali, citra asli dan citra dicerminkan, lalu rata-ratakan probabilitas.
7. Semua teks antarmuka berbahasa Indonesia. Jangan memakai tanda pisah panjang (em dash) atau tanda kutip melengkung.

## Android

- Tambahkan izin `CAMERA`. Jangan tambahkan izin `INTERNET`.
- `minSdk` minimal 26. Aktifkan `android:extractNativeLibs` bila perlu untuk tflite.
- Nama aplikasi: FoodCal AI.

## Kriteria selesai (wajib dipenuhi sebelum berhenti)

1. `flutter analyze` tidak menghasilkan error maupun warning (info diperbolehkan, maksimal 5).
2. `flutter test` lulus. Tulis uji unit untuk: perhitungan kalori dan makro, pembulatan tampilan, batas porsi, rekap harian (SUM), format tanggal dan jam, dan praproses (bentuk keluaran `[1,224,224,3]` dengan rentang 0 sampai 255).
3. Aplikasi dapat dikompilasi: `flutter build apk --debug` bila Android SDK tidak tersedia, cukup pastikan `flutter analyze` dan `flutter test` lulus.
4. Tidak ada TODO yang menggantung pada fitur wajib.

## Cara menjalankan perintah

Flutter ada di `C:\Users\rakas\flutter-sdk\flutter\bin\flutter.bat`. Bila `flutter` tidak dikenali di shell, panggil dengan path lengkap tersebut.

Bekerjalah sampai kriteria selesai terpenuhi, lalu laporkan: berkas yang dibuat, hasil `flutter analyze`, hasil `flutter test`, dan bagian yang belum selesai bila ada.
