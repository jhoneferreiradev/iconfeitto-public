import 'package:sqflite/sqflite.dart';

/// Operações de esquema reutilizadas pelas migrações. Todas são idempotentes:
/// podem rodar de novo sem erro se a alteração já tiver sido feita.
class DatabaseHelpers {
  DatabaseHelpers._();

  static Future<bool> colunaExiste(
    Database db,
    String tabela,
    String coluna,
  ) async {
    final colunas = await db.rawQuery('PRAGMA table_info($tabela)');
    return colunas.any((c) => c['name'] == coluna);
  }

  static Future<void> adicionarColunaSeNecessario(
    Database db,
    String tabela,
    String coluna,
    String definicao,
  ) async {
    if (await colunaExiste(db, tabela, coluna)) return;
    await db.execute('ALTER TABLE $tabela ADD COLUMN $coluna $definicao');
  }

  /// Remove a coluna se ela existir. `DROP COLUMN` exige SQLite 3.35 ou mais
  /// novo (em aparelhos Android antigos o SQLite do sistema pode ser mais velho).
  static Future<void> removerColunaSeExistir(
    Database db,
    String tabela,
    String coluna,
  ) async {
    if (!await colunaExiste(db, tabela, coluna)) return;
    await db.execute('ALTER TABLE $tabela DROP COLUMN $coluna');
  }
}
