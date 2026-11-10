import 'package:flutter/services.dart';

enum HasilPasangWidget { diminta, tidakDidukung, gagal }

class StatusWidgetTerpasang {
  const StatusWidgetTerpasang({
    this.empatKaliDua = 0,
    this.duaKaliDua = 0,
    this.didukungPin = false,
  });

  final int empatKaliDua;
  final int duaKaliDua;
  final bool didukungPin;

  bool get adaYangTerpasang => empatKaliDua > 0 || duaKaliDua > 0;
}

/// Jembatan MethodChannel luring untuk menyegarkan dan memasang AppWidget Android.
class WidgetLayarUtamaService {
  static const MethodChannel kanal = MethodChannel(
    'id.rakasyau.foodcal_ai/widget',
  );

  static VoidCallback? _pendengarKamera;
  static bool _handlerTerpasang = false;

  static void pasangPendengarKamera(VoidCallback? pendengar) {
    _pendengarKamera = pendengar;
    if (_handlerTerpasang) return;
    _handlerTerpasang = true;
    kanal.setMethodCallHandler((panggilan) async {
      if (panggilan.method == 'bukaKamera') {
        _pendengarKamera?.call();
      }
      return null;
    });
  }

  static Future<String?> ambilAksiAwal() async {
    try {
      return await kanal.invokeMethod<String>('ambilAksiAwal');
    } on MissingPluginException {
      return null;
    } on PlatformException {
      return null;
    }
  }

  static Future<void> perbarui({
    required double kalori,
    required int target,
    required String tanggal,
  }) async {
    try {
      await kanal.invokeMethod<void>('perbaruiWidget', <String, Object>{
        'kalori': kalori,
        'target': target,
        'tanggal': tanggal,
      });
    } on MissingPluginException {
      return;
    } on PlatformException {
      return;
    }
  }

  static Future<StatusWidgetTerpasang> cekStatus() async {
    try {
      final peta = await kanal.invokeMapMethod<String, Object?>('cekStatus');
      if (peta == null) return const StatusWidgetTerpasang();
      return StatusWidgetTerpasang(
        empatKaliDua: (peta['empatKaliDua'] as num?)?.toInt() ?? 0,
        duaKaliDua: (peta['duaKaliDua'] as num?)?.toInt() ?? 0,
        didukungPin: (peta['didukungPin'] as bool?) ?? false,
      );
    } on MissingPluginException {
      return const StatusWidgetTerpasang();
    } on PlatformException {
      return const StatusWidgetTerpasang();
    }
  }

  static Future<HasilPasangWidget> pasang({required bool ukuranPenuh}) async {
    try {
      final hasil = await kanal.invokeMethod<String>(
        'pasangWidget',
        <String, Object>{
          'jenis': ukuranPenuh ? 'empat_kali_dua' : 'dua_kali_dua',
        },
      );
      if (hasil == 'diminta') return HasilPasangWidget.diminta;
      if (hasil == 'tidak_didukung') return HasilPasangWidget.tidakDidukung;
      return HasilPasangWidget.gagal;
    } on MissingPluginException {
      return HasilPasangWidget.tidakDidukung;
    } on PlatformException {
      return HasilPasangWidget.gagal;
    }
  }
}
