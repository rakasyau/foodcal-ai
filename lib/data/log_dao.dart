import 'package:sqflite/sqflite.dart';

import '../core/formatter.dart';
import '../domain/model.dart';
import '../domain/rekap.dart';

class LogDao {
  LogDao(this._db);

  final Database _db;

  Future<int> simpan(EntriLog entri) {
    return _db.insert('log_makan', entri.keMap());
  }

  /// Menyimpan beberapa entri sekaligus dalam satu transaksi.
  ///
  /// Bila satu baris gagal, tidak ada yang tersimpan, sehingga menekan
  /// "Simpan" ulang tidak menghasilkan entri ganda.
  Future<void> simpanBanyak(List<EntriLog> daftar) async {
    if (daftar.isEmpty) return;
    await _db.transaction((txn) async {
      final batch = txn.batch();
      for (final entri in daftar) {
        batch.insert('log_makan', entri.keMap());
      }
      await batch.commit(noResult: true);
    });
  }

  Future<void> ubah(EntriLog entri) async {
    final id = entri.id;
    if (id == null) {
      throw ArgumentError('Entri tanpa id tidak dapat diubah');
    }
    await _db.update(
      'log_makan',
      entri.keMap(),
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> hapus(int id) async {
    await _db.delete('log_makan', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> hapusSemua() async {
    await _db.delete('log_makan');
  }

  Future<List<EntriLog>> perTanggal(String tanggal) async {
    final baris = await _db.query(
      'log_makan',
      where: 'tanggal = ?',
      whereArgs: [tanggal],
      orderBy: 'waktu DESC, id DESC',
    );
    return baris.map(EntriLog.dariMap).toList(growable: false);
  }

  Future<List<EntriLog>> rentang(DateTime mulai, DateTime akhir) async {
    final baris = await _db.query(
      'log_makan',
      where: 'tanggal BETWEEN ? AND ?',
      whereArgs: [formatTanggalIso(mulai), formatTanggalIso(akhir)],
      orderBy: 'tanggal DESC, waktu DESC, id DESC',
    );
    return baris.map(EntriLog.dariMap).toList(growable: false);
  }

  Future<List<EntriLog>> semua() async {
    final baris = await _db.query(
      'log_makan',
      orderBy: 'tanggal DESC, waktu DESC, id DESC',
    );
    return baris.map(EntriLog.dariMap).toList(growable: false);
  }

  Future<RekapHarian> rekap(String tanggal) async {
    final hasil = await _db.rawQuery(
      '''
      SELECT
        COALESCE(SUM(kalori), 0) AS kalori,
        COALESCE(SUM(protein_g), 0) AS protein_g,
        COALESCE(SUM(lemak_g), 0) AS lemak_g,
        COALESCE(SUM(kh_g), 0) AS kh_g,
        COUNT(*) AS jumlah
      FROM log_makan
      WHERE tanggal = ?
      ''',
      [tanggal],
    );
    if (hasil.isEmpty) return RekapHarian.kosong;
    return RekapHarian.dariMap(hasil.first);
  }

  Future<List<TitikHarian>> rekapRentang(DateTime mulai, DateTime akhir) async {
    final hasil = await _db.rawQuery(
      '''
      SELECT
        tanggal,
        COALESCE(SUM(kalori), 0) AS kalori,
        COALESCE(SUM(protein_g), 0) AS protein_g,
        COALESCE(SUM(lemak_g), 0) AS lemak_g,
        COALESCE(SUM(kh_g), 0) AS kh_g,
        COUNT(*) AS jumlah
      FROM log_makan
      WHERE tanggal BETWEEN ? AND ?
      GROUP BY tanggal
      ORDER BY tanggal ASC
      ''',
      [formatTanggalIso(mulai), formatTanggalIso(akhir)],
    );
    return hasil.map(TitikHarian.dariMap).toList(growable: false);
  }

  Future<List<String>> tanggalTercatat() async {
    final hasil = await _db.rawQuery(
      'SELECT DISTINCT tanggal FROM log_makan ORDER BY tanggal DESC',
    );
    return hasil
        .map((baris) => baris['tanggal'] as String)
        .toList(growable: false);
  }
}
