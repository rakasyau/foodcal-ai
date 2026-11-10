import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/messenger.dart';
import '../../app/providers.dart';
import '../../app/theme.dart';
import '../../core/formatter.dart';
import '../../domain/model.dart';
import '../../services/ekspor_csv.dart';
import '../../services/inferensi_service.dart';
import '../../widgets/ikon_svg.dart';
import '../../widgets/tombol.dart';

class PengaturanPage extends ConsumerStatefulWidget {
  const PengaturanPage({super.key});

  @override
  ConsumerState<PengaturanPage> createState() => _PengaturanPageState();
}

class _PengaturanPageState extends ConsumerState<PengaturanPage> {
  double? _ambangSementara;
  bool _mengekspor = false;
  bool _menghapus = false;

  Future<void> _simpan(Pengaturan baru) async {
    final repositori = await ref.read(repositoriProvider.future);
    await repositori.pengaturan.simpan(baru);
    ref.invalidate(pengaturanProvider);
    unawaited(sinkronkanWidgetLayarUtama(ref));
  }

  Future<void> _ubahTema(Pengaturan pengaturan, String modeBaru) async {
    final bersih = normalisasiModeTema(modeBaru);
    if (pengaturan.modeTema == bersih) return;
    try {
      await _simpan(pengaturan.salinDengan(modeTema: bersih));
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pengaturan gagal disimpan.')),
      );
    }
  }

  Future<void> _ubahNama(Pengaturan pengaturan) async {
    final hasil = await showDialog<String>(
      context: context,
      builder: (_) => _DialogInputNama(awal: pengaturan.namaPengguna),
    );
    if (hasil == null || !mounted) return;
    try {
      await _simpan(pengaturan.salinDengan(namaPengguna: hasil));
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Nama panggilan diperbarui')));
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pengaturan gagal disimpan.')),
      );
    }
  }

  Future<void> _ubahTarget(Pengaturan pengaturan) async {
    final hasil = await showDialog<int>(
      context: context,
      builder: (_) => _DialogInputTarget(awal: pengaturan.targetKalori),
    );
    if (hasil == null || !mounted) return;
    try {
      await _simpan(pengaturan.salinDengan(targetKalori: hasil));
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Target kalori diperbarui')));
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pengaturan gagal disimpan.')),
      );
    }
  }

  Future<void> _simpanAmbang(Pengaturan pengaturan, double nilai) async {
    final dibulatkan = (nilai * 20).round() / 20.0;
    try {
      await _simpan(pengaturan.salinDengan(ambangKeyakinan: dibulatkan));
      if (!mounted) return;
      setState(() => _ambangSementara = null);
    } catch (_) {
      if (!mounted) return;
      setState(() => _ambangSementara = null);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pengaturan gagal disimpan.')),
      );
    }
  }

  Future<void> _ubahTta(Pengaturan pengaturan, bool nilai) async {
    try {
      await _simpan(pengaturan.salinDengan(ttaAktif: nilai));
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pengaturan gagal disimpan.')),
      );
    }
  }

  Future<void> _ubahModel(Pengaturan pengaturan) async {
    final hasil = await showDialog<String>(
      context: context,
      builder: (dialogContext) {
        final c = context.warna;
        return AlertDialog(
          backgroundColor: c.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.besar),
          ),
          title: const Text('Model aktif'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _PilihanModel(
                judul: 'Bawaan',
                keterangan: 'EfficientNet-B0 FP16 · 9,67 MB',
                terpilih: pengaturan.modelAktif == modelBawaan,
                onTap: () => Navigator.of(dialogContext).pop(modelBawaan),
              ),
              const SizedBox(height: 8),
              _PilihanModel(
                judul: 'Hemat',
                keterangan: 'MobileNetV3-Small FP16 · 2,77 MB',
                terpilih: pengaturan.modelAktif == modelHemat,
                onTap: () => Navigator.of(dialogContext).pop(modelHemat),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Batal'),
            ),
          ],
        );
      },
    );
    if (hasil == null || !mounted || hasil == pengaturan.modelAktif) return;
    try {
      await _simpan(pengaturan.salinDengan(modelAktif: hasil));
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pengaturan gagal disimpan.')),
      );
    }
  }

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

  Future<void> _hapusSemua() async {
    if (_menghapus) return;
    final c = context.warna;
    final pertama = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: c.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.besar),
        ),
        title: const Text('Hapus semua data?'),
        content: const Text(
          'Seluruh catatan makan akan dihapus. Pengaturan kembali ke nilai bawaan.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text('Lanjut', style: TextStyle(color: c.accent)),
          ),
        ],
      ),
    );
    if (pertama != true || !mounted) return;
    final kedua = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: c.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.besar),
        ),
        title: const Text('Konfirmasi terakhir'),
        content: const Text(
          'Tindakan ini tidak dapat dibatalkan. Semua catatan akan hilang.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: c.accent,
              foregroundColor: c.onAccent,
            ),
            child: const Text('Hapus semua'),
          ),
        ],
      ),
    );
    if (kedua != true || !mounted) return;
    setState(() => _menghapus = true);
    try {
      final repositori = await ref.read(repositoriProvider.future);
      await repositori.log.hapusSemua();
      await repositori.pengaturan.reset();
      segarkanCatatan(ref);
      ref.invalidate(pengaturanProvider);
      if (!mounted) return;
      Navigator.of(context).popUntil((rute) => rute.isFirst);
      scaffoldMessengerKey.currentState?.showSnackBar(
        const SnackBar(content: Text('Semua data dihapus')),
      );
    } catch (_) {
      if (!mounted) return;
      setState(() => _menghapus = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Data gagal dihapus. Coba lagi.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.warna;
    final pengaturan = ref.watch(pengaturanProvider).value ?? Pengaturan.bawaan;
    final ambangTampil = (_ambangSementara ?? pengaturan.ambangKeyakinan).clamp(
      0.30,
      0.90,
    );

    return Scaffold(
      backgroundColor: c.bg,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            AppJarak.halaman,
            12,
            AppJarak.halaman,
            32,
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
                Text(
                  'Pengaturan',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: c.ink,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            _BarisPengaturan(
              garisAtas: true,
              judul: 'Nama panggilan',
              keterangan: 'Ditampilkan pada Beranda dan Profil',
              trailing: Text(pengaturan.namaTampil, style: _gayaNilai(c)),
              onTap: () => _ubahNama(pengaturan),
            ),
            _BarisPengaturan(
              judul: 'Target kalori harian',
              keterangan: 'Dapat diubah kapan saja',
              trailing: Text(
                '${formatRibuan(pengaturan.targetKalori)} kkal',
                style: _gayaNilai(c),
              ),
              onTap: () => _ubahTarget(pengaturan),
            ),
            Container(
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                border: Border(bottom: BorderSide(color: c.line)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Tema tampilan',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: c.ink,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Pilih tampilan terang, gelap, atau mengikuti ponsel',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 12,
                      color: c.inkSoft,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _PemilihTema(
                    nilai: pengaturan.modeTema,
                    onChanged: (kode) => _ubahTema(pengaturan, kode),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                border: Border(bottom: BorderSide(color: c.line)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Ambang keyakinan',
                              style: TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: c.ink,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Di bawah ambang, hasil ditolak',
                              style: TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 12,
                                color: c.inkSoft,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        formatDesimal(ambangTampil, desimal: 2),
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
                  const SizedBox(height: 12),
                  Slider(
                    value: ambangTampil,
                    min: 0.30,
                    max: 0.90,
                    divisions: 12,
                    label: formatDesimal(ambangTampil, desimal: 2),
                    onChanged: (baru) =>
                        setState(() => _ambangSementara = baru),
                    onChangeEnd: (baru) => _simpanAmbang(pengaturan, baru),
                  ),
                ],
              ),
            ),
            _BarisPengaturan(
              judul: 'TTA cermin',
              keterangan: 'Lebih akurat, dua kali inferensi',
              trailing: _SakelarPil(
                nilai: pengaturan.ttaAktif,
                onChanged: (nilai) => _ubahTta(pengaturan, nilai),
              ),
              onTap: () => _ubahTta(pengaturan, !pengaturan.ttaAktif),
            ),
            _BarisPengaturan(
              judul: 'Model aktif',
              keterangan: pengaturan.labelModel,
              trailing: Text(pengaturan.singkatanModel, style: _gayaNilai(c)),
              onTap: () => _ubahModel(pengaturan),
            ),
            _BarisPengaturan(
              judul: 'Ekspor catatan',
              keterangan: 'Bagikan sebagai berkas CSV',
              trailing: _mengekspor
                  ? SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: c.inkSoft,
                      ),
                    )
                  : Text('CSV', style: _gayaNilai(c)),
              onTap: _mengekspor ? null : _ekspor,
            ),
            _BarisPengaturan(
              judul: 'Hapus semua data',
              keterangan: 'Perlu konfirmasi dua kali',
              merusak: true,
              onTap: _menghapus ? null : _hapusSemua,
            ),
            const SizedBox(height: 24),
            Text(
              'FoodCal AI v1.0 · berjalan sepenuhnya luring',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 12,
                color: c.inkSoft,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

TextStyle _gayaNilai(FoodCalColors c) {
  return TextStyle(
    fontFamily: 'Poppins',
    fontSize: 14,
    fontWeight: FontWeight.w600,
    color: c.ink,
    fontFeatures: const [FontFeature.tabularFigures()],
  );
}

class _PemilihTema extends StatelessWidget {
  const _PemilihTema({required this.nilai, required this.onChanged});

  final String nilai;
  final ValueChanged<String> onChanged;

  static const _opsi = <({String kode, String label, IconData ikon})>[
    (kode: temaTerang, label: 'Terang', ikon: Icons.light_mode_outlined),
    (kode: temaGelap, label: 'Gelap', ikon: Icons.dark_mode_outlined),
    (kode: temaSistem, label: 'Sistem', ikon: Icons.brightness_auto_outlined),
  ];

  @override
  Widget build(BuildContext context) {
    final c = context.warna;
    final gelap = context.modeGelap;
    final durasi = context.kurangiGerak
        ? Duration.zero
        : const Duration(milliseconds: 180);

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: gelap ? c.surfaceAlt : c.surface,
        borderRadius: BorderRadius.circular(AppRadius.pill),
        border: Border.all(color: c.line),
      ),
      child: Row(
        children: [
          for (final item in _opsi)
            Expanded(
              child: Semantics(
                button: true,
                selected: nilai == item.kode,
                label: 'Tema ${item.label}',
                child: SentuhanSkala(
                  skalaTekan: 0.96,
                  child: AnimatedContainer(
                    duration: durasi,
                    curve: Curves.easeOutCubic,
                    decoration: BoxDecoration(
                      color: nilai == item.kode ? c.ink : Colors.transparent,
                      borderRadius: BorderRadius.circular(AppRadius.pill),
                    ),
                    child: Material(
                      color: Colors.transparent,
                      borderRadius: BorderRadius.circular(AppRadius.pill),
                      clipBehavior: Clip.antiAlias,
                      child: InkWell(
                        onTap: () => onChanged(item.kode),
                        borderRadius: BorderRadius.circular(AppRadius.pill),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            vertical: 10,
                            horizontal: 8,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                item.ikon,
                                size: 16,
                                color: nilai == item.kode ? c.bg : c.inkSoft,
                              ),
                              const SizedBox(width: 6),
                              Flexible(
                                child: AnimatedDefaultTextStyle(
                                  duration: durasi,
                                  curve: Curves.easeOutCubic,
                                  style: TextStyle(
                                    fontFamily: 'Poppins',
                                    fontSize: 12,
                                    fontWeight: nilai == item.kode
                                        ? FontWeight.w600
                                        : FontWeight.w500,
                                    color:
                                        nilai == item.kode ? c.bg : c.inkSoft,
                                  ),
                                  child: Text(
                                    item.label,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _SakelarPil extends StatelessWidget {
  const _SakelarPil({required this.nilai, required this.onChanged});

  final bool nilai;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final c = context.warna;
    final gelap = context.modeGelap;
    final durasi = context.kurangiGerak
        ? Duration.zero
        : const Duration(milliseconds: 180);
    final latarNonaktif = gelap
        ? const Color(0xFF343434)
        : const Color(0xFFC8C8C4);
    final tepiNonaktif = gelap
        ? const Color(0xFF464646)
        : const Color(0xFFB6B6B2);

    return Semantics(
      toggled: nilai,
      label: 'TTA cermin',
      child: GestureDetector(
        onTap: () => onChanged(!nilai),
        child: AnimatedContainer(
          duration: durasi,
          curve: Curves.easeOutCubic,
          width: 52,
          height: 30,
          padding: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            color: nilai ? c.ink : latarNonaktif,
            borderRadius: BorderRadius.circular(AppRadius.pill),
            border: Border.all(color: nilai ? c.ink : tepiNonaktif),
          ),
          alignment: nilai ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            width: 22,
            height: 22,
            decoration: BoxDecoration(
              color: nilai ? c.bg : Colors.white,
              shape: BoxShape.circle,
              boxShadow: const [
                BoxShadow(
                  color: Color(0x24000000),
                  blurRadius: 4,
                  offset: Offset(0, 1),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _BarisPengaturan extends StatelessWidget {
  const _BarisPengaturan({
    required this.judul,
    required this.keterangan,
    this.trailing,
    this.onTap,
    this.garisAtas = false,
    this.merusak = false,
  });

  final String judul;
  final String keterangan;
  final Widget? trailing;
  final VoidCallback? onTap;
  final bool garisAtas;
  final bool merusak;

  @override
  Widget build(BuildContext context) {
    final c = context.warna;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
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
                        color: merusak ? c.accentDark : c.ink,
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
              if (trailing != null) ...[const SizedBox(width: 12), trailing!],
            ],
          ),
        ),
      ),
    );
  }
}

class _PilihanModel extends StatelessWidget {
  const _PilihanModel({
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
                            ? c.bg.withValues(alpha: 0.72)
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

class _DialogInputNama extends StatefulWidget {
  const _DialogInputNama({required this.awal});

  final String awal;

  @override
  State<_DialogInputNama> createState() => _DialogInputNamaState();
}

class _DialogInputNamaState extends State<_DialogInputNama> {
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

class _DialogInputTarget extends StatefulWidget {
  const _DialogInputTarget({required this.awal});

  final int awal;

  @override
  State<_DialogInputTarget> createState() => _DialogInputTargetState();
}

class _DialogInputTargetState extends State<_DialogInputTarget> {
  late final TextEditingController _kontroler = TextEditingController(
    text: formatRibuan(widget.awal),
  );
  String? _galat;

  @override
  void dispose() {
    _kontroler.dispose();
    super.dispose();
  }

  void _simpan() {
    final angka = bacaAngka(_kontroler.text);
    final nilai = angka?.round();
    if (nilai == null || nilai < 800 || nilai > 6000) {
      setState(() => _galat = 'Isi antara 800 dan 6.000 kkal.');
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
      title: const Text('Target kalori harian'),
      content: TextField(
        controller: _kontroler,
        autofocus: true,
        keyboardType: TextInputType.number,
        inputFormatters: [
          FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
        ],
        decoration: InputDecoration(suffixText: 'kkal', errorText: _galat),
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
