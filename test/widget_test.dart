import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:foodcal_ai/app/app.dart';
import 'package:foodcal_ai/app/main_shell.dart';
import 'package:foodcal_ai/app/providers.dart';
import 'package:foodcal_ai/app/theme.dart';
import 'package:foodcal_ai/domain/model.dart';
import 'package:foodcal_ai/domain/rekap.dart';
import 'package:foodcal_ai/features/catatan/catatan_harian_page.dart';
import 'package:foodcal_ai/features/catatan/grafik_page.dart';
import 'package:foodcal_ai/features/catatan/ubah_entri_page.dart';
import 'package:foodcal_ai/features/hasil/belum_dikenali_page.dart';
import 'package:foodcal_ai/features/hasil/hasil_page.dart';
import 'package:foodcal_ai/features/kamera/izin_kamera_page.dart';
import 'package:foodcal_ai/features/onboarding/onboarding_page.dart';
import 'package:foodcal_ai/features/pengaturan/pengaturan_page.dart';
import 'package:foodcal_ai/features/piring/piring_page.dart';
import 'package:foodcal_ai/features/profil/profil_page.dart';
import 'package:foodcal_ai/features/profil/widget_layar_utama_page.dart';
import 'package:foodcal_ai/services/widget_layar_utama_service.dart';
import 'package:foodcal_ai/widgets/baris_entri.dart';
import 'package:foodcal_ai/widgets/cincin_kemajuan.dart';
import 'package:foodcal_ai/widgets/keadaan_kosong.dart';
import 'package:foodcal_ai/widgets/nav_pill.dart';
import 'package:image/image.dart' as img;

Uint8List _buatPngUji() {
  final gambar = img.Image(width: 16, height: 16);
  return Uint8List.fromList(img.encodePng(gambar));
}

void main() {
  testWidgets('baris entri menampilkan nama, porsi, jam, dan kalori', (
    tester,
  ) async {
    final entri = EntriLog(
      id: 1,
      kelasId: 9,
      namaSnapshot: 'Gado-gado',
      porsiG: 250,
      kalori: 452,
      proteinG: 21,
      lemakG: 18,
      khG: 55,
      keyakinan: 0.88,
      waktu: DateTime(2026, 10, 28, 15, 10),
      tanggal: '2026-10-28',
      sumberFoto: 'kamera',
      dibuatPada: DateTime(2026, 10, 28, 15, 10),
    );
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTema.terang(),
        home: Scaffold(body: BarisEntri(entri: entri)),
      ),
    );
    expect(find.text('Gado-gado'), findsOneWidget);
    expect(find.text('Porsi 250 g · 15.10'), findsOneWidget);
    expect(find.text('- 452 kkal'), findsOneWidget);

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTema.terang(),
        home: Scaffold(
          body: BarisEntri(
            entri: entri,
            aksi: BarisAksiEntri(onUbah: () {}, onHapus: () {}),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Porsi 250 g · 15.10 · 452 kkal'), findsOneWidget);
  });

  testWidgets('baris aksi entri menampilkan tombol Ubah dan Hapus', (
    tester,
  ) async {
    var ubahDitekan = false;
    var hapusDitekan = false;
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTema.terang(),
        home: Scaffold(
          body: BarisAksiEntri(
            onUbah: () => ubahDitekan = true,
            onHapus: () => hapusDitekan = true,
          ),
        ),
      ),
    );
    expect(find.text('Ubah'), findsOneWidget);
    expect(find.text('Hapus'), findsOneWidget);
    await tester.tap(find.text('Ubah'));
    await tester.tap(find.text('Hapus'));
    expect(ubahDitekan, isTrue);
    expect(hapusDitekan, isTrue);
  });

  testWidgets('cincin kemajuan menampilkan persentase termasuk di atas 100%', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTema.terang(),
        home: const Scaffold(
          body: Column(
            children: [
              CincinKemajuan(persen: 62),
              CincinKemajuan(persen: 109),
            ],
          ),
        ),
      ),
    );
    expect(find.text('62%'), findsOneWidget);
    expect(find.text('109%'), findsOneWidget);
  });

  testWidgets('nav pill menampilkan label tab aktif dan tombol kamera', (
    tester,
  ) async {
    var tabTerpilih = 0;
    var kameraDitekan = false;
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTema.terang(),
        home: StatefulBuilder(
          builder: (context, setState) {
            return Scaffold(
              bottomNavigationBar: NavPill(
                indeks: tabTerpilih,
                onChanged: (idx) => setState(() => tabTerpilih = idx),
                onKamera: () => kameraDitekan = true,
              ),
            );
          },
        ),
      ),
    );
    expect(find.text('Beranda'), findsOneWidget);
    expect(find.text('Catatan'), findsNothing);
    await tester.tap(find.bySemanticsLabel('Catatan'));
    await tester.pump();
    expect(tabTerpilih, 1);
    expect(find.text('Catatan'), findsOneWidget);
    await tester.tap(find.bySemanticsLabel('Buka kamera'));
    expect(kameraDitekan, isTrue);
  });

  testWidgets('keadaan kosong menampilkan ilustrasi piring dan tombol kamera', (
    tester,
  ) async {
    var ditekan = false;
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTema.terang(),
        home: Scaffold(
          body: KeadaanKosong(
            judul: 'Belum ada catatan hari ini',
            pesan: 'Foto makananmu, lalu simpan. Catatan muncul di sini.',
            labelTombol: 'Buka Kamera',
            onPressed: () => ditekan = true,
          ),
        ),
      ),
    );
    expect(find.text('Belum ada catatan hari ini'), findsOneWidget);
    expect(find.text('Buka Kamera'), findsOneWidget);
    await tester.tap(find.text('Buka Kamera'));
    expect(ditekan, isTrue);
  });

  testWidgets('halaman onboarding menampilkan input nama dan kartu model', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          theme: AppTema.terang(),
          home: const OnboardingPage(),
        ),
      ),
    );
    expect(find.text('FoodCal AI'), findsOneWidget);
    expect(find.text('Nama panggilan'), findsOneWidget);
    expect(find.text('Bawaan'), findsOneWidget);
    expect(find.text('Hemat'), findsOneWidget);
    expect(find.text('Simpan dan Mulai'), findsOneWidget);

    final tombolSimpan = find.text('Simpan dan Mulai');
    await tester.ensureVisible(tombolSimpan);
    await tester.pumpAndSettle();
    await tester.tap(tombolSimpan);
    await tester.pump();
    expect(find.text('Isi nama panggilanmu terlebih dahulu.'), findsOneWidget);
  });

  testWidgets('halaman hasil memperbarui kalori saat porsi digeser', (
    tester,
  ) async {
    const kelas = KelasMakanan(
      id: 9,
      kode: 'gado_gado',
      namaId: 'Gado-gado',
      namaEn: 'Gado-gado',
      kelompok: 'Indonesia',
      kkal100g: 181,
      protein100g: 8.6,
      lemak100g: 7.4,
      kh100g: 22.0,
      serat100g: 1.5,
      porsiRefG: 250,
      gramPerCm2: null,
      sumber: 'TKPI',
    );
    const hasil = HasilPrediksi(
      kelas: kelas,
      keyakinan: 0.88,
      sumberFoto: 'kamera',
    );
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          theme: AppTema.gelap(),
          home: HasilPage(hasil: hasil, foto: _buatPngUji()),
        ),
      ),
    );
    expect(find.text('Gado-gado'), findsOneWidget);
    expect(find.text('88% yakin'), findsOneWidget);
    expect(find.text('453'), findsOneWidget);
    expect(find.text('1 porsi · 250 g'), findsOneWidget);

    final tombolBesar = find.text('Besar');
    await tester.ensureVisible(tombolBesar);
    await tester.tap(tombolBesar);
    await tester.pump();
    expect(find.text('1,5 porsi · 375 g'), findsOneWidget);
    expect(find.text('679'), findsOneWidget);

    final tombolSetengah = find.text('Setengah');
    await tester.tap(tombolSetengah);
    await tester.pump();
    expect(find.text('0,5 porsi · 125 g'), findsOneWidget);
    expect(find.text('226'), findsOneWidget);
  });

  testWidgets('halaman belum dikenali dan izin kamera menampilkan pesan jelas', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTema.terang(),
        home: BelumDikenaliPage(
          keyakinan: 0.41,
          ambang: 0.60,
          foto: Uint8List(8),
          sumberFoto: 'kamera',
        ),
      ),
    );
    expect(find.text('Makanan belum dikenali'), findsOneWidget);
    expect(find.text('Foto Ulang'), findsOneWidget);
    expect(find.text('Pilih dari Galeri'), findsOneWidget);

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTema.terang(),
        home: const IzinKameraDitolakPage(),
      ),
    );
    expect(find.text('Kamera belum bisa dipakai'), findsOneWidget);
    expect(find.text('Buka Pengaturan'), findsOneWidget);
  });

  testWidgets('lembar ubah entri dan widget layar utama tampil sesuai desain', (
    tester,
  ) async {
    final entri = EntriLog(
      id: 1,
      kelasId: 9,
      namaSnapshot: 'Gado-gado',
      porsiG: 250,
      kalori: 452,
      proteinG: 21,
      lemakG: 18,
      khG: 55,
      keyakinan: 0.88,
      waktu: DateTime(2026, 10, 28, 15, 10),
      tanggal: '2026-10-28',
      sumberFoto: 'kamera',
      dibuatPada: DateTime(2026, 10, 28, 15, 10),
    );
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          theme: AppTema.terang(),
          home: Scaffold(body: UbahEntriPage(entri: entri)),
        ),
      ),
    );
    expect(find.text('Gado-gado'), findsOneWidget);
    expect(find.text('Keyakinan 88% · dari kamera'), findsOneWidget);
    expect(find.text('15.10'), findsOneWidget);
    expect(find.text('Simpan Perubahan'), findsOneWidget);

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          theme: AppTema.terang(),
          home: const WidgetLayarUtamaPage(),
        ),
      ),
    );
    expect(find.text('Widget 4×2 · layar utama ponsel'), findsOneWidget);
    expect(find.text('Widget 2×2 · ringkas'), findsOneWidget);
  });

  testWidgets('dialog ubah nama di halaman profil tidak memicu error dispose', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          pengaturanProvider.overrideWith(
            (ref) async =>
                Pengaturan.bawaan.salinDengan(namaPengguna: 'Budi'),
          ),
          tanggalTercatatProvider.overrideWith((ref) async => const []),
        ],
        child: MaterialApp(
          theme: AppTema.terang(),
          home: const Scaffold(body: ProfilPage()),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Budi'), findsOneWidget);

    await tester.tap(find.text('Budi'));
    await tester.pumpAndSettle();
    expect(find.text('Nama panggilan'), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'Andi');
    await tester.tap(find.text('Simpan'));
    await tester.pumpAndSettle();
  });

  testWidgets(
    'ubah entri mempertahankan porsi kecil manual dan batas jam 23.59',
    (tester) async {
      final entriKecil = EntriLog(
        id: 7,
        kelasId: null,
        namaSnapshot: 'Kerupuk',
        porsiG: 30,
        kalori: 150,
        proteinG: 2,
        lemakG: 8,
        khG: 18,
        keyakinan: 0,
        waktu: DateTime(2026, 10, 28, 23, 55),
        tanggal: '2026-10-28',
        sumberFoto: 'manual',
        dibuatPada: DateTime(2026, 10, 28, 23, 55),
        sumberPrediksi: 'manual',
      );
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            theme: AppTema.terang(),
            home: Scaffold(body: UbahEntriPage(entri: entriKecil)),
          ),
        ),
      );
      expect(find.text('30 g'), findsOneWidget);
      expect(find.textContaining('150'), findsOneWidget);
      expect(find.text('23.55'), findsOneWidget);

      await tester.tap(find.bySemanticsLabel('Mundurkan waktu sepuluh menit'));
      await tester.pump();
      expect(find.text('23.59'), findsOneWidget);

      await tester.tap(find.text('−10 g'));
      await tester.pump();
      expect(find.text('20 g'), findsOneWidget);
      expect(find.textContaining('100'), findsOneWidget);
    },
  );

  testWidgets('halaman piring membedakan status model, perlu dicek, dan manual', (
    tester,
  ) async {
    const ayam = KelasMakanan(
      id: 1,
      kode: 'ayam_goreng',
      namaId: 'Ayam Goreng',
      namaEn: 'Fried Chicken',
      kelompok: 'Indonesia',
      kkal100g: 260,
      protein100g: 25,
      lemak100g: 16,
      kh100g: 4,
      serat100g: 0,
      porsiRefG: 100,
      gramPerCm2: null,
      sumber: 'TKPI',
    );
    const tempe = KelasMakanan(
      id: 30,
      kode: 'tempe_goreng',
      namaId: 'Tempe Goreng',
      namaEn: 'Fried Tempeh',
      kelompok: 'Indonesia',
      kkal100g: 330,
      protein100g: 18,
      lemak100g: 22,
      kh100g: 15,
      serat100g: 4,
      porsiRefG: 100,
      gramPerCm2: null,
      sumber: 'TKPI',
    );
    final items = [
      ItemPiring(
        kelas: ayam,
        keyakinan: 0.84,
        porsiG: 100,
        kelasPrediksiId: 1,
      ),
      ItemPiring(
        kelas: tempe,
        keyakinan: 0.45,
        porsiG: 100,
        kelasPrediksiId: 30,
      ),
      ItemPiring(
        kelas: tempe,
        keyakinan: 0,
        porsiG: 50,
      ),
    ];
    expect(items[0].sumberPrediksi, 'model');
    expect(items[1].dikoreksi, isFalse);
    expect(items[2].dipilihManual, isTrue);
    expect(items[2].sumberPrediksi, 'manual');

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          theme: AppTema.terang(),
          home: PiringPage(
            foto: _buatPngUji(),
            items: items,
            sumberFoto: 'galeri',
            ambang: 0.60,
          ),
        ),
      ),
    );
    expect(find.text('84% yakin · 100 g'), findsOneWidget);
    expect(find.text('45% yakin · perlu dicek · 100 g'), findsOneWidget);
    expect(find.text('dipilih manual · 50 g'), findsOneWidget);
    expect(find.text('Foto Ulang'), findsOneWidget);
  });

  testWidgets('grafik 7 hari menampilkan jumlah penuh rentang dan tombol Catat', (
    tester,
  ) async {
    final hariIni = DateTime.now();
    final kemarin = DateTime(hariIni.year, hariIni.month, hariIni.day - 1);
    final isoHariIni =
        '${hariIni.year.toString().padLeft(4, '0')}-${hariIni.month.toString().padLeft(2, '0')}-${hariIni.day.toString().padLeft(2, '0')}';
    final isoKemarin =
        '${kemarin.year.toString().padLeft(4, '0')}-${kemarin.month.toString().padLeft(2, '0')}-${kemarin.day.toString().padLeft(2, '0')}';

    final entri1 = EntriLog(
      id: 1,
      kelasId: 9,
      namaSnapshot: 'Gado-gado',
      porsiG: 250,
      kalori: 400,
      proteinG: 20,
      lemakG: 15,
      khG: 45,
      keyakinan: 0.9,
      waktu: hariIni,
      tanggal: isoHariIni,
      sumberFoto: 'kamera',
      dibuatPada: hariIni,
    );
    final entri2 = EntriLog(
      id: 2,
      kelasId: 16,
      namaSnapshot: 'Nasi Goreng',
      porsiG: 250,
      kalori: 600,
      proteinG: 15,
      lemakG: 20,
      khG: 80,
      keyakinan: 0.9,
      waktu: kemarin,
      tanggal: isoKemarin,
      sumberFoto: 'kamera',
      dibuatPada: kemarin,
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          pengaturanProvider.overrideWith((ref) async => Pengaturan.bawaan),
          rekapRentangProvider(7).overrideWith(
            (ref) async => [
              TitikHarian(
                tanggal: isoKemarin,
                kalori: 600,
                proteinG: 15,
                lemakG: 20,
                khG: 80,
                jumlahEntri: 1,
              ),
              TitikHarian(
                tanggal: isoHariIni,
                kalori: 400,
                proteinG: 20,
                lemakG: 15,
                khG: 45,
                jumlahEntri: 1,
              ),
            ],
          ),
          entriRentangProvider(7).overrideWith(
            (ref) async => [entri1, entri2],
          ),
        ],
        child: MaterialApp(
          theme: AppTema.terang(),
          home: const Scaffold(body: GrafikPage()),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Total 7 hari = 600 + 400 = 1.000 kkal, bukan hanya 400 kkal hari ini.
    expect(find.text('1.000'), findsOneWidget);
    expect(find.text('7 hari terakhir'), findsOneWidget);
    expect(find.text('Catat'), findsOneWidget);
    expect(find.text('Pilih tanggal'), findsOneWidget);
  });

  testWidgets('pengaturan tema terang dan gelap diterapkan pada aplikasi', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          pengaturanProvider.overrideWith(
            (ref) async => Pengaturan.bawaan.salinDengan(
              modeTema: temaTerang,
              onboardingSelesai: false,
            ),
          ),
        ],
        child: const FoodCalApp(),
      ),
    );
    await tester.pumpAndSettle();

    final materialApp = tester.widget<MaterialApp>(find.byType(MaterialApp));
    expect(materialApp.themeMode, ThemeMode.light);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          pengaturanProvider.overrideWith(
            (ref) async => Pengaturan.bawaan.salinDengan(modeTema: temaTerang),
          ),
        ],
        child: MaterialApp(
          theme: AppTema.terang(),
          home: const PengaturanPage(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Tema tampilan'), findsOneWidget);
    expect(find.text('Terang'), findsOneWidget);
    expect(find.text('Gelap'), findsOneWidget);
    expect(find.text('Sistem'), findsOneWidget);
  });

  testWidgets(
    'halaman widget layar utama memicu pemasangan widget 4x2 dan 2x2',
    (tester) async {
      final panggilanKanal = <MethodCall>[];
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(WidgetLayarUtamaService.kanal, (
            MethodCall call,
          ) async {
            panggilanKanal.add(call);
            if (call.method == 'cekStatus') {
              return <String, Object>{
                'empatKaliDua': 1,
                'duaKaliDua': 0,
                'didukungPin': true,
              };
            }
            if (call.method == 'pasangWidget') {
              return 'diminta';
            }
            return null;
          });
      addTearDown(() {
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(WidgetLayarUtamaService.kanal, null);
      });

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            pengaturanProvider.overrideWith((ref) async => Pengaturan.bawaan),
          ],
          child: MaterialApp(
            theme: AppTema.terang(),
            home: const WidgetLayarUtamaPage(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Pasang Widget 4×2'), findsOneWidget);
      expect(find.text('Pasang Widget 2×2'), findsOneWidget);
      expect(find.text('Terpasang'), findsOneWidget);

      await tester.ensureVisible(find.text('Pasang Widget 4×2'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Pasang Widget 4×2'));
      await tester.pumpAndSettle();

      expect(
        panggilanKanal.any(
          (c) =>
              c.method == 'pasangWidget' &&
              (c.arguments as Map)['jenis'] == 'empat_kali_dua',
        ),
        isTrue,
      );
      expect(
        find.text('Konfirmasi pemasangan widget pada layar utama ponsel.'),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'tata letak layar 360dp dengan skala huruf 1.15x bebas overflow pada mode gelap dan terang',
    (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final hariIni = DateTime.now();
      final titik7 = List<TitikHarian>.generate(7, (i) {
        final tgl = DateTime(hariIni.year, hariIni.month, hariIni.day - (6 - i));
        final iso =
            '${tgl.year.toString().padLeft(4, '0')}-${tgl.month.toString().padLeft(2, '0')}-${tgl.day.toString().padLeft(2, '0')}';
        return TitikHarian(
          tanggal: iso,
          kalori: i == 6 ? 0 : 1200,
          proteinG: 40,
          lemakG: 30,
          khG: 150,
          jumlahEntri: i == 6 ? 0 : 2,
        );
      });

      for (final tema in <ThemeData>[AppTema.gelap(), AppTema.terang()]) {
        await tester.pumpWidget(
          ProviderScope(
            key: UniqueKey(),
            overrides: [
              pengaturanProvider.overrideWith((ref) async => Pengaturan.bawaan),
              rekapRentangProvider(7).overrideWith((ref) async => titik7),
              entriRentangProvider(7).overrideWith((ref) async => const []),
              tanggalTercatatProvider.overrideWith((ref) async => const []),
            ],
            child: MediaQuery(
              data: const MediaQueryData(
                size: Size(360, 800),
                padding: EdgeInsets.only(top: 36, bottom: 48),
                textScaler: TextScaler.linear(1.15),
              ),
              child: MaterialApp(
                theme: tema,
                builder: (context, child) => MediaQuery(
                  data: MediaQuery.of(
                    context,
                  ).copyWith(textScaler: const TextScaler.linear(1.15)),
                  child: child!,
                ),
                home: const MainShell(),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);

        await tester.tap(find.bySemanticsLabel('Catatan'));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        expect(find.text('Catatan Harian'), findsOneWidget);

        await tester.tap(find.bySemanticsLabel('Profil'));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);

        await tester.tap(find.bySemanticsLabel('Beranda'));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);

        await tester.pumpWidget(
          ProviderScope(
            key: UniqueKey(),
            overrides: [
              pengaturanProvider.overrideWith((ref) async => Pengaturan.bawaan),
            ],
            child: MaterialApp(
              theme: tema,
              builder: (context, child) => MediaQuery(
                data: MediaQuery.of(
                  context,
                ).copyWith(textScaler: const TextScaler.linear(1.15)),
                child: child!,
              ),
              home: const CatatanHarianPage(),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        expect(find.text('Catatan Harian'), findsOneWidget);
      }
    },
  );
}
