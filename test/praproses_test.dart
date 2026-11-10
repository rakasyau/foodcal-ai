import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:foodcal_ai/services/praproses.dart';
import 'package:image/image.dart' as img;

Uint8List _citraUji({int lebar = 300, int tinggi = 200}) {
  final gambar = img.Image(width: lebar, height: tinggi);
  for (var y = 0; y < tinggi; y++) {
    for (var x = 0; x < lebar; x++) {
      gambar.setPixelRgb(
        x,
        y,
        (x * 255 ~/ lebar),
        (y * 255 ~/ tinggi),
        ((x + y) * 255 ~/ (lebar + tinggi)),
      );
    }
  }
  final bytes = img.encodePng(gambar);
  return Uint8List.fromList(bytes);
}

void main() {
  test('bentuk keluaran adalah [1, 224, 224, 3]', () {
    final hasil = praproses(_citraUji());
    expect(hasil.bentuk, [1, 224, 224, 3]);
    expect(hasil.data.length, 1 * 224 * 224 * 3);
    expect(hasil.data, isA<Float32List>());
  });

  test('nilai piksel berada pada rentang 0 sampai 255', () {
    final hasil = praproses(_citraUji());
    var minimum = double.infinity;
    var maksimum = double.negativeInfinity;
    for (final nilai in hasil.data) {
      if (nilai < minimum) minimum = nilai;
      if (nilai > maksimum) maksimum = nilai;
    }
    expect(minimum, greaterThanOrEqualTo(0));
    expect(maksimum, lessThanOrEqualTo(255));
    expect(maksimum, greaterThan(0));
  });

  test('citra persegi dan tidak persegi menghasilkan ukuran sama', () {
    final persegi = praproses(_citraUji(lebar: 256, tinggi: 256));
    final lebar = praproses(_citraUji(lebar: 640, tinggi: 480));
    expect(persegi.data.length, lebar.data.length);
    expect(persegi.bentuk, [1, 224, 224, 3]);
    expect(lebar.bentuk, [1, 224, 224, 3]);
  });

  test('cermin menghasilkan tensor berbeda', () {
    final pasangan = praprosesDenganCermin(_citraUji());
    expect(pasangan.cermin, isNotNull);
    expect(pasangan.asli.data.length, pasangan.cermin!.data.length);
    var berbeda = false;
    for (var i = 0; i < pasangan.asli.data.length; i++) {
      if (pasangan.asli.data[i] != pasangan.cermin!.data[i]) {
        berbeda = true;
        break;
      }
    }
    expect(berbeda, isTrue);
  });

  test('berkas yang bukan gambar ditolak', () {
    expect(
      () => praproses(Uint8List.fromList([1, 2, 3, 4])),
      throwsA(isA<FormatException>()),
    );
  });
}
