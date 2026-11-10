import 'package:flutter/material.dart';

import '../app/theme.dart';
import '../core/formatter.dart';
import '../domain/model.dart';
import 'ikon_svg.dart';

IconData ikonKelompok(String kelompok) {
  switch (kelompok) {
    case 'Padang':
      return Icons.local_fire_department_outlined;
    case 'Internasional':
      return Icons.restaurant_outlined;
    default:
      return Icons.rice_bowl_outlined;
  }
}

class BarisEntri extends StatelessWidget {
  const BarisEntri({
    super.key,
    required this.entri,
    this.onTap,
    this.aksi,
    this.tampilkanGarisBawah = true,
    this.gantiKaloriDenganAksi = true,
    this.tampilkanTanggal = false,
  });

  final EntriLog entri;
  final VoidCallback? onTap;
  final Widget? aksi;
  final bool tampilkanGarisBawah;
  final bool gantiKaloriDenganAksi;
  final bool tampilkanTanggal;

  @override
  Widget build(BuildContext context) {
    final c = context.warna;
    final kurangi = context.kurangiGerak;
    final durasiAksi = kurangi
        ? Duration.zero
        : const Duration(milliseconds: 180);

    final Widget ekor;
    if (aksi != null && gantiKaloriDenganAksi) {
      ekor = KeyedSubtree(key: const ValueKey<String>('aksi'), child: aksi!);
    } else {
      ekor = Row(
        key: const ValueKey<String>('kalori'),
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '- ${formatKalori(entri.kalori)} kkal',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: c.ink,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
          if (aksi != null) ...[const SizedBox(width: 8), aksi!],
        ],
      );
    }

    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          border: tampilkanGarisBawah
              ? Border(bottom: BorderSide(color: c.line, width: 1))
              : null,
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: c.surfaceAlt,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Center(
                child: IkonGaris(
                  JenisIkon.mangkuk,
                  ukuran: 22,
                  warna: c.ink,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    entri.namaSnapshot,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: c.ink,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    () {
                      final dasar = tampilkanTanggal
                          ? '${formatTanggalDariIso(entri.tanggal)} · Porsi ${formatPorsi(entri.porsiG)} · ${formatJam(entri.waktu)}'
                          : 'Porsi ${formatPorsi(entri.porsiG)} · ${formatJam(entri.waktu)}';
                      if (aksi != null && gantiKaloriDenganAksi) {
                        return '$dasar · ${formatKalori(entri.kalori)} kkal';
                      }
                      return dasar;
                    }(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 12,
                      color: c.inkSoft,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            AnimatedSwitcher(
              duration: durasiAksi,
              switchInCurve: Curves.easeOutCubic,
              switchOutCurve: Curves.easeInCubic,
              transitionBuilder: (child, animation) {
                return FadeTransition(
                  opacity: animation,
                  child: SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(0.06, 0),
                      end: Offset.zero,
                    ).animate(animation),
                    child: child,
                  ),
                );
              },
              child: ekor,
            ),
          ],
        ),
      ),
    );
  }
}
