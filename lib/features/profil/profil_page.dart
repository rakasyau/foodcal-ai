import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../app/router.dart';
import '../../app/theme.dart';
import '../../core/formatter.dart';
import '../../domain/model.dart';
import '../../domain/rekap.dart';
import '../../services/ekspor_csv.dart';
import '../../widgets/ikon_svg.dart';
import 'widget_layar_utama_page.dart';

class ProfilPage extends ConsumerStatefulWidget {
  const ProfilPage({super.key});

  @override
  ConsumerState<ProfilPage> createState() => _ProfilPageState();
}

class _ProfilPageState extends ConsumerState<ProfilPage> {
  bool _mengekspor = false;

  Future<void> _ekspor() async {
    if (_mengekspor) return;
    setState(() => _mengekspor = true);
    try {
      final repositori = await ref.read(repositoriProvider.future);
      final semua = await repositori.log.semua();
      if (!mounted) return;
      if (semua.isEmpty) {
        setState(() => _mengekspor = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Belum ada catatan untuk diekspor.')),
        );
        return;
      }
      await EksporCsv.bagikan(semua);
      if (!mounted) return;
      setState(() => _mengekspor = false);
    } catch (_) {
      if (!mounted) return;
      setState(() => _mengekspor = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Ekspor gagal. Coba lagi.')));
    }
  }

  Future<void> _ubahNama(Pengaturan pengaturan) async {
    final hasil = await showDialog<String>(
      context: context,
      builder: (_) => _DialogUbahNama(awal: pengaturan.namaPengguna),
    );
    if (hasil == null || !mounted) return;
    try {
      final repositori = await ref.read(repositoriProvider.future);
      await repositori.pengaturan.simpan(
        pengaturan.salinDengan(namaPengguna: hasil),
      );
      ref.invalidate(pengaturanProvider);
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Nama panggilan diperbarui')));
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Nama gagal disimpan.')));
    }
  }

  Future<void> _saranTarget(Pengaturan pengaturan) async {
    final hasil = await showDialog<int>(
      context: context,
      builder: (_) => const _DialogSaranTarget(),
    );
    if (hasil == null || !mounted) return;
    try {
      final repositori = await ref.read(repositoriProvider.future);
      await repositori.pengaturan.simpan(
        pengaturan.salinDengan(targetKalori: hasil),
      );
      ref.invalidate(pengaturanProvider);
      unawaited(sinkronkanWidgetLayarUtama(ref));
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Target harian diatur ke ${formatRibuan(hasil)} kkal'),
        ),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Target gagal disimpan.')));
    }
  }

  Future<void> _pilihTema(Pengaturan pengaturan) async {
    final c = context.warna;
    final dipilih = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: c.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.besar),
        ),
        title: const Text('Tema tampilan'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _KartuOpsiTema(
              judul: 'Terang',
              keterangan: 'Latar cerah yang bersih untuk siang hari',
              ikon: Icons.light_mode_outlined,
              terpilih: pengaturan.modeTema == temaTerang,
              onTap: () => Navigator.of(dialogContext).pop(temaTerang),
            ),
            const SizedBox(height: 8),
            _KartuOpsiTema(
              judul: 'Gelap',
              keterangan: 'Nyaman di mata pada ruangan redup',
              ikon: Icons.dark_mode_outlined,
              terpilih: pengaturan.modeTema == temaGelap,
              onTap: () => Navigator.of(dialogContext).pop(temaGelap),
            ),
            const SizedBox(height: 8),
            _KartuOpsiTema(
              judul: 'Ikuti sistem',
              keterangan: 'Menyesuaikan pengaturan tampilan ponsel',
              ikon: Icons.brightness_auto_outlined,
              terpilih: pengaturan.modeTema == temaSistem,
              onTap: () => Navigator.of(dialogContext).pop(temaSistem),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Tutup'),
          ),
        ],
      ),
    );
    if (dipilih == null || !mounted || dipilih == pengaturan.modeTema) return;
    try {
      final repositori = await ref.read(repositoriProvider.future);
      await repositori.pengaturan.simpan(
        pengaturan.salinDengan(modeTema: dipilih),
      );
      ref.invalidate(pengaturanProvider);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Tema gagal disimpan.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.warna;
    final pengaturan = ref.watch(pengaturanProvider).value ?? Pengaturan.bawaan;
    final tanggalTercatat =
        ref.watch(tanggalTercatatProvider).value ?? const <String>[];
    final tujuhHari =
        ref.watch(rekapRentangProvider(7)).value ?? const <TitikHarian>[];
    final rentetan = hitungRentetan(tanggalTercatat.toSet(), DateTime.now());
    final rataRata = rataRataKalori(tujuhHari);

    return SafeArea(
      bottom: false,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppJarak.halaman,
          20,
          AppJarak.halaman,
          124,
        ),
        children: [
          InkWell(
            onTap: () => _ubahNama(pengaturan),
            borderRadius: BorderRadius.circular(18),
            child: Row(
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: c.ink,
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    pengaturan.inisialNama,
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 24,
                      fontWeight: FontWeight.w600,
                      color: c.bg,
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        pengaturan.namaTampil,
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                          color: c.ink,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Data tersimpan hanya di ponsel ini · ketuk untuk ubah nama',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 12,
                          color: c.inkSoft,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 22),
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: c.accent,
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const IkonGaris(
                          JenisIkon.api,
                          ukuran: 22,
                          warna: Colors.white,
                          tebal: 1.8,
                        ),
                        const SizedBox(height: 10),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '$rentetan hari',
                              style: const TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 28,
                                fontWeight: FontWeight.w700,
                                height: 1,
                                letterSpacing: -0.8,
                                color: Colors.white,
                                fontFeatures: [FontFeature.tabularFigures()],
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'berturut-turut mencatat',
                              style: TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 12,
                                color: Colors.white.withValues(alpha: 0.85),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    children: [
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: c.surface,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Rata-rata 7 hari',
                              style: TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 12,
                                color: c.inkSoft,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${formatKalori(rataRata)} kkal',
                              style: TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: c.ink,
                                fontFeatures: const [
                                  FontFeature.tabularFigures(),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: c.maroon,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Target harian',
                              style: TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 12,
                                color: Color(0xFFB5B5B5),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${formatRibuan(pengaturan.targetKalori)} kkal',
                              style: const TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                                fontFeatures: [FontFeature.tabularFigures()],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 22),
          _BarisProfil(
            garisAtas: true,
            judul: 'Saran target kalori',
            keterangan: 'Dari berat, tinggi, usia (opsional)',
            kanan: Text(
              'Isi data',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: c.ink,
              ),
            ),
            onTap: () => _saranTarget(pengaturan),
          ),
          _BarisProfil(
            judul: 'Tema tampilan',
            keterangan: 'Terang, gelap, atau mengikuti ponsel',
            kanan: Text(
              pengaturan.labelTema,
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: c.ink,
              ),
            ),
            onTap: () => _pilihTema(pengaturan),
          ),
          _BarisProfil(
            judul: 'Pengaturan',
            keterangan: 'Tema, model, ambang, TTA',
            onTap: () => Rute.pengaturan(context),
          ),
          _BarisProfil(
            judul: 'Ekspor catatan (CSV)',
            keterangan: 'Bagikan sebagai berkas CSV',
            kanan: _mengekspor
                ? SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: c.inkSoft,
                    ),
                  )
                : null,
            onTap: _mengekspor ? null : _ekspor,
          ),
          _BarisProfil(
            judul: 'Widget layar utama',
            keterangan: 'Pasang widget 4×2 atau 2×2 di layar utama',
            onTap: () => Rute.buka(context, const WidgetLayarUtamaPage()),
          ),
          const _BarisProfil(
            judul: 'Privasi',
            keterangan: 'Foto tidak disimpan, tanpa izin internet',
          ),
        ],
      ),
    );
  }
}

class _BarisProfil extends StatelessWidget {
  const _BarisProfil({
    required this.judul,
    required this.keterangan,
    this.kanan,
    this.onTap,
    this.garisAtas = false,
  });

  final String judul;
  final String keterangan;
  final Widget? kanan;
  final VoidCallback? onTap;
  final bool garisAtas;

  @override
  Widget build(BuildContext context) {
    final c = context.warna;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            border: Border(
              top: garisAtas ? BorderSide(color: c.line) : BorderSide.none,
              bottom: BorderSide(color: c.line),
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      judul,
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: c.ink,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      keterangan,
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 12,
                        color: c.inkSoft,
                      ),
                    ),
                  ],
                ),
              ),
              if (kanan != null) ...[const SizedBox(width: 12), kanan!],
            ],
          ),
        ),
      ),
    );
  }
}

class _DialogSaranTarget extends StatefulWidget {
  const _DialogSaranTarget();

  @override
  State<_DialogSaranTarget> createState() => _DialogSaranTargetState();
}

class _DialogSaranTargetState extends State<_DialogSaranTarget> {
  final _berat = TextEditingController();
  final _tinggi = TextEditingController();
  final _usia = TextEditingController();
  bool _pria = true;
  String? _galat;

  @override
  void dispose() {
    _berat.dispose();
    _tinggi.dispose();
    _usia.dispose();
    super.dispose();
  }

  int? _hitung() {
    final berat = bacaAngka(_berat.text);
    final tinggi = bacaAngka(_tinggi.text);
    final usia = int.tryParse(_usia.text);
    if (berat == null || tinggi == null || usia == null) return null;
    if (berat < 30 || berat > 300) return null;
    if (tinggi < 100 || tinggi > 250) return null;
    if (usia < 10 || usia > 100) return null;
    final bmr = 10 * berat + 6.25 * tinggi - 5 * usia + (_pria ? 5 : -161);
    final target = (bmr * 1.2).round();
    return target.clamp(800, 6000);
  }

  void _pakai() {
    final nilai = _hitung();
    if (nilai == null) {
      setState(() {
        _galat = 'Isi berat, tinggi, dan usia dengan angka yang wajar.';
      });
      return;
    }
    Navigator.of(context).pop(nilai);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.warna;
    final saran = _hitung();
    return AlertDialog(
      backgroundColor: c.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.besar),
      ),
      title: const Text('Saran target kalori'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Dihitung dengan rumus Mifflin-St Jeor. Kamu tetap dapat menimpanya.',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 12,
                height: 1.5,
                color: c.muted,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _PilihanJenisKelamin(
                    label: 'Pria',
                    terpilih: _pria,
                    onTap: () => setState(() => _pria = true),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _PilihanJenisKelamin(
                    label: 'Wanita',
                    terpilih: !_pria,
                    onTap: () => setState(() => _pria = false),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _berat,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
              ],
              decoration: const InputDecoration(labelText: 'Berat (kg)'),
              onChanged: (_) => setState(() => _galat = null),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _tinggi,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
              ],
              decoration: const InputDecoration(labelText: 'Tinggi (cm)'),
              onChanged: (_) => setState(() => _galat = null),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _usia,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: const InputDecoration(labelText: 'Usia (tahun)'),
              onChanged: (_) => setState(() => _galat = null),
            ),
            if (saran != null) ...[
              const SizedBox(height: 12),
              Text(
                'Saran target: ${formatRibuan(saran)} kkal',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: c.ink,
                ),
              ),
            ],
            if (_galat != null) ...[
              const SizedBox(height: 10),
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
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Batal'),
        ),
        FilledButton(
          onPressed: _pakai,
          style: FilledButton.styleFrom(
            backgroundColor: c.ink,
            foregroundColor: c.bg,
          ),
          child: const Text('Pakai saran'),
        ),
      ],
    );
  }
}

class _PilihanJenisKelamin extends StatelessWidget {
  const _PilihanJenisKelamin({
    required this.label,
    required this.terpilih,
    required this.onTap,
  });

  final String label;
  final bool terpilih;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.warna;
    final durasi = context.kurangiGerak
        ? Duration.zero
        : const Duration(milliseconds: 180);

    return AnimatedContainer(
      duration: durasi,
      curve: Curves.easeOutCubic,
      decoration: BoxDecoration(
        color: terpilih ? c.ink : c.surfaceAlt,
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Material(
        color: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.pill),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Center(
              child: AnimatedDefaultTextStyle(
                duration: durasi,
                curve: Curves.easeOutCubic,
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: terpilih ? c.bg : c.inkSoft,
                ),
                child: Text(label),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _KartuOpsiTema extends StatelessWidget {
  const _KartuOpsiTema({
    required this.judul,
    required this.keterangan,
    required this.ikon,
    required this.terpilih,
    required this.onTap,
  });

  final String judul;
  final String keterangan;
  final IconData ikon;
  final bool terpilih;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.warna;
    return Material(
      color: terpilih ? c.ink : c.surfaceAlt,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.kecil),
        side: BorderSide(color: terpilih ? c.ink : c.line),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Icon(ikon, size: 20, color: terpilih ? c.bg : c.ink),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      judul,
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: terpilih ? c.bg : c.ink,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      keterangan,
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 12,
                        color: terpilih
                            ? c.bg.withValues(alpha: 0.75)
                            : c.inkSoft,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DialogUbahNama extends StatefulWidget {
  const _DialogUbahNama({required this.awal});

  final String awal;

  @override
  State<_DialogUbahNama> createState() => _DialogUbahNamaState();
}

class _DialogUbahNamaState extends State<_DialogUbahNama> {
  late final TextEditingController _kontroler = TextEditingController(
    text: widget.awal,
  );
  String? _galat;

  @override
  void dispose() {
    _kontroler.dispose();
    super.dispose();
  }

  void _simpan() {
    final nilai = _kontroler.text.trim();
    if (nilai.isEmpty) {
      setState(() => _galat = 'Nama tidak boleh kosong.');
      return;
    }
    Navigator.of(context).pop(nilai);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.warna;
    return AlertDialog(
      backgroundColor: c.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.besar),
      ),
      title: const Text('Nama panggilan'),
      content: TextField(
        controller: _kontroler,
        autofocus: true,
        textCapitalization: TextCapitalization.words,
        maxLength: 32,
        decoration: InputDecoration(
          hintText: 'Tulis namamu…',
          counterText: '',
          errorText: _galat,
        ),
        onChanged: (_) {
          if (_galat != null) setState(() => _galat = null);
        },
        onSubmitted: (_) => _simpan(),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Batal'),
        ),
        TextButton(onPressed: _simpan, child: const Text('Simpan')),
      ],
    );
  }
}
