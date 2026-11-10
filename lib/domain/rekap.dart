import '../core/formatter.dart';

class RekapHarian {
  const RekapHarian({
    required this.kalori,
    required this.proteinG,
    required this.lemakG,
    required this.khG,
    required this.jumlahEntri,
  });

  final double kalori;
  final double proteinG;
  final double lemakG;
  final double khG;
  final int jumlahEntri;

  static const RekapHarian kosong = RekapHarian(
    kalori: 0,
    proteinG: 0,
    lemakG: 0,
    khG: 0,
    jumlahEntri: 0,
  );

  factory RekapHarian.dariMap(Map<String, Object?> map) {
    return RekapHarian(
      kalori: (map['kalori'] as num?)?.toDouble() ?? 0,
      proteinG: (map['protein_g'] as num?)?.toDouble() ?? 0,
      lemakG: (map['lemak_g'] as num?)?.toDouble() ?? 0,
      khG: (map['kh_g'] as num?)?.toDouble() ?? 0,
      jumlahEntri: (map['jumlah'] as num?)?.toInt() ?? 0,
    );
  }

  RekapHarian dikurangi({
    required double kalori,
    required double proteinG,
    required double lemakG,
    required double khG,
  }) {
    return RekapHarian(
      kalori: this.kalori - kalori,
      proteinG: this.proteinG - proteinG,
      lemakG: this.lemakG - lemakG,
      khG: this.khG - khG,
      jumlahEntri: jumlahEntri > 0 ? jumlahEntri - 1 : 0,
    );
  }
}

class TitikHarian {
  const TitikHarian({
    required this.tanggal,
    required this.kalori,
    required this.proteinG,
    required this.lemakG,
    required this.khG,
    required this.jumlahEntri,
  });

  final String tanggal;
  final double kalori;
  final double proteinG;
  final double lemakG;
  final double khG;
  final int jumlahEntri;

  DateTime get tanggalDate => DateTime.parse(tanggal);

  factory TitikHarian.dariMap(Map<String, Object?> map) {
    return TitikHarian(
      tanggal: map['tanggal'] as String,
      kalori: (map['kalori'] as num?)?.toDouble() ?? 0,
      proteinG: (map['protein_g'] as num?)?.toDouble() ?? 0,
      lemakG: (map['lemak_g'] as num?)?.toDouble() ?? 0,
      khG: (map['kh_g'] as num?)?.toDouble() ?? 0,
      jumlahEntri: (map['jumlah'] as num?)?.toInt() ?? 0,
    );
  }

  static TitikHarian kosong(DateTime tanggal) {
    return TitikHarian(
      tanggal: formatTanggalIso(tanggal),
      kalori: 0,
      proteinG: 0,
      lemakG: 0,
      khG: 0,
      jumlahEntri: 0,
    );
  }
}

double sisaKalori(double target, double total) {
  final sisa = target - total;
  return sisa < 0 ? 0 : sisa;
}

bool melebihiTarget(double target, double total) => total > target;

double selisihTarget(double target, double total) {
  final selisih = total - target;
  return selisih < 0 ? 0 : selisih;
}

double persenTarget(double target, double total) {
  if (target <= 0) return 0;
  return total / target * 100;
}

List<TitikHarian> lengkapiRentang({
  required List<TitikHarian> data,
  required DateTime akhir,
  required int jumlahHari,
}) {
  final peta = <String, TitikHarian>{
    for (final titik in data) titik.tanggal: titik,
  };
  final hasil = <TitikHarian>[];
  final dasar = tanggalSaja(akhir);
  for (var i = jumlahHari - 1; i >= 0; i--) {
    final tanggal = geserHari(dasar, -i);
    final kunci = formatTanggalIso(tanggal);
    hasil.add(peta[kunci] ?? TitikHarian.kosong(tanggal));
  }
  return hasil;
}

/// Jumlah hari berturut-turut yang punya catatan, dihitung mundur dari hari ini.
///
/// Bila hari ini belum ada catatan, rentetan tetap dihitung dari kemarin:
/// hari belum berakhir, jadi rentetan belum putus. Rentetan baru menjadi nol
/// bila kemarin juga kosong.
int hitungRentetan(Set<String> tanggalTercatat, DateTime hariIni) {
  var rentetan = 0;
  var tanggal = tanggalSaja(hariIni);
  if (!tanggalTercatat.contains(formatTanggalIso(tanggal))) {
    tanggal = geserHari(tanggal, -1);
  }
  while (tanggalTercatat.contains(formatTanggalIso(tanggal))) {
    rentetan++;
    tanggal = geserHari(tanggal, -1);
  }
  return rentetan;
}

/// Rata-rata kalori harian, hanya dari hari yang benar-benar punya catatan.
///
/// Hari kosong (lupa mencatat) tidak ikut dibagi, supaya rata-rata tidak
/// tampak jauh lebih rendah dari asupan sebenarnya.
double rataRataKalori(List<TitikHarian> data) {
  final terisi = data.where((titik) => titik.jumlahEntri > 0).toList();
  if (terisi.isEmpty) return 0;
  final total = terisi.fold<double>(0, (jumlah, titik) => jumlah + titik.kalori);
  return total / terisi.length;
}
