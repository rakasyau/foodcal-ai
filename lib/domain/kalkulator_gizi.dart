import 'model.dart';

const double batasPorsiMin = 50;
const double batasPorsiMax = 600;
const double langkahPorsi = 10;

class NilaiGizi {
  const NilaiGizi({
    required this.kalori,
    required this.proteinG,
    required this.lemakG,
    required this.khG,
  });

  final double kalori;
  final double proteinG;
  final double lemakG;
  final double khG;

  static const NilaiGizi nol = NilaiGizi(
    kalori: 0,
    proteinG: 0,
    lemakG: 0,
    khG: 0,
  );
}

NilaiGizi hitungDariPer100({
  required double kkal100g,
  required double protein100g,
  required double lemak100g,
  required double kh100g,
  required double porsiG,
}) {
  final rasio = porsiG / 100;
  return NilaiGizi(
    kalori: kkal100g * rasio,
    proteinG: protein100g * rasio,
    lemakG: lemak100g * rasio,
    khG: kh100g * rasio,
  );
}

NilaiGizi hitungGizi(KelasMakanan kelas, double porsiG) {
  return hitungDariPer100(
    kkal100g: kelas.kkal100g,
    protein100g: kelas.protein100g,
    lemak100g: kelas.lemak100g,
    kh100g: kelas.kh100g,
    porsiG: porsiG,
  );
}

NilaiGizi hitungUlangProporsional(EntriLog entri, double porsiBaru) {
  if (porsiBaru.isNaN || porsiBaru <= 0) return NilaiGizi.nol;
  final porsiAsal = entri.porsiG > 0 ? entri.porsiG : batasPorsiMin;
  final rasio = porsiBaru / porsiAsal;
  return NilaiGizi(
    kalori: entri.kalori * rasio,
    proteinG: entri.proteinG * rasio,
    lemakG: entri.lemakG * rasio,
    khG: entri.khG * rasio,
  );
}

double batasiPorsi(double porsi) {
  if (porsi.isNaN) return batasPorsiMin;
  return porsi.clamp(batasPorsiMin, batasPorsiMax).toDouble();
}

double porsiAwal(KelasMakanan kelas) => batasiPorsi(kelas.porsiRefG);

double geserPorsi(double porsi, double delta) =>
    batasiPorsi(batasiPorsi(porsi) + delta);

/// Pilihan porsi cepat: setengah, biasa, besar.
const List<double> faktorPreset = <double>[0.5, 1.0, 1.5];
const List<String> labelFaktorPreset = <String>['Setengah', 'Biasa', 'Besar'];

double porsiDariPreset(KelasMakanan kelas, double faktor) =>
    batasiPorsi(kelas.porsiRefG * faktor);

/// Indeks preset yang sedang aktif, atau -1 bila porsi diatur manual.
int indeksPresetAktif(KelasMakanan kelas, double porsi) {
  for (var i = 0; i < faktorPreset.length; i++) {
    if ((porsiDariPreset(kelas, faktorPreset[i]) - porsi).abs() < 0.5) {
      return i;
    }
  }
  return -1;
}

/// Contoh: "2 tusuk" untuk sate, atau "1 porsi" untuk nasi goreng.
String labelSatuanPorsi(KelasMakanan kelas, double porsiG) {
  final perSatuan = kelas.gramPerSatuan;
  if (perSatuan > 0 && kelas.satuan != 'porsi') {
    final jumlah = porsiG / perSatuan;
    final bulat = jumlah.round();
    final tampil = (jumlah - bulat).abs() < 0.15
        ? '$bulat'
        : jumlah.toStringAsFixed(1).replaceAll('.', ',');
    return '$tampil ${kelas.satuan}';
  }
  if (kelas.porsiRefG <= 0) return '${porsiG.round()} g';
  final rasio = porsiG / kelas.porsiRefG;
  if ((rasio - 1).abs() < 0.06) return '1 porsi';
  final tampil = rasio.toStringAsFixed(1).replaceAll('.', ',');
  return '$tampil porsi';
}

int tampilkanKalori(double kalori) => kalori.round();

int tampilkanMakro(double gram) => gram.round();
