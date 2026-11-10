import 'dart:isolate';
import 'dart:typed_data';

import 'package:image/image.dart' as img;

import 'deteksi_service.dart';

Uint8List _potongDariCitra(
  img.Image citra,
  KotakPiksel kotak, {
  double margin = 0.08,
}) {
  final lebar = kotak.lebar;
  final tinggi = kotak.tinggi;
  final tambahX = (lebar * margin).round();
  final tambahY = (tinggi * margin).round();

  final kiri = (kotak.kiri - tambahX).clamp(0, citra.width - 2);
  final atas = (kotak.atas - tambahY).clamp(0, citra.height - 2);
  final kanan = (kotak.kanan + tambahX).clamp(kiri + 2, citra.width);
  final bawah = (kotak.bawah + tambahY).clamp(atas + 2, citra.height);

  final potongan = img.copyCrop(
    citra,
    x: kiri,
    y: atas,
    width: kanan - kiri,
    height: bawah - atas,
  );
  return Uint8List.fromList(img.encodeJpg(potongan, quality: 92));
}

/// Memotong satu wilayah dari citra asli, dengan sedikit kelonggaran di tepi.
///
/// Kelonggaran membantu model klasifikasi karena pusat objek biasanya lebih
/// informatif daripada batas kotak yang ketat.
Uint8List potongWilayah(
  Uint8List gambar,
  KotakPiksel kotak, {
  double margin = 0.08,
}) {
  final mentah = img.decodeImage(gambar);
  if (mentah == null) return gambar;
  // Koordinat kotak berasal dari citra yang orientasi EXIF-nya sudah diterapkan
  // (lihat `deteksi_service.dart`), jadi potong dari citra yang sama.
  final citra = img.bakeOrientation(mentah);
  return _potongDariCitra(citra, kotak, margin: margin);
}

/// Memotong beberapa wilayah sekaligus di isolate latar dengan satu kali dekode.
Future<List<Uint8List>> potongBanyakWilayah(
  Uint8List gambar,
  List<KotakPiksel> daftarKotak, {
  double margin = 0.08,
}) {
  if (daftarKotak.isEmpty) return Future.value(const <Uint8List>[]);
  return Isolate.run(() {
    final mentah = img.decodeImage(gambar);
    if (mentah == null) {
      return List<Uint8List>.filled(daftarKotak.length, gambar);
    }
    final citra = img.bakeOrientation(mentah);
    return <Uint8List>[
      for (final kotak in daftarKotak)
        _potongDariCitra(citra, kotak, margin: margin),
    ];
  });
}

/// Mengambil ukuran citra setelah orientasi EXIF diterapkan.
({int lebar, int tinggi})? ukuranCitra(Uint8List gambar) {
  final mentah = img.decodeImage(gambar);
  if (mentah == null) return null;
  final citra = img.bakeOrientation(mentah);
  return (lebar: citra.width, tinggi: citra.height);
}
