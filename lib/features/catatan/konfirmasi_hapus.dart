import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../app/theme.dart';
import '../../core/formatter.dart';
import '../../domain/model.dart';
import '../../domain/rekap.dart';

String sebutanUntukTanggalIso(String iso) {
  if (iso == tanggalHariIni()) return 'hari ini';
  final tgl = DateTime.tryParse(iso);
  if (tgl == null) return 'tanggal tersebut';
  if (tanggalSaja(tgl) == geserHari(tanggalSaja(DateTime.now()), -1)) {
    return 'kemarin';
  }
  return 'tanggal ${formatTanggalPendek(tgl)}';
}

Future<bool> tampilkanKonfirmasiHapus(
  BuildContext context, {
  required EntriLog entri,
  required RekapHarian rekap,
  String? sebutanHari,
}) async {
  final c = context.warna;
  final labelHari = sebutanHari ?? sebutanUntukTanggalIso(entri.tanggal);
  final totalBaru = math.max<double>(0, rekap.kalori - entri.kalori);
  final hasil = await showDialog<bool>(
    context: context,
    barrierColor: Colors.black.withValues(alpha: 0.45),
    builder: (dialogContext) {
      return Dialog(
        backgroundColor: c.surface,
        surfaceTintColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 20),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Hapus entri ini?',
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
                    TextSpan(
                      text:
                          '${entri.namaSnapshot}, ${formatKalori(entri.kalori)} kkal pada ${formatJam(entri.waktu)} akan dihapus. Total $labelHari berubah dari ',
                    ),
                    TextSpan(
                      text: formatRibuan(rekap.kalori),
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: c.ink,
                      ),
                    ),
                    const TextSpan(text: ' menjadi '),
                    TextSpan(
                      text: '${formatRibuan(totalBaru)} kkal',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: c.ink,
                      ),
                    ),
                    const TextSpan(text: '.'),
                  ],
                ),
              ),
              const SizedBox(height: 22),
              Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 52,
                      child: OutlinedButton(
                        onPressed: () => Navigator.of(dialogContext).pop(false),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: c.ink,
                          side: BorderSide(color: c.line),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(AppRadius.pill),
                          ),
                          textStyle: const TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        child: const Text('Batal'),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: SizedBox(
                      height: 52,
                      child: FilledButton(
                        onPressed: () => Navigator.of(dialogContext).pop(true),
                        style: FilledButton.styleFrom(
                          backgroundColor: c.accent,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(AppRadius.pill),
                          ),
                          textStyle: const TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        child: const Text('Hapus'),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    },
  );
  return hasil ?? false;
}

Future<bool> hapusEntriDenganKonfirmasi(
  BuildContext context,
  WidgetRef ref,
  EntriLog entri, {
  RekapHarian? rekap,
  String? sebutanHari,
}) async {
  final id = entri.id;
  if (id == null) return false;
  final rekapDipakai =
      rekap ??
      await (await ref.read(
        repositoriProvider.future,
      )).log.rekap(entri.tanggal);
  if (!context.mounted) return false;
  final setuju = await tampilkanKonfirmasiHapus(
    context,
    entri: entri,
    rekap: rekapDipakai,
    sebutanHari: sebutanHari,
  );
  if (!setuju) return false;
  try {
    final repositori = await ref.read(repositoriProvider.future);
    await repositori.log.hapus(id);
    segarkanCatatan(ref);
    if (context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Entri dihapus')));
    }
    return true;
  } catch (_) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Entri gagal dihapus. Coba lagi.')),
      );
    }
    return false;
  }
}
