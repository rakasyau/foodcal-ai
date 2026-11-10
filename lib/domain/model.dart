class KelasMakanan {
  const KelasMakanan({
    required this.id,
    required this.kode,
    required this.namaId,
    required this.namaEn,
    required this.kelompok,
    required this.kkal100g,
    required this.protein100g,
    required this.lemak100g,
    required this.kh100g,
    required this.serat100g,
    required this.porsiRefG,
    required this.gramPerCm2,
    required this.sumber,
    this.satuan = 'porsi',
    this.gramPerSatuan = 0,
  });

  final int id;
  final String kode;
  final String namaId;
  final String namaEn;
  final String kelompok;
  final double kkal100g;
  final double protein100g;
  final double lemak100g;
  final double kh100g;
  final double serat100g;
  final double porsiRefG;
  final double? gramPerCm2;
  final String sumber;

  /// Satuan alami yang dipakai pengguna: porsi, mangkuk, tusuk, butir, potong.
  final String satuan;

  /// Berat satu satuan dalam gram. Nol berarti belum diisi.
  final double gramPerSatuan;

  String get labelKelompok => 'Masakan $kelompok';

  /// Contoh: "1 porsi", "2 tusuk".
  String labelSatuan(num jumlah) {
    final angka = jumlah == 1 ? '1' : '$jumlah';
    return '$angka $satuan';
  }


  factory KelasMakanan.dariMap(Map<String, Object?> map) {
    return KelasMakanan(
      id: (map['id'] as num).toInt(),
      kode: map['kode'] as String? ?? '',
      namaId: map['nama_id'] as String? ?? '',
      namaEn: map['nama_en'] as String? ?? '',
      kelompok: map['kelompok'] as String? ?? 'Indonesia',
      kkal100g: (map['kkal_100g'] as num?)?.toDouble() ?? 0,
      protein100g: (map['protein_g'] as num?)?.toDouble() ?? 0,
      lemak100g: (map['lemak_g'] as num?)?.toDouble() ?? 0,
      kh100g: (map['kh_g'] as num?)?.toDouble() ?? 0,
      serat100g: (map['serat_g'] as num?)?.toDouble() ?? 0,
      porsiRefG: (map['porsi_ref_g'] as num?)?.toDouble() ?? 100,
      gramPerCm2: (map['gram_per_cm2'] as num?)?.toDouble(),
      sumber: map['sumber'] as String? ?? '',
      satuan: map['satuan'] as String? ?? 'porsi',
      gramPerSatuan: (map['gram_per_satuan'] as num?)?.toDouble() ?? 0,
    );
  }
}

/// Satu kandidat pada daftar tebakan model.
class KandidatPrediksi {
  const KandidatPrediksi({required this.kelas, required this.probabilitas});

  final KelasMakanan kelas;
  final double probabilitas;
}

class EntriLog {
  const EntriLog({
    this.id,
    required this.kelasId,
    required this.namaSnapshot,
    required this.porsiG,
    required this.kalori,
    required this.proteinG,
    required this.lemakG,
    required this.khG,
    required this.keyakinan,
    required this.waktu,
    required this.tanggal,
    required this.sumberFoto,
    required this.dibuatPada,
    this.kelasPrediksiId,
    this.dikoreksi = false,
    this.sumberPrediksi = 'model',
  });

  final int? id;

  /// Nol bila entri dicatat manual dan tidak terkait kelas mana pun.
  final int? kelasId;
  final String namaSnapshot;
  final double porsiG;
  final double kalori;
  final double proteinG;
  final double lemakG;
  final double khG;
  final double keyakinan;
  final DateTime waktu;
  final String tanggal;
  final String sumberFoto;
  final DateTime dibuatPada;

  /// Kelas yang ditebak model sebelum dikoreksi pengguna.
  final int? kelasPrediksiId;

  /// Benar bila pengguna mengganti kelas hasil tebakan.
  final bool dikoreksi;

  /// model, koreksi, atau manual.
  final String sumberPrediksi;

  bool get dicatatManual => sumberPrediksi == 'manual';

  EntriLog salinDengan({
    int? id,
    int? kelasId,
    String? namaSnapshot,
    double? porsiG,
    double? kalori,
    double? proteinG,
    double? lemakG,
    double? khG,
    double? keyakinan,
    DateTime? waktu,
    String? tanggal,
    String? sumberFoto,
    DateTime? dibuatPada,
    int? kelasPrediksiId,
    bool? dikoreksi,
    String? sumberPrediksi,
  }) {
    return EntriLog(
      id: id ?? this.id,
      kelasId: kelasId ?? this.kelasId,
      namaSnapshot: namaSnapshot ?? this.namaSnapshot,
      porsiG: porsiG ?? this.porsiG,
      kalori: kalori ?? this.kalori,
      proteinG: proteinG ?? this.proteinG,
      lemakG: lemakG ?? this.lemakG,
      khG: khG ?? this.khG,
      keyakinan: keyakinan ?? this.keyakinan,
      waktu: waktu ?? this.waktu,
      tanggal: tanggal ?? this.tanggal,
      sumberFoto: sumberFoto ?? this.sumberFoto,
      dibuatPada: dibuatPada ?? this.dibuatPada,
      kelasPrediksiId: kelasPrediksiId ?? this.kelasPrediksiId,
      dikoreksi: dikoreksi ?? this.dikoreksi,
      sumberPrediksi: sumberPrediksi ?? this.sumberPrediksi,
    );
  }

  Map<String, Object?> keMap({bool sertakanId = false}) {
    return <String, Object?>{
      if (sertakanId && id != null) 'id': id,
      'kelas_id': kelasId,
      'nama_snapshot': namaSnapshot,
      'porsi_g': porsiG,
      'kalori': kalori,
      'protein_g': proteinG,
      'lemak_g': lemakG,
      'kh_g': khG,
      'keyakinan': keyakinan,
      'waktu': waktu.toIso8601String(),
      'tanggal': tanggal,
      'sumber_foto': sumberFoto,
      'dibuat_pada': dibuatPada.toIso8601String(),
      'kelas_prediksi_id': kelasPrediksiId,
      'dikoreksi': dikoreksi ? 1 : 0,
      'sumber_prediksi': sumberPrediksi,
    };
  }

  factory EntriLog.dariMap(Map<String, Object?> map) {
    return EntriLog(
      id: (map['id'] as num?)?.toInt(),
      kelasId: (map['kelas_id'] as num?)?.toInt(),
      namaSnapshot: map['nama_snapshot'] as String? ?? '',
      porsiG: (map['porsi_g'] as num?)?.toDouble() ?? 0,
      kalori: (map['kalori'] as num?)?.toDouble() ?? 0,
      proteinG: (map['protein_g'] as num?)?.toDouble() ?? 0,
      lemakG: (map['lemak_g'] as num?)?.toDouble() ?? 0,
      khG: (map['kh_g'] as num?)?.toDouble() ?? 0,
      keyakinan: (map['keyakinan'] as num?)?.toDouble() ?? 0,
      waktu: DateTime.parse(map['waktu'] as String),
      tanggal: map['tanggal'] as String? ?? '',
      sumberFoto: map['sumber_foto'] as String? ?? 'kamera',
      dibuatPada: DateTime.parse(map['dibuat_pada'] as String),
      kelasPrediksiId: (map['kelas_prediksi_id'] as num?)?.toInt(),
      dikoreksi: ((map['dikoreksi'] as num?)?.toInt() ?? 0) == 1,
      sumberPrediksi: map['sumber_prediksi'] as String? ?? 'model',
    );
  }
}

class HasilPrediksi {
  const HasilPrediksi({
    required this.kelas,
    required this.keyakinan,
    required this.sumberFoto,
    this.kandidat = const <KandidatPrediksi>[],
    this.dipilihManual = false,
  });

  final KelasMakanan kelas;
  final double keyakinan;
  final String sumberFoto;

  /// Kandidat teratas hasil model, urut dari yang paling yakin.
  final List<KandidatPrediksi> kandidat;

  /// Benar bila pengguna memilih kelas sendiri, bukan hasil tebakan model.
  final bool dipilihManual;

  HasilPrediksi salinDengan({
    KelasMakanan? kelas,
    double? keyakinan,
    bool? dipilihManual,
  }) {
    return HasilPrediksi(
      kelas: kelas ?? this.kelas,
      keyakinan: keyakinan ?? this.keyakinan,
      sumberFoto: sumberFoto,
      kandidat: kandidat,
      dipilihManual: dipilihManual ?? this.dipilihManual,
    );
  }
}

const String temaSistem = 'sistem';
const String temaTerang = 'terang';
const String temaGelap = 'gelap';

String normalisasiModeTema(String? kode) {
  if (kode == temaTerang || kode == temaGelap) return kode!;
  return temaSistem;
}

class Pengaturan {
  const Pengaturan({
    this.namaPengguna = '',
    required this.targetKalori,
    required this.ambangKeyakinan,
    required this.ttaAktif,
    required this.modelAktif,
    required this.onboardingSelesai,
    this.modeTema = temaSistem,
  });

  final String namaPengguna;
  final int targetKalori;
  final double ambangKeyakinan;
  final bool ttaAktif;
  final String modelAktif;
  final bool onboardingSelesai;
  final String modeTema;

  static const Pengaturan bawaan = Pengaturan(
    namaPengguna: '',
    targetKalori: 2000,
    ambangKeyakinan: 0.60,
    ttaAktif: false,
    modelAktif: 'efficientnet_fp16',
    onboardingSelesai: false,
    modeTema: temaSistem,
  );

  Pengaturan salinDengan({
    String? namaPengguna,
    int? targetKalori,
    double? ambangKeyakinan,
    bool? ttaAktif,
    String? modelAktif,
    bool? onboardingSelesai,
    String? modeTema,
  }) {
    return Pengaturan(
      namaPengguna: namaPengguna ?? this.namaPengguna,
      targetKalori: targetKalori ?? this.targetKalori,
      ambangKeyakinan: ambangKeyakinan ?? this.ambangKeyakinan,
      ttaAktif: ttaAktif ?? this.ttaAktif,
      modelAktif: modelAktif ?? this.modelAktif,
      onboardingSelesai: onboardingSelesai ?? this.onboardingSelesai,
      modeTema: modeTema != null ? normalisasiModeTema(modeTema) : this.modeTema,
    );
  }

  String get namaTampil {
    final bersih = namaPengguna.trim();
    return bersih.isEmpty ? 'Pengguna' : bersih;
  }

  String get inisialNama => namaTampil.substring(0, 1).toUpperCase();

  bool get modelHemat => modelAktif == 'mobilenetv3_fp16';

  String get labelModel => modelHemat
      ? 'MobileNetV3-Small FP16 · 2,77 MB'
      : 'EfficientNet-B0 FP16 · 9,67 MB';

  String get singkatanModel => modelHemat ? 'Hemat' : 'Bawaan';

  String get labelTema {
    switch (modeTema) {
      case temaTerang:
        return 'Terang';
      case temaGelap:
        return 'Gelap';
      default:
        return 'Sistem';
    }
  }
}

class KunciPengaturan {
  static const namaPengguna = 'nama_pengguna';
  static const targetKalori = 'target_kalori';
  static const ambangKeyakinan = 'ambang_keyakinan';
  static const ttaAktif = 'tta_aktif';
  static const modelAktif = 'model_aktif';
  static const onboardingSelesai = 'onboarding_selesai';
  static const modeTema = 'mode_tema';

  /// Porsi terakhir untuk satu kelas: `porsi_<kelas_id>`.
  static String porsiKelas(int kelasId) => 'porsi_$kelasId';
}
