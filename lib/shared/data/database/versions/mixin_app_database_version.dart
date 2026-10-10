import 'package:sqflite/sqflite.dart';

import 'app_database_version.dart';
import 'app_database_version_000_0023.dart';
import 'app_database_version_000_0024.dart';
import 'app_database_version_000_0025.dart';

mixin MixinAppDatabaseVersion {
  List<AppDatabaseVersion> get versions {
    _versions.sort((a, b) => a.versao.compareTo(b.versao));
    return _versions;
  }

  final List<AppDatabaseVersion> _versions = [
    AppDatabaseVersion_000_0023(),
    AppDatabaseVersion_000_0024(),
    AppDatabaseVersion_000_0025(),
  ];

  static Future<void> adicionarColunaSeNecessario(
    Database db,
    String tabela,
    String coluna,
    String definicao,
  ) async {
    final colunas = await db.rawQuery('PRAGMA table_info($tabela)');
    if (colunas.any((c) => c['name'] == coluna)) return;
    await db.execute('ALTER TABLE $tabela ADD COLUMN $coluna $definicao');
  }
}
