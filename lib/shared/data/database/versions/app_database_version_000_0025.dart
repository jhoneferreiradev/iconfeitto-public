import 'package:material_ui/material_ui.dart';
import 'package:sqflite/sqflite.dart';

import 'app_database_version.dart';
import 'mixin_app_database_version.dart';

class AppDatabaseVersion_000_0025 implements AppDatabaseVersion {
  @override
  int get versao => 25;

  @override
  String get descricao => 'Adição da coluna quantidadeMinimaEstoque ao produto';

  @override
  Future<void> aplicarMigracao(
    Database db,
    int oldVersion,
    int newVersion,
  ) async {
    if (oldVersion < versao) {
      debugPrint('Aplicando migração para a versão $versao: $descricao');

      await MixinAppDatabaseVersion.adicionarColunaSeNecessario(
        db,
        'produtos',
        'quantidadeMinimaEstoque',
        'REAL NOT NULL DEFAULT 0',
      );
    }
  }
}
