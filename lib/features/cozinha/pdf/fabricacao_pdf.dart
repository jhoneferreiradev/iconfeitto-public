import 'package:material_ui/material_ui.dart';

import '../../../core/pdf/pdf_padrao.dart';
import '../../../core/pdf/pdf_relatorio.dart';
import '../../../core/utils/formatters.dart';
import '../../../shared/data/app_repository.dart';
import '../../../shared/models/operacao.dart';

/// Registro da fabricação no padrão de impressão do app.
class FabricacaoPdf {
  static Future<void> visualizar(
    BuildContext context,
    Fabricacao fabricacao,
  ) => relatorio(fabricacao).visualizar(context);

  static PdfRelatorio relatorio(Fabricacao fabricacao) {
    final repo = AppRepository.instance;
    final produto = repo.produtoPorId(fabricacao.produtoId);
    final nomeProduto = produto?.nome ?? 'Produto removido';
    final unidadeProduto = produto == null
        ? null
        : repo.unidadePorId(produto.unidadeEstoqueId);
    final quantidade =
        formatarNumero(fabricacao.quantidade) +
        (unidadeProduto != null ? ' ${unidadeProduto.sigla}' : '');
    final titulo = 'Fabricação - $nomeProduto';

    return PdfRelatorio(
      titulo: titulo,
      gerar: (_) => PdfPadrao.gerar(
        empresa: repo.empresa,
        tituloDocumento: titulo,
        referencia: nomeProduto,
        titulo: PdfPadrao.titulo(
          sobretitulo: 'Registro de fabricação',
          titulo: nomeProduto,
          destaques: [
            (rotulo: 'Quantidade fabricada', valor: quantidade),
            (rotulo: 'Data', valor: fabricacao.data.toFormattedDate()),
          ],
        ),
        conteudo: (_) => [
          PdfPadrao.tabela(
            colunas: const ['Ingrediente', 'Qtd.', 'Unid.'],
            larguras: const [5, 1.5, 1.2],
            alinhadasADireita: const {1},
            linhas: [
              for (final item in fabricacao.fichaTecnica)
                [
                  repo.produtoPorId(item.produtoIngredienteId)?.nome ??
                      'Ingrediente removido',
                  formatarNumero(item.quantidade),
                  repo.unidadePorId(item.unidadeId).sigla,
                ],
            ],
          ),
        ],
      ),
    );
  }
}
