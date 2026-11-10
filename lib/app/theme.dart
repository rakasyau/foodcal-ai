import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../domain/model.dart';

class FoodCalColors extends ThemeExtension<FoodCalColors> {
  const FoodCalColors({
    required this.bg,
    required this.surface,
    required this.surfaceAlt,
    required this.ink,
    required this.inkSoft,
    required this.muted,
    required this.line,
    required this.accent,
    required this.accentDark,
    required this.accentTerang,
    required this.maroon,
    required this.maroonSoft,
    required this.onAccent,
    required this.onMaroon,
  });

  final Color bg;
  final Color surface;
  final Color surfaceAlt;
  final Color ink;
  final Color inkSoft;
  final Color muted;
  final Color line;
  final Color accent;
  final Color accentDark;
  final Color accentTerang;
  final Color maroon;
  final Color maroonSoft;
  final Color onAccent;
  final Color onMaroon;

  static const FoodCalColors terang = FoodCalColors(
    bg: Color(0xFFF2F2F0),
    surface: Color(0xFFFFFFFF),
    surfaceAlt: Color(0xFFE4E4E2),
    ink: Color(0xFF111111),
    inkSoft: Color(0xFF595959),
    muted: Color(0xFF595959),
    line: Color(0xFFD4D4D0),
    accent: Color(0xFFD6382F),
    accentDark: Color(0xFFC0322B),
    accentTerang: Color(0xFFFF8A80),
    maroon: Color(0xFF111111),
    maroonSoft: Color(0xFF2A2A2A),
    onAccent: Color(0xFFFFFFFF),
    onMaroon: Color(0xFFFFFFFF),
  );

  static const FoodCalColors gelap = FoodCalColors(
    bg: Color(0xFF0E0E0E),
    surface: Color(0xFF1A1A1A),
    surfaceAlt: Color(0xFF242424),
    ink: Color(0xFFFFFFFF),
    inkSoft: Color(0xFFA3A3A3),
    muted: Color(0xFFA3A3A3),
    line: Color(0xFF2E2E2E),
    accent: Color(0xFFD6382F),
    accentDark: Color(0xFFC0322B),
    accentTerang: Color(0xFFFF8A80),
    maroon: Color(0xFF1A1A1A),
    maroonSoft: Color(0xFF2A2A2A),
    onAccent: Color(0xFFFFFFFF),
    onMaroon: Color(0xFFFFFFFF),
  );

  @override
  FoodCalColors copyWith({
    Color? bg,
    Color? surface,
    Color? surfaceAlt,
    Color? ink,
    Color? inkSoft,
    Color? muted,
    Color? line,
    Color? accent,
    Color? accentDark,
    Color? accentTerang,
    Color? maroon,
    Color? maroonSoft,
    Color? onAccent,
    Color? onMaroon,
  }) {
    return FoodCalColors(
      bg: bg ?? this.bg,
      surface: surface ?? this.surface,
      surfaceAlt: surfaceAlt ?? this.surfaceAlt,
      ink: ink ?? this.ink,
      inkSoft: inkSoft ?? this.inkSoft,
      muted: muted ?? this.muted,
      line: line ?? this.line,
      accent: accent ?? this.accent,
      accentDark: accentDark ?? this.accentDark,
      accentTerang: accentTerang ?? this.accentTerang,
      maroon: maroon ?? this.maroon,
      maroonSoft: maroonSoft ?? this.maroonSoft,
      onAccent: onAccent ?? this.onAccent,
      onMaroon: onMaroon ?? this.onMaroon,
    );
  }

  @override
  FoodCalColors lerp(ThemeExtension<FoodCalColors>? other, double t) {
    if (other is! FoodCalColors) return this;
    return FoodCalColors(
      bg: Color.lerp(bg, other.bg, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      surfaceAlt: Color.lerp(surfaceAlt, other.surfaceAlt, t)!,
      ink: Color.lerp(ink, other.ink, t)!,
      inkSoft: Color.lerp(inkSoft, other.inkSoft, t)!,
      muted: Color.lerp(muted, other.muted, t)!,
      line: Color.lerp(line, other.line, t)!,
      accent: Color.lerp(accent, other.accent, t)!,
      accentDark: Color.lerp(accentDark, other.accentDark, t)!,
      accentTerang: Color.lerp(accentTerang, other.accentTerang, t)!,
      maroon: Color.lerp(maroon, other.maroon, t)!,
      maroonSoft: Color.lerp(maroonSoft, other.maroonSoft, t)!,
      onAccent: Color.lerp(onAccent, other.onAccent, t)!,
      onMaroon: Color.lerp(onMaroon, other.onMaroon, t)!,
    );
  }
}

extension WarnaKonteks on BuildContext {
  FoodCalColors get warna =>
      Theme.of(this).extension<FoodCalColors>() ?? FoodCalColors.terang;

  bool get modeGelap => Theme.of(this).brightness == Brightness.dark;

  bool get kurangiGerak => MediaQuery.disableAnimationsOf(this);
}

ThemeMode modeTemaDariKode(String? kode) {
  switch (kode) {
    case temaTerang:
      return ThemeMode.light;
    case temaGelap:
      return ThemeMode.dark;
    default:
      return ThemeMode.system;
  }
}

SystemUiOverlayStyle gayaSistemUi(Brightness kecerahan, Color latarBawah) {
  final gelap = kecerahan == Brightness.dark;
  return SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: gelap ? Brightness.light : Brightness.dark,
    statusBarBrightness: gelap ? Brightness.dark : Brightness.light,
    systemNavigationBarColor: latarBawah,
    systemNavigationBarIconBrightness:
        gelap ? Brightness.light : Brightness.dark,
  );
}

class AppRadius {
  static const double besar = 24;
  static const double kecil = 16;
  static const double pill = 999;
}

class AppJarak {
  static const double halaman = 20;
  static const double antarKartu = 12;
  static const double kecil = 8;
  static const double sangatKecil = 4;
}

class AppTema {
  static ThemeData terang() => _bangun(FoodCalColors.terang, Brightness.light);

  static ThemeData gelap() => _bangun(FoodCalColors.gelap, Brightness.dark);

  static ThemeData _bangun(FoodCalColors c, Brightness kecerahan) {
    final adalahGelap = kecerahan == Brightness.dark;
    final dasar = ThemeData(
      useMaterial3: true,
      brightness: kecerahan,
      fontFamily: 'Poppins',
      scaffoldBackgroundColor: c.bg,
      colorScheme:
          ColorScheme.fromSeed(
            seedColor: c.accent,
            brightness: kecerahan,
          ).copyWith(
            primary: c.accent,
            onPrimary: c.onAccent,
            surface: c.surface,
            onSurface: c.ink,
            error: c.accent,
            onError: c.onAccent,
            surfaceContainerHighest: c.surfaceAlt,
            outline: c.line,
          ),
    );

    final teks = dasar.textTheme
        .apply(fontFamily: 'Poppins', bodyColor: c.ink, displayColor: c.ink)
        .copyWith(
          displayLarge: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 46,
            fontWeight: FontWeight.w700,
            height: 1.1,
            letterSpacing: -1.5,
            color: c.ink,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
          headlineMedium: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: c.ink,
          ),
          titleMedium: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: c.ink,
          ),
          bodyLarge: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 14,
            fontWeight: FontWeight.w400,
            color: c.ink,
          ),
          bodyMedium: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 14,
            fontWeight: FontWeight.w400,
            color: c.ink,
          ),
          bodySmall: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 12,
            fontWeight: FontWeight.w400,
            color: c.inkSoft,
          ),
          labelLarge: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: c.ink,
          ),
          labelSmall: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 12,
            fontWeight: FontWeight.w400,
            color: c.inkSoft,
          ),
        );

    return dasar.copyWith(
      extensions: [c],
      textTheme: teks,
      appBarTheme: AppBarTheme(
        backgroundColor: c.bg,
        foregroundColor: c.ink,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: teks.headlineMedium,
        systemOverlayStyle: gayaSistemUi(kecerahan, c.bg),
      ),
      dividerTheme: DividerThemeData(color: c.line, thickness: 1, space: 1),
      iconTheme: IconThemeData(color: c.ink, size: 22),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: c.surface,
        hintStyle: TextStyle(color: c.muted, fontSize: 14),
        labelStyle: TextStyle(color: c.inkSoft, fontSize: 14),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.kecil),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.kecil),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.kecil),
          borderSide: BorderSide(color: c.accent, width: 1.5),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: c.ink,
        contentTextStyle: TextStyle(
          fontFamily: 'Poppins',
          fontSize: 14,
          color: c.bg,
        ),
        actionTextColor: c.accentTerang,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.kecil),
        ),
      ),
      sliderTheme: SliderThemeData(
        activeTrackColor: c.accent,
        inactiveTrackColor: adalahGelap
            ? const Color(0xFF3A3A3A)
            : const Color(0xFFD9D9D9),
        thumbColor: c.ink,
        overlayColor: c.accent.withValues(alpha: 0.12),
        trackHeight: 8,
        trackShape: const RoundedRectSliderTrackShape(),
        thumbShape: _CincinSliderThumbShape(
          warnaIsi: c.ink,
          warnaTepi: c.surface,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: c.accent,
          textStyle: teks.labelLarge,
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: c.ink,
          foregroundColor: c.bg,
          textStyle: teks.labelLarge,
          minimumSize: const Size.fromHeight(56),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.pill),
          ),
        ),
      ),
    );
  }
}

class _CincinSliderThumbShape extends SliderComponentShape {
  const _CincinSliderThumbShape({
    required this.warnaIsi,
    required this.warnaTepi,
  });

  final Color warnaIsi;
  final Color warnaTepi;

  @override
  Size getPreferredSize(bool isEnabled, bool isDiscrete) => const Size(24, 24);

  @override
  void paint(
    PaintingContext context,
    Offset center, {
    required Animation<double> activationAnimation,
    required Animation<double> enableAnimation,
    required bool isDiscrete,
    required TextPainter labelPainter,
    required RenderBox parentBox,
    required SliderThemeData sliderTheme,
    required TextDirection textDirection,
    required double value,
    required double textScaleFactor,
    required Size sizeWithOverflow,
  }) {
    final canvas = context.canvas;
    final bayangan = Paint()
      ..color = const Color(0x33000000)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);
    canvas.drawCircle(center.translate(0, 2), 11, bayangan);

    final isi = Paint()
      ..color = warnaIsi
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, 10.5, isi);

    final tepi = Paint()
      ..color = warnaTepi
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;
    canvas.drawCircle(center, 10.5, tepi);
  }
}

TextStyle gayaAngka(
  BuildContext context, {
  double ukuran = 46,
  FontWeight bobot = FontWeight.w700,
  Color? warna,
}) {
  return TextStyle(
    fontFamily: 'Poppins',
    fontSize: ukuran,
    fontWeight: bobot,
    height: 1.1,
    letterSpacing: -1.5,
    color: warna ?? context.warna.ink,
    fontFeatures: const [FontFeature.tabularFigures()],
  );
}
