import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/app_grouped_dropdown.dart';
import '../../../core/widgets/app_number_field.dart';
import '../../../core/widgets/app_scaffold.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../core/widgets/confirm_dialog.dart';
import '../../../core/widgets/form_builder_grouped_dropdown_field.dart';
import '../../../core/widgets/section_card.dart';
import '../../../shared/data/app_repository.dart';
import '../../../shared/models/grupo_unidade.dart';
import '../../../shared/models/item_ficha_tecnica.dart';
import '../../../shared/models/produto.dart';
import '../../../shared/models/unidade_medida.dart';
import '../pdf/ficha_tecnica_pdf.dart';
import '../widgets/item_ficha_row.dart';

part 'part_builder_produto_form_screen.dart';

class ProdutoFormScreen extends StatefulWidget {
  final String? produtoId;
  const ProdutoFormScreen({super.key, this.produtoId});

  @override
  State<ProdutoFormScreen> createState() => _ProdutoFormScreenState();
}

class _ProdutoFormScreenState extends State<ProdutoFormScreen> {
  final _formKey = GlobalKey<FormBuilderState>();
  final _repo = AppRepository.instance;
  late List<ItemFichaTecnica> _itens;
  late bool _possuiFichaTecnica;
  Produto? _produtoOriginal;

  bool get _isEdicao => widget.produtoId != null;

  @override
  void initState() {
    super.initState();
    if (_isEdicao) {
      _produtoOriginal = _repo.produtoPorId(widget.produtoId!);
      _itens =
          _produtoOriginal?.fichaTecnica.map((i) => i.copy()).toList() ?? [];
      _possuiFichaTecnica = _produtoOriginal?.possuiFichaTecnica ?? false;
    } else {
      _itens = [];
      _possuiFichaTecnica = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final unidades = _repo.unidades;
    final ingredientesDisponiveis =
        _repo.produtos.where((p) => p.id != widget.produtoId).toList()
          ..sort((a, b) => a.nome.compareTo(b.nome));

    return AppScaffold(
      title: _isEdicao ? 'Editar produto' : 'Novo produto',
      actions: [
        IconButton(
          tooltip: 'Unidades de medida',
          icon: const Icon(Icons.straighten),
          onPressed: () => context.push('/unidades').then((_) {
            setState(() {});
          }),
        ),
        if (_possuiFichaTecnica && _itens.isNotEmpty)
          IconButton(
            icon: const Icon(Icons.print_outlined),
            tooltip: 'Imprimir ficha técnica',
            onPressed: _imprimirFichaTecnica,
          ),
        if (_isEdicao)
          IconButton(
            icon: const Icon(Icons.delete_outline),
            tooltip: 'Excluir produto',
            onPressed: _excluirProduto,
          ),
      ],
      body: FormBuilder(
        key: _formKey,
        initialValue: _getDadosIniciais,
        child: ListView(
          padding: AppSpacing.screenPadding,
          children: [
            SectionCard(
              title: 'Dados do produto',
              child: Column(
                spacing: AppSpacing.fieldGap.height ?? 0,
                children: [
                  _buildNomeProduto(),
                  _buildStatusProduto(),
                  _buildRowPodeSerCompradoPodeSerVendido(),
                  _buildRowUnidadesDeMedida(unidades),
                  _buildPossuiFichaTecnica(),
                  if (!_possuiFichaTecnica) _buildRowSaldoEstoqueCustoMedio(),
                  if (_possuiFichaTecnica) _buildSaldoEstoque(),
                ],
              ),
            ),
            if (_possuiFichaTecnica)
              _buildSectionCardFichaTecnica(ingredientesDisponiveis),
            FilledButton.icon(
              onPressed: () => _salvar(
                onSuccess: (produto) {
                  if (mounted) context.pop();
                },
              ),
              icon: const Icon(Icons.check),
              label: const Text('Salvar produto'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionCardFichaTecnica(List<Produto> ingredientesDisponiveis) {
    return Row(
      children: [
        Expanded(
          child: Column(
            children: [
              SectionCard(
                title: 'Rendimento, preparo e custos',
                child: Column(
                  spacing: AppSpacing.md,
                  children: [
                    _buildRowRendimentoTempoPreparo(),
                    _buildCustoOperacional(),
                    _buildCustoMedio(),
                    _buildCustoRendimentoUnitario(),
                  ],
                ),
              ),

              SectionCard(
                title: 'Itens da ficha técnica',
                trailing: TextButton.icon(
                  onPressed: ingredientesDisponiveis.isEmpty
                      ? null
                      : () => _adicionarItem(ingredientesDisponiveis),
                  icon: const Icon(Icons.add),
                  label: const Text('Adicionar item'),
                ),
                child: _buildFichaTecnica(ingredientesDisponiveis),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Row _buildRowRendimentoTempoPreparo() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: AppSpacing.md,
      children: [
        Expanded(child: _buildRendimento()),
        Expanded(flex: 2, child: _buildTempoPreparo()),
      ],
    );
  }

  AppNumberField _buildTempoPreparo() {
    return AppNumberField(
      name: 'tempoPreparoMinutos',
      label: 'Tempo de preparo (minutos)',
      required: false,
      min: 0,
      onChanged: (value) {
        _atualizarCamposDeCustos();
      },
    );
  }

  AppNumberField _buildRendimento() {
    return AppNumberField(
      name: 'rendimentoReceita',
      label: 'Rendimento',
      required: false,
      min: 0,
      onChanged: (value) {
        _atualizarCamposDeCustos();
      },
    );
  }

  AppNumberField _buildCustoRendimentoUnitario() {
    final unidadeEstoque =
        (_formKey.currentState?.fields['unidadeEstoqueId']?.value ?? "");

    var unidadeMedidaConsumo =
        (_formKey.currentState?.fields['unidadeConsumoId']?.value ??
        unidadeEstoque);

    unidadeMedidaConsumo = (unidadeMedidaConsumo ?? '').isEmpty
        ? (_produtoOriginal?.unidadeConsumoId ??
              _produtoOriginal?.unidadeEstoqueId)
        : unidadeMedidaConsumo;

    unidadeMedidaConsumo = unidadeMedidaConsumo ?? '';

    return AppNumberField(
      name: 'custoRendimentoUnitario',
      label: 'Custo de 1 $unidadeMedidaConsumo',
      required: false,
      readOnly: true,
      min: 0,
    );
  }

  FormBuilderSwitch _buildPossuiFichaTecnica() {
    return FormBuilderSwitch(
      name: 'possuiFichaTecnica',
      title: const Text('Possui ficha técnica'),
      onChanged: (value) {
        setState(() {
          _possuiFichaTecnica = value ?? false;
        });
      },
    );
  }

  Row _buildRowSaldoEstoqueCustoMedio() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: AppSpacing.md,
      children: [
        Expanded(child: _buildSaldoEstoque()),
        Expanded(child: _buildCustoMedio()),
      ],
    );
  }

  AppNumberField _buildCustoMedio() {
    return AppNumberField(
      name: 'custoMedio',
      label: _possuiFichaTecnica
          ? 'Custo total dos itens da receita + custo operacional'
          : 'Custo médio',
      icon: Icons.attach_money,
      suffixText: 'R\$',
      readOnly: _possuiFichaTecnica,
      min: 0,
    );
  }

  Widget _buildCustoOperacional() {
    double custoOperacionalPorHora = _repo.empresa.custoOperacionalPorHora;

    return Column(
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: AppSpacing.md,
          children: [
            Expanded(
              child: AppNumberField(
                name: 'custoOperacional',
                label:
                    'Custo operacional (${custoOperacionalPorHora.toCurrency()}/hora, ver cadastro da empresa)',
                suffixText: 'R\$',
                min: 0,
                readOnly: true,
              ),
            ),
          ],
        ),
      ],
    );
  }

  AppNumberField _buildSaldoEstoque() {
    return AppNumberField(
      name: 'saldoEstoque',
      label: 'Saldo em estoque',
      icon: Icons.inventory_2_outlined,
      min: 0,
      readOnly: true,
    );
  }

  Row _buildRowUnidadesDeMedida(List<UnidadeMedida> unidades) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: AppSpacing.md,
      children: [
        Expanded(child: _buildUnidadeEstoqueDropdown(unidades)),
        Expanded(child: _buildUnidadeConsumoDropdown(unidades)),
      ],
    );
  }

  Row _buildRowPodeSerCompradoPodeSerVendido() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: AppSpacing.md,
      children: [
        Expanded(child: _buildPodeSerComprado()),
        Expanded(child: _buildPodeSerVendido()),
      ],
    );
  }

  FormBuilderSwitch _buildPodeSerVendido() {
    return FormBuilderSwitch(
      name: 'podeSerVendido',
      title: const Text('Pode ser vendido'),
    );
  }

  FormBuilderSwitch _buildPodeSerComprado() {
    return FormBuilderSwitch(
      name: 'podeSerComprado',
      title: const Text('Pode ser comprado'),
    );
  }

  FormBuilderSwitch _buildStatusProduto() {
    return FormBuilderSwitch(name: 'ativo', title: const Text('Produto ativo'));
  }

  AppTextField _buildNomeProduto() {
    return const AppTextField(
      name: 'nome',
      label: 'Nome do produto',
      icon: Icons.cake_outlined,
    );
  }

  Map<String, dynamic> get _getDadosIniciais {
    return {
      'nome': _produtoOriginal?.nome ?? '',
      'ativo': _produtoOriginal?.ativo ?? true,
      'podeSerVendido': _produtoOriginal?.podeSerVendido ?? true,
      'podeSerComprado': _produtoOriginal?.podeSerComprado ?? true,
      'possuiFichaTecnica': _produtoOriginal?.possuiFichaTecnica ?? false,
      'tempoPreparoMinutos':
          _produtoOriginal?.tempoPreparoMinutos.toString() ?? '0',
      'rendimentoReceita':
          _produtoOriginal?.rendimentoReceita.toString() ?? '0',
      'custoMedio': _produtoOriginal == null
          ? 0.toDouble().toDecimal()
          : _produtoOriginal!.custoMedio.toDecimal(),
      'saldoEstoque': _produtoOriginal == null
          ? '0'
          : formatarNumero(_produtoOriginal!.saldoEstoque),
      'unidadeEstoqueId': _produtoOriginal?.unidadeEstoqueId,
      'unidadeConsumoId': _produtoOriginal?.unidadeConsumoId,
      'custoRendimentoUnitario':
          _produtoOriginal?.custoRendimentoUnitario.toDecimal() ??
          0.toDouble().toDecimal(),
      'custoOperacional':
          _produtoOriginal?.custoOperacional.toDecimal() ??
          0.toDouble().toDecimal(),
    };
  }

  Widget _buildUnidadeEstoqueDropdown(List<UnidadeMedida> unidades) {
    return FormBuilderGroupedDropdownField<String>(
      name: 'unidadeEstoqueId',
      label: 'Unidade de estoque',
      icon: Icons.straighten,
      validator: FormBuilderValidators.required(
        errorText: 'Selecione a unidade',
      ),
      groups: _agruparUnidades(unidades),
      itemBuilder: (id) {
        final unidade = unidades.firstWhere((u) => u.id == id);
        return unidade.sigla;
      },
    );
  }

  Widget _buildUnidadeConsumoDropdown(List<UnidadeMedida> unidades) {
    return FormBuilderGroupedDropdownField<String?>(
      name: 'unidadeConsumoId',
      label: 'Unidade de consumo',
      icon: Icons.sell,
      groups: _agruparUnidadesOpcional(unidades),
      itemBuilder: (id) {
        if (id == null) return 'Usar estoque';
        final unidade = unidades.firstWhere((u) => u.id == id);
        return unidade.sigla;
      },
      onChanged: (value) {
        setState(() {});
      },
    );
  }

  List<AppDropdownGroup<String>> _agruparUnidades(
    List<UnidadeMedida> unidades,
  ) {
    return [
      for (final grupo in GrupoUnidade.values)
        if (unidades.any((u) => u.grupo == grupo))
          AppDropdownGroup<String>(
            name: grupo.label,
            items:
                (unidades.where((u) => u.grupo == grupo).toList()
                      ..sort((a, b) => a.nome.compareTo(b.nome)))
                    .map((u) => u.id)
                    .toList(),
          ),
    ];
  }

  List<AppDropdownGroup<String?>> _agruparUnidadesOpcional(
    List<UnidadeMedida> unidades,
  ) {
    return [
      const AppDropdownGroup<String?>(name: '', items: [null]),
      for (final grupo in GrupoUnidade.values)
        if (unidades.any((u) => u.grupo == grupo))
          AppDropdownGroup<String?>(
            name: grupo.label,
            items:
                (unidades.where((u) => u.grupo == grupo).toList()
                      ..sort((a, b) => a.nome.compareTo(b.nome)))
                    .map<String?>((u) => u.id)
                    .toList(),
          ),
    ];
  }

  void _atualizarCamposDeCustos() {
    final custoOperacional = _calcularCustoOperacional();
    final custoFichaTecnica = _calcularTotalFichaTecnica();

    final custoUnitarioRendimento = _calcularCustoUnitarioRendimentoReceita(
      custoFichaTecnica + custoOperacional,
    );

    _formKey.currentState?.fields['custoOperacional']?.didChange(
      custoOperacional.toDecimal(),
    );

    _formKey.currentState?.fields['custoMedio']?.didChange(
      (custoFichaTecnica).toDecimal(),
    );

    _formKey.currentState?.fields['custoRendimentoUnitario']?.didChange(
      custoUnitarioRendimento.toDecimal(),
    );
  }

  double _calcularTotalFichaTecnica() {
    double totalFichaTecnica = 0;
    for (var i = 0; i < _itens.length; i++) {
      final item = _itens[i];
      final custoLinha = _repo.custoItemFicha(item);
      totalFichaTecnica += custoLinha;
    }

    return totalFichaTecnica;
  }

  double _calcularCustoOperacional() {
    double custoOperacionalPorHora = _repo.empresa.custoOperacionalPorHora;
    double tempoPreparoEmHoras =
        ((_formKey.currentState?.fields['tempoPreparoMinutos']?.value ?? "0.0")
                .toString()
                .toInt() ??
            0) /
        60;
    return custoOperacionalPorHora * tempoPreparoEmHoras;
  }

  double _calcularCustoUnitarioRendimentoReceita(
    double custoFichaTecnicaComCustoOperacional,
  ) {
    int novoRendimentoReceita =
        (_formKey.currentState?.fields['rendimentoReceita']?.value ?? "0.0")
            .toString()
            .toInt() ??
        0;

    return Produto.calcularCustoRendimentoUnitario(
      novoRendimentoReceita,
      custoFichaTecnicaComCustoOperacional,
    );
  }

  Widget _buildFichaTecnica(List<Produto> ingredientes) {
    if (ingredientes.isEmpty) {
      return const Text(
        'Cadastre outros produtos para poder montar a ficha técnica.',
      );
    }
    if (_itens.isEmpty) {
      return const Text(
        'Nenhum item adicionado. Use "Adicionar item" para começar.',
      );
    }

    final linhas = <Widget>[];
    for (var i = 0; i < _itens.length; i++) {
      final item = _itens[i];
      final ingrediente = _repo.produtoPorId(item.produtoIngredienteId);
      if (ingrediente == null) continue;
      final unidadeIngrediente = _repo.unidadePorId(
        ingrediente.unidadeEstoqueId,
      );
      final unidadesCompativeis = _repo.unidadesDoGrupo(
        unidadeIngrediente.grupo,
      );
      final custoLinha = _repo.custoItemFicha(item);

      linhas.add(
        ItemFichaRow(
          key: ValueKey('ficha-$i'),
          item: item,
          ingredientes: ingredientes,
          unidadesCompativeis: unidadesCompativeis,
          custoLinha: custoLinha,
          onChanged: (novo) => setState(() {
            _itens[i] = novo;
            _atualizarCamposDeCustos();
          }),
          onRemover: () => setState(() => _itens.removeAt(i)),
        ),
      );
    }
    linhas.add(const Divider());
    return Column(spacing: AppSpacing.md, children: linhas);
  }

  void _adicionarItem(List<Produto> ingredientes) {
    final primeiro = ingredientes.first;
    setState(() {
      _itens.insert(
        0,
        ItemFichaTecnica(
          produtoIngredienteId: primeiro.id,
          quantidade: 0,
          unidadeId: primeiro.unidadeEstoqueId,
        ),
      );
    });
  }

  void _imprimirFichaTecnica() {
    _salvar(
      onSuccess: (produto) {
        FichaTecnicaPdf.imprimir(produto);
      },
    );
  }

  Future<void> _salvar({required Function(Produto) onSuccess}) async {
    if (_formKey.currentState?.saveAndValidate() != true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Revise os campos obrigatórios do produto.'),
        ),
      );
      return;
    }
    try {
      final valores = _formKey.currentState!.value;
      final possuiFicha = valores['possuiFichaTecnica'] == true;
      final unidadeId = valores['unidadeEstoqueId']?.toString() ?? '';
      if (unidadeId.isEmpty) return;
      final produto = Produto(
        id: _produtoOriginal?.id ?? _repo.novoId(),
        nome: valores['nome']?.toString().trim() ?? '',
        ativo: valores['ativo'] == true,
        podeSerVendido: valores['podeSerVendido'] != false,
        podeSerComprado: valores['podeSerComprado'] != false,
        possuiFichaTecnica: possuiFicha,
        tempoPreparoMinutos: _valorNumerico(valores['tempoPreparoMinutos'])
            .round(),
        custoMedio: _valorNumerico(valores['custoMedio']),
        saldoEstoque: _valorNumerico(valores['saldoEstoque']),
        unidadeEstoqueId: unidadeId,
        unidadeConsumoId: valores['unidadeConsumoId'],
        rendimentoReceita: _valorNumerico(valores['rendimentoReceita']).round(),
        fichaTecnica: possuiFicha
            ? _itens
                  .where(
                    (i) =>
                        i.produtoIngredienteId.isNotEmpty && i.quantidade > 0,
                  )
                  .map((i) => i.copy())
                  .toList()
            : [],
        custoOperacional: _valorNumerico(valores['custoOperacional']),
      );
      await _repo.salvarProduto(produto);
      onSuccess(produto);
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Não foi possível salvar o produto: $error')),
      );
    }
  }

  double _valorNumerico(dynamic valor) {
    if (valor is num) return valor.toDouble();
    return valor is String ? valor.toDouble() ?? 0 : 0;
  }

  Future<void> _excluirProduto() async {
    if (_produtoOriginal == null) return;
    final confirmar = await confirmarExclusao(
      context,
      titulo: 'Excluir produto',
      mensagem:
          'Deseja excluir "${_produtoOriginal!.nome}"? Essa ação não pode ser desfeita.',
    );
    if (confirmar) {
      _repo.excluirProduto(_produtoOriginal!.id);
      if (mounted) context.pop();
    }
  }
}
