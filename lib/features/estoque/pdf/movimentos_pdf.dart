import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/pdf/pdf_padrao.dart';
import '../../../core/pdf/pdf_relatorio.dart';
import '../../../core/utils/formatters.dart';
import '../../../shared/data/app_repository.dart';
import '../../../shared/models/operacao.dart';
import '../../../shared/models/produto.dart';

/// Últimas movimentações de estoque de um produto, com o saldo resultante
/// depois de cada uma, no padrão de impressão do app.
class MovimentosPdf {
  static Future<void> visualizar(BuildContext context, Produto produto) =>
      relatorio(produto).visualizar(context);

  static PdfRelatorio relatorio(Produto produto) {
    final repo = AppRepository.instance;
    final unidadeProduto = repo.unidadePorId(produto.unidadeEstoqueId);
    final titulo = 'Movimentações - ${produto.nome}';
    final formatoData = DateFormat('dd/MM/yyyy HH:mm');

    return PdfRelatorio(
      titulo: titulo,
      gerar: (_) {
        // Calculado na hora de gerar, para refletir o estado atual.
        final passos = repo.ultimasMovimentacoes(produto.id);
        return PdfPadrao.gerar(
          empresa: repo.empresa,
          tituloDocumento: titulo,
          referencia: produto.nome,
          titulo: PdfPadrao.titulo(
            sobretitulo: 'Movimentações de estoque',
            titulo: produto.nome,
            destaques: [
              (
                rotulo: 'Saldo atual',
                valor:
                    '${formatarNumero(produto.saldoEstoque)} ${unidadeProduto.sigla}',
              ),
              (rotulo: 'Custo médio', valor: produto.custoMedio.toCurrency()),
            ],
          ),
          conteudo: (_) => [
            PdfPadrao.secao('Últimas movimentações', apoio: 'da mais recente'),
            PdfPadrao.tabela(
              colunas: const [
                'Data',
                'Tipo',
                'Sentido',
                'Qtd.',
                'Unid.',
                'Vl. unit.',
                'Saldo após',
              ],
              larguras: const [2.2, 2.4, 1.4, 1.3, 1, 1.6, 1.8],
              alinhadasADireita: const {3, 5, 6},
              linhas: [
                for (final passo in passos)
                  [
                    formatoData.format(passo.movimento.data),
                    passo.movimento.tipo.label,
                    _sentido(passo.movimento.tipo),
                    formatarNumero(passo.movimento.quantidade),
                    repo.unidadePorId(passo.movimento.unidadeId).sigla,
                    passo.movimento.valorUnitario.toCurrency(),
                    '${formatarNumero(passo.saldoApos)} ${unidadeProduto.sigla}',
                  ],
              ],
            ),
          ],
        );
      },
    );
  }

  static String _sentido(TipoMovimentoEstoque tipo) {
    if (tipo == TipoMovimentoEstoque.ajuste) return 'Define saldo';
    return tipo == TipoMovimentoEstoque.compra ||
            tipo == TipoMovimentoEstoque.producao
        ? 'Entrada'
        : 'Saída';
  }
}
