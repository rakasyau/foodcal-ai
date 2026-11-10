import 'package:flutter/material.dart';

import '../app/theme.dart';
import 'ikon_svg.dart';

/// Efek tekan mikro yang tidak merebut gesture arena dari tombol di dalamnya.
class SentuhanSkala extends StatefulWidget {
  const SentuhanSkala({
    super.key,
    required this.child,
    this.aktif = true,
    this.skalaTekan = 0.97,
  });

  final Widget child;
  final bool aktif;
  final double skalaTekan;

  @override
  State<SentuhanSkala> createState() => _SentuhanSkalaState();
}

class _SentuhanSkalaState extends State<SentuhanSkala> {
  bool _ditekan = false;

  void _aturTekan(bool nilai) {
    if (!widget.aktif) {
      if (_ditekan) setState(() => _ditekan = false);
      return;
    }
    if (_ditekan != nilai) {
      setState(() => _ditekan = nilai);
    }
  }

  @override
  Widget build(BuildContext context) {
    final kurangi = context.kurangiGerak;
    final bolehAnimasi = widget.aktif && !kurangi;
    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: (_) => _aturTekan(true),
      onPointerUp: (_) => _aturTekan(false),
      onPointerCancel: (_) => _aturTekan(false),
      child: AnimatedScale(
        scale: (bolehAnimasi && _ditekan) ? widget.skalaTekan : 1.0,
        duration: bolehAnimasi
            ? const Duration(milliseconds: 110)
            : Duration.zero,
        curve: Curves.easeOutCubic,
        child: widget.child,
      ),
    );
  }
}

class TombolUtama extends StatelessWidget {
  const TombolUtama({
    super.key,
    required this.label,
    required this.onPressed,
    this.ikon,
    this.aksen = false,
    this.memuat = false,
    this.tinggi = 56,
    this.ukuranTeks = 15,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? ikon;
  final bool aksen;
  final bool memuat;
  final double tinggi;
  final double ukuranTeks;

  @override
  Widget build(BuildContext context) {
    final c = context.warna;
    final gelap = context.modeGelap;
    final kurangi = context.kurangiGerak;
    final latar = aksen
        ? c.accent
        : (gelap ? const Color(0xFFFFFFFF) : const Color(0xFF111111));
    final depan = aksen
        ? c.onAccent
        : (gelap ? const Color(0xFF111111) : const Color(0xFFFFFFFF));

    return SentuhanSkala(
      aktif: !memuat && onPressed != null,
      child: SizedBox(
        width: double.infinity,
        height: tinggi,
        child: FilledButton(
          onPressed: memuat ? null : onPressed,
          style: FilledButton.styleFrom(
            backgroundColor: latar,
            foregroundColor: depan,
            disabledBackgroundColor: c.surfaceAlt,
            disabledForegroundColor: c.muted,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.pill),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 20),
          ),
          child: AnimatedSwitcher(
            duration: kurangi
                ? Duration.zero
                : const Duration(milliseconds: 160),
            child: memuat
                ? SizedBox(
                    key: const ValueKey<String>('memuat'),
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: depan,
                    ),
                  )
                : Row(
                    key: ValueKey<String>(label),
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (ikon != null) ...[
                        Icon(ikon, size: 20, color: depan),
                        const SizedBox(width: 8),
                      ],
                      Flexible(
                        child: Text(
                          label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: ukuranTeks,
                            fontWeight: FontWeight.w600,
                            color: depan,
                          ),
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}

class TombolSekunder extends StatelessWidget {
  const TombolSekunder({
    super.key,
    required this.label,
    required this.onPressed,
    this.ikon,
    this.tinggi = 52,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? ikon;
  final double tinggi;

  @override
  Widget build(BuildContext context) {
    final c = context.warna;
    final gelap = context.modeGelap;
    final warnaGaris = gelap ? const Color(0xFF3A3A3A) : c.line;
    return SentuhanSkala(
      aktif: onPressed != null,
      child: SizedBox(
        width: double.infinity,
        height: tinggi,
        child: OutlinedButton(
          onPressed: onPressed,
          style: OutlinedButton.styleFrom(
            foregroundColor: c.ink,
            side: BorderSide(color: warnaGaris),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.pill),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 20),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (ikon != null) ...[
                Icon(ikon, size: 20, color: c.ink),
                const SizedBox(width: 8),
              ],
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: c.ink,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class TombolLingkaran extends StatelessWidget {
  const TombolLingkaran({
    super.key,
    this.ikon,
    this.ikonGaris,
    this.simbol,
    required this.onPressed,
    this.label,
    this.ukuran = 44,
    this.ukuranSimbol = 20,
    this.latar,
    this.depan,
  });

  final IconData? ikon;
  final JenisIkon? ikonGaris;
  final String? simbol;
  final VoidCallback? onPressed;
  final String? label;
  final double ukuran;
  final double ukuranSimbol;
  final Color? latar;
  final Color? depan;

  @override
  Widget build(BuildContext context) {
    final c = context.warna;
    final warnaDepan = depan ?? c.ink;
    Widget isi;
    if (simbol != null) {
      isi = Text(
        simbol!,
        style: TextStyle(
          fontFamily: 'Poppins',
          fontSize: ukuranSimbol,
          fontWeight: FontWeight.w400,
          height: 1,
          color: warnaDepan,
        ),
      );
    } else if (ikonGaris != null) {
      isi = IkonGaris(ikonGaris!, ukuran: 22, warna: warnaDepan);
    } else {
      isi = Icon(
        ikon ?? Icons.circle,
        size: ukuran * 0.48,
        color: warnaDepan,
      );
    }

    return Semantics(
      button: true,
      label: label,
      excludeSemantics: label != null,
      child: SentuhanSkala(
        aktif: onPressed != null,
        skalaTekan: 0.93,
        child: SizedBox(
          width: ukuran,
          height: ukuran,
          child: Material(
            color: latar ?? c.surfaceAlt,
            shape: const CircleBorder(),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: onPressed,
              child: Center(child: isi),
            ),
          ),
        ),
      ),
    );
  }
}
