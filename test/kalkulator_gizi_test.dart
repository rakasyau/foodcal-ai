import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:foodcal_ai/core/formatter.dart';
import 'package:foodcal_ai/domain/kalkulator_gizi.dart';
import 'package:foodcal_ai/domain/model.dart';
import 'package:foodcal_ai/domain/rekap.dart';
import 'package:foodcal_ai/features/piring/piring_page.dart';
import 'package:foodcal_ai/services/deteksi_service.dart';
import 'package:foodcal_ai/services/potong_citra.dart';
import 'package:image/image.dart' as img;

KelasMakanan _kelas() {
  return const KelasMakanan(
    id: 16,
    kode: 'nasi_goreng',
    namaId: 'Nasi Goreng',
    namaEn: 'Nasi Goreng',
    kelompok: 'Indonesia',
    kkal100g: 189.4,
    protein100g: 4.6,
    lemak100g: 6.4,
    kh100g: 27.3,
    serat100g: 0.2,
    porsiRefG: 250,
    gramPerCm2: 1.136,
    sumber: 'Komposit TKPI',
  );
}

void main() {
  group('perhitungan gizi', () {
    test('kalori dan makro mengikuti aturan per 100 gram', () {
      final gizi = hitungGizi(_kelas(), 250);
      expect(gizi.kalori, closeTo(473.5, 0.0001));
      expect(gizi.proteinG, closeTo(11.5, 0.0001));
      expect(gizi.lemakG, closeTo(16.0, 0.0001));
      expect(gizi.khG, closeTo(68.25, 0.0001));
    });

    test('porsi referensi menjadi nilai awal', () {
      expect(porsiAwal(_kelas()), 250);
    });

    test('hitung ulang proporsional saat porsi berubah', () {
      final entri = EntriLog(
        id: 1,
        kelasId: 16,
        namaSnapshot: 'Nasi Goreng',
        porsiG: 250,
        kalori: 473.5,
        proteinG: 11.5,
        lemakG: 16,
        khG: 68.25,
        keyakinan: 0.92,
        waktu: DateTime(2026, 10, 28, 12, 30),
        tanggal: '2026-10-28',
        sumberFoto: 'kamera',
        dibuatPada: DateTime(2026, 10, 28, 12, 30),
      );
      final gizi = hitungUlangProporsional(entri, 125);
      expect(gizi.kalori, closeTo(236.75, 0.0001));
      expect(gizi.proteinG, closeTo(5.75, 0.0001));
      expect(gizi.lemakG, closeTo(8, 0.0001));
      expect(gizi.khG, closeTo(34.125, 0.0001));
    });
  });

  group('batas porsi', () {
    test('porsi di bawah batas dinaikkan ke 50 gram', () {
      expect(batasiPorsi(10), 50);
    });

    test('porsi di atas batas diturunkan ke 600 gram', () {
      expect(batasiPorsi(900), 600);
    });

    test('geser porsi tetap di dalam batas', () {
      expect(geserPorsi(590, 10), 600);
      expect(geserPorsi(55, -10), 50);
      expect(geserPorsi(150, 10), 160);
    });

    test('nilai NaN jatuh ke batas bawah', () {
      expect(batasiPorsi(double.nan), 50);
    });
  });

  group('pembulatan tampilan', () {
    test('kalori dibulatkan ke bilangan bulat', () {
      expect(tampilkanKalori(467.6), 468);
      expect(formatKalori(467.4), '467');
    });

    test('makro dibulatkan ke bilangan bulat', () {
      expect(tampilkanMakro(20.6), 21);
      expect(formatGram(20.6), '21 g');
    });

    test('angka ribuan memakai titik', () {
      expect(formatRibuan(1240), '1.240');
      expect(formatRibuan(9840), '9.840');
      expect(formatRibuan(0), '0');
    });
  });

  group('preset porsi', () {
    test('tiga preset mengikuti porsi referensi', () {
      expect(porsiDariPreset(_kelas(), 0.5), 125);
      expect(porsiDariPreset(_kelas(), 1.0), 250);
      expect(porsiDariPreset(_kelas(), 1.5), 375);
    });

    test('preset besar tetap di bawah batas atas', () {
      final besar = porsiDariPreset(_kelasBesar(), 1.5);
      expect(besar, lessThanOrEqualTo(batasPorsiMax));
      expect(besar, 450);
    });

    test('preset aktif dikenali dari nilai porsi', () {
      expect(indeksPresetAktif(_kelas(), 125), 0);
      expect(indeksPresetAktif(_kelas(), 250), 1);
      expect(indeksPresetAktif(_kelas(), 375), 2);
    });

    test('porsi di luar preset dianggap atur manual', () {
      expect(indeksPresetAktif(_kelas(), 210), -1);
    });

    test('label satuan memakai porsi untuk nasi goreng', () {
      expect(labelSatuanPorsi(_kelas(), 250), '1 porsi');
      expect(labelSatuanPorsi(_kelas(), 125), '0,5 porsi');
    });

    test('label satuan memakai tusuk untuk sate dan koma untuk pecahan unit', () {
      expect(labelSatuanPorsi(_sate(), 30), '2 tusuk');
      expect(labelSatuanPorsi(_sate(), 15), '1 tusuk');
      expect(labelSatuanPorsi(_telurDadar(), 100), '1,7 butir');
    });
  });

  group('rekap rentetan dan rata-rata', () {
    test('rentetan tetap terjaga di pagi hari sebelum entri pertama dicatat', () {
      final tanggal = {'2026-10-27', '2026-10-26', '2026-10-25'};
      expect(hitungRentetan(tanggal, DateTime(2026, 10, 28, 7, 30)), 3);
      expect(
        hitungRentetan(
          {...tanggal, '2026-10-28'},
          DateTime(2026, 10, 28, 12, 0),
        ),
        4,
      );
      expect(hitungRentetan({'2026-10-25'}, DateTime(2026, 10, 28, 9, 0)), 0);
    });

    test('rataRataKalori hanya membagi dengan hari yang memiliki entri', () {
      final titik = lengkapiRentang(
        akhir: DateTime(2026, 10, 28),
        jumlahHari: 7,
        data: const [
          TitikHarian(
            tanggal: '2026-10-27',
            kalori: 1800,
            proteinG: 80,
            lemakG: 60,
            khG: 220,
            jumlahEntri: 3,
          ),
          TitikHarian(
            tanggal: '2026-10-28',
            kalori: 2200,
            proteinG: 95,
            lemakG: 70,
            khG: 260,
            jumlahEntri: 4,
          ),
        ],
      );
      expect(titik.length, 7);
      expect(rataRataKalori(titik), closeTo(2000, 0.0001));

      final kosongSemua = lengkapiRentang(
        akhir: DateTime(2026, 10, 28),
        jumlahHari: 7,
        data: const [],
      );
      expect(rataRataKalori(kosongSemua), 0);
    });
  });

  group('orientasi EXIF pada pemotongan citra', () {
    test('ukuranCitra dan potongBanyakWilayah menerapkan orientasi EXIF', () async {
      final asal = img.Image(width: 40, height: 20);
      asal.exif.imageIfd.orientation = 6; // rotasi 90 derajat searah jarum jam -> 20x40
      final jpeg = Uint8List.fromList(img.encodeJpg(asal, quality: 90));

      final ukuran = ukuranCitra(jpeg);
      expect(ukuran, (lebar: 20, tinggi: 40));

      final potongan = await potongBanyakWilayah(jpeg, const [
        KotakPiksel(0, 0, 20, 30),
      ]);
      expect(potongan.length, 1);
      final hasilDecode = img.decodeJpg(potongan.first);
      expect(hasilDecode, isNotNull);
      expect(hasilDecode!.height, greaterThan(hasilDecode.width));
    });
  });

  group('edge case gizi, deteksi YOLO, dan deduplikasi piring', () {
    test('hitungUlangProporsional menangani porsi asal <= 0 dan porsi baru tidak valid', () {
      final entriNol = EntriLog(
        id: 2,
        kelasId: null,
        namaSnapshot: 'Makanan Manual',
        porsiG: 0,
        kalori: 300,
        proteinG: 10,
        lemakG: 12,
        khG: 35,
        keyakinan: 0,
        waktu: DateTime(2026, 10, 28, 12, 0),
        tanggal: '2026-10-28',
        sumberFoto: 'manual',
        dibuatPada: DateTime(2026, 10, 28, 12, 0),
        sumberPrediksi: 'manual',
      );
      final tetap = hitungUlangProporsional(entriNol, batasPorsiMin);
      expect(tetap.kalori, closeTo(300, 0.0001));
      final duaKali = hitungUlangProporsional(entriNol, batasPorsiMin * 2);
      expect(duaKali.kalori, closeTo(600, 0.0001));
      expect(hitungUlangProporsional(entriNol, 0).kalori, 0);
      expect(hitungUlangProporsional(entriNol, double.nan).kalori, 0);
    });

    test('uraikanKeluaranDeteksi mendukung koordinat ternormalisasi dan bentuk terbalik', () {
      // Bentuk [jangkar=10, kanal=6] (terbalik) dengan koordinat ternormalisasi [0..1]
      final tensorTerbalik = List<List<double>>.generate(
        10,
        (j) => j == 0
            ? <double>[0.5, 0.5, 0.4, 0.4, 0.1, 0.85]
            : <double>[0, 0, 0, 0, 0, 0],
      );
      final hasil = uraikanKeluaranDeteksi(
        tensor2d: tensorTerbalik,
        ukuranInput: 512,
        lebarCitra: 512,
        tinggiCitra: 512,
        padKiri: 0,
        padAtas: 0,
        skala: 1.0,
        ambang: 0.25,
        iou: 0.45,
      );
      expect(hasil.length, 1);
      expect(hasil.single.kelas, 1);
      expect(hasil.single.skor, closeTo(0.85, 0.0001));
      expect(hasil.single.kotak.lebar, closeTo(205, 2));
      expect(hasil.single.kotak.tinggi, closeTo(205, 2));
    });

    test('gabungkanItemPiringUnik menggabungkan kelas duplikat dengan keyakinan tertinggi', () {
      final digabung = gabungkanItemPiringUnik([
        ItemPiring(
          kelas: _kelas(),
          keyakinan: 0.62,
          porsiG: 250,
          kelasPrediksiId: 16,
        ),
        ItemPiring(
          kelas: _kelas(),
          keyakinan: 0.89,
          porsiG: 250,
          kelasPrediksiId: 16,
        ),
        ItemPiring(
          kelas: _telurDadar(),
          keyakinan: 0.74,
          porsiG: 100,
          kelasPrediksiId: 31,
        ),
      ]);
      expect(digabung.length, 2);
      expect(digabung.first.kelas.id, 16);
      expect(digabung.first.keyakinan, closeTo(0.89, 0.0001));
      expect(digabung.last.kelas.id, 31);
    });
  });
}

KelasMakanan _telurDadar() {
  return const KelasMakanan(
    id: 31,
    kode: 'telur_dadar',
    namaId: 'Telur Dadar',
    namaEn: 'Omelette',
    kelompok: 'Indonesia',
    kkal100g: 251,
    protein100g: 16.3,
    lemak100g: 19.4,
    kh100g: 1.4,
    serat100g: 0,
    porsiRefG: 100,
    gramPerCm2: null,
    sumber: 'TKPI',
    satuan: 'butir',
    gramPerSatuan: 60,
  );
}

KelasMakanan _kelasBesar() {
  return const KelasMakanan(
    id: 8,
    kode: 'fried_rice',
    namaId: 'Fried Rice',
    namaEn: 'fried rice',
    kelompok: 'Internasional',
    kkal100g: 180,
    protein100g: 5,
    lemak100g: 6,
    kh100g: 26,
    serat100g: 1,
    porsiRefG: 300,
    gramPerCm2: 1.1,
    sumber: 'USDA',
  );
}

KelasMakanan _sate() {
  return const KelasMakanan(
    id: 25,
    kode: 'sate',
    namaId: 'Sate',
    namaEn: 'Sate',
    kelompok: 'Indonesia',
    kkal100g: 225,
    protein100g: 19,
    lemak100g: 15,
    kh100g: 5,
    serat100g: 0,
    porsiRefG: 150,
    gramPerCm2: 1.0,
    sumber: 'TKPI',
    satuan: 'tusuk',
    gramPerSatuan: 15,
  );
}
