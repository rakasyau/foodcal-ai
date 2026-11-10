import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../app/theme.dart';
import '../core/formatter.dart';
import '../domain/rekap.dart';

double _batasAtas(List<TitikHarian> data, double target) {
  var tertinggi = target;
  for (final titik in data) {
    tertinggi = math.max(tertinggi, titik.kalori);
  }
  if (tertinggi <= 0) return 100;
  return tertinggi * 1.22;
}

/// Mengambil indeks titik sumbu bawah yang merata untuk rentang panjang
/// (misalnya 5 titik pada grafik 30 hari agar label tanggal selaras dengan X).
List<int> _indeksSumbuBawah(int panjang) {
  if (panjang <= 7) {
    return List<int>.generate(panjang, (i) => i);
  }
  const jumlahTick = 5;
  return <int>[
    for (var k = 0; k < jumlahTick; k++)
      ((panjang - 1) * k / (jumlahTick - 1)).round(),
  ];
}

List<FlSpot> _titikGaris(List<TitikHarian> data) {
  if (data.length == 1) {
    return <FlSpot>[FlSpot(0, data[0].kalori), FlSpot(1, data[0].kalori)];
  }
  return <FlSpot>[
    for (var i = 0; i < data.length; i++) FlSpot(i.toDouble(), data[i].kalori),
  ];
}

class GrafikGaris extends StatelessWidget {
  const GrafikGaris({
    super.key,
    required this.data,
    required this.target,
    this.tinggi = 84,
  });

  final List<TitikHarian> data;
  final double target;
  final double tinggi;

  @override
  Widget build(BuildContext context) {
    final c = context.warna;
    if (data.isEmpty) return SizedBox(height: tinggi);
    final maks = _batasAtas(data, target);
    final warnaSumbu = context.modeGelap
        ? const Color(0xFFA3A3A3)
        : const Color(0xFFB5B5B5);
    final rentangPanjang = data.length > 7;
    final indeksLabel = _indeksSumbuBawah(data.length);
    final titikUjung = data.length == 1 ? 1 : data.length - 1;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6),
          child: SizedBox(
            height: tinggi,
            child: LineChart(
            duration: context.kurangiGerak
                ? Duration.zero
                : const Duration(milliseconds: 260),
            curve: Curves.easeOutCubic,
            LineChartData(
              minX: 0,
              maxX: math.max(1, data.length - 1).toDouble(),
              minY: 0,
              maxY: maks,
              clipData: const FlClipData.none(),
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                horizontalInterval: maks / 3,
                getDrawingHorizontalLine: (_) => FlLine(
                  color: Colors.white.withValues(alpha: 0.22),
                  strokeWidth: 1,
                  dashArray: [3, 5],
                ),
              ),
              titlesData: const FlTitlesData(
                rightTitles: AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                topTitles: AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
              ),
              borderData: FlBorderData(show: false),
              lineTouchData: LineTouchData(
                enabled: true,
                touchTooltipData: LineTouchTooltipData(
                  getTooltipColor: (_) => c.accent,
                  getTooltipItems: (titik) {
                    return titik.map((item) {
                      final indeks = item.x.round().clamp(0, data.length - 1);
                      return LineTooltipItem(
                        '${formatKalori(data[indeks].kalori)} kkal',
                        const TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      );
                    }).toList();
                  },
                ),
              ),
              lineBarsData: [
                LineChartBarData(
                  spots: _titikGaris(data),
                  isCurved: data.length > 2,
                  curveSmoothness: 0.32,
                  preventCurveOverShooting: true,
                  color: Colors.white,
                  barWidth: 2.5,
                  isStrokeCapRound: true,
                  dotData: FlDotData(
                    show: true,
                    checkToShowDot: (spot, barData) =>
                        spot.x.round() == titikUjung,
                    getDotPainter: (spot, persen, bar, indeks) {
                      return FlDotCirclePainter(
                        radius: 5,
                        color: c.accent,
                        strokeWidth: 2,
                        strokeColor: Colors.white,
                      );
                    },
                  ),
                  belowBarData: BarAreaData(show: false),
                ),
              ],
            ),
          ),
        ),
      ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: indeksLabel.length == 1
              ? MainAxisAlignment.end
              : MainAxisAlignment.spaceBetween,
          children: [
            for (final idx in indeksLabel)
              Flexible(
                child: Text(
                  rentangPanjang
                      ? formatTanggalRingkas(data[idx].tanggalDate)
                      : namaHariPendek(data[idx].tanggalDate),
                  maxLines: 1,
                  overflow: TextOverflow.clip,
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 11,
                    color: warnaSumbu,
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }
}

class GrafikCatatan extends StatelessWidget {
  const GrafikCatatan({
    super.key,
    required this.data,
    required this.target,
    this.tanggalTerpilih,
    this.onPilihTanggal,
    this.tinggi = 140,
  });

  final List<TitikHarian> data;
  final double target;
  final String? tanggalTerpilih;
  final ValueChanged<DateTime>? onPilihTanggal;
  final double tinggi;

  @override
  Widget build(BuildContext context) {
    final c = context.warna;
    final gelap = context.modeGelap;
    if (data.isEmpty) return SizedBox(height: tinggi);
    final maks = _batasAtas(data, target);
    final rentangPanjang = data.length > 7;
    final indeksLabel = _indeksSumbuBawah(data.length);

    var indeksTitikAktif = data.length == 1 ? 1 : data.length - 1;
    if (tanggalTerpilih != null && data.length > 1) {
      final ditemukan = data.indexWhere(
        (item) => item.tanggal == tanggalTerpilih,
      );
      if (ditemukan >= 0) indeksTitikAktif = ditemukan;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: rentangPanjang ? 28 : 22),
          child: SizedBox(
            height: tinggi,
            child: LineChart(
              duration: context.kurangiGerak
                  ? Duration.zero
                  : const Duration(milliseconds: 260),
              curve: Curves.easeOutCubic,
              LineChartData(
                minX: 0,
                maxX: math.max(1, data.length - 1).toDouble(),
                minY: 0,
                maxY: maks,
                clipData: const FlClipData.none(),
                gridData: const FlGridData(show: false),
                titlesData: const FlTitlesData(
                  rightTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                ),
                borderData: FlBorderData(show: false),
                lineTouchData: LineTouchData(
                  enabled: true,
                  touchCallback: (event, response) {
                    if (onPilihTanggal == null) return;
                    final spots = response?.lineBarSpots;
                    if (event is FlTapUpEvent &&
                        spots != null &&
                        spots.isNotEmpty) {
                      final idx = spots.first.x.round().clamp(
                        0,
                        data.length - 1,
                      );
                      onPilihTanggal!(data[idx].tanggalDate);
                    }
                  },
                  touchTooltipData: LineTouchTooltipData(
                    getTooltipColor: (_) => c.ink,
                    getTooltipItems: (titik) {
                      return titik.map((item) {
                        final indeks = item.x.round().clamp(0, data.length - 1);
                        return LineTooltipItem(
                          '${formatKalori(data[indeks].kalori)} kkal',
                          TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: c.bg,
                          ),
                        );
                      }).toList();
                    },
                  ),
                ),
                extraLinesData: ExtraLinesData(
                  horizontalLines: [
                    HorizontalLine(
                      y: target,
                      color: c.accent,
                      strokeWidth: 1.2,
                      dashArray: [4, 5],
                      label: HorizontalLineLabel(
                        show: true,
                        alignment: Alignment.topLeft,
                        padding: const EdgeInsets.only(bottom: 4),
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 11,
                          color: c.inkSoft,
                        ),
                        labelResolver: (_) => 'Target ${formatRibuan(target)}',
                      ),
                    ),
                  ],
                ),
                lineBarsData: [
                  LineChartBarData(
                    spots: _titikGaris(data),
                    isCurved: data.length > 2,
                    curveSmoothness: 0.32,
                    preventCurveOverShooting: true,
                    color: c.ink,
                    barWidth: 3,
                    isStrokeCapRound: true,
                    dotData: FlDotData(
                      show: true,
                      checkToShowDot: (spot, barData) =>
                          spot.x.round() == indeksTitikAktif,
                      getDotPainter: (spot, persen, bar, indeks) {
                        return FlDotCirclePainter(
                          radius: 6,
                          color: c.accent,
                          strokeWidth: 2.5,
                          strokeColor: gelap
                              ? const Color(0xFF0E0E0E)
                              : Colors.white,
                        );
                      },
                    ),
                    belowBarData: BarAreaData(show: false),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 6),
        Row(
          mainAxisAlignment: indeksLabel.length == 1
              ? MainAxisAlignment.end
              : MainAxisAlignment.spaceBetween,
          children: [
            for (final idx in indeksLabel)
              _PilHari(
                label: rentangPanjang
                    ? formatTanggalRingkas(data[idx].tanggalDate)
                    : namaHariPendek(data[idx].tanggalDate),
                lebar: rentangPanjang ? 56 : 44,
                aktif:
                    tanggalTerpilih != null &&
                    data[idx].tanggal == tanggalTerpilih,
                onTap: onPilihTanggal == null
                    ? null
                    : () => onPilihTanggal!(data[idx].tanggalDate),
              ),
          ],
        ),
      ],
    );
  }
}

class _PilHari extends StatelessWidget {
  const _PilHari({
    required this.label,
    required this.aktif,
    this.lebar = 44,
    this.onTap,
  });

  final String label;
  final bool aktif;
  final double lebar;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.warna;
    final durasi = context.kurangiGerak
        ? Duration.zero
        : const Duration(milliseconds: 180);

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: durasi,
        curve: Curves.easeOutCubic,
        width: lebar,
        height: 22,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: aktif ? c.ink : Colors.transparent,
          borderRadius: BorderRadius.circular(AppRadius.pill),
        ),
        child: AnimatedDefaultTextStyle(
          duration: durasi,
          curve: Curves.easeOutCubic,
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 12,
            height: 1.1,
            fontWeight: aktif ? FontWeight.w500 : FontWeight.w400,
            color: aktif ? c.bg : c.inkSoft,
          ),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 3),
              child: Text(label, textAlign: TextAlign.center),
            ),
          ),
        ),
      ),
    );
  }
}

class GrafikBatang extends StatelessWidget {
  const GrafikBatang({
    super.key,
    required this.data,
    required this.target,
    this.tinggi = 190,
  });

  final List<TitikHarian> data;
  final double target;
  final double tinggi;

  @override
  Widget build(BuildContext context) {
    return GrafikCatatan(data: data, target: target, tinggi: tinggi);
  }
}
