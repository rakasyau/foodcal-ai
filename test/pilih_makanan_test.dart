import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:foodcal_ai/app/providers.dart';
import 'package:foodcal_ai/app/theme.dart';
import 'package:foodcal_ai/domain/model.dart';
import 'package:foodcal_ai/features/hasil/pilih_makanan_page.dart';

KelasMakanan _kelas({
  required int id,
  required String kode,
  required String nama,
  String kelompok = 'Indonesia',
  double kkal = 180,
  String satuan = 'porsi',
  double gramPerSatuan = 150,
}) {
  return KelasMakanan(
    id: id,
    kode: kode,
    namaId: nama,
    namaEn: nama,
    kelompok: kelompok,
    kkal100g: kkal,
    protein100g: 3,
    lemak100g: 0.3,
    kh100g: 39.8,
    serat100g: 0.2,
    porsiRefG: gramPerSatuan,
    gramPerCm2: 1,
    sumber: 'uji',
    satuan: satuan,
    gramPerSatuan: gramPerSatuan,
  );
}

/// Nasi putih sengaja ditaruh paling akhir, sama seperti urutan di basis data
/// asli, supaya tes ini benar-benar menguji pintasan.
final _daftar = <KelasMakanan>[
  _kelas(id: 0, kode: 'ayam_goreng', nama: 'Ayam Goreng', kelompok: 'Padang', kkal: 283),
  _kelas(id: 16, kode: 'nasi_goreng', nama: 'Nasi Goreng', kkal: 267),
  _kelas(id: 29, kode: 'telur_balado', nama: 'Telur Balado', kelompok: 'Padang', kkal: 175),
  _kelas(id: 30, kode: 'telur_dadar', nama: 'Telur Dadar', kelompok: 'Padang', kkal: 251),
  _kelas(id: 31, kode: 'nasi_putih', nama: 'Nasi Putih', kkal: 180),
];

Widget _bungkus() {
  return ProviderScope(
    overrides: [kelasProvider.overrideWith((ref) async => _daftar)],
    child: MaterialApp(
      theme: AppTema.terang(),
      home: const PilihMakananPage(judul: 'Tambah makanan'),
    ),
  );
}

void main() {
  testWidgets('nasi putih tersedia sebagai pintasan di atas daftar', (
    tester,
  ) async {
    await tester.pumpWidget(_bungkus());
    await tester.pumpAndSettle();

    expect(find.text('Sering ditambahkan'), findsOneWidget);
    // Satu di pil pintasan, satu di daftar penuh di bawahnya.
    expect(find.text('Nasi Putih'), findsNWidgets(2));
    expect(find.text('Nasi Goreng'), findsNWidgets(2));
  });

  testWidgets('menekan pil nasi putih mengembalikan kelas tersebut', (
    tester,
  ) async {
    KelasMakanan? terpilih;
    await tester.pumpWidget(
      ProviderScope(
        overrides: [kelasProvider.overrideWith((ref) async => _daftar)],
        child: MaterialApp(
          theme: AppTema.terang(),
          home: Builder(
            builder: (context) => Scaffold(
              body: Center(
                child: ElevatedButton(
                  onPressed: () async {
                    terpilih = await Navigator.of(context).push<KelasMakanan>(
                      MaterialPageRoute(
                        builder: (_) => const PilihMakananPage(),
                      ),
                    );
                  },
                  child: const Text('buka'),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('buka'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Nasi Putih').first);
    await tester.pumpAndSettle();

    expect(terpilih?.kode, 'nasi_putih');
  });

  testWidgets('pintasan hilang saat pengguna mengetik pencarian', (
    tester,
  ) async {
    await tester.pumpWidget(_bungkus());
    await tester.pumpAndSettle();
    expect(find.text('Sering ditambahkan'), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'nasi');
    await tester.pumpAndSettle();

    expect(find.text('Sering ditambahkan'), findsNothing);
    expect(find.text('Nasi Putih'), findsOneWidget);
  });
}
