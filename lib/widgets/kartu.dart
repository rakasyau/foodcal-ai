import 'package:flutter/material.dart';

import '../app/theme.dart';

class KartuApp extends StatelessWidget {
  const KartuApp({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.warna,
    this.radius = AppRadius.besar,
    this.onTap,
    this.garis,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color? warna;
  final double radius;
  final VoidCallback? onTap;
  final Color? garis;

  @override
  Widget build(BuildContext context) {
    final c = context.warna;
    final isi = Padding(padding: padding, child: child);
    return Material(
      color: warna ?? c.surface,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(radius),
        side: BorderSide(
          color:
              garis ??
              (warna == null
                  ? c.line.withValues(alpha: 0.55)
                  : c.line.withValues(alpha: 0.15)),
        ),
      ),
      child: onTap == null ? isi : InkWell(onTap: onTap, child: isi),
    );
  }
}
