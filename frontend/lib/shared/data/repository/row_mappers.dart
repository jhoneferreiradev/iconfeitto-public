import '../../models/grupo_unidade.dart';
import '../../models/operacao.dart';
import '../../models/produto.dart';
import '../../models/unidade_medida.dart';

// Conversões entre modelos e linhas do banco (funções puras, sem estado).

Map<String, dynamic> movimentoParaLinha(MovimentoEstoque movimento) => {
  'id': movimento.id,
  'operacaoId': movimento.operacaoId,
  'data': movimento.data.toIso8601String(),
  'produtoId': movimento.produtoId,
  'tipo': movimento.tipo.name,
  'quantidade': movimento.quantidade,
  'valorUnitario': movimento.valorUnitario,
  'unidadeId': movimento.unidadeId,
};

Map<String, dynamic> produtoParaLinha(Produto produto) => {
  'id': produto.id,
  'nome': produto.nome,
  'ativo': produto.ativo ? 1 : 0,
  'custoMedio': produto.custoMedio,
  'saldoEstoque': produto.saldoEstoque,
  'tipo': produto.tipo.name,
  'possuiFichaTecnica': produto.possuiFichaTecnica ? 1 : 0,
  'tempoPreparoMinutos': produto.tempoPreparoMinutos,
  'unidadeEstoqueId': produto.unidadeEstoqueId,
  'unidadeConsumoId': produto.unidadeConsumoId,
  'rendimentoReceita': produto.rendimentoReceita,
  'custoOperacional': produto.custoOperacional,
  'precoVenda': produto.precoVenda,
  'quantidadeMinimaEstoque': produto.quantidadeMinimaEstoque,
};

UnidadeMedida unidadeDeLinha(Map<String, dynamic> row) => UnidadeMedida(
  id: idString(row['id']),
  nome: row['nome'] as String,
  sigla: row['sigla'] as String,
  grupo: grupoUnidadeDeTexto(row['grupo'] as String),
  fatorParaBase: row['fatorParaBase'] as double,
);

GrupoUnidade grupoUnidadeDeTexto(String s) {
  return GrupoUnidade.values.firstWhere(
    (grupo) => grupo.name == s || s.endsWith('.${grupo.name}'),
    orElse: () => GrupoUnidade.unidade,
  );
}

TipoMovimentoEstoque tipoMovimentoDeTexto(String s) {
  return TipoMovimentoEstoque.values.firstWhere(
    (tipo) => tipo.name == s || s.endsWith('.${tipo.name}'),
    orElse: () => TipoMovimentoEstoque.ajuste,
  );
}

T enumPorNome<T extends Enum>(List<T> valores, Object? nome, T padrao) {
  for (final valor in valores) {
    if (valor.name == nome) return valor;
  }
  return padrao;
}

String idString(Object? value) => value.toString();
