import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/utils/formatters.dart';
import '../../../core/widgets/app_date_time_field.dart';
import '../../../core/widgets/app_input_decoration.dart';
import '../../../core/widgets/app_number_field.dart';
import '../../../core/widgets/form_builder_searchable_dropdown_field.dart';
import '../../../core/widgets/section_card.dart';
import '../../../shared/data/app_repository.dart';
import '../../../shared/models/cartao_credito.dart';
import '../../../shared/models/forma_pagamento.dart';
import '../../../shared/models/lancamento_financeiro.dart';
import '../../cartoes/widgets/cartao_dialogs.dart';

/// Área de pagamento compartilhada por compras (despesas) e vendas (receitas).
///
/// Gera um lançamento por parcela. O primeiro é o "pai" dos demais.
/// - Compra em cartão de crédito: a pessoa é o cartão (paga-se a fatura) e os
///   vencimentos seguem o dia de vencimento/fechamento dele.
/// - Venda em cartão (crédito ou débito): a pessoa é a bandeira, que aplica a
///   taxa nas parcelas.
/// - Demais formas: a pessoa é o fornecedor/cliente da operação.
///
/// O lançamento é o pagamento da operação; a quitação (feita no financeiro)
/// é o que encerra o fluxo.
class PagamentoOperacaoSection extends StatefulWidget {
  final GlobalKey<FormBuilderState> formKey;
  final TipoLancamentoFinanceiro tipo;
  final TipoOperacaoOrigem origem;
  final double Function() total;
  final DateTime Function() data;

  /// Lançamentos já gravados desta operação (vazio em operação nova).
  final List<LancamentoFinanceiro> existentes;

  /// Operação com quitação: nada pode ser alterado.
  final bool bloqueado;

  /// Edição de uma operação já salva. Se ela não tem lançamentos (criada antes
  /// do financeiro), a opção de lançar começa desligada.
  final bool editando;

  const PagamentoOperacaoSection({
    super.key,
    required this.formKey,
    required this.tipo,
    required this.origem,
    required this.total,
    required this.data,
    this.existentes = const [],
    this.bloqueado = false,
    this.editando = false,
  });

  @override
  State<PagamentoOperacaoSection> createState() =>
      PagamentoOperacaoSectionState();
}

class _ParcelaRascunho {
  final int id;
  final DateTime vencimento;
  final double valor;

  const _ParcelaRascunho({
    required this.id,
    required this.vencimento,
    required this.valor,
  });
}

class PagamentoOperacaoSectionState extends State<PagamentoOperacaoSection> {
  final _repo = AppRepository.instance;
  final _parcelas = <_ParcelaRascunho>[];
  int _proximaParcelaId = 0;
  bool _gerarFinanceiro = true;
  bool _parcelasEditadas = false;
  FormaPagamento _forma = FormaPagamento.dinheiro;
  int _numParcelas = 1;
  PessoaFinanceiro? _pessoaCartao;
  String _assinatura = '';

  bool get _ehVenda => widget.tipo == TipoLancamentoFinanceiro.receita;
  bool get _credito => _forma == FormaPagamento.cartaoCredito;

  /// Forma que exige escolher o cartão (compra) ou a bandeira (venda).
  bool _usaCartao(FormaPagamento forma) =>
      [
        FormaPagamento.cartaoCredito,
        FormaPagamento.cartaoDebito,
      ].contains(forma) ||
      (_ehVenda && forma == FormaPagamento.cartaoDebito);
  bool get gerarFinanceiro => _gerarFinanceiro;

  TipoPessoaFinanceiro get _tipoPessoaCartao => _ehVenda
      ? TipoPessoaFinanceiro.bandeiraCartaoCredito
      : TipoPessoaFinanceiro.cartaoCredito;

  @override
  void initState() {
    super.initState();
    if (widget.existentes.isEmpty) {
      // Operação nova: lança no financeiro por padrão. Em operações antigas
      // (sem lançamentos) o usuário precisa ligar a opção.
      _gerarFinanceiro = !widget.editando;
      if (_gerarFinanceiro) _regenerar();
      return;
    }
    final primeiro = widget.existentes.first;
    _forma =
        primeiro.formaPagamento ??
        (primeiro.pessoaFinanceiro.tipoPessoaFinanceiro == _tipoPessoaCartao
            ? FormaPagamento.cartaoCredito
            : FormaPagamento.dinheiro);
    if (primeiro.pessoaFinanceiro.tipoPessoaFinanceiro == _tipoPessoaCartao) {
      _pessoaCartao = primeiro.pessoaFinanceiro;
    }
    _numParcelas = widget.existentes.length;
    for (final lancamento in widget.existentes) {
      _parcelas.add(
        _ParcelaRascunho(
          id: _proximaParcelaId++,
          vencimento: lancamento.dataVencimento,
          valor: lancamento.valorLancamento,
        ),
      );
    }
    // Preserva o que já foi lançado até o usuário pedir para redistribuir.
    _parcelasEditadas = true;
  }

  // ---------------------------------------------------------------------------
  // Cálculo das parcelas
  // ---------------------------------------------------------------------------

  CartaoCredito? get _cartaoModelo =>
      _pessoaCartao == null ? null : _repo.cartaoPorId(_pessoaCartao!.id);

  BandeiraCartaoCredito? get _bandeiraModelo =>
      _pessoaCartao == null ? null : _repo.bandeiraPorId(_pessoaCartao!.id);

  DateTime _somenteData(DateTime data) =>
      DateTime(data.year, data.month, data.day);

  DateTime _somarMeses(DateTime base, int meses) =>
      CartaoCredito.diaNoMes(base.year, base.month + meses, base.day);

  DateTime _vencimento(DateTime data, int indice) {
    final base = _somenteData(data);
    if (_credito) {
      if (_ehVenda) return _somarMeses(base, indice + 1);
      final cartao = _cartaoModelo;
      if (cartao != null) return cartao.vencimentoDaParcela(base, indice);
    }
    return _somarMeses(base, indice);
  }

  int _centavos(double valor) => (valor * 100).round();

  /// Recalcula as parcelas a partir do total, da quantidade, da data e do
  /// cartão. A última parcela absorve a diferença de centavos.
  void _regenerar() {
    final quantidade = _numParcelas < 1 ? 1 : _numParcelas;
    final centavos = _centavos(widget.total());
    final base = centavos ~/ quantidade;
    final data = widget.data();
    _parcelas
      ..clear()
      ..addAll([
        for (var i = 0; i < quantidade; i++)
          _ParcelaRascunho(
            id: _proximaParcelaId++,
            vencimento: _vencimento(data, i),
            valor:
                (i == quantidade - 1
                    ? centavos - base * (quantidade - 1)
                    : base) /
                100,
          ),
      ]);
    _assinatura = _assinaturaAtual();
  }

  String _assinaturaAtual() =>
      '${_centavos(widget.total())}|${_somenteData(widget.data())}|'
      '${_forma.name}|${_pessoaCartao?.id}';

  /// Chamado pelo pai a cada mudança do formulário: redistribui as parcelas
  /// quando total, data, forma ou cartão mudam (se não houve edição manual).
  void sincronizar() {
    if (!_gerarFinanceiro || widget.bloqueado) return;
    final assinatura = _assinaturaAtual();
    if (assinatura == _assinatura) return;
    if (_parcelasEditadas) {
      _assinatura = assinatura;
      return;
    }
    _regenerar();
  }

  double _valorParcela(_ParcelaRascunho parcela) {
    final valores = widget.formKey.currentState?.instantValue;
    final campo = 'parcela_valor_${parcela.id}';
    if (valores == null || !valores.containsKey(campo)) return parcela.valor;
    return _numero(valores[campo]);
  }

  double _numero(dynamic valor) {
    if (valor is num) return valor.toDouble();
    if (valor is String) return valor.toDouble() ?? 0;
    return 0;
  }

  // ---------------------------------------------------------------------------
  // Montagem dos lançamentos
  // ---------------------------------------------------------------------------

  /// Gera um lançamento por parcela. Retorna null (após avisar) se os dados
  /// forem inconsistentes.
  List<LancamentoFinanceiro>? montarLancamentos({
    required String operacaoId,
    required DateTime data,
    required PessoaFinanceiro pessoaOperacao,
    required String descricaoBase,
    required Map<String, dynamic> valores,
    required double total,
    required void Function(String mensagem) avisar,
  }) {
    final forma = valores['forma_pagamento'] as FormaPagamento;
    final isCartaoCredito = forma == FormaPagamento.cartaoCredito;
    final usaCartao = _usaCartao(forma);
    final isOrigemVenda = widget.origem == TipoOperacaoOrigem.venda;
    final isOrigemCompra = widget.origem == TipoOperacaoOrigem.compra;
    final consideraCartaoComoPessoa =
        usaCartao && (isOrigemVenda || (isOrigemCompra && isCartaoCredito));
    final pessoa = consideraCartaoComoPessoa
        ? valores['cartao_credito'] as PessoaFinanceiro?
        : pessoaOperacao;
    if (pessoa == null) {
      avisar(_ehVenda ? 'Selecione a bandeira.' : 'Selecione o cartão.');
      return null;
    }

    final parcelas = [
      for (final parcela in _parcelas)
        (
          vencimento: valores['parcela_venc_${parcela.id}'] as DateTime,
          valor: _centavos(_numero(valores['parcela_valor_${parcela.id}'])),
        ),
    ];
    if (parcelas.isEmpty || parcelas.any((parcela) => parcela.valor <= 0)) {
      avisar('Informe um valor maior que zero em todas as parcelas.');
      return null;
    }
    final somaCentavos = parcelas.fold<int>(0, (soma, p) => soma + p.valor);
    if (somaCentavos != _centavos(total)) {
      avisar(
        'A soma das parcelas (${(somaCentavos / 100).toCurrency()}) difere do '
        'total (${total.toCurrency()}).',
      );
      return null;
    }

    final bandeira = _ehVenda && usaCartao
        ? _repo.bandeiraPorId(pessoa.id)
        : null;
    final lancamentos = <LancamentoFinanceiro>[];
    LancamentoFinanceiro? pai;
    for (var i = 0; i < parcelas.length; i++) {
      final valor = parcelas[i].valor / 100;
      final lancamento = LancamentoFinanceiro(
        id: _repo.novoId(),
        pessoaFinanceiro: pessoa,
        tipoLancamento: widget.tipo,
        lancamentoPai: pai,
        statusLancamento: StatusLancamentoFinanceiro.pendente,
        tipoOperacaoOriem: widget.origem,
        dataCriacao: data,
        dataVencimento: parcelas[i].vencimento,
        descricao: parcelas.length == 1
            ? descricaoBase
            : '$descricaoBase (${i + 1}/${parcelas.length})',
        valorLancamento: valor,
        valorTaxasImpostos: bandeira?.calcularTaxa(valor) ?? 0,
        operacaoOrigemId: operacaoId,
        formaPagamento: forma,
      );
      pai ??= lancamento;
      lancamentos.add(lancamento);
    }
    return lancamentos;
  }

  // ---------------------------------------------------------------------------
  // Interface
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      title: _ehVenda ? 'Recebimento' : 'Pagamento',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Lançar no financeiro'),
            subtitle: Text(
              widget.existentes.isNotEmpty
                  ? 'Desativar remove os lançamentos desta operação.'
                  : (_ehVenda
                        ? 'Gera as contas a receber desta venda.'
                        : 'Gera as contas a pagar desta compra.'),
            ),
            value: _gerarFinanceiro,
            onChanged: widget.bloqueado
                ? null
                : (valor) => setState(() {
                    _gerarFinanceiro = valor;
                    if (valor) {
                      _parcelasEditadas = false;
                      _regenerar();
                    }
                  }),
          ),
          if (_gerarFinanceiro && widget.bloqueado)
            ..._buildResumoBloqueado()
          else if (_gerarFinanceiro)
            ..._buildCampos(),
        ],
      ),
    );
  }

  List<Widget> _buildResumoBloqueado() {
    final tema = Theme.of(context).textTheme;
    final lancamentos = widget.existentes;
    return [
      Text(
        'Já existem pagamentos registrados nestes lançamentos. Para alterá-los, '
        'use a tela do financeiro.',
        style: tema.bodySmall,
      ),
      const SizedBox(height: 8),
      for (var i = 0; i < lancamentos.length; i++)
        Padding(
          padding: const EdgeInsets.only(bottom: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  '${i + 1}/${lancamentos.length} · vence em '
                  '${lancamentos[i].dataVencimento.toFormattedDate()}'
                  ' · ${lancamentos[i].statusLancamento.label}',
                ),
              ),
              Text(lancamentos[i].valorTotal.toCurrency()),
            ],
          ),
        ),
    ];
  }

  Widget? _buildInfoCartao() {
    final tema = Theme.of(context).textTheme.bodySmall;
    if (_pessoaCartao == null) return null;
    if (_ehVenda) {
      final bandeira = _bandeiraModelo;
      if (bandeira == null) return null;
      final taxaTotal = _parcelas.fold<double>(
        0,
        (soma, p) => soma + bandeira.calcularTaxa(_valorParcela(p)),
      );
      return Text(
        'Taxa da bandeira: ${bandeira.taxa.toPercentage()} · '
        'taxas desta venda: ${taxaTotal.toCurrency()}',
        style: tema,
      );
    }
    final cartao = _cartaoModelo;
    if (cartao == null) return null;
    return Text(
      'Fatura vence todo dia ${cartao.diaVencimento} e fecha '
      '${cartao.diasFechamento} '
      '${cartao.diasFechamento == 1 ? 'dia' : 'dias'} antes. '
      '${avisoDiaVencimento(cartao.diaVencimento) ?? ''}',
      style: tema,
    );
  }

  Future<void> _cadastrarCartao() async {
    final pessoa = _ehVenda
        ? await cadastrarBandeiraRapida(context)
        : await cadastrarCartaoRapido(context);
    if (pessoa == null || !mounted) return;
    _pessoaCartao = pessoa;
    setState(() {});
    widget.formKey.currentState?.fields['cartao_credito']?.didChange(pessoa);
    sincronizar();
  }

  List<Widget> _buildCampos() {
    final tema = Theme.of(context);
    final opcoes = _ehVenda
        ? _repo.pessoasBandeiraCartao
        : _repo.pessoasCartaoCredito;
    final maxParcelas = _numParcelas > 24 ? _numParcelas : 24;
    final somaCentavos = _parcelas.fold<int>(
      0,
      (soma, parcela) => soma + _centavos(_valorParcela(parcela)),
    );
    final diferenca = _centavos(widget.total()) - somaCentavos;
    final info = _usaCartao(_forma) ? _buildInfoCartao() : null;

    return [
      FormBuilderDropdown<FormaPagamento>(
        name: 'forma_pagamento',
        initialValue: _forma,
        decoration: AppInputDecoration.of(
          'Forma de pagamento',
          icon: Icons.payments_outlined,
        ),
        validator: FormBuilderValidators.required(
          errorText: 'Selecione a forma de pagamento',
        ),
        onChanged: (forma) {
          setState(() => _forma = forma ?? FormaPagamento.dinheiro);
          sincronizar();
        },
        items: [
          for (final forma in FormaPagamento.values)
            DropdownMenuItem(value: forma, child: Text(forma.label)),
        ],
      ),
      if (_usaCartao(_forma)) ...[
        const SizedBox(height: 12),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: FormBuilderSearchableDropdownField<PessoaFinanceiro>(
                name: 'cartao_credito',
                label: _ehVenda ? 'Bandeira' : 'Cartão',
                initialValue: _pessoaCartao,
                items: opcoes,
                itemBuilder: (pessoa) => pessoa.nome,
                validator: FormBuilderValidators.required(
                  errorText: _ehVenda
                      ? 'Selecione a bandeira'
                      : 'Selecione o cartão',
                ),
                onChanged: (pessoa) {
                  setState(() => _pessoaCartao = pessoa);
                  sincronizar();
                },
              ),
            ),
            IconButton(
              icon: const Icon(Icons.add_card_outlined),
              tooltip: _ehVenda ? 'Cadastrar bandeira' : 'Cadastrar cartão',
              onPressed: _cadastrarCartao,
            ),
          ],
        ),
        if (info != null)
          Padding(padding: const EdgeInsets.only(top: 4), child: info),
      ],
      const SizedBox(height: 12),
      FormBuilderDropdown<int>(
        name: 'parcelas',
        initialValue: _numParcelas,
        decoration: AppInputDecoration.of(
          'Parcelamento',
          icon: Icons.format_list_numbered,
        ),
        onChanged: (quantidade) => setState(() {
          _numParcelas = quantidade ?? 1;
          _parcelasEditadas = false;
          _regenerar();
        }),
        items: [
          for (var i = 1; i <= maxParcelas; i++)
            DropdownMenuItem(
              value: i,
              child: Text(i == 1 ? 'Parcela única' : '${i}x'),
            ),
        ],
      ),
      const SizedBox(height: 12),
      for (var i = 0; i < _parcelas.length; i++) _buildParcela(i),
      Text(
        'Soma das parcelas: ${(somaCentavos / 100).toCurrency()}',
        style: tema.textTheme.bodyMedium,
      ),
      if (diferenca != 0)
        Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(
            diferenca > 0
                ? 'Faltam ${(diferenca / 100).toCurrency()} para chegar ao total.'
                : 'As parcelas passam ${(-diferenca / 100).toCurrency()} do total.',
            style: tema.textTheme.bodySmall?.copyWith(
              color: tema.colorScheme.error,
            ),
          ),
        ),
      Align(
        alignment: Alignment.centerLeft,
        child: TextButton.icon(
          onPressed: () => setState(() {
            _parcelasEditadas = false;
            _regenerar();
          }),
          icon: const Icon(Icons.refresh),
          label: const Text('Redistribuir valores e datas'),
        ),
      ),
    ];
  }

  Widget _buildParcela(int indice) {
    final parcela = _parcelas[indice];
    return Padding(
      key: ValueKey('parcela_${parcela.id}'),
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 16),
            child: SizedBox(
              width: 40,
              child: Text(
                '${indice + 1}/${_parcelas.length}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
          ),
          Expanded(
            child: AppDateTimeField(
              name: 'parcela_venc_${parcela.id}',
              label: 'Vencimento',
              initialValue: parcela.vencimento,
              onChanged: (_) => _parcelasEditadas = true,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: AppNumberField(
              name: 'parcela_valor_${parcela.id}',
              label: 'Valor',
              min: 0.01,
              initialValue: formatarParaCampo(parcela.valor),
              onChanged: (_) => _parcelasEditadas = true,
            ),
          ),
        ],
      ),
    );
  }
}
