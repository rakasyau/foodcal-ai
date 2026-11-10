import 'dart:io';

import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

class AppDatabase {
  AppDatabase._(this.db);

  final Database db;

  static const int versiSkema = 2;
  static const String namaBerkas = 'foodcal.db';
  static const String jalurAset = 'assets/data/foodcal.db';

  static Future<AppDatabase> buka({
    DatabaseFactory? factory,
    String? path,
    bool salinAset = true,
  }) async {
    final pabrik = factory ?? databaseFactory;
    final jalurDb = path ?? await _siapkanJalur(pabrik, salinAset: salinAset);

    final basisData = await pabrik.openDatabase(
      jalurDb,
      options: OpenDatabaseOptions(
        version: versiSkema,
        onConfigure: (db) async {
          await db.execute('PRAGMA foreign_keys = ON');
          try {
            await db.rawQuery('PRAGMA journal_mode = WAL');
          } on DatabaseException {
            return;
          }
        },
        onCreate: _buatSkema,
        onUpgrade: _migrasi,
        onOpen: _pastikanDataKelasV2,
      ),
    );

    return AppDatabase._(basisData);
  }

  static Future<AppDatabase> bukaUntukUji(DatabaseFactory factory) {
    return buka(factory: factory, path: inMemoryDatabasePath, salinAset: false);
  }

  static Future<String> _siapkanJalur(
    DatabaseFactory factory, {
    required bool salinAset,
  }) async {
    final dokumen = await getApplicationDocumentsDirectory();
    final jalur = p.join(dokumen.path, namaBerkas);
    final berkas = File(jalur);
    final utuh =
        await factory.databaseExists(jalur) &&
        await berkas.exists() &&
        await berkas.length() > 4096;
    if (salinAset && !utuh) {
      final data = await rootBundle.load(jalurAset);
      await berkas.parent.create(recursive: true);
      final sementara = File('$jalur.tmp');
      await sementara.writeAsBytes(
        data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes),
        flush: true,
      );
      await sementara.rename(jalur);
    }
    return jalur;
  }

  static Future<void> _buatSkema(Database db, int versi) async {
    await _migrasi(db, 0, versi);
  }

  static Future<void> _migrasi(Database db, int dari, int ke) async {
    if (dari < 1) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS kelas_makanan (
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
          sumber TEXT,
          satuan TEXT NOT NULL DEFAULT 'porsi',
          gram_per_satuan REAL NOT NULL DEFAULT 0
        )
      ''');
      await db.execute('''
        CREATE TABLE IF NOT EXISTS log_makan (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          kelas_id INTEGER,
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
          dibuat_pada TEXT NOT NULL,
          kelas_prediksi_id INTEGER,
          dikoreksi INTEGER NOT NULL DEFAULT 0,
          sumber_prediksi TEXT NOT NULL DEFAULT 'model',
          FOREIGN KEY (kelas_id) REFERENCES kelas_makanan(id)
        )
      ''');
      await db.execute('''
        CREATE TABLE IF NOT EXISTS pengaturan (
          kunci TEXT PRIMARY KEY,
          nilai TEXT NOT NULL
        )
      ''');
      await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_log_tanggal ON log_makan(tanggal)',
      );
      await db.insert('pengaturan', {
        'kunci': 'target_kalori',
        'nilai': '2000',
      }, conflictAlgorithm: ConflictAlgorithm.ignore);
      await db.insert('pengaturan', {
        'kunci': 'ambang_keyakinan',
        'nilai': '0.60',
      }, conflictAlgorithm: ConflictAlgorithm.ignore);
      await db.insert('pengaturan', {
        'kunci': 'tta_aktif',
        'nilai': '0',
      }, conflictAlgorithm: ConflictAlgorithm.ignore);
      await db.insert('pengaturan', {
        'kunci': 'model_aktif',
        'nilai': 'efficientnet_fp16',
      }, conflictAlgorithm: ConflictAlgorithm.ignore);
      await db.insert('pengaturan', {
        'kunci': 'onboarding_selesai',
        'nilai': '0',
      }, conflictAlgorithm: ConflictAlgorithm.ignore);
    }

    if (dari >= 1 && dari < 2) {
      // Versi 2: satuan alami, koreksi kelas, dan pencatatan manual.
      await db.execute(
        "ALTER TABLE kelas_makanan ADD COLUMN satuan TEXT NOT NULL DEFAULT 'porsi'",
      );
      await db.execute(
        'ALTER TABLE kelas_makanan ADD COLUMN gram_per_satuan REAL NOT NULL DEFAULT 0',
      );

      await db.execute('''
        CREATE TABLE IF NOT EXISTS log_makan_v2 (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          kelas_id INTEGER,
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
          dibuat_pada TEXT NOT NULL,
          kelas_prediksi_id INTEGER,
          dikoreksi INTEGER NOT NULL DEFAULT 0,
          sumber_prediksi TEXT NOT NULL DEFAULT 'model',
          FOREIGN KEY (kelas_id) REFERENCES kelas_makanan(id)
        )
      ''');
      await db.execute('''
        INSERT INTO log_makan_v2 (
          id, kelas_id, nama_snapshot, porsi_g, kalori, protein_g, lemak_g,
          kh_g, keyakinan, waktu, tanggal, sumber_foto, dibuat_pada,
          kelas_prediksi_id, dikoreksi, sumber_prediksi
        )
        SELECT
          id, kelas_id, nama_snapshot, porsi_g, kalori, protein_g, lemak_g,
          kh_g, keyakinan, waktu, tanggal, sumber_foto, dibuat_pada,
          NULL, 0, 'model'
        FROM log_makan
      ''');
      await db.execute('DROP TABLE log_makan');
      await db.execute('ALTER TABLE log_makan_v2 RENAME TO log_makan');
      await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_log_tanggal ON log_makan(tanggal)',
      );
      await _pastikanDataKelasV2(db);
    }
  }

  static const Map<String, (String, double)> _satuanAlamiKelas = {
    'bakso': ('mangkuk', 300.0),
    'donuts': ('buah', 60.0),
    'dumplings': ('buah', 20.0),
    'gulai_ikan': ('mangkuk', 150.0),
    'gulai_tambusu': ('mangkuk', 150.0),
    'gulai_tunjang': ('mangkuk', 150.0),
    'hamburger': ('buah', 200.0),
    'ice_cream': ('scoop', 60.0),
    'pancakes': ('lembar', 75.0),
    'pizza': ('potong', 100.0),
    'ramen': ('mangkuk', 500.0),
    'rawon': ('mangkuk', 300.0),
    'sate': ('tusuk', 15.0),
    'soto': ('mangkuk', 300.0),
    'sushi': ('potong', 30.0),
    'telur_balado': ('butir', 55.0),
    'telur_dadar': ('butir', 60.0),
  };

  static Future<void> _pastikanDataKelasV2(Database db) async {
    final hitung = Sqflite.firstIntValue(
      await db.rawQuery('SELECT COUNT(*) FROM kelas_makanan'),
    );
    if (hitung == null || hitung == 0) return;

    final belumLengkap = Sqflite.firstIntValue(
      await db.rawQuery(
        'SELECT COUNT(*) FROM kelas_makanan WHERE gram_per_satuan <= 0',
      ),
    );
    if ((belumLengkap ?? 0) > 0) {
      final batch = db.batch();
      for (final entri in _satuanAlamiKelas.entries) {
        batch.update(
          'kelas_makanan',
          {'satuan': entri.value.$1, 'gram_per_satuan': entri.value.$2},
          where: 'kode = ? AND gram_per_satuan <= 0',
          whereArgs: [entri.key],
        );
      }
      batch.rawUpdate(
        'UPDATE kelas_makanan SET gram_per_satuan = porsi_ref_g WHERE gram_per_satuan <= 0',
      );
      await batch.commit(noResult: true);
    }

    if (hitung >= 32) {
      await db.insert('kelas_makanan', {
        'id': 32,
        'kode': 'nasi_putih',
        'nama_id': 'Nasi Putih',
        'nama_en': 'Steamed White Rice',
        'kelompok': 'Indonesia',
        'kkal_100g': 180.0,
        'protein_g': 3.0,
        'lemak_g': 0.3,
        'kh_g': 39.8,
        'serat_g': 0.2,
        'porsi_ref_g': 150.0,
        'gram_per_cm2': null,
        'sumber': 'TKPI',
        'satuan': 'porsi',
        'gram_per_satuan': 150.0,
      }, conflictAlgorithm: ConflictAlgorithm.ignore);
    }
  }

  Future<void> tutup() => db.close();
}
