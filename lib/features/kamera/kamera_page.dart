import 'dart:io';
import 'dart:math' as math;

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

import '../../app/router.dart';
import '../../app/theme.dart';
import '../../widgets/ikon_svg.dart';
import '../../widgets/tombol.dart';
import '../hasil/memproses_page.dart';
import 'izin_kamera_page.dart';
import 'metode_foto.dart';

class KameraPage extends StatefulWidget {
  const KameraPage({super.key});

  @override
  State<KameraPage> createState() => _KameraPageState();
}

class _KameraPageState extends State<KameraPage> with WidgetsBindingObserver {
  CameraController? _kontroler;
  bool _memuat = true;
  bool _izinDitolak = false;
  bool _mengambil = false;
  bool _membukaGaleri = false;
  String? _galat;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _inisialisasi();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _lepaskan();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.inactive) {
      if (_kontroler != null && !_mengambil) {
        _lepaskan(perbaruiState: true);
      }
    } else if (state == AppLifecycleState.resumed) {
      if (_kontroler == null && !_memuat && !_mengambil && !_membukaGaleri) {
        _inisialisasi();
      }
    }
  }

  Future<void> _lepaskan({bool perbaruiState = false}) async {
    final kontroler = _kontroler;
    if (perbaruiState && mounted) {
      setState(() => _kontroler = null);
    } else {
      _kontroler = null;
    }
    if (kontroler != null) {
      try {
        await kontroler.dispose();
      } catch (_) {}
    }
  }

  Future<void> _bukaGaleri() async {
    if (_membukaGaleri || _mengambil) return;
    _membukaGaleri = true;
    try {
      await ambilDariGaleri(context);
    } finally {
      _membukaGaleri = false;
      if (mounted && _kontroler == null && !_memuat && !_izinDitolak) {
        await _inisialisasi();
      }
    }
  }

  Future<void> _inisialisasi() async {
    if (!mounted) return;
    setState(() {
      _memuat = true;
      _galat = null;
    });
    try {
      final kamera = await availableCameras();
      if (kamera.isEmpty) {
        if (!mounted) return;
        setState(() {
          _memuat = false;
          _izinDitolak = true;
        });
        return;
      }
      final belakang = kamera.firstWhere(
        (item) => item.lensDirection == CameraLensDirection.back,
        orElse: () => kamera.first,
      );
      final kontroler = CameraController(
        belakang,
        ResolutionPreset.high,
        enableAudio: false,
      );
      await kontroler.initialize();
      if (!mounted) {
        await kontroler.dispose();
        return;
      }
      setState(() {
        _kontroler = kontroler;
        _memuat = false;
        _izinDitolak = false;
      });
    } on CameraException catch (galat) {
      if (!mounted) return;
      final kode = galat.code;
      final ditolak =
          kode == 'CameraAccessDenied' ||
          kode == 'CameraAccessDeniedWithoutPrompt' ||
          kode == 'CameraAccessRestricted';
      setState(() {
        _memuat = false;
        _izinDitolak = ditolak;
        _galat = ditolak ? null : 'Kamera tidak dapat dibuka. Coba lagi.';
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _memuat = false;
        _galat = 'Kamera tidak dapat dibuka. Coba lagi.';
      });
    }
  }

  Future<void> _jepret() async {
    final kontroler = _kontroler;
    if (kontroler == null ||
        !kontroler.value.isInitialized ||
        _mengambil ||
        kontroler.value.isTakingPicture) {
      return;
    }
    setState(() => _mengambil = true);
    try {
      final berkas = await kontroler.takePicture();
      final bytes = await berkas.readAsBytes();
      try {
        final sisa = File(berkas.path);
        if (await sisa.exists()) {
          await sisa.delete();
        }
      } catch (_) {}
      if (!mounted) return;
      await Rute.ganti(
        context,
        MemprosesPage(foto: bytes, sumberFoto: 'kamera'),
      );
    } catch (_) {
      if (!mounted) return;
      setState(() => _mengambil = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Foto gagal diambil. Coba lagi.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_izinDitolak) {
      return IzinKameraDitolakPage(onPilihGaleri: _bukaGaleri);
    }
    final kontroler = _kontroler;
    final siap = kontroler != null && kontroler.value.isInitialized;
    final potret =
        MediaQuery.orientationOf(context) == Orientation.portrait;
    final ukuranPratinjau = kontroler?.value.previewSize;
    final lebarPratinjau = ukuranPratinjau == null
        ? 1.0
        : (potret ? ukuranPratinjau.height : ukuranPratinjau.width);
    final tinggiPratinjau = ukuranPratinjau == null
        ? 1.0
        : (potret ? ukuranPratinjau.width : ukuranPratinjau.height);

    return Scaffold(
      backgroundColor: const Color(0xFF111111),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TombolLingkaran(
                    ikonGaris: JenisIkon.kembali,
                    label: 'Kembali',
                    latar: const Color(0xFF2A2A2A),
                    depan: Colors.white,
                    onPressed: () => Navigator.of(context).maybePop(),
                  ),
                  const Text(
                    'Kamera',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 44),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: Container(
                    width: double.infinity,
                    color: const Color(0xFF2A2A2A),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        AnimatedSwitcher(
                          duration: context.kurangiGerak
                              ? Duration.zero
                              : const Duration(milliseconds: 220),
                          child: siap
                              ? SizedBox.expand(
                                  key: const ValueKey<String>('pratinjau-siap'),
                                  child: FittedBox(
                                    fit: BoxFit.cover,
                                    clipBehavior: Clip.hardEdge,
                                    child: SizedBox(
                                      width: lebarPratinjau,
                                      height: tinggiPratinjau,
                                      child: CameraPreview(kontroler),
                                    ),
                                  ),
                                )
                              : _memuat
                              ? const Center(
                                  key: ValueKey<String>('pratinjau-memuat'),
                                  child: SizedBox(
                                    width: 28,
                                    height: 28,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2.5,
                                      color: Colors.white,
                                    ),
                                  ),
                                )
                              : _galat != null
                              ? Center(
                                  key: const ValueKey<String>(
                                    'pratinjau-galat',
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.all(24),
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          _galat!,
                                          textAlign: TextAlign.center,
                                          style: const TextStyle(
                                            fontFamily: 'Poppins',
                                            fontSize: 13,
                                            color: Color(0xFFD9D9D9),
                                          ),
                                        ),
                                        const SizedBox(height: 12),
                                        TextButton(
                                          onPressed: _inisialisasi,
                                          child: const Text(
                                            'Coba Lagi',
                                            style: TextStyle(
                                              color: Colors.white,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                )
                              : const SizedBox.shrink(),
                        ),
                        LayoutBuilder(
                          builder: (context, batas) {
                            final sisi = math.min(
                              270.0,
                              math.min(batas.maxWidth, batas.maxHeight) * 0.82,
                            );
                            return Center(
                              child: BingkaiSudutKamera(ukuran: sisi),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 14),
            const Text(
              'Letakkan satu makanan di dalam bingkai',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 13,
                color: Color(0xFFD9D9D9),
              ),
            ),
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.fromLTRB(36, 0, 36, 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _TombolGaleri(onPressed: _bukaGaleri),
                  _TombolJepret(
                    onPressed: (siap && !_mengambil) ? _jepret : null,
                  ),
                  const SizedBox(width: 56),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TombolJepret extends StatelessWidget {
  const _TombolJepret({required this.onPressed});

  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final kurangi = context.kurangiGerak;
    return Semantics(
      button: true,
      label: 'Ambil foto',
      child: SentuhanSkala(
        aktif: onPressed != null,
        skalaTekan: 0.91,
        child: GestureDetector(
          onTap: onPressed,
          child: Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 4),
            ),
            alignment: Alignment.center,
            child: AnimatedContainer(
              duration: kurangi
                  ? Duration.zero
                  : const Duration(milliseconds: 160),
              curve: Curves.easeOutCubic,
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: onPressed == null
                    ? Colors.white.withValues(alpha: 0.45)
                    : Colors.white,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _TombolGaleri extends StatelessWidget {
  const _TombolGaleri({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Pilih dari Galeri',
      child: SentuhanSkala(
        skalaTekan: 0.93,
        child: Material(
          color: const Color(0xFF2A2A2A),
          shape: const CircleBorder(),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onPressed,
            child: const SizedBox(
              width: 56,
              height: 56,
              child: Center(
                child: IkonGaris(
                  JenisIkon.galeri,
                  ukuran: 22,
                  warna: Colors.white,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
