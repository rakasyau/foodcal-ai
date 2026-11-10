import 'dart:async';
import 'dart:io';
import 'dart:isolate';
import 'dart:typed_data';

import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:tflite_flutter/tflite_flutter.dart';

import '../domain/model.dart';
import 'praproses.dart';

const String modelBawaan = 'efficientnet_fp16';
const String modelHemat = 'mobilenetv3_fp16';
const List<String> daftarModel = [modelBawaan, modelHemat];

class _ArgumenInferensi {
  const _ArgumenInferensi({
    required this.jalurModel,
    required this.berkasGambar,
    required this.tta,
  });

  final String jalurModel;
  final Uint8List berkasGambar;
  final bool tta;
}

Uint8List _bytesFloat(Float32List data) {
  return data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
}

List<double> _jalankanInferensi(_ArgumenInferensi argumen) {
  final pasangan = argumen.tta
      ? praprosesDenganCermin(argumen.berkasGambar)
      : PasanganInput(asli: praproses(argumen.berkasGambar));
  final opsi = InterpreterOptions()..threads = 2;
  final interpreter = Interpreter.fromFile(
    File(argumen.jalurModel),
    options: opsi,
  );
  try {
    interpreter.allocateTensors();
    final jumlahKelas = interpreter.getOutputTensor(0).shape.last;
    final keluaran = List<List<double>>.generate(
      1,
      (_) => List<double>.filled(jumlahKelas, 0),
    );
    interpreter.run(_bytesFloat(pasangan.asli.data), keluaran);
    final hasil = List<double>.from(keluaran[0]);
    final cermin = pasangan.cermin;
    if (argumen.tta && cermin != null) {
      final keluaranCermin = List<List<double>>.generate(
        1,
        (_) => List<double>.filled(jumlahKelas, 0),
      );
      interpreter.run(_bytesFloat(cermin.data), keluaranCermin);
      for (var i = 0; i < hasil.length; i++) {
        hasil[i] = (hasil[i] + keluaranCermin[0][i]) / 2;
      }
    }
    return hasil;
  } finally {
    interpreter.close();
    opsi.delete();
  }
}

class InferensiService {
  static final Map<String, Future<String>> _berkasModel = {};

  Future<String> siapkanModel(String namaModel) {
    final namaAman = daftarModel.contains(namaModel) ? namaModel : modelBawaan;
    return _berkasModel.putIfAbsent(namaAman, () {
      final tugas = _salinModel(namaAman);
      // Jangan simpan Future yang gagal: percobaan berikutnya harus bisa
      // menyalin ulang, bukan terus menerima galat lama.
      unawaited(
        tugas.then<void>(
          (_) {},
          onError: (Object _) {
            _berkasModel.remove(namaAman);
          },
        ),
      );
      return tugas;
    });
  }

  Future<String> _salinModel(String namaAman) async {
    final direktori = await getApplicationSupportDirectory();
    final folder = Directory(p.join(direktori.path, 'model'));
    if (!await folder.exists()) {
      await folder.create(recursive: true);
    }
    final tujuan = File(p.join(folder.path, '$namaAman.tflite'));
    final data = await rootBundle.load('assets/models/$namaAman.tflite');
    final panjang = await tujuan.exists() ? await tujuan.length() : -1;
    // Salin ulang bila berkas belum ada, terpotong, atau berbeda ukuran dengan
    // aset (mis. model diperbarui pada versi aplikasi yang lebih baru).
    if (panjang != data.lengthInBytes) {
      final sementara = File(p.join(folder.path, '$namaAman.tflite.tmp'));
      await sementara.writeAsBytes(
        data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes),
        flush: true,
      );
      await sementara.rename(tujuan.path);
    }
    return tujuan.path;
  }

  Future<HasilPrediksi> prediksi({
    required Uint8List berkasGambar,
    required List<KelasMakanan> kelas,
    required bool tta,
    required String namaModel,
    required String sumberFoto,
  }) async {
    if (kelas.isEmpty) {
      throw StateError('Tabel kelas makanan kosong');
    }
    final jalur = await siapkanModel(namaModel);
    final probabilitas = await Isolate.run(
      () => _jalankanInferensi(
        _ArgumenInferensi(
          jalurModel: jalur,
          berkasGambar: berkasGambar,
          tta: tta,
        ),
      ),
    );

    final urutan = List<int>.generate(probabilitas.length, (i) => i)
      ..sort((a, b) => probabilitas[b].compareTo(probabilitas[a]));
    final indeksTerbaik = urutan.isEmpty ? 0 : urutan.first;
    final nilaiTerbaik = probabilitas.isEmpty ? 0.0 : probabilitas[indeksTerbaik];

    KelasMakanan kelasUntuk(int indeks) {
      for (final item in kelas) {
        if (item.id == indeks) return item;
      }
      return kelas[indeks.clamp(0, kelas.length - 1)];
    }

    final kandidat = <KandidatPrediksi>[
      for (final indeks in urutan.take(5))
        KandidatPrediksi(
          kelas: kelasUntuk(indeks),
          probabilitas: probabilitas[indeks],
        ),
    ];

    return HasilPrediksi(
      kelas: kelasUntuk(indeksTerbaik),
      keyakinan: nilaiTerbaik,
      sumberFoto: sumberFoto,
      kandidat: kandidat,
    );
  }

  bool lolosAmbang(HasilPrediksi hasil, double ambang) =>
      hasil.keyakinan >= ambang;
}
