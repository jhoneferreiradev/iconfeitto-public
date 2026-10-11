import 'package:sqflite/sqflite.dart';

import 'app_database_helpers.dart';
import 'app_database_version_incremental.dart';

class AppDatabaseVersion_000_0023 extends VersaoIncremental {
  @override
  int get versao => 23;

  @override
  String get descricao => 'Exclusão do isEmbalagem do produto';

  @override
  Future<void> migrar(Database db) =>
      DatabaseHelpers.removerColunaSeExistir(db, 'produtos', 'isEmbalagem');
}
