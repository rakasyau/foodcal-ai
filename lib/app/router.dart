import 'package:flutter/material.dart';

import '../domain/model.dart';
import '../features/catatan/catatan_harian_page.dart';
import '../features/catatan/ubah_entri_page.dart';
import '../features/kamera/kamera_page.dart';
import '../features/pengaturan/pengaturan_page.dart';

enum _GayaTransisi { geserSumbu, lintasHalus, angkatModal }

PageRoute<T> _buatRute<T>(
  Widget halaman, {
  _GayaTransisi gaya = _GayaTransisi.geserSumbu,
  bool dialogPenuh = false,
}) {
  final durasiMaju = switch (gaya) {
    _GayaTransisi.angkatModal => const Duration(milliseconds: 280),
    _GayaTransisi.lintasHalus => const Duration(milliseconds: 260),
    _GayaTransisi.geserSumbu => const Duration(milliseconds: 240),
  };
  final durasiMundur = switch (gaya) {
    _GayaTransisi.angkatModal => const Duration(milliseconds: 220),
    _GayaTransisi.lintasHalus => const Duration(milliseconds: 200),
    _GayaTransisi.geserSumbu => const Duration(milliseconds: 190),
  };

  return PageRouteBuilder<T>(
    fullscreenDialog: dialogPenuh,
    transitionDuration: durasiMaju,
    reverseTransitionDuration: durasiMundur,
    pageBuilder: (context, animation, secondaryAnimation) => halaman,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      if (MediaQuery.disableAnimationsOf(context)) {
        return child;
      }

      final kurvaMasuk = CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutCubic,
        reverseCurve: Curves.easeInCubic,
      );

      switch (gaya) {
        case _GayaTransisi.angkatModal:
          return FadeTransition(
            opacity: Tween<double>(begin: 0.0, end: 1.0).animate(
              CurvedAnimation(
                parent: animation,
                curve: const Interval(0.0, 0.75, curve: Curves.easeOut),
              ),
            ),
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, 0.06),
                end: Offset.zero,
              ).animate(kurvaMasuk),
              child: child,
            ),
          );

        case _GayaTransisi.lintasHalus:
          return FadeTransition(
            opacity: kurvaMasuk,
            child: ScaleTransition(
              scale: Tween<double>(begin: 0.985, end: 1.0).animate(kurvaMasuk),
              child: child,
            ),
          );

        case _GayaTransisi.geserSumbu:
          final kurvaSekunder = CurvedAnimation(
            parent: secondaryAnimation,
            curve: Curves.easeOutCubic,
            reverseCurve: Curves.easeInCubic,
          );
          return SlideTransition(
            position: Tween<Offset>(
              begin: Offset.zero,
              end: const Offset(-0.025, 0),
            ).animate(kurvaSekunder),
            child: FadeTransition(
              opacity: Tween<double>(begin: 0.0, end: 1.0).animate(
                CurvedAnimation(
                  parent: animation,
                  curve: const Interval(0.0, 0.8, curve: Curves.easeOut),
                ),
              ),
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0.045, 0),
                  end: Offset.zero,
                ).animate(kurvaMasuk),
                child: child,
              ),
            ),
          );
      }
    },
  );
}

class Rute {
  static Future<T?> buka<T>(BuildContext context, Widget halaman) {
    return Navigator.of(context).push<T>(
      _buatRute<T>(halaman, gaya: _GayaTransisi.geserSumbu),
    );
  }

  static Future<T?> ganti<T>(BuildContext context, Widget halaman) {
    return Navigator.of(context).pushReplacement<T, Object?>(
      _buatRute<T>(halaman, gaya: _GayaTransisi.lintasHalus),
    );
  }

  static Future<T?> hapusSampaiAwal<T>(
    NavigatorState navigator,
    Widget halaman,
  ) {
    return navigator.pushAndRemoveUntil<T>(
      _buatRute<T>(halaman, gaya: _GayaTransisi.geserSumbu),
      (rute) => rute.isFirst,
    );
  }

  static Future<void> kamera(BuildContext context) async {
    await Navigator.of(context).push<void>(
      _buatRute<void>(
        const KameraPage(),
        gaya: _GayaTransisi.angkatModal,
        dialogPenuh: true,
      ),
    );
  }

  static Future<void> catatan(BuildContext context, {DateTime? tanggal}) async {
    await buka<void>(context, CatatanHarianPage(tanggal: tanggal));
  }

  static Future<void> pengaturan(BuildContext context) async {
    await buka<void>(context, const PengaturanPage());
  }

  static Future<void> ubahEntri(BuildContext context, EntriLog entri) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.45),
      builder: (_) => UbahEntriPage(entri: entri),
    );
  }
}
