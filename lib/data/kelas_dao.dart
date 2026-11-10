import 'package:sqflite/sqflite.dart';

import '../domain/model.dart';

class KelasDao {
  KelasDao(this._db);

  final Database _db;

  Future<List<KelasMakanan>> semua() async {
    final baris = await _db.query('kelas_makanan', orderBy: 'id ASC');
    return baris.map(KelasMakanan.dariMap).toList(growable: false);
  }

  Future<KelasMakanan?> cari(int id) async {
    final baris = await _db.query(
      'kelas_makanan',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (baris.isEmpty) return null;
    return KelasMakanan.dariMap(baris.first);
  }
}
