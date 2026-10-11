import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

import 'versions/app_database_version.dart';
import 'versions/mixin_app_database_version.dart';

/// Acesso ao banco SQLite do app (conexão única).
///
/// A estrutura do banco é versionada: o esquema de um banco novo vem da versão
/// inicial e os bancos antigos são atualizados pelas migrações registradas em
/// [MixinAppDatabaseVersion].
class AppDatabase with MixinAppDatabaseVersion {
  static final AppDatabase _instance = AppDatabase._internal();
  static Future<Database>? _abertura;

  static const _nomeDoArquivo = 'iconfeitto.db';

  factory AppDatabase() => _instance;

  AppDatabase._internal();

  /// Abre o banco na primeira chamada; chamadas simultâneas aguardam a mesma
  /// abertura (evita abrir e migrar duas vezes).
  Future<Database> get database => _abertura ??= _abrir();

  Future<Database> _abrir() async {
    final caminho = join(await getDatabasesPath(), _nomeDoArquivo);
    return openDatabase(
      caminho,
      version: versaoAtual,
      onCreate: _aoCriar,
      onUpgrade: _aoAtualizar,
    );
  }

  /// Banco novo: cria direto o esquema mais recente. As migrações só servem
  /// para bancos que já existiam em versões anteriores.
  Future<void> _aoCriar(Database db, int version) =>
      AppDatabaseVersion_000_0001().aplicarMigracao(db, 0, 0);

  Future<void> _aoAtualizar(Database db, int oldVersion, int newVersion) async {
    for (final versao in versions) {
      await versao.aplicarMigracao(db, oldVersion, newVersion);
    }
  }

  Future<void> close() async {
    final abertura = _abertura;
    _abertura = null;
    await (await abertura)?.close();
  }
}
