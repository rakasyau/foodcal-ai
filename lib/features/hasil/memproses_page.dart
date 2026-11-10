import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../app/router.dart';
import '../../app/theme.dart';
import '../../domain/kalkulator_gizi.dart';
import '../../domain/model.dart';
import '../../domain/peta_kelas_deteksi.dart';
import '../../services/deteksi_service.dart';
import '../../services/potong_citra.dart';
import '../../widgets/ikon_svg.dart';
import '../../widgets/tombol.dart';
import '../piring/piring_page.dart';
import 'belum_dikenali_page.dart';
import 'hasil_page.dart';

class MemprosesPage extends ConsumerStatefulWidget {
  const MemprosesPage({
    super.key,
    required this.foto,
    required this.sumberFoto,
  });

  final Uint8List foto;
  final String sumberFoto;

  @override
  ConsumerState<MemprosesPage> createState() => _MemprosesPageState();
}

class _MemprosesPageState extends ConsumerState<MemprosesPage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animasi = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  )..repeat(reverse: true);

  bool _batal = false;
  String? _galat;

  @override
  void initState() {
    super.initState();
    _mulai();
  }

  @override
  void dispose() {
    _batal = true;
    _animasi.dispose();
    super.dispose();
  }

  Future<void> _mulai() async {
    try {
      final repositori = await ref.read(repositoriProvider.future);
      final kelas = await repositori.kelas.semua();
      final pengaturan = await ref.read(pengaturanProvider.future);
      if (_batal || !mounted) return;

      // Deteksi wilayah makanan: kalau ada dua atau lebih, susun satu piring.
      var deteksi = HasilDeteksi.kosong;
      try {
        deteksi = await ref
            .read(deteksiProvider)
            .deteksiLengkap(gambar: widget.foto);
      } catch (_) {
        deteksi = HasilDeteksi.kosong;
      }
      if (_batal || !mounted) return;

      // Pecah jadi beberapa item hanya bila detektor benar-benar menemukan
      // wilayah kedua yang cukup besar. Kalau tidak, tetap alur satu makanan,
      // dan pengguna bisa menambah nasi atau lauk lewat tombol di layar hasil.
      final luasGambar = deteksi.luasCitra;
      final kandidat = deteksi.kotak.take(4).toList();
      final layakPiring =
          kandidat.length >= 2 &&
          luasGambar > 0 &&
          kandidat[1].kotak.luas > luasGambar * 0.06;

      if (layakPiring) {
        final indeksPerluPotong = <int>[];
        final hasilSementara = List<ItemPiring?>.filled(kandidat.length, null);
        final dariDetektor = List<bool>.filled(kandidat.length, false);
        for (var i = 0; i < kandidat.length; i++) {
          final langsung = _itemDariDeteksi(kandidat[i], kelas);
          if (langsung != null) {
            hasilSementara[i] = langsung;
            dariDetektor[i] = true;
          } else {
            indeksPerluPotong.add(i);
          }
        }

        var potongan = const <Uint8List>[];
        if (indeksPerluPotong.isNotEmpty) {
          try {
            potongan = await potongBanyakWilayah(
              widget.foto,
              [for (final idx in indeksPerluPotong) kandidat[idx].kotak],
            );
          } catch (_) {
            potongan = const <Uint8List>[];
          }
          if (_batal || !mounted) return;
        }

        for (var p = 0; p < indeksPerluPotong.length; p++) {
          if (p >= potongan.length) break;
          final idx = indeksPerluPotong[p];
          try {
            final hasil = await ref
                .read(inferensiProvider)
                .prediksi(
                  berkasGambar: potongan[p],
                  kelas: kelas,
                  tta: pengaturan.ttaAktif,
                  namaModel: pengaturan.modelAktif,
                  sumberFoto: widget.sumberFoto,
                );
            // Abaikan potongan yang keyakinannya terlalu lemah (kemungkinan bukan makanan).
            if (hasil.keyakinan >= 0.25) {
              hasilSementara[idx] = ItemPiring(
                kelas: hasil.kelas,
                keyakinan: hasil.keyakinan,
                porsiG: porsiAwal(hasil.kelas),
                kelasPrediksiId: hasil.kelas.id,
              );
            }
          } catch (_) {
            // Satu potongan gagal tidak membatalkan seluruh piring.
          }
          if (_batal || !mounted) return;
        }

        final mentahItems = <ItemPiring>[];
        var adaYangYakin = false;
        final ambangDetektor = math.min(0.45, pengaturan.ambangKeyakinan);
        for (var i = 0; i < hasilSementara.length; i++) {
          final item = hasilSementara[i];
          if (item == null) continue;
          item.porsiG = await repositori.pengaturan.porsiUntukKelas(
            item.kelas.id,
            item.porsiG,
          );
          mentahItems.add(item);
          final batas = dariDetektor[i]
              ? ambangDetektor
              : pengaturan.ambangKeyakinan;
          if (item.keyakinan >= batas) {
            adaYangYakin = true;
          }
        }
        if (_batal || !mounted) return;

        final items = gabungkanItemPiringUnik(mentahItems);
        if (items.length >= 2 && adaYangYakin) {
          await Rute.ganti(
            context,
            PiringPage(
              foto: widget.foto,
              items: items,
              sumberFoto: widget.sumberFoto,
              ambang: pengaturan.ambangKeyakinan,
            ),
          );
          return;
        }
      }

      final hasil = await ref
          .read(inferensiProvider)
          .prediksi(
            berkasGambar: widget.foto,
            kelas: kelas,
            tta: pengaturan.ttaAktif,
            namaModel: pengaturan.modelAktif,
            sumberFoto: widget.sumberFoto,
          );
      if (_batal || !mounted) return;
      if (hasil.keyakinan < pengaturan.ambangKeyakinan) {
        await Rute.ganti(
          context,
          BelumDikenaliPage(
            keyakinan: hasil.keyakinan,
            ambang: pengaturan.ambangKeyakinan,
            foto: widget.foto,
            sumberFoto: widget.sumberFoto,
          ),
        );
      } else {
        await Rute.ganti(context, HasilPage(hasil: hasil, foto: widget.foto));
      }
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _galat = 'Analisis belum berhasil. Periksa foto lalu coba lagi.';
      });
    }
  }

  /// Item piring langsung dari kelas detektor, atau null bila kelas itu tidak
  /// punya padanan aman di basis data.
  ItemPiring? _itemDariDeteksi(KotakDeteksi kotak, List<KelasMakanan> kelas) {
    final kode = kodeDariDeteksi(kotak.kelas);
    if (kode == null) return null;
    for (final k in kelas) {
      if (k.kode == kode) {
        return ItemPiring(
          kelas: k,
          keyakinan: kotak.skor,
          porsiG: porsiAwal(k),
          kelasPrediksiId: k.id,
        );
      }
    }
    return null;
  }

  void _batalkan() {
    _batal = true;
    Navigator.of(context).maybePop();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.warna;
    final kurangi = context.kurangiGerak;
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
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          Container(color: c.line),
                          Image.memory(
                            widget.foto,
                            fit: BoxFit.cover,
                            gaplessPlayback: true,
                            errorBuilder: (_, _, _) => const SizedBox.shrink(),
                          ),
                          AnimatedBuilder(
                            animation: _animasi,
                            builder: (context, _) {
                              final gelap = kurangi
                                  ? 0.28
                                  : (0.18 + (_animasi.value * 0.22));
                              return Container(
                                color: Colors.black.withValues(alpha: gelap),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                    Positioned(
                      top: 12,
                      left: 12,
                      child: TombolLingkaran(
                        ikonGaris: JenisIkon.kembali,
                        label: 'Batalkan',
                        latar: c.surface,
                        depan: c.ink,
                        onPressed: _batalkan,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Transform.translate(
              offset: const Offset(0, -26),
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
                    AnimatedBuilder(
                      animation: _animasi,
                      builder: (context, child) {
                        return Opacity(
                          opacity: kurangi
                              ? 0.85
                              : (0.55 + (_animasi.value * 0.45)),
                          child: child,
                        );
                      },
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Container(
                                width: 170,
                                height: 28,
                                decoration: BoxDecoration(
                                  color: c.surfaceAlt,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              Container(
                                width: 84,
                                height: 28,
                                decoration: BoxDecoration(
                                  color: c.surfaceAlt,
                                  borderRadius: BorderRadius.circular(
                                    AppRadius.pill,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Container(
                            width: 210,
                            height: 14,
                            decoration: BoxDecoration(
                              color: c.surfaceAlt,
                              borderRadius: BorderRadius.circular(6),
                            ),
                          ),
                          const SizedBox(height: 20),
                          Container(
                            width: 150,
                            height: 52,
                            decoration: BoxDecoration(
                              color: c.surfaceAlt,
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          const SizedBox(height: 18),
                          Container(
                            width: double.infinity,
                            height: 68,
                            decoration: BoxDecoration(
                              color: c.surfaceAlt,
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          const SizedBox(height: 22),
                          Container(
                            width: double.infinity,
                            height: 8,
                            decoration: BoxDecoration(
                              color: c.surfaceAlt,
                              borderRadius: BorderRadius.circular(
                                AppRadius.pill,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 26),
                    Center(
                      child: Text(
                        _galat ?? 'Sedang menganalisis…',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: c.inkSoft,
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    if (_galat == null)
                      TombolSekunder(label: 'Batalkan', onPressed: _batalkan)
                    else
                      Row(
                        children: [
                          Expanded(
                            child: TombolSekunder(
                              label: 'Batalkan',
                              onPressed: _batalkan,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: TombolUtama(
                              label: 'Coba Lagi',
                              onPressed: () {
                                setState(() => _galat = null);
                                _mulai();
                              },
                            ),
                          ),
                        ],
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
