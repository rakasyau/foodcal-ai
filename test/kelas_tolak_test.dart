import 'package:flutter_test/flutter_test.dart';
import 'package:foodcal_ai/domain/kelas_tolak.dart';

/// Vektor probabilitas buatan. Nilainya tidak dinormalkan karena fungsi yang diuji
/// hanya membandingkan besaran relatif antar kelas.
List<double> _vektor(int panjang, Map<int, double> isi) {
  final data = List<double>.filled(panjang, 0.005);
  isi.forEach((i, v) => data[i] = v);
  return data;
}

void main() {
  group('pisahkanKelasTolak', () {
    test('citra bukan makanan ditolak saat kelas ke-34 menang', () {
      final p = _vektor(34, {33: 0.92});
      final hasil = pisahkanKelasTolak(p, 33);
      expect(hasil.adaKelasTolak, isTrue);
      expect(hasil.bukanMakanan, isTrue);
      expect(hasil.probabilitasTolak, greaterThan(0.8));
      // indeks makanan tidak boleh menunjuk ke kelas penolakan
      expect(hasil.indeksMakananTerbaik, lessThan(33));
    });

    test('makanan tetap lolos walau probabilitas kelas penolakan kecil', () {
      final p = _vektor(34, {7: 0.88});
      final hasil = pisahkanKelasTolak(p, 33);
      expect(hasil.bukanMakanan, isFalse);
      expect(hasil.indeksMakananTerbaik, 7);
      expect(hasil.keyakinanMakanan, greaterThan(0.8));
    });

    test('kelas penolakan tidak boleh muncul pada kandidat', () {
      final p = _vektor(34, {33: 0.4, 12: 0.3});
      final hasil = pisahkanKelasTolak(p, 33);
      expect(hasil.urutanMakanan, isNot(contains(33)));
      expect(hasil.urutanMakanan.first, 12);
    });

    test('model 33 kelas lama tetap bekerja tanpa kelas penolakan', () {
      final p = _vektor(33, {5: 0.7});
      final hasil = pisahkanKelasTolak(p, 33);
      expect(hasil.adaKelasTolak, isFalse);
      expect(hasil.bukanMakanan, isFalse);
      expect(hasil.indeksMakananTerbaik, 5);
    });

    test('kelas makanan yang menang tetapi di bawah ambang tidak ditolak', () {
      // kelas penolakan 0,45 < 0,5 sehingga belum dianggap bukan makanan
      final p = _vektor(34, {33: 0.45, 3: 0.4});
      final hasil = pisahkanKelasTolak(p, 33);
      expect(hasil.bukanMakanan, isFalse);
      expect(hasil.indeksMakananTerbaik, 3);
    });
  });
}
