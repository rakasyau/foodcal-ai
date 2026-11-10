// Membandingkan tensor hasil praproses Dart dengan pipeline Python.
// Jalankan: dart run tool/cek_praproses.dart <berkas_gambar> <keluaran.bin>
import 'dart:io';
import 'dart:typed_data';

import 'package:foodcal_ai/services/praproses.dart';

void main(List<String> args) {
  if (args.length < 2) {
    stderr.writeln(
      'pakai: dart run tool/cek_praproses.dart gambar keluaran.bin',
    );
    exit(2);
  }
  final bytes = File(args[0]).readAsBytesSync();
  final tensor = praproses(Uint8List.fromList(bytes));
  final data = tensor.data;
  File(args[1]).writeAsBytesSync(
    data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes),
  );
  stdout.writeln(
    'bentuk=${tensor.bentuk} jumlah=${data.length} '
    'min=${data.reduce((a, b) => a < b ? a : b)} '
    'max=${data.reduce((a, b) => a > b ? a : b)}',
  );
}
