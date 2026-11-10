import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../app/theme.dart';
import '../../core/formatter.dart';
import '../../domain/model.dart';
import '../../widgets/ikon_svg.dart';
import '../../widgets/tombol.dart';

/// Mencatat makanan yang tidak ada di 32 kelas model.
///
/// Hanya nama, kalori, dan makro opsional yang disimpan. Tidak ada foto.
class CatatManualPage extends ConsumerStatefulWidget {
  const CatatManualPage({super.key, this.tanggal});

  final DateTime? tanggal;

  @override
  ConsumerState<CatatManualPage> createState() => _CatatManualPageState();
}

class _CatatManualPageState extends ConsumerState<CatatManualPage> {
  final _nama = TextEditingController();
  final _kalori = TextEditingController();
  final _porsi = TextEditingController(text: '250');
  final _protein = TextEditingController();
  final _lemak = TextEditingController();
  final _karbo = TextEditingController();
  String? _galat;
  bool _menyimpan = false;

  @override
  void dispose() {
    _nama.dispose();
    _kalori.dispose();
    _porsi.dispose();
    _protein.dispose();
    _lemak.dispose();
    _karbo.dispose();
    super.dispose();
  }

  double? _angkaOpsional(TextEditingController kendali) {
    final teks = kendali.text.trim();
    if (teks.isEmpty) return 0;
    return bacaAngka(teks);
  }

  Future<void> _simpan() async {
    if (_menyimpan) return;
    final nama = _nama.text.trim();
    final kalori = bacaAngka(_kalori.text);
    if (nama.isEmpty) {
      setState(() => _galat = 'Nama makanan belum diisi.');
      return;
    }
    if (kalori == null || kalori <= 0) {
      setState(() => _galat = 'Kalori harus lebih dari nol.');
      return;
    }
    final teksPorsi = _porsi.text.trim();
    final porsi = teksPorsi.isEmpty ? 250.0 : bacaAngka(teksPorsi);
    if (porsi == null || porsi <= 0) {
      setState(() => _galat = 'Porsi harus lebih dari nol.');
      return;
    }
    final protein = _angkaOpsional(_protein);
    final lemak = _angkaOpsional(_lemak);
    final karbo = _angkaOpsional(_karbo);
    if (protein == null ||
        lemak == null ||
        karbo == null ||
        protein < 0 ||
        lemak < 0 ||
        karbo < 0) {
      setState(() => _galat = 'Periksa kembali angka gizi yang diisi.');
      return;
    }
    setState(() {
      _galat = null;
      _menyimpan = true;
    });
    final sekarang = DateTime.now();
    final targetTanggal = tanggalSaja(widget.tanggal ?? sekarang);
    final waktuCatat = targetTanggal == tanggalSaja(sekarang)
        ? sekarang
        : DateTime(
            targetTanggal.year,
            targetTanggal.month,
            targetTanggal.day,
            sekarang.hour,
            sekarang.minute,
            sekarang.second,
          );
    final entri = EntriLog(
      kelasId: null,
      namaSnapshot: nama,
      porsiG: porsi,
      kalori: kalori,
      proteinG: protein,
      lemakG: lemak,
      khG: karbo,
      keyakinan: 0,
      waktu: waktuCatat,
      tanggal: formatTanggalIso(targetTanggal),
      sumberFoto: 'manual',
      dibuatPada: sekarang,
      sumberPrediksi: 'manual',
    );
    try {
      final repositori = await ref.read(repositoriProvider.future);
      await repositori.log.simpan(entri);
      if (!mounted) return;
      segarkanCatatan(ref);
      Navigator.of(context).pop(true);
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _menyimpan = false;
        _galat = 'Catatan gagal disimpan. Coba lagi.';
      });
    }
  }

  Widget _kolom({
    required String label,
    required TextEditingController kendali,
    String? petunjuk,
    bool angka = false,
    bool wajib = false,
  }) {
    final c = context.warna;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: kendali,
        keyboardType: angka
            ? const TextInputType.numberWithOptions(decimal: true)
            : TextInputType.text,
        inputFormatters: angka
            ? [FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]'))]
            : null,
        style: TextStyle(fontFamily: 'Poppins', fontSize: 14, color: c.ink),
        decoration: InputDecoration(
          labelText: wajib ? '$label *' : label,
          hintText: petunjuk,
          labelStyle: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 13,
            color: c.inkSoft,
          ),
          hintStyle: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 13,
            color: c.muted,
          ),
          filled: true,
          fillColor: c.surfaceAlt,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 14,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = context.warna;
    return Scaffold(
      backgroundColor: c.bg,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            AppJarak.halaman,
            12,
            AppJarak.halaman,
            28,
          ),
          children: [
            Row(
              children: [
                TombolLingkaran(
                  ikonGaris: JenisIkon.kembali,
                  label: 'Kembali',
                  latar: c.surface,
                  onPressed: () => Navigator.of(context).maybePop(),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Catat Manual',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: c.ink,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Untuk makanan di luar 32 kelas model. Angka kalori diisi sendiri, '
              'foto tidak disimpan.',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 13,
                height: 1.5,
                color: c.inkSoft,
              ),
            ),
            const SizedBox(height: 20),
            _kolom(
              label: 'Nama makanan',
              kendali: _nama,
              petunjuk: 'Contoh: nasi uduk',
              wajib: true,
            ),
            _kolom(
              label: 'Kalori (kkal)',
              kendali: _kalori,
              petunjuk: 'Contoh: 350',
              angka: true,
              wajib: true,
            ),
            _kolom(
              label: 'Porsi (gram)',
              kendali: _porsi,
              petunjuk: '250',
              angka: true,
            ),
            Row(
              children: [
                Expanded(
                  child: _kolom(
                    label: 'Protein (g)',
                    kendali: _protein,
                    angka: true,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _kolom(
                    label: 'Lemak (g)',
                    kendali: _lemak,
                    angka: true,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _kolom(
                    label: 'Karbo (g)',
                    kendali: _karbo,
                    angka: true,
                  ),
                ),
              ],
            ),
            if (_galat != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Text(
                  _galat!,
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 13,
                    color: c.accent,
                  ),
                ),
              ),
            const SizedBox(height: 6),
            TombolUtama(
              label: 'Simpan ke Catatan',
              onPressed: _simpan,
              memuat: _menyimpan,
            ),
          ],
        ),
      ),
    );
  }
}
