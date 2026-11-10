import 'package:flutter/material.dart';

import '../app/theme.dart';
import '../core/formatter.dart';
import '../domain/kalkulator_gizi.dart';
import '../domain/model.dart';
import 'tombol.dart';

/// Pemilih porsi berbasis preset, bukan slider gram.
///
/// Tiga pilihan cepat mengikuti porsi referensi kelas, ditambah pengaturan
/// gram halus untuk yang membutuhkan.
class PemilihPorsi extends StatelessWidget {
  const PemilihPorsi({
    super.key,
    required this.kelas,
    required this.porsi,
    required this.onUbah,
  });

  final KelasMakanan kelas;
  final double porsi;
  final ValueChanged<double> onUbah;

  Future<void> _aturGram(BuildContext context) async {
    final hasil = await showDialog<double>(
      context: context,
      builder: (_) => _DialogGram(awal: porsi, kelas: kelas),
    );
    if (hasil != null) onUbah(hasil);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.warna;
    final aktif = indeksPresetAktif(kelas, porsi);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Porsi',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: c.ink,
              ),
            ),
            const Spacer(),
            TextButton(
              onPressed: () => _aturGram(context),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                minimumSize: const Size(0, 32),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Text(
                'Atur gram',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: c.accent,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            for (var i = 0; i < faktorPreset.length; i++) ...[
              Expanded(
                child: _ChipPorsi(
                  label: labelFaktorPreset[i],
                  gram: porsiDariPreset(kelas, faktorPreset[i]),
                  terpilih: aktif == i,
                  onTap: () => onUbah(porsiDariPreset(kelas, faktorPreset[i])),
                ),
              ),
              if (i != faktorPreset.length - 1) const SizedBox(width: 8),
            ],
          ],
        ),
        const SizedBox(height: 8),
        Text(
          '${labelSatuanPorsi(kelas, porsi)} · ${formatPorsi(porsi)}',
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 12,
            color: c.inkSoft,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
      ],
    );
  }
}

class _ChipPorsi extends StatelessWidget {
  const _ChipPorsi({
    required this.label,
    required this.gram,
    required this.terpilih,
    required this.onTap,
  });

  final String label;
  final double gram;
  final bool terpilih;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.warna;
    final durasi = context.kurangiGerak
        ? Duration.zero
        : const Duration(milliseconds: 180);

    return SentuhanSkala(
      skalaTekan: 0.96,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.pill),
        child: AnimatedContainer(
          duration: durasi,
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
          decoration: BoxDecoration(
            color: terpilih ? c.ink : c.surfaceAlt,
            borderRadius: BorderRadius.circular(AppRadius.pill),
            border: Border.all(
              color: terpilih ? c.ink : c.line,
              width: 1,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedDefaultTextStyle(
                duration: durasi,
                curve: Curves.easeOutCubic,
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: terpilih ? c.bg : c.ink,
                ),
                child: Text(label, textAlign: TextAlign.center),
              ),
              const SizedBox(height: 2),
              AnimatedDefaultTextStyle(
                duration: durasi,
                curve: Curves.easeOutCubic,
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 11,
                  color: terpilih ? c.bg.withValues(alpha: 0.75) : c.muted,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
                child: Text(formatPorsi(gram), textAlign: TextAlign.center),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DialogGram extends StatefulWidget {
  const _DialogGram({required this.awal, required this.kelas});

  final double awal;
  final KelasMakanan kelas;

  @override
  State<_DialogGram> createState() => _DialogGramState();
}

class _DialogGramState extends State<_DialogGram> {
  late double _nilai = batasiPorsi(widget.awal);

  void _geser(double delta) {
    setState(() => _nilai = geserPorsi(_nilai, delta));
  }

  @override
  Widget build(BuildContext context) {
    final c = context.warna;
    return AlertDialog(
      backgroundColor: c.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      title: Text(
        'Atur berat',
        style: TextStyle(
          fontFamily: 'Poppins',
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: c.ink,
        ),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            formatPorsi(_nilai),
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 32,
              fontWeight: FontWeight.w700,
              color: c.ink,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
          Text(
            labelSatuanPorsi(widget.kelas, _nilai),
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 12,
              color: c.inkSoft,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _TombolGram(label: '−50', onTap: () => _geser(-50)),
              const SizedBox(width: 10),
              _TombolGram(label: '−10', onTap: () => _geser(-10)),
              const SizedBox(width: 10),
              _TombolGram(label: '+10', onTap: () => _geser(10)),
              const SizedBox(width: 10),
              _TombolGram(label: '+50', onTap: () => _geser(50)),
            ],
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(
            'Batal',
            style: TextStyle(fontFamily: 'Poppins', color: c.inkSoft),
          ),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(_nilai),
          child: Text(
            'Pakai',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontWeight: FontWeight.w600,
              color: c.accent,
            ),
          ),
        ),
      ],
    );
  }
}

class _TombolGram extends StatelessWidget {
  const _TombolGram({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.warna;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.pill),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: c.surfaceAlt,
          borderRadius: BorderRadius.circular(AppRadius.pill),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: c.ink,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
      ),
    );
  }
}
