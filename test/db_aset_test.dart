import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:foodcal_ai/data/db.dart';
import 'package:foodcal_ai/data/kelas_dao.dart';
import 'package:foodcal_ai/data/log_dao.dart';
import 'package:foodcal_ai/data/pengaturan_dao.dart';
import 'package:foodcal_ai/domain/model.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  sqfliteFfiInit();

  late Directory folder;
  late AppDatabase basisData;

  setUp(() async {
    folder = await Directory.systemTemp.createTemp('foodcal_uji_');
    final salinan = File(p.join(folder.path, AppDatabase.namaBerkas));
    await File(AppDatabase.jalurAset).copy(salinan.path);
    basisData = await AppDatabase.buka(
      factory: databaseFactoryFfi,
      path: salinan.path,
      salinAset: false,
    );
  });

  tearDown(() async {
    await basisData.tutup();
    await folder.delete(recursive: true);
  });

  test('aset basis data terbaca dengan 33 kelas berurutan', () async {
    final kelas = await KelasDao(basisData.db).semua();
    expect(kelas.length, 33);
    expect(kelas.first.id, 0);
    expect(kelas.first.namaId, 'Ayam Goreng');
    expect(kelas.last.id, 32);
    expect(kelas.last.kode, 'nasi_putih');
    final nasiGoreng = kelas.firstWhere((k) => k.kode == 'nasi_goreng');
    expect(nasiGoreng.namaId, 'Nasi Goreng');
    expect(nasiGoreng.porsiRefG, 250);
    final nasiPutih = kelas.firstWhere((k) => k.kode == 'nasi_putih');
    expect(nasiPutih.namaId, 'Nasi Putih');
    expect(nasiPutih.kkal100g, 180);
    expect(nasiPutih.porsiRefG, 150);
    final friedRice = kelas.firstWhere((k) => k.kode == 'fried_rice');
    expect(friedRice.id, 8);
  });

  test('pengaturan bawaan tersedia setelah migrasi', () async {
    final pengaturan = await PengaturanDao(basisData.db).ambil();
    expect(pengaturan.targetKalori, 2000);
    expect(pengaturan.ambangKeyakinan, closeTo(0.60, 0.0001));
    expect(pengaturan.ttaAktif, isFalse);
    expect(pengaturan.modelAktif, 'efficientnet_fp16');
    expect(pengaturan.onboardingSelesai, isFalse);
  });

  test(
    'entri tetap ada setelah basis data ditutup dan dibuka kembali',
    () async {
      final waktu = DateTime(2026, 10, 28, 12, 30);
      await LogDao(basisData.db).simpan(
        EntriLog(
          kelasId: 16,
          namaSnapshot: 'Nasi Goreng',
          porsiG: 250,
          kalori: 473.5,
          proteinG: 11.5,
          lemakG: 16,
          khG: 68.25,
          keyakinan: 0.92,
          waktu: waktu,
          tanggal: '2026-10-28',
          sumberFoto: 'kamera',
          dibuatPada: waktu,
        ),
      );
      await basisData.tutup();
      basisData = await AppDatabase.buka(
        factory: databaseFactoryFfi,
        path: p.join(folder.path, AppDatabase.namaBerkas),
        salinAset: false,
      );
      final rekap = await LogDao(basisData.db).rekap('2026-10-28');
      expect(rekap.kalori, closeTo(473.5, 0.0001));
      expect(rekap.jumlahEntri, 1);
    },
  );
  test('versi skema dan indeks tanggal sesuai', () async {
    final versi = await basisData.db.rawQuery('PRAGMA user_version');
    expect(versi.first['user_version'], AppDatabase.versiSkema);
    final indeks = await basisData.db.rawQuery(
      "SELECT name FROM sqlite_master WHERE type = 'index' AND name = 'idx_log_tanggal'",
    );
    expect(indeks, isNotEmpty);
  });

  test('kelas membawa satuan alami', () async {
    final kelas = await KelasDao(basisData.db).semua();
    final sate = kelas.firstWhere((k) => k.kode == 'sate');
    expect(sate.satuan, 'tusuk');
    expect(sate.gramPerSatuan, 15);
    final nasiGoreng = kelas.firstWhere((k) => k.kode == 'nasi_goreng');
    expect(nasiGoreng.satuan, 'porsi');
  });

  test('entri koreksi menyimpan kelas prediksi dan penanda', () async {
    final waktu = DateTime(2026, 10, 29, 12, 0);
    final dao = LogDao(basisData.db);
    await dao.simpan(
      EntriLog(
        kelasId: 29,
        kelasPrediksiId: 16,
        dikoreksi: true,
        sumberPrediksi: 'koreksi',
        namaSnapshot: 'Sushi',
        porsiG: 150,
        kalori: 220,
        proteinG: 9,
        lemakG: 4,
        khG: 38,
        keyakinan: 0.44,
        waktu: waktu,
        tanggal: '2026-10-29',
        sumberFoto: 'kamera',
        dibuatPada: waktu,
      ),
    );
    final entri = await dao.perTanggal('2026-10-29');
    expect(entri.single.kelasPrediksiId, 16);
    expect(entri.single.dikoreksi, isTrue);
    expect(entri.single.sumberPrediksi, 'koreksi');
  });

  test('migrasi versi 1 ke 2 mempertahankan entri lama', () async {
    final folderLama = await Directory.systemTemp.createTemp('foodcal_v1_');
    final jalur = p.join(folderLama.path, 'lama.db');
    final lama = await databaseFactoryFfi.openDatabase(
      jalur,
      options: OpenDatabaseOptions(version: 1),
    );
    await lama.execute('''
      CREATE TABLE kelas_makanan (
        id INTEGER PRIMARY KEY,
        kode TEXT NOT NULL UNIQUE,
        nama_id TEXT NOT NULL,
        nama_en TEXT NOT NULL,
        kelompok TEXT NOT NULL,
        kkal_100g REAL NOT NULL,
        protein_g REAL NOT NULL,
        lemak_g REAL NOT NULL,
        kh_g REAL NOT NULL,
        serat_g REAL DEFAULT 0,
        porsi_ref_g REAL NOT NULL,
        gram_per_cm2 REAL,
        sumber TEXT
      )
    ''');
    await lama.execute('''
      CREATE TABLE log_makan (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        kelas_id INTEGER NOT NULL,
        nama_snapshot TEXT NOT NULL,
        porsi_g REAL NOT NULL,
        kalori REAL NOT NULL,
        protein_g REAL NOT NULL,
        lemak_g REAL NOT NULL,
        kh_g REAL NOT NULL,
        keyakinan REAL NOT NULL,
        waktu TEXT NOT NULL,
        tanggal TEXT NOT NULL,
        sumber_foto TEXT NOT NULL DEFAULT 'kamera',
        dibuat_pada TEXT NOT NULL
      )
    ''');
    await lama.execute('''
      CREATE TABLE pengaturan (kunci TEXT PRIMARY KEY, nilai TEXT NOT NULL)
    ''');
    await lama.insert('kelas_makanan', {
      'id': 16,
      'kode': 'nasi_goreng',
      'nama_id': 'Nasi Goreng',
      'nama_en': 'Nasi Goreng',
      'kelompok': 'Indonesia',
      'kkal_100g': 189.4,
      'protein_g': 4.6,
      'lemak_g': 6.4,
      'kh_g': 27.3,
      'porsi_ref_g': 250,
    });
    await lama.insert('kelas_makanan', {
      'id': 25,
      'kode': 'sate',
      'nama_id': 'Sate',
      'nama_en': 'Sate',
      'kelompok': 'Indonesia',
      'kkal_100g': 254.9,
      'protein_g': 12.5,
      'lemak_g': 20.6,
      'kh_g': 6.1,
      'porsi_ref_g': 150,
    });
    await lama.insert('log_makan', {
      'kelas_id': 16,
      'nama_snapshot': 'Nasi Goreng',
      'porsi_g': 250,
      'kalori': 473.5,
      'protein_g': 11.5,
      'lemak_g': 16,
      'kh_g': 68.25,
      'keyakinan': 0.9,
      'waktu': '2026-10-27T12:00:00.000',
      'tanggal': '2026-10-27',
      'dibuat_pada': '2026-10-27T12:00:00.000',
    });
    await lama.setVersion(1);
    await lama.close();

    final naik = await AppDatabase.buka(
      factory: databaseFactoryFfi,
      path: jalur,
      salinAset: false,
    );
    final entri = await LogDao(naik.db).perTanggal('2026-10-27');
    expect(entri.single.namaSnapshot, 'Nasi Goreng');
    expect(entri.single.dikoreksi, isFalse);
    final daftarKelas = await KelasDao(naik.db).semua();
    final nasiGoreng = daftarKelas.firstWhere((k) => k.kode == 'nasi_goreng');
    expect(nasiGoreng.satuan, 'porsi');
    expect(nasiGoreng.gramPerSatuan, 250);
    final sate = daftarKelas.firstWhere((k) => k.kode == 'sate');
    expect(sate.satuan, 'tusuk');
    expect(sate.gramPerSatuan, 15);
    await naik.tutup();
    await folderLama.delete(recursive: true);
  });

  test('pengaturan porsiUntukKelas dan batas targetKalori aman', () async {
    final dao = PengaturanDao(basisData.db);
    expect(await dao.porsiUntukKelas(16, 250), 250);
    await dao.set(KunciPengaturan.porsiKelas(16), '180');
    expect(await dao.porsiUntukKelas(16, 250), 180);

    await dao.set(KunciPengaturan.targetKalori, '100');
    expect((await dao.ambil()).targetKalori, 800);
    await dao.set(KunciPengaturan.targetKalori, '99999');
    expect((await dao.ambil()).targetKalori, 6000);
    await dao.set(KunciPengaturan.targetKalori, '-50');
    expect((await dao.ambil()).targetKalori, 2000);
  });

  test('entri manual tanpa kelas tetap masuk rekap harian', () async {
    final waktu = DateTime(2026, 10, 29, 8, 15);
    final dao = LogDao(basisData.db);
    await dao.simpan(
      EntriLog(
        kelasId: null,
        namaSnapshot: 'Nasi uduk',
        porsiG: 250,
        kalori: 380,
        proteinG: 0,
        lemakG: 0,
        khG: 0,
        keyakinan: 0,
        waktu: waktu,
        tanggal: '2026-10-29',
        sumberFoto: 'manual',
        dibuatPada: waktu,
        sumberPrediksi: 'manual',
      ),
    );
    final entri = await dao.perTanggal('2026-10-29');
    expect(entri.single.kelasId, isNull);
    expect(entri.single.dicatatManual, isTrue);
    final rekap = await dao.rekap('2026-10-29');
    expect(rekap.kalori, closeTo(380, 0.0001));
  });
}
