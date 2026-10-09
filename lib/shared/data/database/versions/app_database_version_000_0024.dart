import 'package:material_ui/material_ui.dart';
import 'package:sqflite/sqflite.dart';

import 'app_database_version.dart';

class AppDatabaseVersion_000_0024 implements AppDatabaseVersion {
  @override
  int get versao => 24;

  @override
  String get descricao =>
      'Exclusão dos campos podeSerVendido e podeSerComprado do produto';

  @override
  Future<void> aplicarMigracao(
    Database db,
    int oldVersion,
    int newVersion,
  ) async {
    if (oldVersion < versao) {
      debugPrint('Aplicando migração para a versão $versao: $descricao');
      await db.execute('''
        ALTER TABLE produtos
        DROP COLUMN podeSerVendido
      ''');

      await db.execute('''
        ALTER TABLE produtos
        DROP COLUMN podeSerComprado
      ''');
    }
  }
}
