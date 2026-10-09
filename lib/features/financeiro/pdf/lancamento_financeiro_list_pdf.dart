import 'package:material_ui/material_ui.dart';

import '../../../core/pdf/pdf_padrao.dart';
import '../../../core/pdf/pdf_relatorio.dart';
import '../../../core/utils/formatters.dart';
import '../../../shared/data/app_repository.dart';
import '../../../shared/models/lancamento_financeiro.dart';

/// Lista de lançamentos financeiros no padrão de impressão do app.
class LancamentoFinanceiroListPdf {
  static Future<void> visualizar(
    BuildContext context,
    List<LancamentoFinanceiro> lancamentos, {
    required String titulo,
  }) => relatorio(lancamentos, titulo: titulo).visualizar(context);

  static PdfRelatorio relatorio(
    List<LancamentoFinanceiro> lancamentos, {
    required String titulo,
  }) {
    final repo = AppRepository.instance;
    final ordenados = [...lancamentos]
      ..sort((a, b) => a.dataVencimento.compareTo(b.dataVencimento));
    final totalValores = ordenados.fold<double>(0, (s, l) => s + l.valorTotal);
    final totalAberto = ordenados.fold<double>(
      0,
      (s, l) => s + (l.isEncerrado ? 0 : l.valorRestante),
    );

    return PdfRelatorio(
      titulo: titulo,
      gerar: (_) => PdfPadrao.gerar(
        empresa: repo.empresa,
        tituloDocumento: titulo,
        referencia: titulo,
        titulo: PdfPadrao.titulo(
          sobretitulo: 'Relatório financeiro',
          titulo: titulo,
          destaques: [(rotulo: 'Lançamentos', valor: '${ordenados.length}')],
        ),
        conteudo: (_) => [
          PdfPadrao.tabela(
            colunas: const [
              'Vencimento',
              'Descrição',
              'Pessoa',
              'Situação',
              'Total',
              'Em aberto',
            ],
            larguras: const [1.6, 3.4, 2.4, 1.8, 1.6, 1.6],
            alinhadasADireita: const {4, 5},
            linhas: [
              for (final item in ordenados)
                [
                  item.dataVencimento.toFormattedDate(),
                  item.descricao,
                  item.pessoaFinanceiro.nome,
                  item.statusLancamento.label,
                  item.valorTotal.toCurrency(),
                  (item.isEncerrado ? 0.0 : item.valorRestante).toCurrency(),
                ],
            ],
          ),
          PdfPadrao.espaco(14),
          PdfPadrao.caixaTotal(
            rotulo: 'Total dos lançamentos',
            valor: totalValores.toCurrency(),
            detalhes: [
              PdfDetalheTotal('Em aberto', totalAberto.toCurrency()),
            ],
          ),
        ],
      ),
    );
  }
}
