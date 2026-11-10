import 'dart:async';
import 'dart:io';
import 'dart:isolate';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/services.dart';
import 'package:image/image.dart' as img;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:tflite_flutter/tflite_flutter.dart';

class KotakPiksel {
  const KotakPiksel(this.kiri, this.atas, this.kanan, this.bawah);

  final int kiri;
  final int atas;
  final int kanan;
  final int bawah;

  int get lebar => kanan - kiri;
  int get tinggi => bawah - atas;
  double get luas => math.max(0, lebar).toDouble() * math.max(0, tinggi).toDouble();

  Map<String, Object> keMap() => {
    'kiri': kiri,
    'atas': atas,
    'kanan': kanan,
    'bawah': bawah,
  };

  static KotakPiksel dariMap(Map<String, Object?> map) => KotakPiksel(
    (map['kiri'] as num).toInt(),
    (map['atas'] as num).toInt(),
    (map['kanan'] as num).toInt(),
    (map['bawah'] as num).toInt(),
  );
}

/// Satu wilayah makanan yang ditemukan model deteksi.
class KotakDeteksi {
  const KotakDeteksi({
    required this.kotak,
    required this.skor,
    required this.kelas,
  });

  /// Kotak pada koordinat citra asli (piksel).
  final KotakPiksel kotak;
  final double skor;

  /// Indeks kelas keluaran model deteksi (lihat `peta_kelas_deteksi.dart`).
  final int kelas;
}

/// Hasil deteksi lengkap beserta ukuran citra setelah orientasi EXIF diterapkan.
class HasilDeteksi {
  const HasilDeteksi({
    required this.kotak,
    required this.lebarCitra,
    required this.tinggiCitra,
  });

  final List<KotakDeteksi> kotak;
  final int lebarCitra;
  final int tinggiCitra;

  double get luasCitra => lebarCitra.toDouble() * tinggiCitra.toDouble();

  static const HasilDeteksi kosong = HasilDeteksi(
    kotak: <KotakDeteksi>[],
    lebarCitra: 0,
    tinggiCitra: 0,
  );
}

class _Argumen {
  const _Argumen({
    required this.jalurModel,
    required this.modelBuffer,
    required this.gambar,
    required this.ukuran,
    required this.ambang,
    required this.iou,
  });

  final String? jalurModel;
  final Uint8List? modelBuffer;
  final Uint8List gambar;
  final int ukuran;
  final double ambang;
  final double iou;
}

/// Model YOLO 28 kelas: menemukan wilayah tiap makanan pada satu piring.
class DeteksiService {
  static const int ukuranInput = 512;
  static const double ambangBawaan = 0.25;
  static const double iouBawaan = 0.45;

  static final Map<String, Future<String>> _berkasModel = {};
  final Map<String, Uint8List> _modelBuffer = {};

  Future<String?> _siapkanJalur(String aset) async {
    try {
      final tugas = _berkasModel.putIfAbsent(aset, () {
        final salin = _salinAsetKeBerkas(aset);
        unawaited(
          salin.then<void>(
            (_) {},
            onError: (Object _) {
              _berkasModel.remove(aset);
            },
          ),
        );
        return salin;
      });
      return await tugas;
    } catch (_) {
      return null;
    }
  }

  Future<String> _salinAsetKeBerkas(String aset) async {
    final direktori = await getApplicationSupportDirectory();
    final folder = Directory(p.join(direktori.path, 'model'));
    if (!await folder.exists()) {
      await folder.create(recursive: true);
    }
    final namaBerkas = p.basename(aset);
    final tujuan = File(p.join(folder.path, namaBerkas));
    final data = await rootBundle.load(aset);
    final panjang = await tujuan.exists() ? await tujuan.length() : -1;
    if (panjang != data.lengthInBytes) {
      final sementara = File(p.join(folder.path, '$namaBerkas.tmp'));
      await sementara.writeAsBytes(
        data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes),
        flush: true,
      );
      await sementara.rename(tujuan.path);
    }
    return tujuan.path;
  }

  Future<Uint8List> _muatBuffer(String aset) async {
    final ada = _modelBuffer[aset];
    if (ada != null) return ada;
    final data = await rootBundle.load(aset);
    final bytes = data.buffer.asUint8List(
      data.offsetInBytes,
      data.lengthInBytes,
    );
    _modelBuffer[aset] = bytes;
    return bytes;
  }

  Future<HasilDeteksi> deteksiLengkap({
    required Uint8List gambar,
    String asetModel = 'assets/models/yolo_makanan.tflite',
    double ambang = ambangBawaan,
    double iou = iouBawaan,
  }) async {
    final jalur = await _siapkanJalur(asetModel);
    final buffer = jalur == null ? await _muatBuffer(asetModel) : null;
    return Isolate.run(
      () => _deteksi(
        _Argumen(
          jalurModel: jalur,
          modelBuffer: buffer,
          gambar: gambar,
          ukuran: ukuranInput,
          ambang: ambang,
          iou: iou,
        ),
      ),
    );
  }

  Future<List<KotakDeteksi>> deteksi({
    required Uint8List gambar,
    String asetModel = 'assets/models/yolo_makanan.tflite',
    double ambang = ambangBawaan,
    double iou = iouBawaan,
  }) async {
    final hasil = await deteksiLengkap(
      gambar: gambar,
      asetModel: asetModel,
      ambang: ambang,
      iou: iou,
    );
    return hasil.kotak;
  }
}

/// Menguraikan tensor keluaran YOLO (`[1, 4+kelas, jangkar]` atau `[1, jangkar, 4+kelas]`)
/// menjadi daftar kotak deteksi setelah NMS, baik untuk koordinat piksel maupun ternormalisasi `[0..1]`.
List<KotakDeteksi> uraikanKeluaranDeteksi({
  required List<List<double>> tensor2d,
  required int ukuranInput,
  required int lebarCitra,
  required int tinggiCitra,
  required int padKiri,
  required int padAtas,
  required double skala,
  required double ambang,
  required double iou,
}) {
  if (tensor2d.isEmpty || tensor2d.first.isEmpty) return const [];
  final a = tensor2d.length;
  final b = tensor2d.first.length;
  final kanalDulu = a < b;
  final kanal = kanalDulu ? a : b;
  final jangkar = kanalDulu ? b : a;
  if (kanal <= 4) return const [];

  final kelas = kanal - 4;
  double nilai(int j, int c) => kanalDulu ? tensor2d[c][j] : tensor2d[j][c];

  final kandidat = <KotakDeteksi>[];
  for (var j = 0; j < jangkar; j++) {
    var skor = 0.0;
    var indeksKelas = 0;
    for (var c = 0; c < kelas; c++) {
      final v = nilai(j, 4 + c);
      if (v > skor) {
        skor = v;
        indeksKelas = c;
      }
    }
    if (skor < ambang) continue;

    var cx = nilai(j, 0);
    var cy = nilai(j, 1);
    var w = nilai(j, 2);
    var h = nilai(j, 3);
    // Sebagian ekspor Ultralytics TFLite menghasilkan koordinat ternormalisasi [0..1].
    if (cx <= 1.5 && cy <= 1.5 && w <= 1.5 && h <= 1.5) {
      final faktor = ukuranInput.toDouble();
      cx *= faktor;
      cy *= faktor;
      w *= faktor;
      h *= faktor;
    }

    final kotak = KotakPiksel(
      (((cx - w / 2) - padKiri) / skala).clamp(0, lebarCitra - 1).round(),
      (((cy - h / 2) - padAtas) / skala).clamp(0, tinggiCitra - 1).round(),
      (((cx + w / 2) - padKiri) / skala).clamp(1, lebarCitra).round(),
      (((cy + h / 2) - padAtas) / skala).clamp(1, tinggiCitra).round(),
    );
    if (kotak.lebar < 16 || kotak.tinggi < 16) continue;
    kandidat.add(
      KotakDeteksi(kotak: kotak, skor: skor, kelas: indeksKelas),
    );
  }

  kandidat.sort((x, y) => y.skor.compareTo(x.skor));
  return _nms(kandidat, iou);
}

HasilDeteksi _deteksi(_Argumen arg) {
  final mentah = img.decodeImage(arg.gambar);
  if (mentah == null) return HasilDeteksi.kosong;
  // Foto kamera sering hanya ditandai EXIF "diputar". Putar betul-betul supaya
  // detektor melihat makanan tegak dan koordinat kotak cocok dengan
  // `potongWilayah`, yang juga memakai citra yang sudah diputar.
  final citra = img.bakeOrientation(mentah);

  final lebar = citra.width;
  final tinggi = citra.height;
  final skala = arg.ukuran / math.max(lebar, tinggi);
  final lebarBaru = math.max(1, (lebar * skala).round());
  final tinggiBaru = math.max(1, (tinggi * skala).round());
  final kecil = img.copyResize(
    citra,
    width: lebarBaru,
    height: tinggiBaru,
    interpolation: img.Interpolation.linear,
  );
  final padKiri = (arg.ukuran - lebarBaru) ~/ 2;
  final padAtas = (arg.ukuran - tinggiBaru) ~/ 2;

  final tensor = Float32List(arg.ukuran * arg.ukuran * 3);
  tensor.fillRange(0, tensor.length, 114 / 255);
  for (var y = 0; y < tinggiBaru; y++) {
    for (var x = 0; x < lebarBaru; x++) {
      final p = kecil.getPixel(x, y);
      final idx = ((y + padAtas) * arg.ukuran + (x + padKiri)) * 3;
      tensor[idx] = p.r / 255.0;
      tensor[idx + 1] = p.g / 255.0;
      tensor[idx + 2] = p.b / 255.0;
    }
  }

  final opsi = InterpreterOptions()..threads = 2;
  final interpreter = arg.jalurModel != null
      ? Interpreter.fromFile(File(arg.jalurModel!), options: opsi)
      : Interpreter.fromBuffer(arg.modelBuffer!, options: opsi);
  try {
    interpreter.allocateTensors();
    final bentuk = interpreter.getOutputTensor(0).shape;
    if (bentuk.length != 3) {
      return HasilDeteksi(
        kotak: const [],
        lebarCitra: lebar,
        tinggiCitra: tinggi,
      );
    }

    final a = bentuk[1];
    final b = bentuk[2];
    final kanal = math.min(a, b);
    if (kanal <= 4) {
      return HasilDeteksi(
        kotak: const [],
        lebarCitra: lebar,
        tinggiCitra: tinggi,
      );
    }

    final keluaran = [
      List.generate(a, (_) => List<double>.filled(b, 0.0)),
    ];
    interpreter.run(
      tensor.buffer.asUint8List(tensor.offsetInBytes, tensor.lengthInBytes),
      keluaran,
    );

    return HasilDeteksi(
      kotak: uraikanKeluaranDeteksi(
        tensor2d: keluaran[0],
        ukuranInput: arg.ukuran,
        lebarCitra: lebar,
        tinggiCitra: tinggi,
        padKiri: padKiri,
        padAtas: padAtas,
        skala: skala,
        ambang: arg.ambang,
        iou: arg.iou,
      ),
      lebarCitra: lebar,
      tinggiCitra: tinggi,
    );
  } finally {
    interpreter.close();
    opsi.delete();
  }
}

double _iou(KotakPiksel a, KotakPiksel b) {
  final kiri = math.max(a.kiri, b.kiri);
  final atas = math.max(a.atas, b.atas);
  final kanan = math.min(a.kanan, b.kanan);
  final bawah = math.min(a.bawah, b.bawah);
  final w = math.max(0, kanan - kiri);
  final h = math.max(0, bawah - atas);
  final irisan = w * h;
  final total = a.luas + b.luas - irisan;
  return total <= 0 ? 0 : irisan / total;
}

List<KotakDeteksi> _nms(List<KotakDeteksi> kandidat, double ambang) {
  final hasil = <KotakDeteksi>[];
  final buang = List<bool>.filled(kandidat.length, false);
  for (var i = 0; i < kandidat.length; i++) {
    if (buang[i]) continue;
    hasil.add(kandidat[i]);
    for (var j = i + 1; j < kandidat.length; j++) {
      if (buang[j]) continue;
      if (_iou(kandidat[i].kotak, kandidat[j].kotak) > ambang) buang[j] = true;
    }
  }
  return hasil;
}
