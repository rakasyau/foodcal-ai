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
import '../../widgets/ikon_svg.dart';
import '../../widgets/keadaan_kosong.dart';
import '../../widgets/pemilih.dart';
import '../../widgets/tombol.dart';
import 'grafik_page.dart';
import 'catat_manual_page.dart';
import 'konfirmasi_hapus.dart';

class CatatanHarianPage extends ConsumerStatefulWidget {
  const CatatanHarianPage({super.key, this.tanggal});

  final DateTime? tanggal;

  @override
  ConsumerState<CatatanHarianPage> createState() => _CatatanHarianPageState();
}

class _CatatanHarianPageState extends ConsumerState<CatatanHarianPage> {
  late DateTime _tanggal = tanggalSaja(widget.tanggal ?? DateTime.now());
  final Set<int> _dihapusSementara = <int>{};
  int _indeksEntriAktif = 0;
  bool _mengekspor = false;

  String get _kunciTanggal => formatTanggalIso(_tanggal);

  bool get _hariIni =>
      formatTanggalIso(_tanggal) == formatTanggalIso(DateTime.now());

  Future<void> _catatManual() async {
    final tersimpan = await Rute.buka<bool>(
      context,
      CatatManualPage(tanggal: _tanggal),
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

  Future<void> _hapus(EntriLog entri, RekapHarian rekap) async {
    await hapusEntriDenganKonfirmasi(
      context,
      ref,
      entri,
      rekap: rekap,
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = context.warna;
    final pengaturan = ref.watch(pengaturanProvider).value ?? Pengaturan.bawaan;
    final rekap =
        ref.watch(rekapHariProvider(_kunciTanggal)).value ?? RekapHarian.kosong;
    final entriMentah =
        ref.watch(entriHariProvider(_kunciTanggal)).value ?? const [];
    final entri = _dihapusSementara.isEmpty
        ? entriMentah
        : entriMentah
              .where((e) => e.id == null || !_dihapusSementara.contains(e.id))
              .toList(growable: false);

    return Scaffold(
      backgroundColor: c.bg,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            AppJarak.halaman,
            12,
            AppJarak.halaman,
            32,
          ),
          children: [
            Row(
              children: [
                if (Navigator.of(context).canPop()) ...[
                  TombolLingkaran(
                    ikonGaris: JenisIkon.kembali,
                    label: 'Kembali',
                    latar: c.surface,
                    onPressed: () => Navigator.of(context).maybePop(),
                  ),
                  const SizedBox(width: 10),
                ],
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
                const SizedBox(width: 8),
                ChipAksi(
                  label: 'Catat',
                  onTap: _catatManual,
                ),
                const SizedBox(width: 6),
                ChipAksi(
                  label: Navigator.of(context).canPop() ? 'CSV' : 'Ekspor CSV',
                  memuat: _mengekspor,
                  onTap: _ekspor,
                ),
              ],
            ),
            const SizedBox(height: 18),
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  formatKalori(rekap.kalori),
                  style: gayaAngka(context, ukuran: 46),
                ),
                const SizedBox(width: 10),
                Flexible(
                  child: Text(
                    _hariIni
                        ? 'kkal hari ini · target ${formatRibuan(pengaturan.targetKalori)}'
                        : 'kkal · target ${formatRibuan(pengaturan.targetKalori)}',
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
            if (rekap.jumlahEntri > 0) ...[
              const SizedBox(height: 6),
              Text(
                'P ${formatGram(rekap.proteinG)} · L ${formatGram(rekap.lemakG)} · K ${formatGram(rekap.khG)}',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 12,
                  color: c.inkSoft,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ],
            const SizedBox(height: 16),
            PemilihTanggal(
              tanggal: _tanggal,
              onChanged: (nilai) => setState(() {
                _tanggal = nilai;
                _dihapusSementara.clear();
                _indeksEntriAktif = 0;
              }),
            ),
            if (entri.isEmpty)
              KeadaanKosong(
                judul: _hariIni
                    ? 'Belum ada catatan hari ini'
                    : 'Belum ada catatan pada tanggal ini',
                pesan: 'Foto makananmu, lalu simpan. Catatan muncul di sini.',
                labelTombol: 'Buka Kamera',
                jarakAtas: 60,
                onPressed: () => Rute.kamera(context),
              )
            else ...[
              const SizedBox(height: 20),
              Text(
                'Riwayat',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: c.ink,
                ),
              ),
              const SizedBox(height: 6),
              for (var i = 0; i < entri.length; i++)
                Dismissible(
                  key: ValueKey('entri-${entri[i].id}'),
                  direction: DismissDirection.endToStart,
                  background: Container(
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 20),
                    color: c.accent,
                    child: const Text(
                      'Hapus',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  confirmDismiss: (_) => tampilkanKonfirmasiHapus(
                    context,
                    entri: entri[i],
                    rekap: rekap,
                  ),
                  onDismissed: (_) async {
                    final item = entri[i];
                    final id = item.id;
                    if (id == null) return;
                    final messenger = ScaffoldMessenger.of(context);
                    setState(() => _dihapusSementara.add(id));
                    try {
                      final repositori = await ref.read(
                        repositoriProvider.future,
                      );
                      await repositori.log.hapus(id);
                      segarkanCatatan(ref);
                      if (mounted) {
                        messenger.showSnackBar(
                          const SnackBar(content: Text('Entri dihapus')),
                        );
                      }
                    } catch (_) {
                      if (mounted) {
                        setState(() => _dihapusSementara.remove(id));
                        messenger.showSnackBar(
                          const SnackBar(
                            content: Text('Entri gagal dihapus. Coba lagi.'),
                          ),
                        );
                      }
                      segarkanCatatan(ref);
                    }
                  },
                  child: BarisEntri(
                    entri: entri[i],
                    onTap: () {
                      if (_indeksEntriAktif == i) {
                        Rute.ubahEntri(context, entri[i]);
                      } else {
                        setState(() => _indeksEntriAktif = i);
                      }
                    },
                    aksi:
                        (_indeksEntriAktif == i ||
                            (_indeksEntriAktif >= entri.length && i == 0))
                        ? BarisAksiEntri(
                            onUbah: () => Rute.ubahEntri(context, entri[i]),
                            onHapus: () => _hapus(entri[i], rekap),
                          )
                        : null,
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }
}
