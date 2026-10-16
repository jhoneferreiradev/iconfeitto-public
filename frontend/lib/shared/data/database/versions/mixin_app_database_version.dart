import 'package:sqflite/sqflite.dart';

import 'app_database_helpers.dart';
import 'app_database_version.dart';
import 'app_database_version_000_0023.dart';
import 'app_database_version_000_0024.dart';
import 'app_database_version_000_0025.dart';

/// Registro das versões do banco.
///
/// Para criar uma nova versão:
/// 1. crie `app_database_version_000_00NN.dart` estendendo [VersaoIncremental];
/// 2. acrescente a classe em [_registro];
/// 3. atualize o esquema inicial (`AppDatabaseVersion_000_0001`) com a mesma
///    mudança, porque bancos novos são criados direto a partir dele.
mixin MixinAppDatabaseVersion {
  static final List<AppDatabaseVersion> _registro = List.unmodifiable(
    <AppDatabaseVersion>[
      AppDatabaseVersion_000_0023(),
      AppDatabaseVersion_000_0024(),
      AppDatabaseVersion_000_0025(),
    ]..sort((a, b) => a.versao.compareTo(b.versao)),
  );

  /// Migrações em ordem crescente de versão.
  List<AppDatabaseVersion> get versions => _registro;

  /// Versão do banco que o app espera (a da última migração).
  int get versaoAtual => _registro.last.versao;

  /// Mantido por compatibilidade; prefira [DatabaseHelpers].
  static Future<void> adicionarColunaSeNecessario(
    Database db,
    String tabela,
    String coluna,
    String definicao,
  ) => DatabaseHelpers.adicionarColunaSeNecessario(
    db,
    tabela,
    coluna,
    definicao,
  );
}
