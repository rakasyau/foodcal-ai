/// Pemisahan kelas penolakan dari keluaran model.
library;

/// Model produksi punya satu kelas tambahan di indeks terakhir, yaitu
/// "bukan makanan". Kelas itu tidak ada di tabel `kelas_makanan`, sehingga
/// indeksnya harus dibuang sebelum indeks lain dipetakan ke basis data.
class PemisahanTolak {
  const PemisahanTolak({
    required this.bukanMakanan,
    required this.probabilitasTolak,
    required this.indeksMakananTerbaik,
    required this.keyakinanMakanan,
    required this.urutanMakanan,
    required this.adaKelasTolak,
  });

  final bool bukanMakanan;
  final double probabilitasTolak;
  final int indeksMakananTerbaik;
  final double keyakinanMakanan;
  final List<int> urutanMakanan;
  final bool adaKelasTolak;
}

/// [probabilitas] adalah keluaran softmax model, [jumlahKelasMakanan] adalah
/// banyak baris pada tabel kelas makanan. Bila panjang probabilitas lebih besar,
/// indeks terakhir dianggap kelas penolakan.
PemisahanTolak pisahkanKelasTolak(
  List<double> probabilitas,
  int jumlahKelasMakanan, {
  double ambangTolak = 0.5,
}) {
  final urutan = List<int>.generate(probabilitas.length, (i) => i)
    ..sort((a, b) => probabilitas[b].compareTo(probabilitas[a]));
  final adaKelasTolak = probabilitas.length > jumlahKelasMakanan;
  final indeksTolak = adaKelasTolak ? jumlahKelasMakanan : -1;
  final probabilitasTolak = adaKelasTolak ? probabilitas[indeksTolak] : 0.0;
  final terbaik = urutan.isEmpty ? 0.0 : probabilitas[urutan.first];

  final urutanMakanan = [
    for (final indeks in urutan)
      if (indeks != indeksTolak && indeks < probabilitas.length) indeks,
  ];
  final indeksTerbaik = urutanMakanan.isEmpty ? 0 : urutanMakanan.first;

  return PemisahanTolak(
    bukanMakanan: adaKelasTolak &&
        probabilitasTolak >= ambangTolak &&
        probabilitasTolak >= terbaik,
    probabilitasTolak: probabilitasTolak,
    indeksMakananTerbaik: indeksTerbaik,
    keyakinanMakanan: probabilitas.isEmpty ? 0.0 : probabilitas[indeksTerbaik],
    urutanMakanan: urutanMakanan,
    adaKelasTolak: adaKelasTolak,
  );
}
