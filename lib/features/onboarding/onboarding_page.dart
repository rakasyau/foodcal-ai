import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../app/theme.dart';
import '../../domain/model.dart';
import '../../services/inferensi_service.dart';
import '../../widgets/ikon_svg.dart';
import '../../widgets/tombol.dart';

class OnboardingPage extends ConsumerStatefulWidget {
  const OnboardingPage({super.key});

  @override
  ConsumerState<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends ConsumerState<OnboardingPage> {
  final _nama = TextEditingController();
  final _target = TextEditingController(text: '2.000');
  String _model = modelBawaan;
  String? _galatNama;
  String? _galat;
  bool _menyimpan = false;

  @override
  void dispose() {
    _nama.dispose();
    _target.dispose();
    super.dispose();
  }

  Future<void> _simpan() async {
    final namaBersih = _nama.text.trim();
    if (namaBersih.isEmpty) {
      setState(() {
        _galatNama = 'Isi nama panggilanmu terlebih dahulu.';
      });
      return;
    }
    final bersih = _target.text.replaceAll(RegExp(r'[^0-9]'), '').trim();
    final target = int.tryParse(bersih);
    if (target == null || target < 800 || target > 6000) {
      setState(() {
        _galatNama = null;
        _galat = 'Target harus antara 800 dan 6.000 kkal.';
      });
      return;
    }
    setState(() {
      _galatNama = null;
      _galat = null;
      _menyimpan = true;
    });
    try {
      final repositori = await ref.read(repositoriProvider.future);
      await repositori.pengaturan.simpan(
        Pengaturan.bawaan.salinDengan(
          namaPengguna: namaBersih,
          targetKalori: target,
          modelAktif: _model,
          onboardingSelesai: true,
        ),
      );
      ref.invalidate(pengaturanProvider);
      unawaited(sinkronkanWidgetLayarUtama(ref));
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _menyimpan = false;
        _galat = 'Data belum dapat disimpan. Coba lagi.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.warna;
    return Scaffold(
      backgroundColor: c.bg,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverFillRemaining(
              hasScrollBody: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppJarak.halaman,
                  24,
                  AppJarak.halaman,
                  28,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const LogoFoodCal(ukuran: 44),
                        const SizedBox(width: 10),
                        Text(
                          'FoodCal AI',
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: c.ink,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 28),
                    Text(
                      'Atur target\nkalori harianmu',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 30,
                        height: 1.2,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -1,
                        color: c.ink,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Foto makananmu dianalisis di ponsel, tanpa internet. Foto tidak pernah disimpan atau diunggah.',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 14,
                        height: 1.5,
                        color: c.inkSoft,
                      ),
                    ),
                    const SizedBox(height: 22),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: c.surface,
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Nama panggilan',
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 12,
                              color: c.inkSoft,
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextField(
                            controller: _nama,
                            textCapitalization: TextCapitalization.words,
                            textInputAction: TextInputAction.next,
                            maxLength: 32,
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 22,
                              fontWeight: FontWeight.w600,
                              height: 1.2,
                              color: c.ink,
                            ),
                            decoration: InputDecoration(
                              isDense: true,
                              filled: false,
                              counterText: '',
                              contentPadding: EdgeInsets.zero,
                              border: InputBorder.none,
                              enabledBorder: InputBorder.none,
                              focusedBorder: InputBorder.none,
                              hintText: 'Tulis namamu…',
                              hintStyle: TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 22,
                                fontWeight: FontWeight.w500,
                                color: c.inkSoft.withValues(alpha: 0.55),
                              ),
                            ),
                            onChanged: (_) {
                              if (_galatNama != null) {
                                setState(() => _galatNama = null);
                              }
                            },
                          ),
                          if (_galatNama != null) ...[
                            const SizedBox(height: 6),
                            Text(
                              _galatNama!,
                              style: TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 12,
                                color: c.accent,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: c.surface,
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Target kalori per hari',
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 12,
                              color: c.inkSoft,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.baseline,
                            textBaseline: TextBaseline.alphabetic,
                            children: [
                              IntrinsicWidth(
                                child: ConstrainedBox(
                                  constraints: const BoxConstraints(
                                    minWidth: 110,
                                  ),
                                  child: TextField(
                                    controller: _target,
                                    keyboardType: TextInputType.number,
                                    inputFormatters: [
                                      FilteringTextInputFormatter.allow(
                                        RegExp(r'[0-9.]'),
                                      ),
                                    ],
                                    style: TextStyle(
                                      fontFamily: 'Poppins',
                                      fontSize: 44,
                                      fontWeight: FontWeight.w700,
                                      height: 1,
                                      letterSpacing: -1.5,
                                      color: c.ink,
                                      fontFeatures: const [
                                        FontFeature.tabularFigures(),
                                      ],
                                    ),
                                    decoration: const InputDecoration(
                                      isDense: true,
                                      filled: false,
                                      contentPadding: EdgeInsets.zero,
                                      border: InputBorder.none,
                                      enabledBorder: InputBorder.none,
                                      focusedBorder: InputBorder.none,
                                      hintText: '2.000',
                                    ),
                                    onChanged: (_) {
                                      if (_galat != null) {
                                        setState(() => _galat = null);
                                      }
                                    },
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'kkal',
                                style: TextStyle(
                                  fontFamily: 'Poppins',
                                  fontSize: 16,
                                  color: c.inkSoft,
                                ),
                              ),
                            ],
                          ),
                          if (_galat != null) ...[
                            const SizedBox(height: 8),
                            Text(
                              _galat!,
                              style: TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 12,
                                color: c.accent,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Model pengenal makanan',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: c.ink,
                      ),
                    ),
                    const SizedBox(height: 10),
                    IntrinsicHeight(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Expanded(
                            child: _KartuModel(
                              judul: 'Bawaan',
                              keterangan:
                                  'EfficientNet-B0 · 9,67 MB · akurasi 0,90',
                              terpilih: _model == modelBawaan,
                              onTap: () => setState(() => _model = modelBawaan),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _KartuModel(
                              judul: 'Hemat',
                              keterangan:
                                  'MobileNetV3 · 2,77 MB · RAM di bawah 3 GB',
                              terpilih: _model == modelHemat,
                              onTap: () => setState(() => _model = modelHemat),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Spacer(),
                    const SizedBox(height: 24),
                    TombolUtama(
                      label: 'Simpan dan Mulai',
                      onPressed: _simpan,
                      memuat: _menyimpan,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _KartuModel extends StatelessWidget {
  const _KartuModel({
    required this.judul,
    required this.keterangan,
    required this.terpilih,
    required this.onTap,
  });

  final String judul;
  final String keterangan;
  final bool terpilih;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.warna;
    final durasi = context.kurangiGerak
        ? Duration.zero
        : const Duration(milliseconds: 180);
    final latar = terpilih ? c.ink : Colors.transparent;
    final warnaJudul = terpilih ? c.bg : c.ink;
    final warnaKeterangan = terpilih
        ? c.bg.withValues(alpha: 0.72)
        : c.inkSoft;

    return SentuhanSkala(
      skalaTekan: 0.97,
      child: AnimatedContainer(
        duration: durasi,
        curve: Curves.easeOutCubic,
        decoration: BoxDecoration(
          color: latar,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: terpilih ? c.ink : c.line),
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AnimatedDefaultTextStyle(
                    duration: durasi,
                    curve: Curves.easeOutCubic,
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: warnaJudul,
                    ),
                    child: Text(judul),
                  ),
                  const SizedBox(height: 2),
                  AnimatedDefaultTextStyle(
                    duration: durasi,
                    curve: Curves.easeOutCubic,
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 11,
                      height: 1.4,
                      color: warnaKeterangan,
                    ),
                    child: Text(keterangan),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
