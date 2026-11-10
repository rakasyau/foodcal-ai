import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../../app/router.dart';
import '../hasil/memproses_page.dart';

Future<void> ambilDariGaleri(BuildContext context) async {
  final pemilih = ImagePicker();
  final berkas = await pemilih.pickImage(
    source: ImageSource.gallery,
    maxWidth: 1800,
    imageQuality: 92,
  );
  if (berkas == null) return;
  final bytes = await berkas.readAsBytes();
  await _hapusSalinanSementara(berkas.path);
  if (!context.mounted) return;
  await Rute.ganti(context, MemprosesPage(foto: bytes, sumberFoto: 'galeri'));
}

Future<void> _hapusSalinanSementara(String jalur) async {
  try {
    final normal = p.normalize(jalur);
    final folder = <Directory>[
      await getTemporaryDirectory(),
      await getApplicationCacheDirectory(),
    ];
    final diPenyimpananAplikasi = folder.any(
      (item) => p.isWithin(item.path, normal),
    );
    if (diPenyimpananAplikasi) {
      final berkas = File(normal);
      if (await berkas.exists()) {
        await berkas.delete();
      }
    }
  } catch (_) {
    return;
  }
}
