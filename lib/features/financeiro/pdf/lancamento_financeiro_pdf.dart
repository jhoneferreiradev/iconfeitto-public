import 'package:material_ui/material_ui.dart';

import '../../../core/pdf/pdf_padrao.dart';
import '../../../core/pdf/pdf_relatorio.dart';
import '../../../core/utils/formatters.dart';
import '../../../shared/data/app_repository.dart';
import '../../../shared/models/lancamento_financeiro.dart';

/// Comprovante de um lançamento financeiro (valores e quitações) no padrão de
/// impressão do app.
class LancamentoFinanceiroPdf {
  static Future<void> visualizar(
    BuildContext context,
    LancamentoFinanceiro lancamento,
  ) => relatorio(lancamento).visualizar(context);

  static PdfRelatorio relatorio(LancamentoFinanceiro lancamento) {
    final repo = AppRepository.instance;
    final titulo = '${lancamento.tipoLancamento.label} - ${lancamento.descricao}';
    final pessoa = lancamento.pessoaFinanceiro;

    return PdfRelatorio(
      titulo: titulo,
      gerar: (_) => PdfPadrao.gerar(
        empresa: repo.empresa,
        tituloDocumento: titulo,
        referencia: pessoa.nome,
        titulo: PdfPadrao.titulo(
          sobretitulo: 'Lançamento financeiro',
          titulo: lancamento.descricao,
          destaques: [
            (rotulo: 'Tipo', valor: lancamento.tipoLancamento.label),
            (rotulo: pessoa.tipoPessoaFinanceiro.label, valor: pessoa.nome),
            (rotulo: 'Situação', valor: lancamento.statusLancamento.label),
            (
              rotulo: 'Vencimento',
              valor: lancamento.dataVencimento.toFormattedDate(),
            ),
            if (lancamento.isReceita && lancamento.dataCompensacao != null)
              (
                rotulo: 'Compensação',
                valor: lancamento.dataCompensacao!.toFormattedDate(),
              ),
            if (lancamento.formaPagamento != null)
              (rotulo: 'Forma', valor: lancamento.formaPagamento!.label),
          ],
        ),
        conteudo: (_) => [
          PdfPadrao.secao('Valores'),
          PdfPadrao.tabela(
            colunas: const ['Descrição', 'Valor'],
            larguras: const [4, 2],
            alinhadasADireita: const {1},
            linhas: [
              ['Valor do lançamento', lancamento.valorLancamento.toCurrency()],
              if (lancamento.valorDesconto > 0)
                ['(-) Desconto', lancamento.valorDesconto.toCurrency()],
              if (lancamento.valorAcrescimo > 0)
                ['(+) Acréscimo', lancamento.valorAcrescimo.toCurrency()],
              if (lancamento.valorTaxasImpostos > 0)
                [
                  lancamento.isReceita
                      ? '(-) Taxas e impostos'
                      : '(+) Taxas e impostos',
                  lancamento.valorTaxasImpostos.toCurrency(),
                ],
            ],
          ),
          PdfPadrao.espaco(14),
          PdfPadrao.caixaTotal(
            rotulo: lancamento.isReceita ? 'Total a receber' : 'Total a pagar',
            valor: lancamento.valorTotal.toCurrency(),
            detalhes: [
              PdfDetalheTotal(
                lancamento.isReceita ? 'Recebido' : 'Pago',
                lancamento.valorQuitado.toCurrency(),
              ),
              PdfDetalheTotal(
                'Saldo em aberto',
                lancamento.valorRestante.toCurrency(),
                cor: lancamento.valorRestante > 0.005
                    ? PdfCores.negativo
                    : PdfCores.positivo,
              ),
            ],
          ),
          if (lancamento.hasQuitacoes) ...[
            PdfPadrao.espaco(18),
            PdfPadrao.secao('Quitações'),
            PdfPadrao.tabela(
              colunas: const ['Data', 'Forma de pagamento', 'Valor'],
              larguras: const [2, 3, 2],
              alinhadasADireita: const {2},
              linhas: [
                for (final quitacao in lancamento.quitacoesOrdenadas)
                  [
                    quitacao.dataQuitacao.toFormattedDate(),
                    quitacao.formaPagamento.label,
                    quitacao.valorQuitado.toCurrency(),
                  ],
              ],
            ),
          ],
        ],
      ),
    );
  }
}
