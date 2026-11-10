import 'package:flutter_test/flutter_test.dart';
import 'package:foodcal_ai/domain/model.dart';
import 'package:foodcal_ai/services/ekspor_csv.dart';

void main() {
  test('CSV memuat tajuk dan satu baris per entri', () {
    final waktu = DateTime(2026, 10, 28, 15, 10);
    final entri = EntriLog(
      id: 1,
      kelasId: 9,
      namaSnapshot: 'Gado-gado, spesial',
      porsiG: 250,
      kalori: 452,
      proteinG: 21,
      lemakG: 18,
      khG: 55,
      keyakinan: 0.88,
      waktu: waktu,
      tanggal: '2026-10-28',
      sumberFoto: 'kamera',
      dibuatPada: waktu,
    );
    final csv = EksporCsv.buatCsv([entri]);
    final baris = csv.split('\r\n');
    expect(baris.first, startsWith('Tanggal,Waktu,Makanan'));
    expect(baris.length, 2);
    expect(baris.last, contains('"Gado-gado, spesial"'));
    expect(baris.last, contains('15.10'));
    expect(baris.last, contains('452,0'));
  });
}
