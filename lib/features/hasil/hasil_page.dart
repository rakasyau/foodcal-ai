import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../app/router.dart';
import '../../app/theme.dart';
import '../../core/formatter.dart';
import '../../domain/kalkulator_gizi.dart';
import '../../domain/model.dart';
import '../../widgets/ikon_svg.dart';
import '../../widgets/pemilih_porsi.dart';
import '../../widgets/tombol.dart';
import '../catatan/catatan_harian_page.dart';
import '../piring/piring_page.dart';
import '../kamera/kamera_page.dart';
import 'koreksi_sheet.dart';

class HasilPage extends ConsumerStatefulWidget {
  const HasilPage({super.key, required this.hasil, required this.foto});

  final HasilPrediksi hasil;
  final Uint8List foto;

  @override
  ConsumerState<HasilPage> createState() => _HasilPageState();
}

class _HasilPageState extends ConsumerState<HasilPage> {
  late KelasMakanan _kelas = widget.hasil.kelas;
  late double _porsi = porsiAwal(widget.hasil.kelas);
  late bool _dipilihManual = widget.hasil.dipilihManual;
  late final int? _kelasPrediksiId =
      widget.hasil.dipilihManual ? null : widget.hasil.kelas.id;
  bool _dikoreksi = false;
  bool _porsiDiubahPengguna = false;
  bool _menyimpan = false;
  bool _tersimpan = false;

  @override
  void initState() {
    super.initState();
    _muatPorsiTerakhir();
  }

  Future<void> _muatPorsiTerakhir([int? idKelas]) async {
    final targetId = idKelas ?? _kelas.id;
    try {
      final repositori = await ref.read(repositoriProvider.future);
      final nilai = await repositori.pengaturan.nilai(
        KunciPengaturan.porsiKelas(targetId),
      );
      final tersimpan = double.tryParse(nilai ?? '');
      if (!mounted ||
          tersimpan == null ||
          _kelas.id != targetId ||
          _porsiDiubahPengguna) {
        return;
      }
      setState(() => _porsi = batasiPorsi(tersimpan));
    } catch (_) {
      // Porsi tersimpan bersifat tambahan, kegagalan tidak menghalangi.
    }
  }

  Future<void> _gantiKelas() async {
    if (_menyimpan || _tersimpan) return;
    final dipilih = await tampilkanKoreksi(
      context,
      kandidat: widget.hasil.kandidat,
      idTerpilih: _kelas.id,
    );
    if (dipilih == null || !mounted || dipilih.id == _kelas.id) return;
    setState(() {
      _porsiDiubahPengguna = false;
      _dikoreksi = _kelasPrediksiId != null && dipilih.id != _kelasPrediksiId;
      _dipilihManual = _kelasPrediksiId == null;
      _kelas = dipilih;
      _porsi = porsiAwal(dipilih);
    });
    await _muatPorsiTerakhir(dipilih.id);
  }

  Future<void> _simpan() async {
    if (_menyimpan || _tersimpan) return;
    setState(() => _menyimpan = true);
    final navigator = Navigator.of(context);
    final gizi = hitungGizi(_kelas, _porsi);
    final sekarang = DateTime.now();
    final entri = EntriLog(
      kelasId: _kelas.id,
      namaSnapshot: _kelas.namaId,
      porsiG: _porsi,
      kalori: gizi.kalori,
      proteinG: gizi.proteinG,
      lemakG: gizi.lemakG,
      khG: gizi.khG,
      keyakinan: widget.hasil.keyakinan,
      waktu: sekarang,
      tanggal: formatTanggalIso(sekarang),
      sumberFoto: widget.hasil.sumberFoto,
      dibuatPada: sekarang,
      kelasPrediksiId: _kelasPrediksiId,
      dikoreksi: _dikoreksi,
      sumberPrediksi: _dikoreksi
          ? 'koreksi'
          : (_kelasPrediksiId == null ? 'manual' : 'model'),
    );
    try {
      final repositori = await ref.read(repositoriProvider.future);
      await repositori.log.simpan(entri);
      await repositori.pengaturan.set(
        KunciPengaturan.porsiKelas(_kelas.id),
        _porsi.toStringAsFixed(0),
      );
      if (!mounted) return;
      segarkanCatatan(ref);
      setState(() {
        _menyimpan = false;
        _tersimpan = true;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${_kelas.namaId} tersimpan di catatan'),
          action: SnackBarAction(
            label: 'Lihat Catatan',
            onPressed: () {
              if (!navigator.mounted) return;
              Rute.hapusSampaiAwal<void>(
                navigator,
                const CatatanHarianPage(),
              );
            },
          ),
        ),
      );
    } catch (_) {
      if (!mounted) return;
      setState(() => _menyimpan = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Catatan gagal disimpan. Coba lagi.')),
      );
    }
  }

  Future<void> _tambahNasi() async {
    if (_menyimpan || _tersimpan) return;
    final repositori = await ref.read(repositoriProvider.future);
    final semua = await ref.read(kelasProvider.future);
    final pengaturan = await ref.read(pengaturanProvider.future);
    if (!mounted) return;
    final nasi = semua.firstWhere(
      (k) => k.kode == 'nasi_putih',
      orElse: () => _kelas,
    );
    if (nasi.id == _kelas.id) return;
    final porsiNasi = await repositori.pengaturan.porsiUntukKelas(
      nasi.id,
      porsiAwal(nasi),
    );
    if (!mounted) return;
    final utama = ItemPiring(
      kelas: _kelas,
      keyakinan: widget.hasil.keyakinan,
      porsiG: _porsi,
      kelasPrediksiId: _kelasPrediksiId,
    );
    final pendamping = ItemPiring(
      kelas: nasi,
      keyakinan: 0,
      porsiG: porsiNasi,
    );
    await Rute.ganti(
      context,
      PiringPage(
        foto: widget.foto,
        items: [utama, pendamping],
        sumberFoto: widget.hasil.sumberFoto,
        ambang: pengaturan.ambangKeyakinan,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = context.warna;
    final gelap = context.modeGelap;
    final gizi = hitungGizi(_kelas, _porsi);
    final warnaKotakMakro = gelap
        ? const Color(0xFF242424)
        : const Color(0xFFF2F2F2);
    final warnaGarisMakro = gelap
        ? const Color(0xFF3A3A3A)
        : const Color(0xFFD9D9D9);

    return Scaffold(
      backgroundColor: c.bg,
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
              child: SizedBox(
                height: 290,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(28),
                      child: Container(
                        color: gelap
                            ? const Color(0xFF3A3A3A)
                            : const Color(0xFFD9D9D9),
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            Image.memory(
                              widget.foto,
                              fit: BoxFit.cover,
                              gaplessPlayback: true,
                              errorBuilder: (_, _, _) =>
                                  const SizedBox.shrink(),
                            ),
                            Container(
                              color: Colors.black.withValues(alpha: 0.18),
                            ),
                            Center(
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: c.surface.withValues(alpha: 0.82),
                                  borderRadius: BorderRadius.circular(
                                    AppRadius.pill,
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IkonGaris(
                                      JenisIkon.mangkuk,
                                      ukuran: 18,
                                      warna: c.inkSoft,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Pratinjau foto (tidak disimpan)',
                                      style: TextStyle(
                                        fontFamily: 'Poppins',
                                        fontSize: 12,
                                        color: c.inkSoft,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    Positioned(
                      top: 12,
                      left: 12,
                      child: TombolLingkaran(
                        ikonGaris: JenisIkon.kembali,
                        label: 'Kembali',
                        latar: c.surface,
                        depan: c.ink,
                        onPressed: () => Navigator.of(context).maybePop(),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            TweenAnimationBuilder<double>(
              tween: Tween<double>(
                begin: context.kurangiGerak ? 0 : 14,
                end: 0,
              ),
              duration: context.kurangiGerak
                  ? Duration.zero
                  : const Duration(milliseconds: 260),
              curve: Curves.easeOutCubic,
              builder: (context, geserY, child) => Transform.translate(
                offset: Offset(0, -26 + geserY),
                child: child,
              ),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
                decoration: BoxDecoration(
                  color: c.surface,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(32),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            _kelas.namaId,
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 20,
                              fontWeight: FontWeight.w600,
                              color: c.ink,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: c.ink,
                            borderRadius: BorderRadius.circular(AppRadius.pill),
                          ),
                          child: Text(
                            _dipilihManual
                                ? 'dipilih manual'
                                : (_dikoreksi
                                      ? 'dikoreksi'
                                      : '${formatPersen(widget.hasil.keyakinan * 100)} yakin'),
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: c.bg,
                              fontFeatures: const [
                                FontFeature.tabularFigures(),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${_kelas.labelKelompok} · porsi referensi ${formatPorsi(_kelas.porsiRefG)}',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 12,
                        color: c.inkSoft,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text(
                          formatKalori(gizi.kalori),
                          style: gayaAngka(context, ukuran: 48),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'kkal',
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 16,
                            color: c.inkSoft,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          'perkiraan',
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 12,
                            color: c.inkSoft,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: warnaKotakMakro,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: IntrinsicHeight(
                        child: Row(
                          children: [
                            _MakroKolom(
                              label: 'Protein',
                              nilai: '${tampilkanMakro(gizi.proteinG)} g',
                            ),
                            VerticalDivider(
                              width: 1,
                              thickness: 1,
                              color: warnaGarisMakro,
                            ),
                            _MakroKolom(
                              label: 'Lemak',
                              nilai: '${tampilkanMakro(gizi.lemakG)} g',
                            ),
                            VerticalDivider(
                              width: 1,
                              thickness: 1,
                              color: warnaGarisMakro,
                            ),
                            _MakroKolom(
                              label: 'Karbo',
                              nilai: '${tampilkanMakro(gizi.khG)} g',
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    PemilihPorsi(
                      kelas: _kelas,
                      porsi: _porsi,
                      onUbah: (nilai) {
                        if (_tersimpan || _menyimpan) return;
                        setState(() {
                          _porsiDiubahPengguna = true;
                          _porsi = nilai;
                        });
                      },
                    ),
                    const SizedBox(height: 4),
                    Wrap(
                      spacing: 16,
                      runSpacing: 4,
                      children: [
                        if (_kelas.kode != 'nasi_putih')
                          TextButton.icon(
                            onPressed: (_tersimpan || _menyimpan)
                                ? null
                                : _tambahNasi,
                            style: TextButton.styleFrom(
                              padding: EdgeInsets.zero,
                              minimumSize: const Size(0, 36),
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            icon: Icon(
                              Icons.rice_bowl_outlined,
                              size: 18,
                              color: c.accent,
                            ),
                            label: Text(
                              'Ada nasi juga',
                              style: TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: c.accent,
                              ),
                            ),
                          ),
                        TextButton.icon(
                          onPressed: (_tersimpan || _menyimpan)
                              ? null
                              : _gantiKelas,
                          style: TextButton.styleFrom(
                            padding: EdgeInsets.zero,
                            minimumSize: const Size(0, 36),
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          icon: Icon(
                            Icons.swap_horiz,
                            size: 18,
                            color: c.accent,
                          ),
                          label: Text(
                            'Bukan ini? Ganti makanan',
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: c.accent,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    TombolUtama(
                      label: 'Simpan ke Catatan',
                      onPressed: _tersimpan ? null : _simpan,
                      memuat: _menyimpan,
                    ),
                    const SizedBox(height: 10),
                    TombolSekunder(
                      label: 'Foto Ulang',
                      onPressed: () => Rute.ganti(context, const KameraPage()),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MakroKolom extends StatelessWidget {
  const _MakroKolom({required this.label, required this.nilai});

  final String label;
  final String nilai;

  @override
  Widget build(BuildContext context) {
    final c = context.warna;
    return Expanded(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 12,
              color: c.inkSoft,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            nilai,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: c.ink,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }
}
