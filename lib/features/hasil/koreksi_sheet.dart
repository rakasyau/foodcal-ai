import 'package:flutter/material.dart';

import '../../app/theme.dart';
import '../../core/formatter.dart';
import '../../domain/model.dart';
import '../../domain/kalkulator_gizi.dart';
import '../../widgets/tombol.dart';
import 'pilih_makanan_page.dart';

/// Membuka lembar koreksi berisi kandidat teratas model.
///
/// Mengembalikan kelas yang dipilih pengguna, atau null bila dibatalkan.
Future<KelasMakanan?> tampilkanKoreksi(
  BuildContext context, {
  required List<KandidatPrediksi> kandidat,
  int? idTerpilih,
}) {
  return showModalBottomSheet<KelasMakanan>(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (_) => _LembarKoreksi(kandidat: kandidat, idTerpilih: idTerpilih),
  );
}

class _LembarKoreksi extends StatelessWidget {
  const _LembarKoreksi({required this.kandidat, this.idTerpilih});

  final List<KandidatPrediksi> kandidat;
  final int? idTerpilih;

  Future<void> _cariSemua(BuildContext context) async {
    final dipilih = await Navigator.of(context).push<KelasMakanan>(
      MaterialPageRoute<KelasMakanan>(
        builder: (_) => const PilihMakananPage(judul: 'Cari makanan'),
      ),
    );
    if (dipilih != null && context.mounted) {
      Navigator.of(context).pop(dipilih);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.warna;
    final daftar = kandidat
        .where((k) => idTerpilih == null || k.kelas.id != idTerpilih)
        .take(5)
        .toList(growable: false);

    return Container(
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 12,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: c.line,
                borderRadius: BorderRadius.circular(AppRadius.pill),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Bukan makanan ini?',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: c.ink,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Pilih yang benar, kalori dan gizi dihitung ulang otomatis.',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 12,
              color: c.inkSoft,
            ),
          ),
          const SizedBox(height: 14),
          if (daftar.isEmpty)
            Text(
              'Model tidak memberi kandidat lain. Cari manual di daftar.',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 13,
                color: c.inkSoft,
              ),
            )
          else
            ...daftar.map(
              (k) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _BarisKandidat(
                  kelas: k.kelas,
                  probabilitas: k.probabilitas,
                  onTap: () => Navigator.of(context).pop(k.kelas),
                ),
              ),
            ),
          const SizedBox(height: 4),
          TombolSekunder(
            label: 'Cari semua makanan',
            onPressed: () => _cariSemua(context),
          ),
          const SizedBox(height: 4),
          Center(
            child: TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'Batal',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 13,
                  color: c.inkSoft,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BarisKandidat extends StatelessWidget {
  const _BarisKandidat({
    required this.kelas,
    required this.probabilitas,
    required this.onTap,
  });

  final KelasMakanan kelas;
  final double probabilitas;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.warna;
    final gizi = hitungGizi(kelas, porsiAwal(kelas));
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: c.surfaceAlt,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    kelas.namaId,
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: c.ink,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${kelas.labelKelompok} · ${formatKalori(gizi.kalori)} kkal per porsi',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 11,
                      color: c.inkSoft,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: c.surface,
                borderRadius: BorderRadius.circular(AppRadius.pill),
              ),
              child: Text(
                formatPersen(probabilitas * 100),
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: c.ink,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
