import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../app/router.dart';
import '../../app/theme.dart';
import '../../core/formatter.dart';
import '../../domain/model.dart';
import '../../domain/rekap.dart';
import '../../services/widget_layar_utama_service.dart';
import '../../widgets/cincin_kemajuan.dart';
import '../../widgets/ikon_svg.dart';
import '../../widgets/tombol.dart';

class WidgetLayarUtamaPage extends ConsumerStatefulWidget {
  const WidgetLayarUtamaPage({super.key});

  @override
  ConsumerState<WidgetLayarUtamaPage> createState() =>
      _WidgetLayarUtamaPageState();
}

class _WidgetLayarUtamaPageState extends ConsumerState<WidgetLayarUtamaPage>
    with WidgetsBindingObserver {
  StatusWidgetTerpasang _status = const StatusWidgetTerpasang();
  bool _memasang4x2 = false;
  bool _memasang2x2 = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _muatStatus();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _muatStatus();
    }
  }

  Future<void> _muatStatus() async {
    final status = await WidgetLayarUtamaService.cekStatus();
    if (!mounted) return;
    setState(() => _status = status);
  }

  Future<void> _pasang({
    required bool ukuranPenuh,
    required double kalori,
    required int target,
  }) async {
    if (_memasang4x2 || _memasang2x2) return;
    setState(() {
      if (ukuranPenuh) {
        _memasang4x2 = true;
      } else {
        _memasang2x2 = true;
      }
    });
    final messenger = ScaffoldMessenger.of(context);
    try {
      await WidgetLayarUtamaService.perbarui(
        kalori: kalori,
        target: target,
        tanggal: tanggalHariIni(),
      );
      final hasil = await WidgetLayarUtamaService.pasang(
        ukuranPenuh: ukuranPenuh,
      );
      if (!mounted) return;
      await _muatStatus();
      if (!mounted) return;

      switch (hasil) {
        case HasilPasangWidget.diminta:
          messenger.showSnackBar(
            const SnackBar(
              content: Text(
                'Konfirmasi pemasangan widget pada layar utama ponsel.',
              ),
            ),
          );
        case HasilPasangWidget.tidakDidukung:
          await _tampilkanPanduanManual();
        case HasilPasangWidget.gagal:
          messenger.showSnackBar(
            const SnackBar(
              content: Text(
                'Gagal membuka pemasang otomatis. Gunakan cara manual di bawah.',
              ),
            ),
          );
      }
    } finally {
      if (mounted) {
        setState(() {
          _memasang4x2 = false;
          _memasang2x2 = false;
        });
      }
    }
  }

  Future<void> _tampilkanPanduanManual() async {
    final c = context.warna;
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: c.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.besar),
        ),
        title: const Text('Pasang dari layar utama'),
        content: Text(
          'Peluncur ponsel ini memerlukan pemasangan langsung dari layar utama:\n\n'
          '1. Tekan lama area kosong di layar utama HP.\n'
          '2. Ketuk menu Widget, lalu cari FoodCal AI.\n'
          '3. Tahan dan tarik widget 4×2 atau 2×2 ke posisi yang diinginkan.',
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 13,
            height: 1.55,
            color: c.inkSoft,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Mengerti'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = context.warna;
    final gelap = context.modeGelap;
    final pengaturan = ref.watch(pengaturanProvider).value ?? Pengaturan.bawaan;
    final rekap =
        ref.watch(rekapHariProvider(tanggalHariIni())).value ??
        RekapHarian.kosong;
    final persen = persenTarget(
      pengaturan.targetKalori.toDouble(),
      rekap.kalori,
    );

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
                TombolLingkaran(
                  ikonGaris: JenisIkon.kembali,
                  label: 'Kembali',
                  latar: c.surface,
                  onPressed: () => Navigator.of(context).maybePop(),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Widget Layar Utama',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: c.ink,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              'Pantau kalori harian langsung dari layar utama HP dan buka kamera sekali ketuk. Angka diperbarui otomatis setiap kali kamu mencatat makan.',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 13,
                height: 1.5,
                color: c.inkSoft,
              ),
            ),
            const SizedBox(height: 18),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Widget 4×2 · layar utama ponsel',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: c.inkSoft,
                  ),
                ),
                if (_status.empatKaliDua > 0)
                  _LencanaTerpasang(jumlah: _status.empatKaliDua),
              ],
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(28),
                border: Border.all(
                  color: gelap
                      ? const Color(0xFF2E2E2E)
                      : const Color(0xFFE2E2E2),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 28,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'FoodCal AI · Hari ini',
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 12,
                            color: Color(0xFF5F5F5F),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          formatKalori(rekap.kalori),
                          style: const TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 36,
                            fontWeight: FontWeight.w700,
                            height: 1,
                            letterSpacing: -1,
                            color: Color(0xFF111111),
                            fontFeatures: [FontFeature.tabularFigures()],
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'dari ${formatRibuan(pengaturan.targetKalori)} kkal',
                          style: const TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 12,
                            color: Color(0xFF5F5F5F),
                            fontFeatures: [FontFeature.tabularFigures()],
                          ),
                        ),
                      ],
                    ),
                  ),
                  CincinKemajuan(
                    persen: persen,
                    ukuran: 64,
                    tebal: 6,
                    warnaTeks: const Color(0xFF111111),
                    warnaDasar: const Color(0xFFD9D9D9),
                  ),
                  const SizedBox(width: 12),
                  Material(
                    color: const Color(0xFF111111),
                    shape: const CircleBorder(),
                    clipBehavior: Clip.antiAlias,
                    child: InkWell(
                      onTap: () => Rute.kamera(context),
                      child: const SizedBox(
                        width: 52,
                        height: 52,
                        child: Center(
                          child: IkonGaris(
                            JenisIkon.kamera,
                            ukuran: 22,
                            warna: Colors.white,
                            tebal: 1.8,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            TombolUtama(
              label: 'Pasang Widget 4×2',
              ikon: Icons.add_to_home_screen_outlined,
              tinggi: 50,
              ukuranTeks: 14,
              memuat: _memasang4x2,
              onPressed: () => _pasang(
                ukuranPenuh: true,
                kalori: rekap.kalori,
                target: pengaturan.targetKalori,
              ),
            ),
            const SizedBox(height: 26),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Widget 2×2 · ringkas',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: c.inkSoft,
                  ),
                ),
                if (_status.duaKaliDua > 0)
                  _LencanaTerpasang(jumlah: _status.duaKaliDua),
              ],
            ),
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.centerLeft,
              child: Container(
                width: 168,
                height: 168,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: const Color(0xFF111111),
                  borderRadius: BorderRadius.circular(28),
                  border: gelap
                      ? Border.all(color: const Color(0xFF2E2E2E))
                      : null,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.14),
                      blurRadius: 28,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'kkal',
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 12,
                            color: Color(0xFFA3A3A3),
                          ),
                        ),
                        Container(
                          width: 10,
                          height: 10,
                          decoration: const BoxDecoration(
                            color: Color(0xFFD6382F),
                            shape: BoxShape.circle,
                          ),
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          formatKalori(rekap.kalori),
                          style: const TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 32,
                            fontWeight: FontWeight.w700,
                            height: 1,
                            letterSpacing: -1,
                            color: Colors.white,
                            fontFeatures: [FontFeature.tabularFigures()],
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${formatPersen(persen)} target',
                          style: const TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 11,
                            color: Color(0xFFA3A3A3),
                            fontFeatures: [FontFeature.tabularFigures()],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            TombolSekunder(
              label: 'Pasang Widget 2×2',
              ikon: Icons.widgets_outlined,
              tinggi: 50,
              onPressed: _memasang2x2
                  ? null
                  : () => _pasang(
                      ukuranPenuh: false,
                      kalori: rekap.kalori,
                      target: pengaturan.targetKalori,
                    ),
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: c.surface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: c.line),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Cara pasang manual dari layar utama',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: c.ink,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Tekan lama area kosong pada layar utama ponsel, pilih menu Widget, cari FoodCal AI, lalu tarik ukuran 4×2 atau 2×2 ke layar utama.',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 12,
                      height: 1.5,
                      color: c.inkSoft,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LencanaTerpasang extends StatelessWidget {
  const _LencanaTerpasang({required this.jumlah});

  final int jumlah;

  @override
  Widget build(BuildContext context) {
    final c = context.warna;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(
        color: c.ink,
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Text(
        jumlah > 1 ? 'Terpasang ($jumlah)' : 'Terpasang',
        style: TextStyle(
          fontFamily: 'Poppins',
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: c.bg,
        ),
      ),
    );
  }
}
