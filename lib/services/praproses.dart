import 'dart:math' as math;
import 'dart:typed_data';

import 'package:image/image.dart' as img;

const int ukuranInput = 224;
const int jumlahKanal = 3;
const int panjangInput = ukuranInput * ukuranInput * jumlahKanal;
const List<int> bentukInput = [1, ukuranInput, ukuranInput, jumlahKanal];

class GambarInput {
  const GambarInput(this.data);

  final Float32List data;

  List<int> get bentuk => bentukInput;
}

class PasanganInput {
  const PasanganInput({required this.asli, this.cermin});

  final GambarInput asli;
  final GambarInput? cermin;
}

img.Image _siapkanCitra(img.Image sumber) {
  final berorientasi = img.bakeOrientation(sumber);
  final sisi = math.min(berorientasi.width, berorientasi.height);
  final kiri = ((berorientasi.width - sisi) / 2).floor();
  final atas = ((berorientasi.height - sisi) / 2).floor();
  final potong = img.copyCrop(
    berorientasi,
    x: kiri,
    y: atas,
    width: sisi,
    height: sisi,
  );
  return img.copyResize(
    potong,
    width: ukuranInput,
    height: ukuranInput,
    interpolation: img.Interpolation.cubic,
  );
}

Float32List _keTensor(img.Image citra) {
  final data = Float32List(panjangInput);
  var indeks = 0;
  for (var y = 0; y < ukuranInput; y++) {
    for (var x = 0; x < ukuranInput; x++) {
      final piksel = citra.getPixel(x, y);
      data[indeks++] = piksel.r.toDouble().clamp(0, 255).toDouble();
      data[indeks++] = piksel.g.toDouble().clamp(0, 255).toDouble();
      data[indeks++] = piksel.b.toDouble().clamp(0, 255).toDouble();
    }
  }
  return data;
}

GambarInput praprosesCitra(img.Image citra) {
  return GambarInput(_keTensor(_siapkanCitra(citra)));
}

PasanganInput praprosesDenganCermin(Uint8List berkasGambar) {
  final asli = _siapkanCitraDariBerkas(berkasGambar);
  final cermin = img.flipHorizontal(asli.clone());
  return PasanganInput(
    asli: GambarInput(_keTensor(asli)),
    cermin: GambarInput(_keTensor(cermin)),
  );
}

GambarInput praproses(Uint8List berkasGambar) {
  return GambarInput(_keTensor(_siapkanCitraDariBerkas(berkasGambar)));
}

img.Image _siapkanCitraDariBerkas(Uint8List berkasGambar) {
  final dekode = img.decodeImage(berkasGambar);
  if (dekode == null) {
    throw const FormatException('Berkas gambar tidak dapat dibaca');
  }
  return _siapkanCitra(dekode);
}
