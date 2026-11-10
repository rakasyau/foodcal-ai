import 'package:flutter_test/flutter_test.dart';
import 'package:foodcal_ai/data/db.dart';
import 'package:foodcal_ai/data/log_dao.dart';
import 'package:foodcal_ai/data/pengaturan_dao.dart';
import 'package:foodcal_ai/domain/model.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

EntriLog _entri({
  required double kalori,
  required double protein,
  required double lemak,
  required double kh,
  required String tanggal,
  required int jam,
  required int menit,
}) {
  final waktu = DateTime.parse(
    '${tanggal}T${jam.toString().padLeft(2, '0')}:${menit.toString().padLeft(2, '0')}:00',
  );
  return EntriLog(
    kelasId: 16,
    namaSnapshot: 'Nasi Goreng',
    porsiG: 250,
    kalori: kalori,
    proteinG: protein,
    lemakG: lemak,
    khG: kh,
    keyakinan: 0.92,
    waktu: waktu,
    tanggal: tanggal,
    sumberFoto: 'kamera',
    dibuatPada: waktu,
  );
}

void main() {
  sqfliteFfiInit();

  late AppDatabase basisData;
  late LogDao dao;

  setUp(() async {
    basisData = await AppDatabase.bukaUntukUji(databaseFactoryFfi);
    dao = LogDao(basisData.db);
    await basisData.db.insert('kelas_makanan', {
      'id': 16,
      'kode': 'nasi_goreng',
      'nama_id': 'Nasi Goreng',
      'nama_en': 'Nasi Goreng',
      'kelompok': 'Indonesia',
      'kkal_100g': 189.4,
      'protein_g': 4.6,
      'lemak_g': 6.4,
      'kh_g': 27.3,
      'serat_g': 0.2,
      'porsi_ref_g': 250.0,
      'gram_per_cm2': 1.136,
      'sumber': 'Komposit TKPI',
    });
  });

  tearDown(() async {
    await basisData.tutup();
  });

  test('rekap harian memakai SUM dari basis data', () async {
    await dao.simpan(
      _entri(
        kalori: 468,
        protein: 21,
        lemak: 18,
        kh: 55,
        tanggal: '2026-10-28',
        jam: 12,
        menit: 30,
      ),
    );
    await dao.simpan(
      _entri(
        kalori: 452,
        protein: 33,
        lemak: 23,
        kh: 93,
        tanggal: '2026-10-28',
        jam: 15,
        menit: 10,
      ),
    );
    await dao.simpan(
      _entri(
        kalori: 320,
        protein: 20,
        lemak: 10,
        kh: 40,
        tanggal: '2026-10-27',
        jam: 7,
        menit: 45,
      ),
    );

    final rekap = await dao.rekap('2026-10-28');
    expect(rekap.kalori, closeTo(920, 0.0001));
    expect(rekap.proteinG, closeTo(54, 0.0001));
    expect(rekap.lemakG, closeTo(41, 0.0001));
    expect(rekap.khG, closeTo(148, 0.0001));
    expect(rekap.jumlahEntri, 2);

    final kosong = await dao.rekap('2026-10-20');
    expect(kosong.kalori, 0);
    expect(kosong.jumlahEntri, 0);
  });

  test('entri per tanggal diurutkan waktu menurun', () async {
    await dao.simpan(
      _entri(
        kalori: 468,
        protein: 21,
        lemak: 18,
        kh: 55,
        tanggal: '2026-10-28',
        jam: 12,
        menit: 30,
      ),
    );
    await dao.simpan(
      _entri(
        kalori: 452,
        protein: 33,
        lemak: 23,
        kh: 93,
        tanggal: '2026-10-28',
        jam: 15,
        menit: 10,
      ),
    );

    final entri = await dao.perTanggal('2026-10-28');
    expect(entri.length, 2);
    expect(entri.first.waktu.hour, 15);
    expect(entri.last.waktu.hour, 12);
  });

  test('rekap rentang mengelompokkan per tanggal', () async {
    await dao.simpan(
      _entri(
        kalori: 468,
        protein: 21,
        lemak: 18,
        kh: 55,
        tanggal: '2026-10-27',
        jam: 12,
        menit: 30,
      ),
    );
    await dao.simpan(
      _entri(
        kalori: 452,
        protein: 33,
        lemak: 23,
        kh: 93,
        tanggal: '2026-10-28',
        jam: 12,
        menit: 30,
      ),
    );
    await dao.simpan(
      _entri(
        kalori: 100,
        protein: 5,
        lemak: 5,
        kh: 10,
        tanggal: '2026-10-28',
        jam: 18,
        menit: 0,
      ),
    );

    final rentang = await dao.rekapRentang(
      DateTime(2026, 10, 27),
      DateTime(2026, 10, 28),
    );
    expect(rentang.length, 2);
    expect(rentang.first.tanggal, '2026-10-27');
    expect(rentang.first.kalori, closeTo(468, 0.0001));
    expect(rentang.last.tanggal, '2026-10-28');
    expect(rentang.last.kalori, closeTo(552, 0.0001));
    expect(rentang.last.jumlahEntri, 2);
  });

  test('ubah dan hapus entri memperbarui total', () async {
    final id = await dao.simpan(
      _entri(
        kalori: 468,
        protein: 21,
        lemak: 18,
        kh: 55,
        tanggal: '2026-10-28',
        jam: 12,
        menit: 30,
      ),
    );
    final entri = (await dao.perTanggal('2026-10-28')).single;
    await dao.ubah(
      entri.salinDengan(
        porsiG: 200,
        kalori: 374.4,
        proteinG: 16.8,
        lemakG: 14.4,
        khG: 44,
      ),
    );
    var rekap = await dao.rekap('2026-10-28');
    expect(rekap.kalori, closeTo(374.4, 0.0001));

    await dao.hapus(id);
    rekap = await dao.rekap('2026-10-28');
    expect(rekap.kalori, 0);
    expect(rekap.jumlahEntri, 0);
    expect(await dao.perTanggal('2026-10-28'), isEmpty);
  });

  test('tanggal tercatat unik dan berurutan menurun', () async {
    await dao.simpan(
      _entri(
        kalori: 100,
        protein: 1,
        lemak: 1,
        kh: 1,
        tanggal: '2026-10-26',
        jam: 8,
        menit: 0,
      ),
    );
    await dao.simpan(
      _entri(
        kalori: 100,
        protein: 1,
        lemak: 1,
        kh: 1,
        tanggal: '2026-10-28',
        jam: 8,
        menit: 0,
      ),
    );
    await dao.simpan(
      _entri(
        kalori: 100,
        protein: 1,
        lemak: 1,
        kh: 1,
        tanggal: '2026-10-28',
        jam: 9,
        menit: 0,
      ),
    );

    final tanggal = await dao.tanggalTercatat();
    expect(tanggal, ['2026-10-28', '2026-10-26']);
  });

  test('simpanBanyak menyimpan piring multi-item secara transaksional', () async {
    final waktu = DateTime(2026, 10, 28, 13, 15);
    await dao.simpanBanyak([
      EntriLog(
        kelasId: 16,
        namaSnapshot: 'Nasi Goreng',
        porsiG: 250,
        kalori: 473.5,
        proteinG: 11.5,
        lemakG: 16,
        khG: 68.25,
        keyakinan: 0.85,
        waktu: waktu,
        tanggal: '2026-10-28',
        sumberFoto: 'galeri',
        dibuatPada: waktu,
        kelasPrediksiId: 16,
        dikoreksi: false,
        sumberPrediksi: 'model',
      ),
      EntriLog(
        kelasId: null,
        namaSnapshot: 'Kerupuk Udang',
        porsiG: 30,
        kalori: 140,
        proteinG: 2,
        lemakG: 7,
        khG: 17,
        keyakinan: 0,
        waktu: waktu,
        tanggal: '2026-10-28',
        sumberFoto: 'galeri',
        dibuatPada: waktu,
        kelasPrediksiId: null,
        dikoreksi: false,
        sumberPrediksi: 'manual',
      ),
    ]);

    final daftar = await dao.perTanggal('2026-10-28');
    expect(daftar.length, 2);
    expect(daftar.map((e) => e.sumberFoto).toSet(), {'galeri'});
    expect(
      daftar.map((e) => e.sumberPrediksi).toSet(),
      {'model', 'manual'},
    );
    final rekap = await dao.rekap('2026-10-28');
    expect(rekap.kalori, closeTo(613.5, 0.0001));
    expect(rekap.jumlahEntri, 2);
  });

  test('pengaturan menyimpan dan memuat mode tema terang serta gelap', () async {
    final pengaturanDao = PengaturanDao(basisData.db);

    final awal = await pengaturanDao.ambil();
    expect(awal.modeTema, temaSistem);
    expect(awal.labelTema, 'Sistem');

    await pengaturanDao.simpan(awal.salinDengan(modeTema: temaTerang));
    final terang = await pengaturanDao.ambil();
    expect(terang.modeTema, temaTerang);
    expect(terang.labelTema, 'Terang');

    await pengaturanDao.simpan(terang.salinDengan(modeTema: temaGelap));
    final gelap = await pengaturanDao.ambil();
    expect(gelap.modeTema, temaGelap);
    expect(gelap.labelTema, 'Gelap');

    await pengaturanDao.reset();
    final direset = await pengaturanDao.ambil();
    expect(direset.modeTema, temaSistem);
  });
}
