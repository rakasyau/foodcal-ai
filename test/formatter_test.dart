import 'package:flutter_test/flutter_test.dart';
import 'package:foodcal_ai/core/formatter.dart';

void main() {
  group('format angka', () {
    test('ribuan Indonesia memakai titik', () {
      expect(formatRibuan(0), '0');
      expect(formatRibuan(999), '999');
      expect(formatRibuan(1000), '1.000');
      expect(formatRibuan(1240), '1.240');
      expect(formatRibuan(1234567), '1.234.567');
    });

    test('desimal Indonesia memakai koma', () {
      expect(formatDesimal(0.6, desimal: 2), '0,60');
      expect(formatDesimal(12.345, desimal: 1), '12,3');
    });

    test('persen dan gram', () {
      expect(formatPersen(92.4), '92%');
      expect(formatPersen(62.5, desimal: 1), '62,5%');
      expect(formatGram(20.6), '21 g');
      expect(formatPorsi(250), '250 g');
    });

    test('bacaAngka mengenali ribuan titik dan desimal koma Indonesia', () {
      expect(bacaAngka('1.200'), 1200);
      expect(bacaAngka('2.000'), 2000);
      expect(bacaAngka('12.500'), 12500);
      expect(bacaAngka('12,5'), closeTo(12.5, 0.0001));
      expect(bacaAngka('12.5'), closeTo(12.5, 0.0001));
      expect(bacaAngka('1.250,5'), closeTo(1250.5, 0.0001));
      expect(bacaAngka('350'), 350);
      expect(bacaAngka(''), isNull);
      expect(bacaAngka('   '), isNull);
      expect(bacaAngka('..'), isNull);
    });
  });

  group('format tanggal dan jam', () {
    final tanggal = DateTime(2026, 10, 28, 15, 10);

    test('nama hari dan bulan Indonesia', () {
      expect(namaHari(tanggal), 'Rabu');
      expect(namaHariPendek(tanggal), 'Rab');
      expect(namaBulan(tanggal), 'Oktober');
      expect(namaBulanPendek(tanggal), 'Okt');
    });

    test('tanggal pendek dan panjang', () {
      expect(formatTanggalPendek(tanggal), '28 Okt 2026');
      expect(formatTanggalPanjang(tanggal), 'Rabu, 28 Oktober 2026');
      expect(formatTanggalIso(tanggal), '2026-10-28');
    });

    test('jam memakai titik', () {
      expect(formatJam(tanggal), '15.10');
      expect(formatJam(DateTime(2026, 10, 28, 7, 5)), '07.05');
    });

    test('tanggal tanpa waktu', () {
      expect(
        tanggalSaja(DateTime(2026, 10, 28, 23, 59)),
        DateTime(2026, 10, 28),
      );
    });

    test('hari ini dikenali dan geserHari melintasi batas bulan', () {
      expect(formatLabelTanggal(DateTime.now()), 'Hari Ini');
      expect(
        formatLabelTanggal(geserHari(DateTime.now(), -1)),
        'Kemarin',
      );
      expect(formatTanggalRingkas(tanggal), '28 Okt');
      expect(geserHari(DateTime(2026, 3, 1), -1), DateTime(2026, 2, 28));
      expect(geserHari(DateTime(2028, 3, 1), -1), DateTime(2028, 2, 29));
    });
  });
}
