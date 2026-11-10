import 'package:app_settings/app_settings.dart';
import 'package:flutter/material.dart';

import '../../app/theme.dart';
import '../../widgets/ikon_svg.dart';
import '../../widgets/tombol.dart';
import 'metode_foto.dart';

class IzinKameraDitolakPage extends StatelessWidget {
  const IzinKameraDitolakPage({super.key, this.onPilihGaleri});

  final VoidCallback? onPilihGaleri;

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
                      child: IkonGaris(
                        JenisIkon.kameraMati,
                        ukuran: 28,
                        warna: c.ink,
                        tebal: 1.8,
                      ),
                    ),
                    const SizedBox(height: 18),
                    Text(
                      'Kamera belum bisa dipakai',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: c.ink,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Izin kamera ditolak. Nyalakan di pengaturan ponsel, atau pilih satu foto dari galeri tanpa memberi akses ke seluruh galeri.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 14,
                        height: 1.5,
                        color: c.inkSoft,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              TombolUtama(
                label: 'Buka Pengaturan',
                onPressed: () => AppSettings.openAppSettings(),
              ),
              const SizedBox(height: 10),
              TombolSekunder(
                label: 'Pilih dari Galeri',
                onPressed: onPilihGaleri ?? () => ambilDariGaleri(context),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
