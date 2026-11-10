import 'dart:math' as math;

import 'package:flutter/material.dart';

enum JenisIkon {
  mangkuk,
  lonceng,
  beranda,
  grafik,
  profil,
  kamera,
  kameraMati,
  galeri,
  kembali,
  api,
}

class IkonGaris extends StatelessWidget {
  const IkonGaris(
    this.jenis, {
    super.key,
    this.ukuran = 22,
    this.warna,
    this.tebal = 1.5,
  });

  final JenisIkon jenis;
  final double ukuran;
  final Color? warna;
  final double tebal;

  @override
  Widget build(BuildContext context) {
    final c = warna ?? IconTheme.of(context).color ?? const Color(0xFF111111);
    return SizedBox(
      width: ukuran,
      height: ukuran,
      child: CustomPaint(
        painter: _IkonGarisPainter(jenis: jenis, warna: c, tebal: tebal),
      ),
    );
  }
}

class _IkonGarisPainter extends CustomPainter {
  const _IkonGarisPainter({
    required this.jenis,
    required this.warna,
    required this.tebal,
  });

  final JenisIkon jenis;
  final Color warna;
  final double tebal;

  @override
  void paint(Canvas canvas, Size size) {
    final skala = size.width / 24.0;
    canvas.save();
    canvas.scale(skala, skala);

    final kuas = Paint()
      ..color = warna
      ..style = PaintingStyle.stroke
      ..strokeWidth = tebal
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    switch (jenis) {
      case JenisIkon.mangkuk:
        // M4 12h16a8 8 0 0 1-16 0z M8 8c0-2 2-2 2-4 M13 8c0-2 2-2 2-4
        final mangkuk = Path()
          ..moveTo(4, 12)
          ..lineTo(20, 12)
          ..arcToPoint(
            const Offset(4, 12),
            radius: const Radius.circular(8),
            clockwise: true,
          )
          ..close();
        canvas.drawPath(mangkuk, kuas);
        final uap1 = Path()
          ..moveTo(8, 8)
          ..cubicTo(8, 6, 10, 6, 10, 4);
        final uap2 = Path()
          ..moveTo(13, 8)
          ..cubicTo(13, 6, 15, 6, 15, 4);
        canvas.drawPath(uap1, kuas);
        canvas.drawPath(uap2, kuas);

      case JenisIkon.lonceng:
        // M6 17v-6a6 6 0 0 1 12 0v6l1.5 2h-15z M10 21h4
        final lonceng = Path()
          ..moveTo(6, 17)
          ..lineTo(6, 11)
          ..arcToPoint(
            const Offset(18, 11),
            radius: const Radius.circular(6),
            clockwise: true,
          )
          ..lineTo(18, 17)
          ..lineTo(19.5, 19)
          ..lineTo(4.5, 19)
          ..close();
        canvas.drawPath(lonceng, kuas);
        canvas.drawLine(const Offset(10, 21), const Offset(14, 21), kuas);

      case JenisIkon.beranda:
        // M4 11l8-7 8 7v8a1 1 0 0 1-1 1h-4v-6H9v6H5a1 1 0 0 1-1-1z
        final rumah = Path()
          ..moveTo(4, 11)
          ..lineTo(12, 4)
          ..lineTo(20, 11)
          ..lineTo(20, 19)
          ..arcToPoint(
            const Offset(19, 20),
            radius: const Radius.circular(1),
            clockwise: true,
          )
          ..lineTo(15, 20)
          ..lineTo(15, 14)
          ..lineTo(9, 14)
          ..lineTo(9, 20)
          ..lineTo(5, 20)
          ..arcToPoint(
            const Offset(4, 19),
            radius: const Radius.circular(1),
            clockwise: true,
          )
          ..close();
        canvas.drawPath(rumah, kuas);

      case JenisIkon.grafik:
        // M5 20V10 M12 20V4 M19 20v-7
        canvas.drawLine(const Offset(5, 20), const Offset(5, 10), kuas);
        canvas.drawLine(const Offset(12, 20), const Offset(12, 4), kuas);
        canvas.drawLine(const Offset(19, 20), const Offset(19, 13), kuas);

      case JenisIkon.profil:
        // circle cx="12" cy="8" r="4", M4 20c1-4 4-6 8-6s7 2 8 6
        canvas.drawCircle(const Offset(12, 8), 4, kuas);
        final badan = Path()
          ..moveTo(4, 20)
          ..cubicTo(5, 16, 8, 14, 12, 14)
          ..cubicTo(16, 14, 19, 16, 20, 20);
        canvas.drawPath(badan, kuas);

      case JenisIkon.kamera:
        // M4 8h3l2-3h6l2 3h3v11H4z, circle cx="12" cy="13" r="3.5"
        final bodi = Path()
          ..moveTo(4, 8)
          ..lineTo(7, 8)
          ..lineTo(9, 5)
          ..lineTo(15, 5)
          ..lineTo(17, 8)
          ..lineTo(20, 8)
          ..lineTo(20, 19)
          ..lineTo(4, 19)
          ..close();
        canvas.drawPath(bodi, kuas);
        canvas.drawCircle(const Offset(12, 13), 3.5, kuas);

      case JenisIkon.kameraMati:
        // M4 8h3l2-3h6l2 3h3v11H4z M3 3l18 18
        final bodi = Path()
          ..moveTo(4, 8)
          ..lineTo(7, 8)
          ..lineTo(9, 5)
          ..lineTo(15, 5)
          ..lineTo(17, 8)
          ..lineTo(20, 8)
          ..lineTo(20, 19)
          ..lineTo(4, 19)
          ..close();
        canvas.drawPath(bodi, kuas);
        canvas.drawLine(const Offset(3, 3), const Offset(21, 21), kuas);

      case JenisIkon.galeri:
        // rect x="4" y="4" width="16" height="16" rx="3"
        // circle cx="9" cy="9" r="1.5"
        // M4 17l5-5 4 4 3-3 4 4
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            const Rect.fromLTWH(4, 4, 16, 16),
            const Radius.circular(3),
          ),
          kuas,
        );
        canvas.drawCircle(const Offset(9, 9), 1.5, kuas);
        final gunung = Path()
          ..moveTo(4, 17)
          ..lineTo(9, 12)
          ..lineTo(13, 16)
          ..lineTo(16, 13)
          ..lineTo(20, 17);
        canvas.drawPath(gunung, kuas);

      case JenisIkon.kembali:
        // M15 5l-7 7 7 7
        final panah = Path()
          ..moveTo(15, 5)
          ..lineTo(8, 12)
          ..lineTo(15, 19);
        canvas.drawPath(panah, kuas);

      case JenisIkon.api:
        // M12 3c1 4 5 5 5 10a5 5 0 0 1-10 0c0-2 1-3 2-4 0 2 1 3 2 3 0-3-1-6 1-9z
        final api = Path()
          ..moveTo(12, 3)
          ..cubicTo(13, 7, 17, 8, 17, 13)
          ..arcToPoint(
            const Offset(7, 13),
            radius: const Radius.circular(5),
            clockwise: true,
          )
          ..cubicTo(7, 11, 8, 10, 9, 9)
          ..cubicTo(9, 11, 10, 12, 11, 12)
          ..cubicTo(11, 9, 10, 6, 12, 3)
          ..close();
        canvas.drawPath(api, kuas);
    }

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _IkonGarisPainter lama) {
    return lama.jenis != jenis || lama.warna != warna || lama.tebal != tebal;
  }
}

class IlustrasiPiringKosong extends StatelessWidget {
  const IlustrasiPiringKosong({
    super.key,
    required this.warnaUtama,
    required this.warnaGaris,
    this.lebar = 150,
    this.tinggi = 110,
  });

  final Color warnaUtama;
  final Color warnaGaris;
  final double lebar;
  final double tinggi;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Piring kosong',
      child: SizedBox(
        width: lebar,
        height: tinggi,
        child: CustomPaint(
          painter: _PiringKosongPainter(
            warnaUtama: warnaUtama,
            warnaGaris: warnaGaris,
          ),
        ),
      ),
    );
  }
}

class _PiringKosongPainter extends CustomPainter {
  const _PiringKosongPainter({
    required this.warnaUtama,
    required this.warnaGaris,
  });

  final Color warnaUtama;
  final Color warnaGaris;

  @override
  void paint(Canvas canvas, Size size) {
    final sx = size.width / 150.0;
    final sy = size.height / 110.0;
    canvas.save();
    canvas.scale(sx, sy);

    final kuasUtama = Paint()
      ..color = warnaUtama
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final kuasDalam = Paint()
      ..color = warnaGaris
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;

    // <ellipse cx="75" cy="62" rx="52" ry="32"></ellipse>
    canvas.drawOval(
      Rect.fromCenter(center: const Offset(75, 62), width: 104, height: 64),
      kuasUtama,
    );
    // <ellipse cx="75" cy="62" rx="32" ry="19" stroke="#D9D9D9"></ellipse>
    canvas.drawOval(
      Rect.fromCenter(center: const Offset(75, 62), width: 64, height: 38),
      kuasDalam,
    );
    // <path d="M12 20v30M18 20v14M6 20v14M12 34v16M138 20c-6 8-6 22 0 28v-28M138 48v16"></path>
    final alatMakan = Path()
      ..moveTo(12, 20)
      ..lineTo(12, 50)
      ..moveTo(18, 20)
      ..lineTo(18, 34)
      ..moveTo(6, 20)
      ..lineTo(6, 34)
      ..moveTo(12, 34)
      ..lineTo(12, 50)
      ..moveTo(138, 20)
      ..cubicTo(132, 28, 132, 42, 138, 48)
      ..lineTo(138, 20)
      ..moveTo(138, 48)
      ..lineTo(138, 64);
    canvas.drawPath(alatMakan, kuasUtama);

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _PiringKosongPainter lama) {
    return lama.warnaUtama != warnaUtama || lama.warnaGaris != warnaGaris;
  }
}

class BingkaiSudutKamera extends StatelessWidget {
  const BingkaiSudutKamera({
    super.key,
    this.warna = Colors.white,
    this.ukuran = 270,
  });

  final Color warna;
  final double ukuran;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: SizedBox(
        width: ukuran,
        height: ukuran,
        child: CustomPaint(painter: _BingkaiSudutPainter(warna: warna)),
      ),
    );
  }
}

class _BingkaiSudutPainter extends CustomPainter {
  const _BingkaiSudutPainter({required this.warna});

  final Color warna;

  @override
  void paint(Canvas canvas, Size size) {
    final s = math.min(size.width, size.height) / 270.0;
    canvas.save();
    canvas.scale(s, s);

    final kuas = Paint()
      ..color = warna
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    // M2 50V16a14 14 0 0 1 14-14h34
    // M220 2h34a14 14 0 0 1 14 14v34
    // M268 220v34a14 14 0 0 1-14 14h-34
    // M50 268H16A14 14 0 0 1 2 254v-34
    final p = Path()
      ..moveTo(2, 50)
      ..lineTo(2, 16)
      ..arcToPoint(
        const Offset(16, 2),
        radius: const Radius.circular(14),
        clockwise: true,
      )
      ..lineTo(50, 2)
      ..moveTo(220, 2)
      ..lineTo(254, 2)
      ..arcToPoint(
        const Offset(268, 16),
        radius: const Radius.circular(14),
        clockwise: true,
      )
      ..lineTo(268, 50)
      ..moveTo(268, 220)
      ..lineTo(268, 254)
      ..arcToPoint(
        const Offset(254, 268),
        radius: const Radius.circular(14),
        clockwise: true,
      )
      ..lineTo(220, 268)
      ..moveTo(50, 268)
      ..lineTo(16, 268)
      ..arcToPoint(
        const Offset(2, 254),
        radius: const Radius.circular(14),
        clockwise: true,
      )
      ..lineTo(2, 220);

    canvas.drawPath(p, kuas);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _BingkaiSudutPainter lama) =>
      lama.warna != warna;
}

class LogoFoodCal extends StatelessWidget {
  const LogoFoodCal({super.key, this.ukuran = 44});

  final double ukuran;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: ukuran,
      height: ukuran,
      child: CustomPaint(painter: const _LogoFoodCalPainter()),
    );
  }
}

class _LogoFoodCalPainter extends CustomPainter {
  const _LogoFoodCalPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final s = math.min(size.width, size.height) / 1024.0;
    canvas.save();
    canvas.scale(s, s);

    // Latar squircle #111111
    final rrect = RRect.fromRectAndRadius(
      const Rect.fromLTWH(0, 0, 1024, 1024),
      const Radius.circular(228),
    );
    canvas.drawRRect(rrect, Paint()..color = const Color(0xFF111111));

    // Garis tepi dalam halus #2A2A2A
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(6, 6, 1012, 1012),
        const Radius.circular(222),
      ),
      Paint()
        ..color = const Color(0xFF2A2A2A)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4,
    );

    // Siku bingkai kamera AI #545454
    final kuasSiku = Paint()
      ..color = const Color(0xFF545454)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 24
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final siku = Path()
      ..moveTo(172, 286)
      ..lineTo(172, 220)
      ..arcToPoint(
        const Offset(220, 172),
        radius: const Radius.circular(48),
        clockwise: true,
      )
      ..lineTo(286, 172)
      ..moveTo(172, 738)
      ..lineTo(172, 804)
      ..arcToPoint(
        const Offset(220, 852),
        radius: const Radius.circular(48),
        clockwise: false,
      )
      ..lineTo(286, 852)
      ..moveTo(738, 852)
      ..lineTo(804, 852)
      ..arcToPoint(
        const Offset(852, 804),
        radius: const Radius.circular(48),
        clockwise: false,
      )
      ..lineTo(852, 738);
    canvas.drawPath(siku, kuasSiku);

    // Titik indikator merah vermilion #D6382F
    canvas.drawCircle(
      const Offset(824, 200),
      34,
      Paint()..color = const Color(0xFFD6382F),
    );

    // Tiga gelombang uap
    final kuasUapPutih = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 38
      ..strokeCap = StrokeCap.round;
    final kuasUapMerah = Paint()
      ..color = const Color(0xFFD6382F)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 38
      ..strokeCap = StrokeCap.round;

    final uapKiri = Path()
      ..moveTo(384, 404)
      ..cubicTo(358, 354, 422, 314, 400, 262);
    final uapTengah = Path()
      ..moveTo(512, 404)
      ..cubicTo(486, 354, 550, 314, 528, 262);
    final uapKanan = Path()
      ..moveTo(640, 404)
      ..cubicTo(614, 354, 678, 314, 656, 262);
    canvas.drawPath(uapKiri, kuasUapPutih);
    canvas.drawPath(uapTengah, kuasUapMerah);
    canvas.drawPath(uapKanan, kuasUapPutih);

    // Mangkuk utama putih
    final kuasMangkuk = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 44
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final mangkuk = Path()
      ..moveTo(256, 486)
      ..lineTo(768, 486)
      ..arcTo(
        const Rect.fromLTRB(256, 230, 768, 742),
        0,
        math.pi,
        false,
      )
      ..close();
    canvas.drawPath(mangkuk, kuasMangkuk);

    // Alas mangkuk
    canvas.drawLine(
      const Offset(428, 782),
      const Offset(596, 782),
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 36
        ..strokeCap = StrokeCap.round,
    );

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _LogoFoodCalPainter oldDelegate) => false;
}


