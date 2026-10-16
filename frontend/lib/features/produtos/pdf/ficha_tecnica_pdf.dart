import 'package:material_ui/material_ui.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../../core/pdf/pdf_padrao.dart';
import '../../../core/pdf/pdf_relatorio.dart';
import '../../../core/utils/formatters.dart';
import '../../../shared/data/app_repository.dart';
import '../../../shared/models/item_ficha_tecnica.dart';
import '../../../shared/models/produto.dart';
import '../../../shared/models/tipo_item.dart';

/// Ingrediente que possui ficha técnica própria, exibido como receita.
class _SubReceita {
  final Produto produto;

  /// Item da receita que o referencia (quantidade usada na receita pai).
  final ItemFichaTecnica usadoEm;

  const _SubReceita(this.produto, this.usadoEm);
}

/// Gera e imprime a ficha técnica de um produto: dados da empresa, resumo de
/// custos, embalagens, ingredientes e, para os ingredientes que também têm
/// ficha técnica, a receita de cada um em um bloco próprio.
class FichaTecnicaPdf {
  static Future<void> visualizar(BuildContext context, Produto produto) =>
      relatorio(produto).visualizar(context);

  static PdfRelatorio relatorio(Produto produto) {
    final repo = AppRepository.instance;
    final titulo = 'Ficha técnica - ${produto.nome}';

    return PdfRelatorio(
      titulo: titulo,
      gerar: (_) {
        final subReceitas = _coletarSubReceitas(repo, produto);
        final detalhados = {for (final s in subReceitas) s.produto.id};
        final custos = CalculadoraCustoProduto(
          rendimentoReceita: produto.rendimentoReceita,
          custoFichaTecnica: repo.custoTotalFicha(produto),
          custoOperacional: produto.custoOperacional,
          custoUnitarioEmbalagem: repo.custoEmbalagem(produto),
        );
        return PdfPadrao.gerar(
          empresa: repo.empresa,
          tituloDocumento: titulo,
          referencia: produto.nome,
          titulo: _tituloProduto(repo, produto),
          conteudo: (_) => [
            _secaoCustos(repo, produto, custos),
            PdfPadrao.espaco(22),
            _secaoEmbalagem(repo, produto),
            PdfPadrao.espaco(22),
            _secaoIngredientes(repo, produto, detalhados),
            if (subReceitas.isNotEmpty)
              ..._secaoSubReceitas(repo, subReceitas, detalhados),
          ],
        );
      },
    );
  }

  // ---------------------------------------------------------------------------
  // Dados
  // ---------------------------------------------------------------------------

  /// Percorre a ficha técnica em profundidade e devolve cada ingrediente que
  /// também possui ficha técnica (uma única vez, protegendo contra ciclos).
  static List<_SubReceita> _coletarSubReceitas(
    AppRepository repo,
    Produto raiz,
  ) {
    final resultado = <_SubReceita>[];
    final visitados = <String>{raiz.id};

    void visitar(Produto receita) {
      for (final item in receita.fichaTecnica) {
        final ingrediente = repo.produtoPorId(item.produtoIngredienteId);
        if (ingrediente == null || !_temFicha(ingrediente)) continue;
        if (!visitados.add(ingrediente.id)) continue;
        resultado.add(_SubReceita(ingrediente, item));
        visitar(ingrediente);
      }
    }

    visitar(raiz);
    return resultado;
  }

  static bool _temFicha(Produto p) =>
      TipoItem.tiposFichaTecnica.contains(p.tipo) &&
      p.possuiFichaTecnica &&
      p.fichaTecnica.isNotEmpty;


  static String _formatarTempo(int minutos) {
    if (minutos < 60) return '$minutos min';
    final horas = minutos ~/ 60;
    final resto = minutos % 60;
    return resto == 0 ? '$horas h' : '$horas h $resto min';
  }


  // ---------------------------------------------------------------------------
  // Estilos e peças básicas
  // ---------------------------------------------------------------------------


  static pw.Widget _celula(
    String texto, {
    double tamanho = 10,
    bool negrito = false,
    PdfColor? cor,
    pw.TextAlign alinhamento = pw.TextAlign.left,
  }) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      child: pw.Text(
        texto,
        textAlign: alinhamento,
        style: PdfPadrao.estilo(tamanho, negrito: negrito, cor: cor),
      ),
    );
  }

  static pw.BoxDecoration _decoracaoLinha(int indice) {
    return pw.BoxDecoration(
      color: indice.isOdd ? PdfCores.zebra : null,
      border: pw.Border(bottom: pw.BorderSide(color: PdfCores.linha, width: 0.5)),
    );
  }

  static pw.TableRow _cabecalhoTabela(
    List<String> titulos,
    List<pw.TextAlign> alinhamentos,
  ) {
    return pw.TableRow(
      repeat: true,
      decoration: pw.BoxDecoration(color: PdfCores.primaria),
      children: [
        for (var i = 0; i < titulos.length; i++)
          pw.Padding(
            padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 7),
            child: pw.Text(
              titulos[i].toUpperCase(),
              textAlign: alinhamentos[i],
              style: PdfPadrao.estilo(
                8,
                negrito: true,
                cor: PdfColors.white,
                espacamento: 0.6,
              ),
            ),
          ),
      ],
    );
  }

  static pw.TableRow _linhaTotal(String rotulo, double valor, int colunas) {
    return pw.TableRow(
      decoration: pw.BoxDecoration(
        color: PdfCores.primariaSuave,
        border: pw.Border(top: pw.BorderSide(color: PdfCores.primaria, width: 1)),
      ),
      children: [
        _celula(rotulo, negrito: true),
        for (var i = 0; i < colunas - 2; i++) _celula(''),
        _celula(
          valor.toCurrency(),
          negrito: true,
          alinhamento: pw.TextAlign.right,
        ),
      ],
    );
  }

  static pw.Widget _tituloSecao(String titulo, {String? apoio}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 8),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.center,
        children: [
          pw.Container(
            width: 4,
            height: 15,
            decoration: pw.BoxDecoration(
              color: PdfCores.primaria,
              borderRadius: pw.BorderRadius.circular(2),
            ),
          ),
          pw.SizedBox(width: 8),
          pw.Text(titulo, style: PdfPadrao.estilo(13, negrito: true)),
          if (apoio != null) ...[
            pw.Spacer(),
            pw.Text(apoio, style: PdfPadrao.estilo(8.5, cor: PdfCores.apagado)),
          ],
        ],
      ),
    );
  }

  static pw.Widget _selo(String texto) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 5, vertical: 2),
      decoration: pw.BoxDecoration(
        color: PdfCores.primariaSuave,
        borderRadius: pw.BorderRadius.circular(6),
      ),
      child: pw.Text(
        texto,
        style: PdfPadrao.estilo(
          7,
          negrito: true,
          cor: PdfCores.primaria,
          espacamento: 0.5,
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Cabeçalho e título
  // ---------------------------------------------------------------------------


  static pw.Widget _tituloProduto(AppRepository repo, Produto produto) {
    final sigla = repo.unidadePorId(produto.unidadeConsumoId).sigla;
    return PdfPadrao.titulo(
      sobretitulo: 'Ficha técnica',
      titulo: produto.nome,
      destaques: [
        if (produto.rendimentoReceita > 0)
          (rotulo: 'Rendimento', valor: '${produto.rendimentoReceita} $sigla'),
        if (produto.tempoPreparoMinutos > 0)
          (
            rotulo: 'Tempo de preparo',
            valor: _formatarTempo(produto.tempoPreparoMinutos),
          ),
        if (produto.podeSerVendido)
          (rotulo: 'Preço de venda', valor: produto.precoVenda.toCurrency()),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Seções
  // ---------------------------------------------------------------------------

  static pw.Widget _secaoCustos(
    AppRepository repo,
    Produto produto,
    CalculadoraCustoProduto custos,
  ) {
    final sigla = repo.unidadePorId(produto.unidadeConsumoId).sigla;
    final custoHora = repo.empresa.custoOperacionalPorHora;
    final detalheOperacional = produto.tempoPreparoMinutos > 0
        ? '${custoHora.toCurrency()}/hora · '
              '${_formatarTempo(produto.tempoPreparoMinutos)} de preparo'
        : '${custoHora.toCurrency()}/hora';

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.stretch,
      children: [
        _tituloSecao('Resumo de custos'),
        pw.Table(
          columnWidths: const {
            0: pw.FlexColumnWidth(5),
            1: pw.FlexColumnWidth(2),
          },
          defaultVerticalAlignment: pw.TableCellVerticalAlignment.middle,
          children: [
            _linhaCusto(
              'Itens da receita',
              'Soma do custo de todos os ingredientes',
              custos.custoFichaTecnica,
              indice: 0,
            ),
            _linhaCusto(
              'Custo operacional',
              detalheOperacional,
              custos.custoOperacional,
              indice: 1,
            ),
            _linhaCusto(
              'Embalagem total',
              'Soma das embalagens do produto rendido',
              custos.custoTotalEmbalagem,
              indice: 2,
            ),
            _linhaCusto(
              'Custo total da receita',
              null,
              custos.custoReceitaTotal,
              total: true,
            ),
            _linhaCusto(
              'Custo para produzir 1 $sigla',
              produto.rendimentoReceita > 0
                  ? 'Custo total dividido pelo rendimento'
                  : 'Rendimento não informado',
              custos.custoRendimentoUnitario,
              destaque: true,
            ),
          ],
        ),
      ],
    );
  }

  static pw.TableRow _linhaCusto(
    String titulo,
    String? detalhe,
    double valor, {
    int indice = 0,
    bool total = false,
    bool destaque = false,
  }) {
    final corTexto = destaque ? PdfColors.white : PdfCores.texto;
    final corDetalhe = destaque ? PdfCores.primariaSuave : PdfCores.apagado;

    final decoracao = destaque
        ? pw.BoxDecoration(color: PdfCores.primaria)
        : total
        ? pw.BoxDecoration(
            color: PdfCores.primariaSuave,
            border: pw.Border(
              top: pw.BorderSide(color: PdfCores.primaria, width: 1),
            ),
          )
        : _decoracaoLinha(indice);

    return pw.TableRow(
      decoration: decoracao,
      children: [
        pw.Padding(
          padding: pw.EdgeInsets.symmetric(
            horizontal: 10,
            vertical: destaque ? 11 : 7,
          ),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                titulo,
                style: PdfPadrao.estilo(
                  destaque ? 12 : 10,
                  negrito: total || destaque,
                  cor: corTexto,
                ),
              ),
              if (detalhe != null)
                pw.Padding(
                  padding: const pw.EdgeInsets.only(top: 1.5),
                  child: pw.Text(detalhe, style: PdfPadrao.estilo(8, cor: corDetalhe)),
                ),
            ],
          ),
        ),
        _celula(
          valor.toCurrency(),
          tamanho: destaque ? 15 : 10,
          negrito: total || destaque,
          cor: corTexto,
          alinhamento: pw.TextAlign.right,
        ),
      ],
    );
  }

  static pw.Widget _secaoEmbalagem(AppRepository repo, Produto produto) {
    final itens = produto.fichaTecnicaEmbalagem;

    final linhas = <pw.TableRow>[
      _cabecalhoTabela(
        ['Item de embalagem', 'Custo unitário'],
        [pw.TextAlign.left, pw.TextAlign.right],
      ),
      for (var i = 0; i < itens.length; i++)
        pw.TableRow(
          decoration: _decoracaoLinha(i),
          children: [
            _celula(
              repo.produtoPorId(itens[i].produtoEmbalagemId)?.nome ??
                  'Item removido',
            ),
            _celula(
              repo.custoItemFichaEmbalagem(itens[i]).toCurrency(),
              alinhamento: pw.TextAlign.right,
            ),
          ],
        ),
      if (itens.isNotEmpty)
        _linhaTotal('Total de embalagem', repo.custoEmbalagem(produto), 2),
    ];

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.stretch,
      children: [
        _tituloSecao('Embalagem'),
        if (itens.isEmpty)
          pw.Text(
            'Nenhum item de embalagem cadastrado.',
            style: PdfPadrao.estilo(9.5, cor: PdfCores.apagado),
          )
        else
          pw.Table(
            columnWidths: const {
              0: pw.FlexColumnWidth(5),
              1: pw.FlexColumnWidth(2),
            },
            defaultVerticalAlignment: pw.TableCellVerticalAlignment.middle,
            children: linhas,
          ),
      ],
    );
  }

  static pw.Widget _secaoIngredientes(
    AppRepository repo,
    Produto produto,
    Set<String> detalhados,
  ) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.stretch,
      children: [
        _tituloSecao(
          'Ingredientes',
          apoio: detalhados.isEmpty
              ? null
              : 'Itens marcados como receita estão detalhados abaixo',
        ),
        _tabelaItens(repo, produto, detalhados),
      ],
    );
  }

  static List<pw.Widget> _secaoSubReceitas(
    AppRepository repo,
    List<_SubReceita> subReceitas,
    Set<String> detalhados,
  ) {
    return [
      pw.SizedBox(height: 26),
      _tituloSecao(
        'Receitas dos preparos',
        apoio: 'Ingredientes que possuem ficha técnica própria',
      ),
      for (final sub in subReceitas) ...[
        _blocoSubReceita(repo, sub, detalhados),
        pw.SizedBox(height: 16),
      ],
    ];
  }

  static pw.Widget _blocoSubReceita(
    AppRepository repo,
    _SubReceita sub,
    Set<String> detalhados,
  ) {
    final receita = sub.produto;
    final unidadeUsada = repo.unidadePorId(sub.usadoEm.unidadeId);
    final siglaRendimento = repo.unidadePorId(receita.unidadeConsumoId).sigla;

    final meta = [
      if (receita.rendimentoReceita > 0)
        'Rende ${receita.rendimentoReceita} $siglaRendimento',
      if (receita.tempoPreparoMinutos > 0)
        _formatarTempo(receita.tempoPreparoMinutos),
    ].join('  ·  ');

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.stretch,
      children: [
        pw.Container(
          padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 9),
          decoration: pw.BoxDecoration(
            color: PdfCores.primariaSuave,
            border: pw.Border(
              left: pw.BorderSide(color: PdfCores.primaria, width: 3),
            ),
          ),
          child: pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.center,
            children: [
              pw.Expanded(
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(receita.nome, style: PdfPadrao.estilo(11.5, negrito: true)),
                    pw.SizedBox(height: 2),
                    pw.Text(
                      'Usado na receita: '
                      '${formatarNumero(sub.usadoEm.quantidade)} '
                      '${unidadeUsada.sigla}',
                      style: PdfPadrao.estilo(8.5, cor: PdfCores.apagado),
                    ),
                  ],
                ),
              ),
              if (meta.isNotEmpty)
                pw.Text(
                  meta,
                  style: PdfPadrao.estilo(9, cor: PdfCores.primaria, negrito: true),
                ),
            ],
          ),
        ),
        _tabelaItens(repo, receita, detalhados),
      ],
    );
  }

  /// Tabela de ingredientes de uma receita (principal ou preparo).
  static pw.Widget _tabelaItens(
    AppRepository repo,
    Produto receita,
    Set<String> detalhados,
  ) {
    final itens = receita.fichaTecnica;

    if (itens.isEmpty) {
      return pw.Padding(
        padding: const pw.EdgeInsets.symmetric(vertical: 6),
        child: pw.Text(
          'Nenhum ingrediente cadastrado.',
          style: PdfPadrao.estilo(9.5, cor: PdfCores.apagado),
        ),
      );
    }

    final linhas = <pw.TableRow>[
      _cabecalhoTabela(
        ['Ingrediente', 'Quantidade', 'Custo'],
        [pw.TextAlign.left, pw.TextAlign.right, pw.TextAlign.right],
      ),
      for (var i = 0; i < itens.length; i++)
        _linhaIngrediente(repo, itens[i], i, detalhados),
      _linhaTotal('Total dos itens', repo.custoTotalFicha(receita), 3),
    ];

    return pw.Table(
      columnWidths: const {
        0: pw.FlexColumnWidth(5),
        1: pw.FlexColumnWidth(2),
        2: pw.FlexColumnWidth(2),
      },
      defaultVerticalAlignment: pw.TableCellVerticalAlignment.middle,
      children: linhas,
    );
  }

  static pw.TableRow _linhaIngrediente(
    AppRepository repo,
    ItemFichaTecnica item,
    int indice,
    Set<String> detalhados,
  ) {
    final ingrediente = repo.produtoPorId(item.produtoIngredienteId);
    final unidade = repo.unidadePorId(item.unidadeId);
    final temReceita =
        ingrediente != null && detalhados.contains(ingrediente.id);

    return pw.TableRow(
      decoration: _decoracaoLinha(indice),
      children: [
        pw.Padding(
          padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 7),
          child: pw.Row(
            mainAxisSize: pw.MainAxisSize.min,
            children: [
              pw.Flexible(
                child: pw.Text(
                  ingrediente?.nome ?? 'Ingrediente removido',
                  style: PdfPadrao.estilo(10),
                ),
              ),
              if (temReceita) ...[pw.SizedBox(width: 6), _selo('RECEITA')],
            ],
          ),
        ),
        _celula(
          '${formatarNumero(item.quantidade)} ${unidade.sigla}',
          alinhamento: pw.TextAlign.right,
        ),
        _celula(
          repo.custoItemFicha(item).toCurrency(),
          alinhamento: pw.TextAlign.right,
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Rodapé
  // ---------------------------------------------------------------------------

}
