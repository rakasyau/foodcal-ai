import 'package:flutter/material.dart';

import '../app/theme.dart';
import 'ikon_svg.dart';
import 'tombol.dart';

class NavPill extends StatelessWidget {
  const NavPill({
    super.key,
    required this.indeks,
    required this.onChanged,
    required this.onKamera,
  });

  final int indeks;
  final ValueChanged<int> onChanged;
  final VoidCallback onKamera;

  static const _tab = <({JenisIkon ikon, String label})>[
    (ikon: JenisIkon.beranda, label: 'Beranda'),
    (ikon: JenisIkon.grafik, label: 'Catatan'),
    (ikon: JenisIkon.profil, label: 'Profil'),
  ];

  @override
  Widget build(BuildContext context) {
    final c = context.warna;
    final gelap = context.modeGelap;
    final kurangi = context.kurangiGerak;
    final latarNav = gelap ? const Color(0xFF1A1A1A) : const Color(0xFF111111);
    final latarFab = gelap ? const Color(0xFFFFFFFF) : const Color(0xFF111111);
    final depanFab = gelap ? const Color(0xFF111111) : const Color(0xFFFFFFFF);
    final durasiTema = kurangi
        ? Duration.zero
        : const Duration(milliseconds: 220);

    return Stack(
      alignment: Alignment.bottomCenter,
      children: [
        Positioned.fill(
          child: IgnorePointer(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  stops: const [0.0, 0.48, 1.0],
                  colors: [
                    c.bg.withValues(alpha: 0.0),
                    c.bg.withValues(alpha: 0.88),
                    c.bg,
                  ],
                ),
              ),
            ),
          ),
        ),
        SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                  child: AnimatedContainer(
                    duration: durasiTema,
                    curve: Curves.easeOutCubic,
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: latarNav,
                      borderRadius: BorderRadius.circular(AppRadius.pill),
                      border: Border.all(
                        color: gelap
                            ? const Color(0xFF2E2E2E)
                            : Colors.transparent,
                      ),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x18000000),
                          blurRadius: 24,
                          offset: Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        for (var i = 0; i < _tab.length; i++) ...[
                          if (i > 0) const SizedBox(width: 4),
                          if (i == indeks)
                            Flexible(
                              child: _ItemTab(
                                ikon: _tab[i].ikon,
                                label: _tab[i].label,
                                aktif: true,
                                warnaAktifLatar: const Color(0xFFFFFFFF),
                                onTap: () => onChanged(i),
                              ),
                            )
                          else
                            _ItemTab(
                              ikon: _tab[i].ikon,
                              label: _tab[i].label,
                              aktif: false,
                              warnaAktifLatar: const Color(0xFFFFFFFF),
                              onTap: () => onChanged(i),
                            ),
                        ],
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Semantics(
                  button: true,
                  label: 'Buka kamera',
                  child: SentuhanSkala(
                    aktif: !kurangi,
                    skalaTekan: 0.94,
                    child: AnimatedContainer(
                      duration: durasiTema,
                      curve: Curves.easeOutCubic,
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        color: latarFab,
                        shape: BoxShape.circle,
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x18000000),
                            blurRadius: 24,
                            offset: Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Material(
                        color: Colors.transparent,
                        shape: const CircleBorder(),
                        clipBehavior: Clip.antiAlias,
                        child: InkWell(
                          onTap: onKamera,
                          child: Center(
                            child: IkonGaris(
                              JenisIkon.kamera,
                              ukuran: 22,
                              warna: depanFab,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _ItemTab extends StatelessWidget {
  const _ItemTab({
    required this.ikon,
    required this.label,
    required this.aktif,
    required this.warnaAktifLatar,
    required this.onTap,
  });

  final JenisIkon ikon;
  final String label;
  final bool aktif;
  final Color warnaAktifLatar;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    const warnaTeksAktif = Color(0xFF111111);
    const warnaTeksPasif = Color(0xFFFFFFFF);
    final durasi = context.kurangiGerak
        ? Duration.zero
        : const Duration(milliseconds: 200);

    return Semantics(
      selected: aktif,
      button: true,
      label: label,
      child: AnimatedContainer(
        duration: durasi,
        curve: Curves.easeOutCubic,
        decoration: BoxDecoration(
          color: aktif ? warnaAktifLatar : Colors.transparent,
          borderRadius: BorderRadius.circular(AppRadius.pill),
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(AppRadius.pill),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(AppRadius.pill),
            child: AnimatedSize(
              duration: durasi,
              curve: Curves.easeOutCubic,
              child: Container(
                height: 46,
                width: aktif ? null : 44,
                padding: aktif
                    ? const EdgeInsets.symmetric(horizontal: 14)
                    : EdgeInsets.zero,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    TweenAnimationBuilder<Color?>(
                      tween: ColorTween(
                        end: aktif ? warnaTeksAktif : warnaTeksPasif,
                      ),
                      duration: durasi,
                      curve: Curves.easeOutCubic,
                      builder: (context, warnaIkon, _) => IkonGaris(
                        ikon,
                        ukuran: 20,
                        warna:
                            warnaIkon ??
                            (aktif ? warnaTeksAktif : warnaTeksPasif),
                      ),
                    ),
                    if (aktif) ...[
                      const SizedBox(width: 7),
                      Flexible(
                        child: Text(
                          label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: warnaTeksAktif,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
