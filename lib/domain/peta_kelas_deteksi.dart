/// Padanan antara kelas keluaran model deteksi (dataset Food-28, Roboflow)
/// dan kode kelas di basis data aplikasi.
///
/// Detektor tahu nama 28 jenis makanan; sebagian besar sudah punya padanan
/// langsung di 32 kelas aplikasi. Yang tidak punya padanan (mis. french fries,
/// croissant, miso soup) sengaja dibiarkan kosong: item seperti itu tetap
/// dinamai oleh classifier dari potongan gambarnya, bukan dipaksa masuk kelas
/// yang kalorinya berbeda jauh.
library;

/// Urutan kelas pada model deteksi. Harus sama dengan `names` di data.yaml
/// dataset Food-28 (Roboflow `foodrecognition-gxgbz/food-7ki5q` versi 3).
const List<String> namaKelasDeteksi = [
  'Japanese tofu and vegetable chowder',
  'beef curry',
  'beef steak',
  'boiled chicken and vegetables',
  'chinese soup',
  'croissant',
  'croquette',
  'egg roll',
  'egg sunny-side up',
  'french fries',
  'fried chicken',
  'fried fish',
  'fried noodle',
  'fried rice',
  'green salad',
  'grilled eggplant',
  'hamburger',
  'hot dog',
  'macaroni salad',
  'miso soup',
  'pizza',
  'potato salad',
  'raisin bread',
  'rice',
  'roast chicken',
  'sandwiches',
  'sausage',
  'sauteed spinach',
];

/// Kelas deteksi -> kode kelas di tabel `kelas_makanan`.
const Map<String, String> padananKelasDeteksi = {
  'rice': 'nasi_putih',
  'fried rice': 'nasi_goreng',
  'fried chicken': 'ayam_goreng',
  'roast chicken': 'ayam_goreng',
  'green salad': 'caesar_salad',
  'hamburger': 'hamburger',
  'pizza': 'pizza',
  'beef steak': 'steak',
  'egg roll': 'spring_rolls',
};

/// Kode kelas aplikasi untuk satu indeks kelas deteksi, atau null bila tidak
/// ada padanan yang aman.
String? kodeDariDeteksi(int indeks) {
  if (indeks < 0 || indeks >= namaKelasDeteksi.length) return null;
  return padananKelasDeteksi[namaKelasDeteksi[indeks]];
}

/// Nama kelas deteksi untuk satu indeks, dipakai saat menampilkan alasan.
String namaDariDeteksi(int indeks) {
  if (indeks < 0 || indeks >= namaKelasDeteksi.length) return 'makanan';
  return namaKelasDeteksi[indeks];
}
