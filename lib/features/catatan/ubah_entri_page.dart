import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/messenger.dart';
import '../../app/providers.dart';
import '../../app/theme.dart';
import '../../core/formatter.dart';
import '../../domain/kalkulator_gizi.dart';
import '../../domain/model.dart';
import '../../widgets/tombol.dart';

class UbahEntriPage extends ConsumerStatefulWidget {
  const UbahEntriPage({super.key, required this.entri});

  final EntriLog entri;

  @override
  ConsumerState<UbahEntriPage> createState() => _UbahEntriPageState();
}

class _UbahEntriPageState extends ConsumerState<UbahEntriPage> {
  late double _porsi =
      widget.entri.porsiG > 0 ? widget.entri.porsiG : batasPorsiMin;
  late DateTime _waktu = widget.entri.waktu;
  bool _menyimpan = false;

  void _geserGram(double delta) {
    final porsiAsal =
        widget.entri.porsiG > 0 ? widget.entri.porsiG : batasPorsiMin;
    final batasBawah = porsiAsal < batasPorsiMin
        ? (porsiAsal < langkahPorsi ? porsiAsal : langkahPorsi)
        : batasPorsiMin;
    final batasAtas = porsiAsal > batasPorsiMax ? porsiAsal : batasPorsiMax;
    setState(() {
      _porsi = (_porsi + delta).clamp(batasBawah, batasAtas).toDouble();
    });
  }

  void _geserWaktu(int menit) {
    final tanggal = tanggalSaja(widget.entri.waktu);
    var total = _waktu.hour * 60 + _waktu.minute + menit;
    total = total.clamp(0, 23 * 60 + 59);
    setState(() {
      _waktu = DateTime(
        tanggal.year,
        tanggal.month,
        tanggal.day,
        total ~/ 60,
        total % 60,
      );
    });
  }

  Future<void> _simpan() async {
    if (_menyimpan) return;
    setState(() => _menyimpan = true);
    final gizi = hitungUlangProporsional(widget.entri, _porsi);
    final baru = widget.entri.salinDengan(
      porsiG: _porsi,
      kalori: gizi.kalori,
      proteinG: gizi.proteinG,
      lemakG: gizi.lemakG,
      khG: gizi.khG,
      waktu: _waktu,
      tanggal: widget.entri.tanggal,
    );
    try {
      final repositori = await ref.read(repositoriProvider.future);
      await repositori.log.ubah(baru);
      if (!mounted) return;
      segarkanCatatan(ref);
      Navigator.of(context).pop();
      scaffoldMessengerKey.currentState?.showSnackBar(
        const SnackBar(content: Text('Perubahan disimpan')),
      );
    } catch (_) {
      if (!mounted) return;
      setState(() => _menyimpan = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Perubahan gagal disimpan. Coba lagi.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.warna;
    final entri = widget.entri;
    final gizi = hitungUlangProporsional(entri, _porsi);
    final insetBawah = MediaQuery.viewInsetsOf(context).bottom;

    return Material(
      color: Colors.transparent,
      child: Align(
        alignment: Alignment.bottomCenter,
        child: Container(
          width: double.infinity,
          padding: EdgeInsets.fromLTRB(20, 20, 20, 28 + insetBawah),
          decoration: BoxDecoration(
            color: c.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.25),
                blurRadius: 48,
                offset: const Offset(0, -16),
              ),
            ],
          ),
          child: SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: c.line,
                      borderRadius: BorderRadius.circular(AppRadius.pill),
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    border: Border(bottom: BorderSide(color: c.line)),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              entri.namaSnapshot,
                              style: TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: c.ink,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              entri.dicatatManual
                                  ? 'Dicatat manual · tanpa tebakan model'
                                  : (entri.dikoreksi
                                        ? 'Dikoreksi dari tebakan model · ${formatPersen(entri.keyakinan * 100)}'
                                        : 'Keyakinan ${formatPersen(entri.keyakinan * 100)} · dari ${entri.sumberFoto}'),
                              style: TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 12,
                                color: c.inkSoft,
                                fontFeatures: const [
                                  FontFeature.tabularFigures(),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text.rich(
                        TextSpan(
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 24,
                            fontWeight: FontWeight.w700,
                            color: c.ink,
                            fontFeatures: const [FontFeature.tabularFigures()],
                          ),
                          children: [
                            TextSpan(text: formatKalori(gizi.kalori)),
                            TextSpan(
                              text: ' kkal',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w400,
                                color: c.inkSoft,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Porsi',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: c.ink,
                      ),
                    ),
                    Text(
                      formatPorsi(_porsi),
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: c.ink,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _TombolGramUbah(
                      label: '−50 g',
                      onTap: () => _geserGram(-50),
                    ),
                    _TombolGramUbah(
                      label: '−10 g',
                      onTap: () => _geserGram(-langkahPorsi),
                    ),
                    _TombolGramUbah(
                      label: '+10 g',
                      onTap: () => _geserGram(langkahPorsi),
                    ),
                    _TombolGramUbah(
                      label: '+50 g',
                      onTap: () => _geserGram(50),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    border: Border(
                      top: BorderSide(color: c.line),
                      bottom: BorderSide(color: c.line),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Waktu makan',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: c.ink,
                        ),
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          TombolLingkaran(
                            simbol: '−',
                            label: 'Majukan waktu sepuluh menit',
                            ukuran: 36,
                            latar: c.surfaceAlt,
                            onPressed: () => _geserWaktu(-10),
                          ),
                          const SizedBox(width: 10),
                          SizedBox(
                            width: 56,
                            child: Text(
                              formatJam(_waktu),
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: c.ink,
                                fontFeatures: const [
                                  FontFeature.tabularFigures(),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          TombolLingkaran(
                            simbol: '+',
                            label: 'Mundurkan waktu sepuluh menit',
                            ukuran: 36,
                            latar: c.surfaceAlt,
                            onPressed: () => _geserWaktu(10),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                TombolUtama(
                  label: 'Simpan Perubahan',
                  onPressed: _simpan,
                  memuat: _menyimpan,
                ),
                const SizedBox(height: 8),
                TombolSekunder(
                  label: 'Batal',
                  onPressed: () => Navigator.of(context).maybePop(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _TombolGramUbah extends StatelessWidget {
  const _TombolGramUbah({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.warna;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.pill),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: c.surfaceAlt,
          borderRadius: BorderRadius.circular(AppRadius.pill),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: c.ink,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
      ),
    );
  }
}
