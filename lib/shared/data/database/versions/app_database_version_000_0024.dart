import 'package:sqflite/sqflite.dart';

import 'app_database_helpers.dart';
import 'app_database_version_incremental.dart';

class AppDatabaseVersion_000_0024 extends VersaoIncremental {
  @override
  int get versao => 24;

  @override
  String get descricao =>
      'Exclusão dos campos podeSerVendido e podeSerComprado do produto';

  @override
  Future<void> migrar(Database db) async {
    await DatabaseHelpers.removerColunaSeExistir(
      db,
      'produtos',
      'podeSerVendido',
    );
    await DatabaseHelpers.removerColunaSeExistir(
      db,
      'produtos',
      'podeSerComprado',
    );
  }
}
