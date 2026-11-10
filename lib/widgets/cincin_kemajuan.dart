import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../app/theme.dart';
import '../core/formatter.dart';

class CincinKemajuan extends StatefulWidget {
  const CincinKemajuan({
    super.key,
    required this.persen,
    this.ukuran = 72,
    this.tebal = 7,
    this.warnaTeks,
    this.warnaDasar,
  });

  final double persen;
  final double ukuran;
  final double tebal;
  final Color? warnaTeks;
  final Color? warnaDasar;

  @override
  State<CincinKemajuan> createState() => _CincinKemajuanState();
}

class _CincinKemajuanState extends State<CincinKemajuan> {
  late double _persenAwal = widget.persen;

  @override
  void didUpdateWidget(covariant CincinKemajuan oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.persen != widget.persen) {
      _persenAwal = oldWidget.persen;
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.warna;
    final kurangi = context.kurangiGerak;
    final durasi = kurangi
        ? Duration.zero
        : const Duration(milliseconds: 360);

    return Semantics(
      label: 'Kemajuan target ${formatPersen(widget.persen)}',
      child: TweenAnimationBuilder<double>(
        tween: Tween<double>(
          begin: kurangi ? widget.persen : _persenAwal,
          end: widget.persen,
        ),
        duration: durasi,
        curve: Curves.easeOutCubic,
        builder: (context, nilaiAnimasi, _) {
          final nilaiBusur = nilaiAnimasi.clamp(0, 100).toDouble();
          return SizedBox(
            width: widget.ukuran,
            height: widget.ukuran,
            child: CustomPaint(
              painter: _CincinPainter(
                persen: nilaiBusur,
                tebal: widget.tebal,
                warnaDasar: widget.warnaDasar ?? c.line,
                warnaAksen: c.accent,
              ),
              child: Center(
                child: Text(
                  formatPersen(nilaiAnimasi),
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: widget.ukuran * (14 / 72),
                    fontWeight: FontWeight.w600,
                    color: widget.warnaTeks ?? c.ink,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _CincinPainter extends CustomPainter {
  _CincinPainter({
    required this.persen,
    required this.tebal,
    required this.warnaDasar,
    required this.warnaAksen,
  });

  final double persen;
  final double tebal;
  final Color warnaDasar;
  final Color warnaAksen;

  @override
  void paint(Canvas canvas, Size size) {
    final tengah = size.center(Offset.zero);
    final radius = (size.shortestSide - tebal) / 2;
    final dasar = Paint()
      ..color = persen >= 100 ? warnaAksen : warnaDasar
      ..style = PaintingStyle.stroke
      ..strokeWidth = tebal
      ..strokeCap = StrokeCap.round;
    canvas.drawCircle(tengah, radius, dasar);

    if (persen >= 100) return;
    final sapuan = 2 * math.pi * (persen / 100);
    if (sapuan <= 0) return;

    final kotak = Rect.fromCircle(center: tengah, radius: radius);
    final progres = Paint()
      ..color = warnaAksen
      ..style = PaintingStyle.stroke
      ..strokeWidth = tebal
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(kotak, -math.pi / 2, sapuan, false, progres);
  }

  @override
  bool shouldRepaint(covariant _CincinPainter lama) {
    return lama.persen != persen ||
        lama.tebal != tebal ||
        lama.warnaDasar != warnaDasar ||
        lama.warnaAksen != warnaAksen;
  }
}
