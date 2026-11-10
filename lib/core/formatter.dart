import 'package:intl/intl.dart';

const _namaHari = <String>[
  'Senin',
  'Selasa',
  'Rabu',
  'Kamis',
  'Jumat',
  'Sabtu',
  'Minggu',
];

const _namaHariPendek = <String>[
  'Sen',
  'Sel',
  'Rab',
  'Kam',
  'Jum',
  'Sab',
  'Min',
];

const _namaBulan = <String>[
  'Januari',
  'Februari',
  'Maret',
  'April',
  'Mei',
  'Juni',
  'Juli',
  'Agustus',
  'September',
  'Oktober',
  'November',
  'Desember',
];

const _namaBulanPendek = <String>[
  'Jan',
  'Feb',
  'Mar',
  'Apr',
  'Mei',
  'Jun',
  'Jul',
  'Agu',
  'Sep',
  'Okt',
  'Nov',
  'Des',
];

String formatRibuan(num nilai) {
  final bulat = nilai.round();
  final teks = bulat.abs().toString();
  final hasil = StringBuffer();
  for (var i = 0; i < teks.length; i++) {
    if (i > 0 && (teks.length - i) % 3 == 0) {
      hasil.write('.');
    }
    hasil.write(teks[i]);
  }
  return bulat < 0 ? '-$hasil' : hasil.toString();
}

String formatDesimal(num nilai, {int desimal = 1}) {
  final teks = nilai.toStringAsFixed(desimal);
  return teks.replaceAll('.', ',');
}

String formatPersen(num nilai, {int desimal = 0}) {
  return '${formatDesimal(nilai, desimal: desimal)}%';
}

String formatKalori(num kkal) => formatRibuan(kkal.round());

String formatGram(num gram) => '${formatRibuan(gram.round())} g';

String formatPorsi(num gram) => '${formatRibuan(gram.round())} g';

String formatJam(DateTime waktu) {
  final jam = waktu.hour.toString().padLeft(2, '0');
  final menit = waktu.minute.toString().padLeft(2, '0');
  return '$jam.$menit';
}

String formatJamMenit(DateTime waktu) => formatJam(waktu);

String namaHari(DateTime tanggal) => _namaHari[tanggal.weekday - 1];

String namaHariPendek(DateTime tanggal) => _namaHariPendek[tanggal.weekday - 1];

String namaBulan(DateTime tanggal) => _namaBulan[tanggal.month - 1];

String namaBulanPendek(DateTime tanggal) => _namaBulanPendek[tanggal.month - 1];

String formatTanggalRingkas(DateTime tanggal) =>
    '${tanggal.day} ${namaBulanPendek(tanggal)}';

String formatTanggalPendek(DateTime tanggal) =>
    '${tanggal.day} ${namaBulanPendek(tanggal)} ${tanggal.year}';

String formatTanggalPanjang(DateTime tanggal) =>
    '${namaHari(tanggal)}, ${tanggal.day} ${namaBulan(tanggal)} ${tanggal.year}';

String formatTanggalIso(DateTime tanggal) =>
    DateFormat('yyyy-MM-dd').format(tanggal);

DateTime tanggalSaja(DateTime waktu) =>
    DateTime(waktu.year, waktu.month, waktu.day);

/// Menggeser tanggal sebanyak [hari] hari kalender.
///
/// Memakai konstruktor `DateTime` alih-alih `Duration(days: n)` supaya tetap
/// tepat pada zona waktu yang mengenal pergeseran jam musim panas (hari bisa
/// berisi 23 atau 25 jam).
DateTime geserHari(DateTime tanggal, int hari) =>
    DateTime(tanggal.year, tanggal.month, tanggal.day + hari);

/// Membaca angka dari masukan pengguna dengan kebiasaan Indonesia.
///
/// - `1.500` dibaca seribu lima ratus (titik sebagai pemisah ribuan),
/// - `12,5` dan `12.5` dibaca dua belas koma lima,
/// - `1.250,5` dibaca seribu dua ratus lima puluh koma lima.
///
/// Mengembalikan null bila teks kosong atau bukan angka.
double? bacaAngka(String teks) {
  var bersih = teks.trim().replaceAll(' ', '');
  if (bersih.isEmpty) return null;
  final adaKoma = bersih.contains(',');
  final adaTitik = bersih.contains('.');
  if (adaKoma && adaTitik) {
    // Format lengkap Indonesia: titik ribuan, koma desimal.
    bersih = bersih.replaceAll('.', '').replaceAll(',', '.');
  } else if (adaKoma) {
    bersih = bersih.replaceAll(',', '.');
  } else if (adaTitik && RegExp(r'^\d{1,3}(\.\d{3})+$').hasMatch(bersih)) {
    // "1.500" atau "12.000": titik di sini pemisah ribuan.
    bersih = bersih.replaceAll('.', '');
  }
  return double.tryParse(bersih);
}

String tanggalHariIni() => formatTanggalIso(DateTime.now());

String formatLabelTanggal(DateTime tanggal) {
  final hariIni = tanggalSaja(DateTime.now());
  final dicek = tanggalSaja(tanggal);
  if (dicek == hariIni) return 'Hari Ini';
  if (dicek == geserHari(hariIni, -1)) return 'Kemarin';
  return formatTanggalPendek(tanggal);
}

String formatTanggalDariIso(String iso) {
  final tanggal = DateTime.tryParse(iso);
  if (tanggal == null) return iso;
  return formatTanggalPendek(tanggal);
}
