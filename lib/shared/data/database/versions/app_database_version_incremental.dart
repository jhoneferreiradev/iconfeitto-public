import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';

import 'app_database_version.dart';

/// Base das migrações que atualizam bancos antigos.
///
/// Cuida do que é igual em todas: só executa se o banco ainda não está nesta
/// versão e registra no log. Cada versão informa apenas o que muda em [migrar].
abstract class VersaoIncremental implements AppDatabaseVersion {
  @override
  Future<void> aplicarMigracao(
    Database db,
    int oldVersion,
    int newVersion,
  ) async {
    if (oldVersion >= versao) return;
    debugPrint('Aplicando migração para a versão $versao: $descricao');
    await migrar(db);
  }

  /// Alterações desta versão.
  Future<void> migrar(Database db);
}
