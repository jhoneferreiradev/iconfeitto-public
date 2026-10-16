import 'package:material_ui/material_ui.dart';

import '../../../core/pdf/pdf_padrao.dart';
import '../../../core/pdf/pdf_relatorio.dart';
import '../../../core/utils/formatters.dart';
import '../../../shared/data/app_repository.dart';
import '../../../shared/models/operacao.dart';

/// Comprovante da venda, com custo e lucro/prejuízo, no padrão de impressão
/// do app.
class VendaPdf {
  static Future<void> visualizar(BuildContext context, Venda venda) =>
      relatorio(venda).visualizar(context);

  static PdfRelatorio relatorio(Venda venda) {
    final repo = AppRepository.instance;
    final cliente =
        repo.clientePorId(venda.clienteId)?.nome ?? 'Cliente removido';
    final titulo = 'Venda - $cliente';

    var totalVenda = 0.0;
    var totalCusto = 0.0;
    final linhas = <List<String>>[];
    for (final item in venda.itens) {
      final produto = repo.produtoPorId(item.produtoId);
      final unidade = repo.unidadePorId(item.unidadeId);
      final custoUnitario = produto == null
          ? 0.0
          : repo.custoPorUnidadeBase(produto) * unidade.fatorParaBase;
      final subtotal = item.quantidade * item.valorUnitario;
      totalVenda += subtotal;
      totalCusto += custoUnitario * item.quantidade;
      linhas.add([
        produto?.nome ?? 'Produto removido',
        formatarNumero(item.quantidade),
        unidade.sigla,
        item.valorUnitario.toCurrency(),
        custoUnitario.toCurrency(),
        subtotal.toCurrency(),
      ]);
    }
    final lucro = totalVenda - totalCusto;

    return PdfRelatorio(
      titulo: titulo,
      gerar: (_) => PdfPadrao.gerar(
        empresa: repo.empresa,
        tituloDocumento: titulo,
        referencia: cliente,
        titulo: PdfPadrao.titulo(
          sobretitulo: 'Registro de venda',
          titulo: 'Venda',
          destaques: [
            (rotulo: 'Cliente', valor: cliente),
            (rotulo: 'Situação', valor: venda.status.label),
            (rotulo: 'Pedido', valor: venda.data.toFormattedDate()),
            if (venda.dataEntrega != null)
              (
                rotulo: 'Entrega prevista',
                valor: venda.dataEntrega!.toFormattedDate(),
              ),
            if (venda.dataEntregue != null)
              (
                rotulo: 'Entregue em',
                valor: venda.dataEntregue!.toFormattedDate(),
              ),
          ],
        ),
        conteudo: (_) => [
          PdfPadrao.tabela(
            colunas: const [
              'Produto',
              'Qtd.',
              'Unid.',
              'Vl. unitário',
              'Custo unit.',
              'Subtotal',
            ],
            larguras: const [4, 1.2, 1, 1.6, 1.6, 1.6],
            alinhadasADireita: const {1, 3, 4, 5},
            linhas: linhas,
          ),
          PdfPadrao.espaco(14),
          PdfPadrao.caixaTotal(
            rotulo: 'Total da venda',
            valor: totalVenda.toCurrency(),
            detalhes: [
              PdfDetalheTotal('Total de custo', totalCusto.toCurrency()),
              PdfDetalheTotal(
                lucro >= 0 ? 'Lucro' : 'Prejuízo',
                lucro.toCurrency(),
                cor: lucro >= 0 ? PdfCores.positivo : PdfCores.negativo,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
