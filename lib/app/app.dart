import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/model.dart';
import '../features/onboarding/onboarding_page.dart';
import '../widgets/ikon_svg.dart';
import 'main_shell.dart';
import 'messenger.dart';
import 'providers.dart';
import 'theme.dart';

class FoodCalApp extends ConsumerWidget {
  const FoodCalApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final modeKode = ref.watch(
      pengaturanProvider.select((nilai) => nilai.value?.modeTema ?? temaSistem),
    );

    return MaterialApp(
      title: 'FoodCal AI',
      debugShowCheckedModeBanner: false,
      scaffoldMessengerKey: scaffoldMessengerKey,
      locale: const Locale('id', 'ID'),
      supportedLocales: const [Locale('id', 'ID')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      theme: AppTema.terang(),
      darkTheme: AppTema.gelap(),
      themeMode: modeTemaDariKode(modeKode),
      themeAnimationDuration: const Duration(milliseconds: 260),
      themeAnimationCurve: Curves.easeOutCubic,
      builder: (context, child) {
        final tema = Theme.of(context);
        final warnaLatar = tema.scaffoldBackgroundColor;
        return AnnotatedRegion<SystemUiOverlayStyle>(
          value: gayaSistemUi(tema.brightness, warnaLatar),
          child: child ?? const SizedBox.shrink(),
        );
      },
      home: const GerbangAwal(),
    );
  }
}

class GerbangAwal extends ConsumerStatefulWidget {
  const GerbangAwal({super.key});

  @override
  ConsumerState<GerbangAwal> createState() => _GerbangAwalState();
}

class _GerbangAwalState extends ConsumerState<GerbangAwal> {
  String? _modelDipanaskan;
  int? _targetWidgetDisinkronkan;
  bool? _onboardingTerakhir;

  void _panaskanModelJikaPerlu(String kodeModel) {
    if (_modelDipanaskan == kodeModel) return;
    _modelDipanaskan = kodeModel;
    unawaited(
      ref
          .read(inferensiProvider)
          .siapkanModel(kodeModel)
          .catchError((Object _) => ''),
    );
  }

  void _sinkronkanWidgetJikaPerlu(Pengaturan nilai) {
    if (_targetWidgetDisinkronkan == nilai.targetKalori &&
        _onboardingTerakhir == nilai.onboardingSelesai) {
      return;
    }
    _targetWidgetDisinkronkan = nilai.targetKalori;
    _onboardingTerakhir = nilai.onboardingSelesai;
    unawaited(sinkronkanWidgetLayarUtama(ref));
  }

  @override
  Widget build(BuildContext context) {
    final c = context.warna;
    final kurangi = context.kurangiGerak;
    final pengaturan = ref.watch(pengaturanProvider);

    final Widget layar = pengaturan.when(
      loading: () => Scaffold(
        key: const ValueKey<String>('gerbang-memuat'),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const LogoFoodCal(ukuran: 64),
              const SizedBox(height: 18),
              Text(
                'FoodCal AI',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: c.ink,
                ),
              ),
              const SizedBox(height: 14),
              SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: c.accent,
                ),
              ),
            ],
          ),
        ),
      ),
      error: (_, _) => Scaffold(
        key: const ValueKey<String>('gerbang-galat'),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Data belum dapat dibuka',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: c.ink,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Aplikasi gagal menyiapkan basis data luring.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 13,
                    color: c.muted,
                  ),
                ),
                const SizedBox(height: 20),
                TextButton(
                  onPressed: () {
                    ref.invalidate(databaseProvider);
                    ref.invalidate(pengaturanProvider);
                  },
                  child: const Text('Coba Lagi'),
                ),
              ],
            ),
          ),
        ),
      ),
      data: (nilai) {
        _panaskanModelJikaPerlu(nilai.modelAktif);
        _sinkronkanWidgetJikaPerlu(nilai);
        return nilai.onboardingSelesai
            ? const MainShell(key: ValueKey<String>('gerbang-utama'))
            : const OnboardingPage(key: ValueKey<String>('gerbang-onboarding'));
      },
    );

    return AnimatedSwitcher(
      duration: kurangi ? Duration.zero : const Duration(milliseconds: 260),
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      child: layar,
    );
  }
}
