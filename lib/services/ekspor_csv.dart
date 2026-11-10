import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../core/formatter.dart';
import '../domain/model.dart';

class EksporCsv {
  static const _header = [
    'Tanggal',
    'Waktu',
    'Makanan',
    'Porsi (g)',
    'Kalori (kkal)',
    'Protein (g)',
    'Lemak (g)',
    'Karbohidrat (g)',
    'Keyakinan',
    'Sumber',
  ];

  static String _amankan(String nilai) {
    if (nilai.contains(',') ||
        nilai.contains('"') ||
        nilai.contains('\n') ||
        nilai.contains('\r')) {
      return '"${nilai.replaceAll('"', '""')}"';
    }
    return nilai;
  }

  static String buatCsv(List<EntriLog> entri) {
    final baris = <String>[_header.join(',')];
    for (final item in entri) {
      baris.add(
        [
          item.tanggal,
          formatJam(item.waktu),
          item.namaSnapshot,
          formatDesimal(item.porsiG, desimal: 0),
          formatDesimal(item.kalori, desimal: 1),
          formatDesimal(item.proteinG, desimal: 1),
          formatDesimal(item.lemakG, desimal: 1),
          formatDesimal(item.khG, desimal: 1),
          formatDesimal(item.keyakinan, desimal: 3),
          item.sumberFoto,
        ].map(_amankan).join(','),
      );
    }
    return baris.join('\r\n');
  }

  static Future<File> tulisBerkas(List<EntriLog> entri) async {
    final direktori = await getTemporaryDirectory();
    final sekarang = DateTime.now();
    final nama =
        'foodcal_catatan_${formatTanggalIso(sekarang)}_${formatJam(sekarang).replaceAll('.', '')}.csv';
    final berkas = File(p.join(direktori.path, nama));
    await berkas.writeAsString('\uFEFF${buatCsv(entri)}', flush: true);
    return berkas;
  }

  static Future<ShareResult> bagikan(List<EntriLog> entri) async {
    final berkas = await tulisBerkas(entri);
    return SharePlus.instance.share(
      ShareParams(
        files: [XFile(berkas.path)],
        subject: 'Catatan FoodCal AI',
        text: 'Catatan makanan FoodCal AI',
      ),
    );
  }
}
