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
import '../hasil/pilih_makanan_page.dart';
import '../kamera/kamera_page.dart';

/// Satu makanan yang ditemukan pada satu foto.
class ItemPiring {
  ItemPiring({
    required this.kelas,
    required this.keyakinan,
    required this.porsiG,
    this.kelasPrediksiId,
  });

  KelasMakanan kelas;
  double keyakinan;
  double porsiG;

  /// Kelas yang ditebak model untuk item ini. Null bila item ditambahkan
  /// atau dipilih sendiri oleh pengguna, tanpa tebakan model.
  final int? kelasPrediksiId;

  bool get dipilihManual => kelasPrediksiId == null;

  /// Benar bila pengguna mengganti kelas hasil tebakan model.
  bool get dikoreksi => kelasPrediksiId != null && kelas.id != kelasPrediksiId;

  /// Nilai kolom `sumber_prediksi`: model, koreksi, atau manual.
  String get sumberPrediksi =>
      dipilihManual ? 'manual' : (dikoreksi ? 'koreksi' : 'model');

  NilaiGizi get gizi => hitungGizi(kelas, porsiG);

  ItemPiring salin() => ItemPiring(
    kelas: kelas,
    keyakinan: keyakinan,
    porsiG: porsiG,
    kelasPrediksiId: kelasPrediksiId,
  );
}

/// Menggabungkan hasil deteksi piring yang menunjuk ke kelas makanan yang sama,
/// dengan mempertahankan keyakinan tertinggi agar satu hidangan tidak tercatat ganda.
List<ItemPiring> gabungkanItemPiringUnik(Iterable<ItemPiring> masukan) {
  final peta = <int, ItemPiring>{};
  for (final item in masukan) {
    final ada = peta[item.kelas.id];
    if (ada == null) {
      peta[item.kelas.id] = item.salin();
    } else if (item.keyakinan > ada.keyakinan) {
      ada.keyakinan = item.keyakinan;
    }
  }
  return peta.values.toList(growable: false);
}

/// Satu foto berisi beberapa makanan: total dijumlah dan disimpan sekaligus.
class PiringPage extends ConsumerStatefulWidget {
  const PiringPage({
    super.key,
    required this.foto,
    required this.items,
    this.sumberFoto = 'kamera',
    this.ambang = 0.60,
  });

  final Uint8List foto;
  final List<ItemPiring> items;

  /// Asal foto: kamera atau galeri.
  final String sumberFoto;

  /// Ambang keyakinan; item tebakan di bawahnya ditandai perlu dicek.
  final double ambang;

  @override
  ConsumerState<PiringPage> createState() => _PiringPageState();
}

class _PiringPageState extends ConsumerState<PiringPage> {
  late List<ItemPiring> _items = [
    for (final item in widget.items) item.salin(),
  ];
  bool _menyimpan = false;
  bool _tersimpan = false;

  Future<double> _porsiTersimpanAtauAwal(KelasMakanan kelas) async {
    try {
      final repositori = await ref.read(repositoriProvider.future);
      return await repositori.pengaturan.porsiUntukKelas(
        kelas.id,
        porsiAwal(kelas),
      );
    } catch (_) {
      return porsiAwal(kelas);
    }
  }

  double get _totalKalori =>
      _items.fold(0.0, (jumlah, item) => jumlah + item.gizi.kalori);

  double _total(FungsiNilai fungsi) =>
      _items.fold(0.0, (jumlah, item) => jumlah + fungsi(item.gizi));

  Future<void> _ubahPorsi(ItemPiring item) async {
    if (_tersimpan || _menyimpan) return;
    final nilai = await showModalBottomSheet<double>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (sheetContext) => _LembarPorsi(
        kelas: item.kelas,
        porsi: item.porsiG,
        onUbah: (baru) => Navigator.of(sheetContext).pop(baru),
      ),
    );
    if (nilai == null || !mounted) return;
    setState(() => item.porsiG = nilai);
  }

  Future<void> _gantiKelas(ItemPiring item) async {
    if (_tersimpan || _menyimpan) return;
    final dipilih = await Rute.buka<KelasMakanan>(
      context,
      PilihMakananPage(judul: 'Ganti ${item.kelas.namaId}'),
    );
    if (dipilih == null || !mounted || dipilih.id == item.kelas.id) return;
    final porsi = await _porsiTersimpanAtauAwal(dipilih);
    if (!mounted) return;
    setState(() {
      item.kelas = dipilih;
      item.porsiG = porsi;
    });
  }

  Future<void> _tambahNasi() async {
    if (_tersimpan || _menyimpan) return;
    final semua = await ref.read(kelasProvider.future);
    if (!mounted) return;
    KelasMakanan? nasi;
    for (final k in semua) {
      if (k.kode == 'nasi_putih') {
        nasi = k;
        break;
      }
    }
    if (nasi == null) return;
    final nasiTerpilih = nasi;
    if (_items.any((item) => item.kelas.kode == 'nasi_putih')) return;
    final porsi = await _porsiTersimpanAtauAwal(nasiTerpilih);
    if (!mounted || _items.any((item) => item.kelas.kode == 'nasi_putih')) {
      return;
    }
    setState(() {
      _items = [
        ..._items,
        ItemPiring(
          kelas: nasiTerpilih,
          keyakinan: 0,
          porsiG: porsi,
        ),
      ];
    });
  }

  Future<void> _tambahItem() async {
    if (_tersimpan || _menyimpan) return;
    final dipilih = await Rute.buka<KelasMakanan>(
      context,
      const PilihMakananPage(judul: 'Tambah makanan'),
    );
    if (dipilih == null || !mounted) return;
    final porsi = await _porsiTersimpanAtauAwal(dipilih);
    if (!mounted) return;
    setState(() {
      _items = [
        ..._items,
        ItemPiring(
          kelas: dipilih,
          keyakinan: 0,
          porsiG: porsi,
        ),
      ];
    });
  }

  Future<void> _simpan() async {
    if (_menyimpan || _tersimpan || _items.isEmpty) return;
    setState(() => _menyimpan = true);
    final navigator = Navigator.of(context);
    final sekarang = DateTime.now();
    final tanggal = formatTanggalIso(sekarang);
    try {
      final repositori = await ref.read(repositoriProvider.future);
      final daftar = <EntriLog>[
        for (final item in _items)
          () {
            final gizi = item.gizi;
            return EntriLog(
              kelasId: item.kelas.id,
              namaSnapshot: item.kelas.namaId,
              porsiG: item.porsiG,
              kalori: gizi.kalori,
              proteinG: gizi.proteinG,
              lemakG: gizi.lemakG,
              khG: gizi.khG,
              keyakinan: item.keyakinan,
              waktu: sekarang,
              tanggal: tanggal,
              sumberFoto: widget.sumberFoto,
              dibuatPada: sekarang,
              kelasPrediksiId: item.kelasPrediksiId,
              dikoreksi: item.dikoreksi,
              sumberPrediksi: item.sumberPrediksi,
            );
          }(),
      ];
      await repositori.log.simpanBanyak(daftar);
      await repositori.pengaturan.setBanyak({
        for (final item in _items)
          KunciPengaturan.porsiKelas(item.kelas.id):
              item.porsiG.toStringAsFixed(0),
      });
      if (!mounted) return;
      segarkanCatatan(ref);
      setState(() {
        _menyimpan = false;
        _tersimpan = true;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${_items.length} makanan tersimpan di catatan'),
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

  @override
  Widget build(BuildContext context) {
    final c = context.warna;
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
                height: 220,
                width: double.infinity,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(28),
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          Image.memory(
                            widget.foto,
                            fit: BoxFit.cover,
                            gaplessPlayback: true,
                            errorBuilder: (_, _, _) =>
                                Container(color: c.surfaceAlt),
                          ),
                          Container(
                            color: Colors.black.withValues(alpha: 0.16),
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
                offset: Offset(0, -24 + geserY),
                child: child,
              ),
              child: Container(
                padding: const EdgeInsets.fromLTRB(20, 22, 20, 30),
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
                            '${_items.length} makanan terdeteksi',
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: c.ink,
                            ),
                          ),
                        ),
                        if (!_items.any((i) => i.kelas.kode == 'nasi_putih'))
                          TextButton(
                            onPressed: _tersimpan ? null : _tambahNasi,
                            child: Text(
                              'Nasi',
                              style: TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: c.accent,
                              ),
                            ),
                          ),
                        TextButton.icon(
                          onPressed: _tersimpan ? null : _tambahItem,
                          icon: Icon(Icons.add, size: 18, color: c.accent),
                          label: Text(
                            'Tambah',
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
                    Text(
                      'Periksa satu per satu, lalu simpan sekaligus.',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 12,
                        color: c.inkSoft,
                      ),
                    ),
                    const SizedBox(height: 14),
                    AnimatedSize(
                      duration: context.kurangiGerak
                          ? Duration.zero
                          : const Duration(milliseconds: 200),
                      curve: Curves.easeOutCubic,
                      alignment: Alignment.topCenter,
                      child: Column(
                        children: [
                          for (final item in _items)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: _BarisItem(
                                item: item,
                                ambang: widget.ambang,
                                terkunci: _tersimpan,
                                onPorsi: () => _ubahPorsi(item),
                                onGanti: () => _gantiKelas(item),
                                onHapus: (!_tersimpan && _items.length > 1)
                                    ? () => setState(() => _items.remove(item))
                                    : null,
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                        color: c.maroon,
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _TotalKolom(
                            label: 'Total',
                            nilai: '${formatKalori(_totalKalori)} kkal',
                            terang: true,
                          ),
                          _TotalKolom(
                            label: 'Protein',
                            nilai: '${tampilkanMakro(_total((g) => g.proteinG))} g',
                            terang: false,
                          ),
                          _TotalKolom(
                            label: 'Lemak',
                            nilai: '${tampilkanMakro(_total((g) => g.lemakG))} g',
                            terang: false,
                          ),
                          _TotalKolom(
                            label: 'Karbo',
                            nilai: '${tampilkanMakro(_total((g) => g.khG))} g',
                            terang: false,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),
                    TombolUtama(
                      label: 'Simpan ${_items.length} Makanan',
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

typedef FungsiNilai = double Function(NilaiGizi);

class _BarisItem extends StatelessWidget {
  const _BarisItem({
    required this.item,
    required this.ambang,
    required this.terkunci,
    required this.onPorsi,
    required this.onGanti,
    this.onHapus,
  });

  final ItemPiring item;
  final double ambang;
  final bool terkunci;
  final VoidCallback onPorsi;
  final VoidCallback onGanti;
  final VoidCallback? onHapus;

  String _labelStatus() {
    if (item.dipilihManual) return 'dipilih manual';
    if (item.dikoreksi) return 'dikoreksi';
    final persen = '${formatPersen(item.keyakinan * 100)} yakin';
    if (item.keyakinan < ambang) {
      return '$persen · perlu dicek';
    }
    return persen;
  }

  @override
  Widget build(BuildContext context) {
    final c = context.warna;
    final perluDicek =
        !item.dipilihManual && !item.dikoreksi && item.keyakinan < ambang;
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 10, 12),
      decoration: BoxDecoration(
        color: c.surfaceAlt,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.kelas.namaId,
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: c.ink,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${_labelStatus()} · ${formatPorsi(item.porsiG)}',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 11,
                        fontWeight:
                            perluDicek ? FontWeight.w500 : FontWeight.w400,
                        color: perluDicek ? c.accent : c.inkSoft,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                formatKalori(item.gizi.kalori),
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: c.ink,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
              if (onHapus != null) ...[
                const SizedBox(width: 4),
                IconButton(
                  onPressed: onHapus,
                  icon: Icon(Icons.close, size: 16, color: c.muted),
                  visualDensity: VisualDensity.compact,
                  tooltip: 'Hapus item',
                ),
              ] else
                const SizedBox(width: 4),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              _PilKecil(
                label: 'Atur porsi',
                onTap: terkunci ? null : onPorsi,
              ),
              const SizedBox(width: 8),
              _PilKecil(
                label: 'Ganti makanan',
                onTap: terkunci ? null : onGanti,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PilKecil extends StatelessWidget {
  const _PilKecil({required this.label, required this.onTap});

  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.warna;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.pill),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: c.surface,
          borderRadius: BorderRadius.circular(AppRadius.pill),
          border: Border.all(color: c.line),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: c.ink,
          ),
        ),
      ),
    );
  }
}

class _TotalKolom extends StatelessWidget {
  const _TotalKolom({
    required this.label,
    required this.nilai,
    required this.terang,
  });

  final String label;
  final String nilai;
  final bool terang;

  @override
  Widget build(BuildContext context) {
    final c = context.warna;
    final warna = terang ? c.onMaroon : c.onMaroon.withValues(alpha: 0.72);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 10,
            color: warna,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          nilai,
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: terang ? 15 : 13,
            fontWeight: FontWeight.w700,
            color: c.onMaroon,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
      ],
    );
  }
}

class _LembarPorsi extends StatelessWidget {
  const _LembarPorsi({
    required this.kelas,
    required this.porsi,
    required this.onUbah,
  });

  final KelasMakanan kelas;
  final double porsi;
  final ValueChanged<double> onUbah;

  @override
  Widget build(BuildContext context) {
    final c = context.warna;
    return Container(
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            kelas.namaId,
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: c.ink,
            ),
          ),
          const SizedBox(height: 12),
          PemilihPorsi(kelas: kelas, porsi: porsi, onUbah: onUbah),
          const SizedBox(height: 8),
          TombolSekunder(
            label: 'Tutup',
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }
}
