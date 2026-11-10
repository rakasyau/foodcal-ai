import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/main_shell.dart';
import '../../app/providers.dart';
import '../../app/router.dart';
import '../../app/theme.dart';
import '../../core/formatter.dart';
import '../../domain/model.dart';
import '../../domain/rekap.dart';
import '../../widgets/baris_entri.dart';
import '../../widgets/cincin_kemajuan.dart';
import '../../widgets/grafik_kalori.dart';
import '../../widgets/ikon_svg.dart';
import '../../widgets/keadaan_kosong.dart';
import '../../widgets/pemilih.dart';
import '../../widgets/tombol.dart';

class BerandaPage extends ConsumerStatefulWidget {
  const BerandaPage({super.key});

  @override
  ConsumerState<BerandaPage> createState() => _BerandaPageState();
}

class _BerandaPageState extends ConsumerState<BerandaPage> {
  int _rentang = 7;

  @override
  Widget build(BuildContext context) {
    final c = context.warna;
    final gelap = context.modeGelap;
    final pengaturan = ref.watch(pengaturanProvider).value ?? Pengaturan.bawaan;
    final tanggal = tanggalHariIni();
    final rekap =
        ref.watch(rekapHariProvider(tanggal)).value ?? RekapHarian.kosong;
    final entri = ref.watch(entriHariProvider(tanggal)).value ?? const [];
    final titik =
        ref.watch(rekapRentangProvider(_rentang)).value ??
        const <TitikHarian>[];
    final totalRentang = titik.fold<double>(
      0,
      (jumlah, item) => jumlah + item.kalori,
    );
    final targetDouble = pengaturan.targetKalori.toDouble();
    final lewat = melebihiTarget(targetDouble, rekap.kalori);
    final persen = persenTarget(targetDouble, rekap.kalori);

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
                child: Text.rich(
                  TextSpan(
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 18,
                      fontWeight: FontWeight.w400,
                      color: c.inkSoft,
                    ),
                    children: [
                      const TextSpan(text: 'Halo, '),
                      TextSpan(
                        text: pengaturan.namaTampil,
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: c.ink,
                        ),
                      ),
                    ],
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 12),
              TombolLingkaran(
                ikonGaris: JenisIkon.lonceng,
                label: 'Pengaturan',
                latar: c.surface,
                onPressed: () => Rute.pengaturan(context),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AnimatedDefaultTextStyle(
                      duration: context.kurangiGerak
                          ? Duration.zero
                          : const Duration(milliseconds: 220),
                      curve: Curves.easeOutCubic,
                      style: gayaAngka(
                        context,
                        ukuran: 46,
                        warna: lewat ? c.accent : c.ink,
                      ),
                      child: Text(formatKalori(rekap.kalori)),
                    ),
                    const SizedBox(height: 6),
                    AnimatedDefaultTextStyle(
                      duration: context.kurangiGerak
                          ? Duration.zero
                          : const Duration(milliseconds: 220),
                      curve: Curves.easeOutCubic,
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 12,
                        fontWeight: lewat ? FontWeight.w500 : FontWeight.w400,
                        color: lewat ? c.accent : c.inkSoft,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                      child: Text(
                        lewat
                            ? 'Melebihi target ${formatRibuan(selisihTarget(targetDouble, rekap.kalori))} kkal'
                            : 'kkal hari ini · target ${formatRibuan(pengaturan.targetKalori)}',
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              CincinKemajuan(persen: persen),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: c.maroon,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(
                      child: Text(
                        _rentang == 1 ? 'Hari ini' : '$_rentang hari terakhir',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 12,
                          color: gelap
                              ? const Color(0xFFA3A3A3)
                              : const Color(0xFFB5B5B5),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: c.accent,
                        borderRadius: BorderRadius.circular(AppRadius.pill),
                      ),
                      child: AnimatedSwitcher(
                        duration: context.kurangiGerak
                            ? Duration.zero
                            : const Duration(milliseconds: 180),
                        child: Text(
                          '${formatRibuan(totalRentang)} kkal',
                          key: ValueKey<String>(
                            '$_rentang-${formatRibuan(totalRentang)}',
                          ),
                          style: const TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                            fontFeatures: [FontFeature.tabularFigures()],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                GrafikGaris(data: titik, target: targetDouble),
              ],
            ),
          ),
          const SizedBox(height: 14),
          PemilihRentang(
            nilai: _rentang,
            onChanged: (nilai) => setState(() => _rentang = nilai),
          ),
          const SizedBox(height: 18),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Text(
                  'Catatan Hari Ini',
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
                onTap: () {
                  if (!MainShell.pindahTab(context, 1)) {
                    Rute.catatan(context);
                  }
                },
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 4,
                    vertical: 2,
                  ),
                  child: Text(
                    'Lihat semua',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 12,
                      color: c.inkSoft,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          if (entri.isEmpty)
            KeadaanKosong(
              judul: 'Belum ada catatan hari ini',
              pesan: 'Foto makananmu, lalu simpan. Catatan muncul di sini.',
              labelTombol: 'Buka Kamera',
              jarakAtas: 14,
              ringkas: true,
              onPressed: () => Rute.kamera(context),
            )
          else
            Column(
              children: [
                for (var i = 0; i < entri.length && i < 3; i++)
                  BarisEntri(
                    entri: entri[i],
                    onTap: () => Rute.ubahEntri(context, entri[i]),
                  ),
              ],
            ),
        ],
      ),
    );
  }
}
