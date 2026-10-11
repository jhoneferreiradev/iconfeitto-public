import 'package:sqflite/sqflite.dart';

import 'app_database_helpers.dart';
import 'app_database_version_incremental.dart';

class AppDatabaseVersion_000_0025 extends VersaoIncremental {
  @override
  int get versao => 25;

  @override
  String get descricao => 'Adição da coluna quantidadeMinimaEstoque ao produto';

  @override
  Future<void> migrar(Database db) =>
      DatabaseHelpers.adicionarColunaSeNecessario(
        db,
        'produtos',
        'quantidadeMinimaEstoque',
        'REAL NOT NULL DEFAULT 0',
      );
}
