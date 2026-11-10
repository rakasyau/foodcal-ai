import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../../app/router.dart';
import '../../app/theme.dart';
import '../../core/formatter.dart';
import '../../domain/model.dart';
import '../../widgets/ikon_svg.dart';
import '../../widgets/tombol.dart';
import '../kamera/kamera_page.dart';
import '../kamera/metode_foto.dart';
import 'hasil_page.dart';
import 'pilih_makanan_page.dart';

class BelumDikenaliPage extends StatelessWidget {
  const BelumDikenaliPage({
    super.key,
    required this.keyakinan,
    required this.ambang,
    required this.foto,
    required this.sumberFoto,
  });

  final double keyakinan;
  final double ambang;
  final Uint8List foto;
  final String sumberFoto;

  Future<void> _pilihSendiri(BuildContext context) async {
    final dipilih = await Rute.buka<KelasMakanan>(
      context,
      const PilihMakananPage(judul: 'Pilih makanan'),
    );
    if (dipilih == null || !context.mounted) return;
    await Rute.ganti(
      context,
      HasilPage(
        hasil: HasilPrediksi(
          kelas: dipilih,
          keyakinan: 0,
          sumberFoto: sumberFoto,
          dipilihManual: true,
        ),
        foto: foto,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = context.warna;
    final gelap = context.modeGelap;
    final warnaKartu = gelap ? c.surface : const Color(0xFFD9D9D9);
    final warnaLingkaran = gelap ? c.surfaceAlt : Colors.white;

    return Scaffold(
      backgroundColor: c.bg,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(
            AppJarak.halaman,
            12,
            AppJarak.halaman,
            28,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: TombolLingkaran(
                  ikonGaris: JenisIkon.kembali,
                  label: 'Kembali',
                  latar: c.surface,
                  onPressed: () => Navigator.of(context).maybePop(),
                ),
              ),
              const SizedBox(height: 24),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 32,
                ),
                decoration: BoxDecoration(
                  color: warnaKartu,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Column(
                  children: [
                    Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        color: warnaLingkaran,
                        shape: BoxShape.circle,
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        '?',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 32,
                          fontWeight: FontWeight.w600,
                          color: c.ink,
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    Text(
                      'Makanan belum dikenali',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: c.ink,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text.rich(
                      TextSpan(
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 14,
                          height: 1.5,
                          color: c.inkSoft,
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                        children: [
                          const TextSpan(text: 'Keyakinan model hanya '),
                          TextSpan(
                            text: formatPersen(keyakinan * 100),
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: c.ink,
                            ),
                          ),
                          const TextSpan(text: ', di bawah ambang '),
                          TextSpan(
                            text: formatPersen(ambang * 100),
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: c.ink,
                            ),
                          ),
                          const TextSpan(
                            text:
                                '. Coba foto dari atas piring dengan cahaya yang cukup.',
                          ),
                        ],
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              TombolUtama(
                label: 'Foto Ulang',
                onPressed: () => Rute.ganti(context, const KameraPage()),
              ),
              const SizedBox(height: 10),
              TombolSekunder(
                label: 'Pilih dari Galeri',
                onPressed: () => ambilDariGaleri(context),
              ),
              const SizedBox(height: 10),
              TombolSekunder(
                label: 'Pilih Makanan Sendiri',
                onPressed: () => _pilihSendiri(context),
              ),
              const SizedBox(height: 16),
              Text(
                'Foto tidak disimpan dan tidak diunggah.',
                textAlign: TextAlign.center,
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
    );
  }
}
