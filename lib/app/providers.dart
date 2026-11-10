import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/formatter.dart';
import '../data/db.dart';
import '../data/repositori.dart';
import '../domain/model.dart';
import '../domain/rekap.dart';
import '../services/deteksi_service.dart';
import '../services/inferensi_service.dart';
import '../services/widget_layar_utama_service.dart';

final databaseProvider = FutureProvider<AppDatabase>((ref) {
  return AppDatabase.buka();
});

final repositoriProvider = FutureProvider<Repositori>((ref) async {
  final basisData = await ref.watch(databaseProvider.future);
  return Repositori(basisData);
});

final pengaturanProvider = FutureProvider<Pengaturan>((ref) async {
  final repositori = await ref.watch(repositoriProvider.future);
  return repositori.pengaturan.ambil();
});

final kelasProvider = FutureProvider<List<KelasMakanan>>((ref) async {
  final repositori = await ref.watch(repositoriProvider.future);
  return repositori.kelas.semua();
});

final entriHariProvider = FutureProvider.family<List<EntriLog>, String>((
  ref,
  tanggal,
) async {
  final repositori = await ref.watch(repositoriProvider.future);
  return repositori.log.perTanggal(tanggal);
});

final rekapHariProvider = FutureProvider.family<RekapHarian, String>((
  ref,
  tanggal,
) async {
  final repositori = await ref.watch(repositoriProvider.future);
  return repositori.log.rekap(tanggal);
});

final rekapRentangProvider = FutureProvider.family<List<TitikHarian>, int>((
  ref,
  jumlahHari,
) async {
  final repositori = await ref.watch(repositoriProvider.future);
  final akhir = tanggalSaja(DateTime.now());
  final mulai = geserHari(akhir, -(jumlahHari - 1));
  final data = await repositori.log.rekapRentang(mulai, akhir);
  return lengkapiRentang(data: data, akhir: akhir, jumlahHari: jumlahHari);
});

final entriRentangProvider = FutureProvider.family<List<EntriLog>, int>((
  ref,
  jumlahHari,
) async {
  final repositori = await ref.watch(repositoriProvider.future);
  final akhir = tanggalSaja(DateTime.now());
  final mulai = geserHari(akhir, -(jumlahHari - 1));
  return repositori.log.rentang(mulai, akhir);
});

final tanggalTercatatProvider = FutureProvider<List<String>>((ref) async {
  final repositori = await ref.watch(repositoriProvider.future);
  return repositori.log.tanggalTercatat();
});

final inferensiProvider = Provider<InferensiService>((ref) {
  return InferensiService();
});

final deteksiProvider = Provider<DeteksiService>((ref) {
  return DeteksiService();
});

void segarkanCatatan(WidgetRef ref) {
  ref.invalidate(entriHariProvider);
  ref.invalidate(rekapHariProvider);
  ref.invalidate(rekapRentangProvider);
  ref.invalidate(entriRentangProvider);
  ref.invalidate(tanggalTercatatProvider);
  unawaited(sinkronkanWidgetLayarUtama(ref));
}

Future<void> sinkronkanWidgetLayarUtama(WidgetRef ref) async {
  try {
    final repositori = await ref.read(repositoriProvider.future);
    final hariIni = tanggalHariIni();
    final rekap = await repositori.log.rekap(hariIni);
    final pengaturan = await repositori.pengaturan.ambil();
    await WidgetLayarUtamaService.perbarui(
      kalori: rekap.kalori,
      target: pengaturan.targetKalori,
      tanggal: hariIni,
    );
  } catch (_) {
    return;
  }
}
