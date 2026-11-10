import 'package:flutter/material.dart';

import '../app/theme.dart';
import '../core/formatter.dart';
import 'tombol.dart';

class PemilihRentang extends StatelessWidget {
  const PemilihRentang({
    super.key,
    required this.nilai,
    required this.onChanged,
    this.trailing,
  });

  final int nilai;
  final ValueChanged<int> onChanged;
  final Widget? trailing;

  static const pilihan = <int, String>{
    1: 'Hari Ini',
    7: '7 Hari',
    30: '30 Hari',
  };

  @override
  Widget build(BuildContext context) {
    final c = context.warna;
    final gelap = context.modeGelap;
    final durasi = context.kurangiGerak
        ? Duration.zero
        : const Duration(milliseconds: 180);

    final deretPil = SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      clipBehavior: Clip.none,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final item in pilihan.entries)
            Padding(
              padding: const EdgeInsets.only(right: AppJarak.kecil),
              child: SentuhanSkala(
                skalaTekan: 0.95,
                child: AnimatedContainer(
                  duration: durasi,
                  curve: Curves.easeOutCubic,
                  decoration: ShapeDecoration(
                    color: item.key == nilai
                        ? c.accent
                        : (gelap ? c.surfaceAlt : c.surface),
                    shape: StadiumBorder(
                      side: BorderSide(
                        color: item.key == nilai
                            ? c.accent
                            : (gelap ? Colors.transparent : c.line),
                      ),
                    ),
                  ),
                  child: Material(
                    color: Colors.transparent,
                    shape: const StadiumBorder(),
                    clipBehavior: Clip.antiAlias,
                    child: InkWell(
                      onTap: () => onChanged(item.key),
                      child: SizedBox(
                        height: 36,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 15),
                          child: Center(
                            child: AnimatedDefaultTextStyle(
                              duration: durasi,
                              curve: Curves.easeOutCubic,
                              style: TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 13,
                                fontWeight: item.key == nilai
                                    ? FontWeight.w500
                                    : FontWeight.w400,
                                color: item.key == nilai ? c.onAccent : c.ink,
                              ),
                              child: Text(item.value),
                            ),
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

    if (trailing == null) {
      return Align(alignment: Alignment.centerLeft, child: deretPil);
    }

    return Row(
      children: [
        Expanded(child: deretPil),
        const SizedBox(width: 8),
        trailing!,
      ],
    );
  }
}

class ChipAksi extends StatelessWidget {
  const ChipAksi({
    super.key,
    required this.label,
    required this.onTap,
    this.memuat = false,
  });

  final String label;
  final VoidCallback? onTap;
  final bool memuat;

  @override
  Widget build(BuildContext context) {
    final c = context.warna;
    final gelap = context.modeGelap;
    return SentuhanSkala(
      aktif: !memuat && onTap != null,
      skalaTekan: 0.95,
      child: Material(
        color: gelap ? c.surfaceAlt : c.surface,
        shape: StadiumBorder(
          side: BorderSide(color: gelap ? Colors.transparent : c.line),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: memuat ? null : onTap,
          child: SizedBox(
            height: 34,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Center(
                child: memuat
                    ? SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: c.ink,
                        ),
                      )
                    : Text(
                        label,
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 12.5,
                          fontWeight: FontWeight.w500,
                          color: c.ink,
                        ),
                      ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class PemilihTanggal extends StatelessWidget {
  const PemilihTanggal({
    super.key,
    required this.tanggal,
    required this.onChanged,
    this.maksimal,
  });

  final DateTime tanggal;
  final ValueChanged<DateTime> onChanged;
  final DateTime? maksimal;

  @override
  Widget build(BuildContext context) {
    final c = context.warna;
    final durasi = context.kurangiGerak
        ? Duration.zero
        : const Duration(milliseconds: 180);
    final batas = tanggalSaja(maksimal ?? DateTime.now());
    final dapatMaju = tanggalSaja(tanggal).isBefore(batas);
    return Row(
      children: [
        _TombolPanah(
          ikon: Icons.chevron_left,
          label: 'Tanggal sebelumnya',
          onPressed: () => onChanged(geserHari(tanggalSaja(tanggal), -1)),
        ),
        Expanded(
          child: InkWell(
            borderRadius: BorderRadius.circular(AppRadius.kecil),
            onTap: () async {
              final hasil = await showDatePicker(
                context: context,
                initialDate: tanggalSaja(tanggal),
                firstDate: DateTime(2020),
                lastDate: batas,
                locale: const Locale('id', 'ID'),
              );
              if (hasil != null) onChanged(tanggalSaja(hasil));
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: AnimatedSwitcher(
                duration: durasi,
                switchInCurve: Curves.easeOutCubic,
                switchOutCurve: Curves.easeInCubic,
                child: Column(
                  key: ValueKey<String>(formatTanggalIso(tanggal)),
                  children: [
                    Text(
                      formatLabelTanggal(tanggal),
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: c.ink,
                      ),
                    ),
                    Text(
                      formatTanggalPanjang(tanggal),
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 11,
                        color: c.inkSoft,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        _TombolPanah(
          ikon: Icons.chevron_right,
          label: 'Tanggal berikutnya',
          onPressed: dapatMaju
              ? () => onChanged(geserHari(tanggalSaja(tanggal), 1))
              : null,
        ),
      ],
    );
  }
}

class _TombolPanah extends StatelessWidget {
  const _TombolPanah({
    required this.ikon,
    required this.label,
    required this.onPressed,
  });

  final IconData ikon;
  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final c = context.warna;
    return IconButton(
      onPressed: onPressed,
      tooltip: label,
      visualDensity: VisualDensity.compact,
      icon: Icon(ikon, color: onPressed == null ? c.line : c.inkSoft),
    );
  }
}
