import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../app/router.dart';
import '../../app/theme.dart';
import '../../core/formatter.dart';
import '../../domain/model.dart';
import '../../domain/rekap.dart';
import '../../services/ekspor_csv.dart';
import '../../widgets/baris_entri.dart';
import '../../widgets/grafik_kalori.dart';
import '../../widgets/keadaan_kosong.dart';
import '../../widgets/pemilih.dart';
import 'catat_manual_page.dart';
import 'konfirmasi_hapus.dart';

class GrafikPage extends ConsumerStatefulWidget {
  const GrafikPage({super.key});

  @override
  ConsumerState<GrafikPage> createState() => _GrafikPageState();
}

class _GrafikPageState extends ConsumerState<GrafikPage> {
  int _rentang = 7;
  int? _indeksHari;
  int _indeksEntriAktif = 0;
  bool _mengekspor = false;

  Future<void> _catatManual({DateTime? tanggal}) async {
    final tersimpan = await Rute.buka<bool>(
      context,
      CatatManualPage(tanggal: tanggal),
    );
    if (tersimpan == true && mounted) {
      setState(() => _indeksEntriAktif = 0);
    }
  }

  Future<void> _ekspor() async {
    if (_mengekspor) return;
    setState(() => _mengekspor = true);
    try {
      final repositori = await ref.read(repositoriProvider.future);
      final semua = await repositori.log.semua();
      if (!mounted) return;
      if (semua.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Belum ada catatan untuk diekspor.')),
        );
        setState(() => _mengekspor = false);
        return;
      }
      await EksporCsv.bagikan(semua);
      if (!mounted) return;
      setState(() => _mengekspor = false);
    } catch (_) {
      if (!mounted) return;
      setState(() => _mengekspor = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Ekspor gagal. Coba lagi.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.warna;
    final pengaturan = ref.watch(pengaturanProvider).value ?? Pengaturan.bawaan;
    final hariUntukGrafik = _rentang == 1 ? 7 : _rentang;
    final titik =
        ref.watch(rekapRentangProvider(hariUntukGrafik)).value ??
        const <TitikHarian>[];
    final entriRentang =
        ref.watch(entriRentangProvider(_rentang)).value ?? const <EntriLog>[];

    final indeksHariValid =
        (_indeksHari != null &&
            _indeksHari! >= 0 &&
            _indeksHari! < titik.length)
        ? _indeksHari
        : null;

    final double kaloriTampil;
    final double proteinTampil;
    final double lemakTampil;
    final double karboTampil;
    final String labelKonteks;
    final List<EntriLog> entriTampil;
    final bool tampilkanTanggalEntri;
    final DateTime? tanggalPilihan;

    if (_rentang == 1) {
      final rekapHariIni =
          ref.watch(rekapHariProvider(tanggalHariIni())).value ??
          RekapHarian.kosong;
      kaloriTampil = rekapHariIni.kalori;
      proteinTampil = rekapHariIni.proteinG;
      lemakTampil = rekapHariIni.lemakG;
      karboTampil = rekapHariIni.khG;
      labelKonteks = 'Hari Ini';
      entriTampil = entriRentang;
      tampilkanTanggalEntri = false;
      tanggalPilihan = DateTime.now();
    } else if (indeksHariValid != null) {
      final t = titik[indeksHariValid];
      kaloriTampil = t.kalori;
      proteinTampil = t.proteinG;
      lemakTampil = t.lemakG;
      karboTampil = t.khG;
      labelKonteks = formatLabelTanggal(t.tanggalDate);
      entriTampil = entriRentang
          .where((e) => e.tanggal == t.tanggal)
          .toList(growable: false);
      tampilkanTanggalEntri = false;
      tanggalPilihan = t.tanggalDate;
    } else {
      kaloriTampil = titik.fold<double>(0, (j, item) => j + item.kalori);
      proteinTampil = titik.fold<double>(0, (j, item) => j + item.proteinG);
      lemakTampil = titik.fold<double>(0, (j, item) => j + item.lemakG);
      karboTampil = titik.fold<double>(0, (j, item) => j + item.khG);
      labelKonteks = '$_rentang hari terakhir';
      entriTampil = entriRentang;
      tampilkanTanggalEntri = true;
      tanggalPilihan = null;
    }

    final tanggalTerpilihGrafik = _rentang == 1
        ? tanggalHariIni()
        : (indeksHariValid != null ? titik[indeksHariValid].tanggal : null);
    final kosongHariIni = _rentang == 1 && entriTampil.isEmpty;

    return SafeArea(
      bottom: false,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppJarak.halaman,
          12,
          AppJarak.halaman,
          124,
        ),
        children: [
          Row(
            children: [
              Expanded(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Catatan Harian',
                    maxLines: 1,
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: c.ink,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              ChipAksi(
                label: 'Catat',
                onTap: () => _catatManual(tanggal: tanggalPilihan),
              ),
              const SizedBox(width: 6),
              ChipAksi(
                label: 'Ekspor CSV',
                memuat: _mengekspor,
                onTap: _ekspor,
              ),
            ],
          ),
          if (kosongHariIni) ...[
            const SizedBox(height: 18),
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text('0', style: gayaAngka(context, ukuran: 46)),
                const SizedBox(width: 10),
                Flexible(
                  child: Text(
                    'kkal hari ini · target ${formatRibuan(pengaturan.targetKalori)}',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 12,
                      color: c.inkSoft,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            PemilihRentang(
              nilai: _rentang,
              onChanged: (nilai) => setState(() {
                _rentang = nilai;
                _indeksHari = null;
                _indeksEntriAktif = 0;
              }),
            ),
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.centerLeft,
              child: InkWell(
                onTap: () => Rute.catatan(context),
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 4,
                    vertical: 4,
                  ),
                  child: Text(
                    'Pilih tanggal lain',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: c.accent,
                    ),
                  ),
                ),
              ),
            ),
            KeadaanKosong(
              judul: 'Belum ada catatan hari ini',
              pesan: 'Foto makananmu, lalu simpan. Catatan muncul di sini.',
              labelTombol: 'Buka Kamera',
              jarakAtas: 32,
              ringkas: true,
              onPressed: () => Rute.kamera(context),
            ),
          ] else ...[
            const SizedBox(height: 16),
            PemilihRentang(
              nilai: _rentang,
              onChanged: (nilai) => setState(() {
                _rentang = nilai;
                _indeksHari = null;
                _indeksEntriAktif = 0;
              }),
            ),
            const SizedBox(height: 16),
            GrafikCatatan(
              data: titik,
              target: pengaturan.targetKalori.toDouble(),
              tanggalTerpilih: tanggalTerpilihGrafik,
              onPilihTanggal: (tgl) {
                final iso = formatTanggalIso(tgl);
                final idx = titik.indexWhere((item) => item.tanggal == iso);
                if (idx < 0) return;
                setState(() {
                  if (_rentang == 1) {
                    if (iso == tanggalHariIni()) return;
                    _rentang = 7;
                    _indeksHari = idx;
                  } else {
                    _indeksHari = _indeksHari == idx ? null : idx;
                  }
                  _indeksEntriAktif = 0;
                });
              },
            ),
            const SizedBox(height: 18),
            Text(
              labelKonteks,
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: c.inkSoft,
              ),
            ),
            const SizedBox(height: 2),
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  formatKalori(kaloriTampil),
                  style: gayaAngka(context, ukuran: 28),
                ),
                const SizedBox(width: 10),
                Flexible(
                  child: Text(
                    'kkal · P ${formatGram(proteinTampil)} · L ${formatGram(lemakTampil)} · K ${formatGram(karboTampil)}',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 12,
                      color: c.inkSoft,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                  child: Text(
                    'Riwayat',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: c.ink,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                InkWell(
                  onTap: () => Rute.catatan(context, tanggal: tanggalPilihan),
                  borderRadius: BorderRadius.circular(8),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 4,
                      vertical: 2,
                    ),
                    child: Text(
                      'Pilih tanggal',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: c.accent,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            if (entriTampil.isEmpty)
              KeadaanKosong(
                judul: indeksHariValid != null
                    ? 'Belum ada catatan pada tanggal ini'
                    : 'Belum ada catatan $_rentang hari terakhir',
                pesan: 'Foto makananmu, lalu simpan. Catatan muncul di sini.',
                labelTombol: 'Buka Kamera',
                jarakAtas: 18,
                ringkas: true,
                onPressed: () => Rute.kamera(context),
              )
            else
              Column(
                children: [
                  for (var i = 0; i < entriTampil.length; i++)
                    BarisEntri(
                      entri: entriTampil[i],
                      tampilkanTanggal: tampilkanTanggalEntri,
                      onTap: () {
                        if (_indeksEntriAktif == i) {
                          Rute.ubahEntri(context, entriTampil[i]);
                        } else {
                          setState(() => _indeksEntriAktif = i);
                        }
                      },
                      aksi:
                          (_indeksEntriAktif == i ||
                              (_indeksEntriAktif >= entriTampil.length &&
                                  i == 0))
                          ? BarisAksiEntri(
                              onUbah: () =>
                                  Rute.ubahEntri(context, entriTampil[i]),
                              onHapus: () => hapusEntriDenganKonfirmasi(
                                context,
                                ref,
                                entriTampil[i],
                              ),
                            )
                          : null,
                    ),
                ],
              ),
          ],
        ],
      ),
    );
  }
}

class BarisAksiEntri extends StatelessWidget {
  const BarisAksiEntri({
    super.key,
    required this.onUbah,
    required this.onHapus,
  });

  final VoidCallback onUbah;
  final VoidCallback onHapus;

  @override
  Widget build(BuildContext context) {
    final c = context.warna;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Semantics(
          button: true,
          label: 'Ubah entri',
          child: Material(
            color: c.ink,
            borderRadius: BorderRadius.circular(16),
            child: InkWell(
              onTap: onUbah,
              borderRadius: BorderRadius.circular(16),
              child: SizedBox(
                width: 64,
                height: 48,
                child: Center(
                  child: Text(
                    'Ubah',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: c.bg,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 6),
        Semantics(
          button: true,
          label: 'Hapus entri',
          child: Material(
            color: c.accent,
            borderRadius: BorderRadius.circular(16),
            child: InkWell(
              onTap: onHapus,
              borderRadius: BorderRadius.circular(16),
              child: const SizedBox(
                width: 64,
                height: 48,
                child: Center(
                  child: Text(
                    'Hapus',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
