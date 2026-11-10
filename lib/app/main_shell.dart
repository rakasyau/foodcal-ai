import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/formatter.dart';
import '../features/beranda/beranda_page.dart';
import '../features/catatan/grafik_page.dart';
import '../features/profil/profil_page.dart';
import '../services/widget_layar_utama_service.dart';
import '../widgets/nav_pill.dart';
import 'providers.dart';
import 'router.dart';
import 'theme.dart';

class MainShell extends ConsumerStatefulWidget {
  const MainShell({super.key, this.awal = 0});

  final int awal;

  static bool pindahTab(BuildContext context, int indeks) {
    final state = context.findAncestorStateOfType<_MainShellState>();
    if (state == null) return false;
    state.aturTab(indeks);
    return true;
  }

  @override
  ConsumerState<MainShell> createState() => _MainShellState();
}

class _MainShellState extends ConsumerState<MainShell>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  late int _indeks = widget.awal;
  double _arahGeser = 1;
  bool _sedangMembukaKameraWidget = false;
  String _tanggalTerakhir = tanggalHariIni();

  late final AnimationController _kontrolerTab = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 220),
    value: 1,
  );

  static const List<Widget> _halaman = <Widget>[
    BerandaPage(),
    GrafikPage(),
    ProfilPage(),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetLayarUtamaService.pasangPendengarKamera(_bukaKameraDariWidget);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(_periksaAksiAwalWidget());
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    WidgetLayarUtamaService.pasangPendengarKamera(null);
    _kontrolerTab.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed || !mounted) return;
    final sekarang = tanggalHariIni();
    if (sekarang != _tanggalTerakhir) {
      setState(() => _tanggalTerakhir = sekarang);
      segarkanCatatan(ref);
    }
  }

  Future<void> _periksaAksiAwalWidget() async {
    final aksi = await WidgetLayarUtamaService.ambilAksiAwal();
    if (!mounted) return;
    if (aksi == 'buka_kamera') {
      _bukaKameraDariWidget();
    }
  }

  Future<void> _bukaKameraDariWidget() async {
    if (!mounted || _sedangMembukaKameraWidget) return;
    _sedangMembukaKameraWidget = true;
    try {
      await Rute.kamera(context);
    } finally {
      _sedangMembukaKameraWidget = false;
    }
  }

  void aturTab(int indeks) {
    if (!mounted || indeks == _indeks) return;
    final kurangi = context.kurangiGerak;
    setState(() {
      _arahGeser = indeks > _indeks ? 1.0 : -1.0;
      _indeks = indeks;
    });
    if (!kurangi) {
      _kontrolerTab.forward(from: 0);
    } else {
      _kontrolerTab.value = 1;
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.warna;
    final kurva = CurvedAnimation(
      parent: _kontrolerTab,
      curve: Curves.easeOutCubic,
    );

    return PopScope(
      canPop: _indeks == 0,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && _indeks != 0) {
          aturTab(0);
        }
      },
      child: Scaffold(
        extendBody: true,
        backgroundColor: c.bg,
        body: AnimatedBuilder(
          animation: kurva,
          builder: (context, child) {
            final t = kurva.value;
            final geserX = (1 - t) * 10 * _arahGeser;
            final opasitas = 0.38 + (0.62 * t);
            return Opacity(
              opacity: opasitas.clamp(0.0, 1.0),
              child: Transform.translate(
                offset: Offset(geserX, 0),
                child: child,
              ),
            );
          },
          child: IndexedStack(index: _indeks, children: _halaman),
        ),
        bottomNavigationBar: NavPill(
          indeks: _indeks,
          onChanged: aturTab,
          onKamera: () => Rute.kamera(context),
        ),
      ),
    );
  }
}
