import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../app/theme.dart';
import '../../domain/model.dart';
import '../../widgets/ikon_svg.dart';
import '../../widgets/tombol.dart';

/// Kelas yang paling sering ditambahkan, tampil sebagai pintasan di atas daftar.
///
/// Nasi putih ada di urutan terakhir tabel `kelas_makanan` karena ditambahkan
/// belakangan, jadi tanpa pintasan ini pengguna harus menggulir sampai bawah
/// atau mengetik di kolom pencarian untuk menemukannya.
const List<String> _pintasan = [
  'nasi_putih',
  'nasi_goreng',
  'ayam_goreng',
  'telur_dadar',
];

/// Daftar seluruh 32 kelas makanan dengan pencarian.
///
/// Mengembalikan [KelasMakanan] yang dipilih lewat Navigator.pop.
class PilihMakananPage extends ConsumerStatefulWidget {
  const PilihMakananPage({super.key, this.judul = 'Pilih makanan'});

  final String judul;

  @override
  ConsumerState<PilihMakananPage> createState() => _PilihMakananPageState();
}

class _PilihMakananPageState extends ConsumerState<PilihMakananPage> {
  final _kendali = TextEditingController();
  String _kunci = '';

  @override
  void dispose() {
    _kendali.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.warna;
    final kelasAsync = ref.watch(kelasProvider);

    return Scaffold(
      backgroundColor: c.bg,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 20, 0),
              child: Row(
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
                      widget.judul,
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: c.ink,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: TextField(
                controller: _kendali,
                onChanged: (nilai) => setState(() => _kunci = nilai.trim()),
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 14,
                  color: c.ink,
                ),
                decoration: InputDecoration(
                  hintText: 'Cari makanan',
                  hintStyle: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 14,
                    color: c.muted,
                  ),
                  prefixIcon: Icon(Icons.search, color: c.muted, size: 20),
                  filled: true,
                  fillColor: c.surfaceAlt,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
            if (_kunci.isEmpty)
              kelasAsync.maybeWhen(
                data: (kelas) {
                  final cepat = <KelasMakanan>[
                    for (final kode in _pintasan)
                      ...kelas.where((k) => k.kode == kode),
                  ];
                  if (cepat.isEmpty) return const SizedBox.shrink();
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 0, 20, 6),
                        child: Text(
                          'Sering ditambahkan',
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: c.muted,
                          ),
                        ),
                      ),
                      SizedBox(
                        height: 40,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          itemCount: cepat.length,
                          separatorBuilder: (_, _) => const SizedBox(width: 8),
                          itemBuilder: (context, i) {
                            final k = cepat[i];
                            return _PilPintasan(
                              label: k.namaId,
                              onTap: () => Navigator.of(context).pop(k),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 8),
                    ],
                  );
                },
                orElse: () => const SizedBox.shrink(),
              ),
            Expanded(
              child: kelasAsync.when(
                loading: () => Center(
                  child: CircularProgressIndicator(color: c.accent),
                ),
                error: (_, _) => Center(
                  child: Text(
                    'Daftar makanan belum bisa dimuat.',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      color: c.inkSoft,
                    ),
                  ),
                ),
                data: (kelas) {
                  final kunci = _kunci.toLowerCase();
                  final tersaring = kunci.isEmpty
                      ? kelas
                      : kelas
                            .where(
                              (k) =>
                                  k.namaId.toLowerCase().contains(kunci) ||
                                  k.kode.toLowerCase().contains(kunci) ||
                                  k.kelompok.toLowerCase().contains(kunci),
                            )
                            .toList(growable: false);
                  if (tersaring.isEmpty) {
                    return Center(
                      child: Text(
                        'Tidak ada yang cocok.',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          color: c.inkSoft,
                        ),
                      ),
                    );
                  }
                  return ListView.separated(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
                    itemCount: tersaring.length,
                    separatorBuilder: (_, _) => Divider(
                      height: 1,
                      color: c.line,
                    ),
                    itemBuilder: (context, i) {
                      final k = tersaring[i];
                      return ListTile(
                        contentPadding: EdgeInsets.zero,
                        onTap: () => Navigator.of(context).pop(k),
                        title: Text(
                          k.namaId,
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: c.ink,
                          ),
                        ),
                        subtitle: Text(
                          '${k.labelKelompok} · ${k.kkal100g.toStringAsFixed(0)} kkal/100 g',
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 12,
                            color: c.inkSoft,
                          ),
                        ),
                        trailing: Icon(
                          Icons.chevron_right,
                          size: 20,
                          color: c.muted,
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Tombol pil kecil untuk pintasan "sering ditambahkan".
class _PilPintasan extends StatelessWidget {
  const _PilPintasan({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.warna;
    final gelap = context.modeGelap;
    return Material(
      color: c.surfaceAlt,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.pill),
        side: BorderSide(color: gelap ? const Color(0xFF3A3A3A) : c.line),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.pill),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.add, size: 15, color: c.inkSoft),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: c.ink,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
