import 'db.dart';
import 'kelas_dao.dart';
import 'log_dao.dart';
import 'pengaturan_dao.dart';

class Repositori {
  Repositori(this.basisData)
    : kelas = KelasDao(basisData.db),
      log = LogDao(basisData.db),
      pengaturan = PengaturanDao(basisData.db);

  final AppDatabase basisData;
  final KelasDao kelas;
  final LogDao log;
  final PengaturanDao pengaturan;
}
