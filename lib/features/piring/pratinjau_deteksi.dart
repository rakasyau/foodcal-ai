import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../services/deteksi_service.dart';

/// Palet warna kontras tinggi untuk membedakan kotak deteksi pada satu piring.
const List<Color> paletWarnaDeteksi = <Color>[
  Color(0xFFD6382F),
  Color(0xFF0D9488),
  Color(0xFFD97706),
  Color(0xFF2563EB),
];

Color warnaUntukIndeksDeteksi(int indeks) =>
    paletWarnaDeteksi[indeks % paletWarnaDeteksi.length];

/// Data satu kotak deteksi siap gambar di atas pratinjau foto.
class WilayahKotakTampil {
  const WilayahKotakTampil({
    required this.kotak,
    required this.label,
    required this.warna,
  });

  final KotakPiksel kotak;
  final String label;
  final Color warna;
}

/// Memetakan kotak koordinat piksel citra asli ke koordinat kanvas Flutter
/// sesuai `fit` (`BoxFit.contain` atau `BoxFit.cover`).
Rect petakanKotakKeKanvas({
  required KotakPiksel kotak,
  required Size ukuranCitra,
  required Size ukuranKanvas,
  BoxFit fit = BoxFit.contain,
}) {
  if (ukuranCitra.width <= 0 ||
      ukuranCitra.height <= 0 ||
      ukuranKanvas.width <= 0 ||
      ukuranKanvas.height <= 0) {
    return Rect.zero;
  }

  final rasioX = ukuranKanvas.width / ukuranCitra.width;
  final rasioY = ukuranKanvas.height / ukuranCitra.height;
  final skala = fit == BoxFit.cover
      ? math.max(rasioX, rasioY)
      : math.min(rasioX, rasioY);

  final dx = (ukuranKanvas.width - ukuranCitra.width * skala) / 2;
  final dy = (ukuranKanvas.height - ukuranCitra.height * skala) / 2;

  return Rect.fromLTRB(
    dx + kotak.kiri * skala,
    dy + kotak.atas * skala,
    dx + kotak.kanan * skala,
    dy + kotak.bawah * skala,
  );
}

/// Lapisan kotak deteksi YOLO yang digambar presisi di atas pratinjau foto.
class OverlayKotakDeteksi extends StatelessWidget {
  const OverlayKotakDeteksi({
    super.key,
    required this.ukuranCitra,
    required this.daftarKotak,
    this.fit = BoxFit.contain,
  });

  final Size ukuranCitra;
  final List<WilayahKotakTampil> daftarKotak;
  final BoxFit fit;

  @override
  Widget build(BuildContext context) {
    if (daftarKotak.isEmpty ||
        ukuranCitra.width <= 0 ||
        ukuranCitra.height <= 0) {
      return const SizedBox.shrink();
    }
    return IgnorePointer(
      child: CustomPaint(
        painter: _PelukisKotakDeteksi(
          ukuranCitra: ukuranCitra,
          daftarKotak: daftarKotak,
          fit: fit,
        ),
        child: const SizedBox.expand(),
      ),
    );
  }
}

class _PelukisKotakDeteksi extends CustomPainter {
  const _PelukisKotakDeteksi({
    required this.ukuranCitra,
    required this.daftarKotak,
    required this.fit,
  });

  final Size ukuranCitra;
  final List<WilayahKotakTampil> daftarKotak;
  final BoxFit fit;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.clipRect(Offset.zero & size);

    final isiKuas = Paint()..style = PaintingStyle.fill;
    final tepiKuas = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    for (final item in daftarKotak) {
      final rect = petakanKotakKeKanvas(
        kotak: item.kotak,
        ukuranCitra: ukuranCitra,
        ukuranKanvas: size,
        fit: fit,
      );
      if (rect.isEmpty) continue;

      final bentuk = RRect.fromRectAndRadius(rect, const Radius.circular(8));
      isiKuas.color = item.warna.withValues(alpha: 0.12);
      tepiKuas.color = item.warna;
      canvas.drawRRect(bentuk, isiKuas);
      canvas.drawRRect(bentuk, tepiKuas);

      if (item.label.isEmpty) continue;
      final pelukisTeks = TextPainter(
        text: TextSpan(
          text: item.label,
          style: const TextStyle(
            fontFamily: 'Poppins',
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: Colors.white,
            height: 1.15,
          ),
        ),
        textDirection: TextDirection.ltr,
        maxLines: 1,
        ellipsis: '…',
      )..layout(maxWidth: math.max(48.0, size.width - 16.0));

      const padX = 6.0;
      const padY = 3.0;
      final lebarPil = pelukisTeks.width + padX * 2;
      final tinggiPil = pelukisTeks.height + padY * 2;

      final xAwal = rect.left
          .clamp(4.0, math.max(4.0, size.width - lebarPil - 4.0))
          .toDouble();
      final muatDiAtas = rect.top - tinggiPil - 3 >= 4.0;
      final yMentah = muatDiAtas ? rect.top - tinggiPil - 3 : rect.top + 4.0;
      final yAwal = yMentah
          .clamp(4.0, math.max(4.0, size.height - tinggiPil - 4.0))
          .toDouble();

      final pilRect = RRect.fromRectAndRadius(
        Rect.fromLTWH(xAwal, yAwal, lebarPil, tinggiPil),
        const Radius.circular(6),
      );
      isiKuas.color = item.warna.withValues(alpha: 0.92);
      canvas.drawRRect(pilRect, isiKuas);
      pelukisTeks.paint(canvas, Offset(xAwal + padX, yAwal + padY));
    }

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _PelukisKotakDeteksi oldDelegate) {
    return oldDelegate.ukuranCitra != ukuranCitra ||
        oldDelegate.fit != fit ||
        oldDelegate.daftarKotak != daftarKotak;
  }
}
