import 'package:flutter/material.dart';

import '../app/theme.dart';
import 'ikon_svg.dart';
import 'tombol.dart';

class KeadaanKosong extends StatelessWidget {
  const KeadaanKosong({
    super.key,
    required this.judul,
    required this.pesan,
    required this.labelTombol,
    required this.onPressed,
    this.ikon = Icons.photo_camera_outlined,
    this.jarakAtas = 48,
    this.ringkas = false,
  });

  final String judul;
  final String pesan;
  final String labelTombol;
  final VoidCallback onPressed;
  final IconData ikon;
  final double jarakAtas;
  final bool ringkas;

  @override
  Widget build(BuildContext context) {
    final c = context.warna;
    return Padding(
      padding: EdgeInsets.only(top: jarakAtas, bottom: ringkas ? 12 : 20),
      child: Column(
        children: [
          IlustrasiPiringKosong(
            warnaUtama: const Color(0xFF8A8A8A),
            warnaGaris: c.line,
            lebar: ringkas ? 122 : 150,
            tinggi: ringkas ? 86 : 110,
          ),
          SizedBox(height: ringkas ? 10 : 18),
          Text(
            judul,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: ringkas ? 16 : 18,
              fontWeight: FontWeight.w600,
              color: c.ink,
            ),
          ),
          SizedBox(height: ringkas ? 4 : 6),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              pesan,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: ringkas ? 13 : 14,
                height: 1.45,
                color: c.inkSoft,
              ),
            ),
          ),
          SizedBox(height: ringkas ? 14 : 22),
          SizedBox(
            width: ringkas ? 188 : 200,
            child: TombolUtama(
              label: labelTombol,
              tinggi: ringkas ? 48 : 56,
              ukuranTeks: ringkas ? 14 : 15,
              onPressed: onPressed,
            ),
          ),
        ],
      ),
    );
  }
}
