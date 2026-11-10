import 'package:sqflite/sqflite.dart';

import '../domain/kalkulator_gizi.dart';
import '../domain/model.dart';

class PengaturanDao {
  PengaturanDao(this._db);

  final Database _db;

  Future<Pengaturan> ambil() async {
    final baris = await _db.query('pengaturan');
    final map = <String, String>{
      for (final item in baris)
        item['kunci'] as String: item['nilai'] as String,
    };
    return _dariMap(map);
  }

  Future<String?> nilai(String kunci) async {
    final baris = await _db.query(
      'pengaturan',
      columns: ['nilai'],
      where: 'kunci = ?',
      whereArgs: [kunci],
      limit: 1,
    );
    if (baris.isEmpty) return null;
    return baris.first['nilai'] as String?;
  }

  /// Mengambil porsi tersimpan untuk suatu kelas, atau nilai bawaan bila belum ada.
  Future<double> porsiUntukKelas(int kelasId, double bawaan) async {
    final teks = await nilai(KunciPengaturan.porsiKelas(kelasId));
    final angka = double.tryParse(teks ?? '');
    if (angka == null || angka <= 0) return batasiPorsi(bawaan);
    return batasiPorsi(angka);
  }

  Future<void> set(String kunci, String nilai) async {
    await _db.insert('pengaturan', {
      'kunci': kunci,
      'nilai': nilai,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> setBanyak(Map<String, String> nilai) async {
    final batch = _db.batch();
    for (final entri in nilai.entries) {
      batch.insert('pengaturan', {
        'kunci': entri.key,
        'nilai': entri.value,
      }, conflictAlgorithm: ConflictAlgorithm.replace);
    }
    await batch.commit(noResult: true);
  }

  Future<void> simpan(Pengaturan pengaturan) {
    return setBanyak({
      KunciPengaturan.namaPengguna: pengaturan.namaPengguna.trim(),
      KunciPengaturan.targetKalori: pengaturan.targetKalori.toString(),
      KunciPengaturan.ambangKeyakinan: pengaturan.ambangKeyakinan
          .toStringAsFixed(2),
      KunciPengaturan.ttaAktif: pengaturan.ttaAktif ? '1' : '0',
      KunciPengaturan.modelAktif: pengaturan.modelAktif,
      KunciPengaturan.onboardingSelesai: pengaturan.onboardingSelesai
          ? '1'
          : '0',
      KunciPengaturan.modeTema: normalisasiModeTema(pengaturan.modeTema),
    });
  }

  Future<void> reset() async {
    await _db.delete('pengaturan');
    await simpan(Pengaturan.bawaan);
  }

  Pengaturan _dariMap(Map<String, String> map) {
    final nama = (map[KunciPengaturan.namaPengguna] ?? '').trim();
    final targetMentah =
        int.tryParse(map[KunciPengaturan.targetKalori] ?? '') ?? 2000;
    final target = targetMentah <= 0 ? 2000 : targetMentah.clamp(800, 6000);
    final ambang =
        double.tryParse(map[KunciPengaturan.ambangKeyakinan] ?? '') ?? 0.60;
    return Pengaturan(
      namaPengguna: nama,
      targetKalori: target,
      ambangKeyakinan: ambang.clamp(0.05, 0.99).toDouble(),
      ttaAktif: (map[KunciPengaturan.ttaAktif] ?? '0') == '1',
      modelAktif: map[KunciPengaturan.modelAktif] ?? 'efficientnet_fp16',
      onboardingSelesai: (map[KunciPengaturan.onboardingSelesai] ?? '0') == '1',
      modeTema: normalisasiModeTema(map[KunciPengaturan.modeTema]),
    );
  }
}
