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
import '../../../core/widgets/responsive.dart';
import '../../../core/widgets/section_card.dart';
import '../../../shared/data/app_repository.dart';
import '../../../shared/models/grupo_unidade.dart';
import '../../../shared/models/item_ficha_tecnica.dart';
import '../../../shared/models/item_ficha_tecnica_embalagem.dart';
import '../../../shared/models/produto.dart';
import '../pdf/ficha_tecnica_pdf.dart';
import '../widgets/item_ficha_embalagem_row.dart';
import '../widgets/item_ficha_row.dart';

class ProdutoFormScreen extends StatefulWidget {
  final String? produtoId;
  const ProdutoFormScreen({super.key, this.produtoId});

  @override
  State<ProdutoFormScreen> createState() => _ProdutoFormScreenState();
}

class _ProdutoFormScreenState extends State<ProdutoFormScreen> {
  /// Unidade fixa usada por produtos do tipo embalagem.
  static const _unidadeEmbalagem = 'un';

  final _formKey = GlobalKey<FormBuilderState>();
  final _repo = AppRepository.instance;

  late final Produto? _produtoOriginal;
  late final List<Produto> _ingredientesDisponiveis;
  late final List<Produto> _embalagensDisponiveis;
  late final Map<String, dynamic> _dadosIniciais;

  late List<ItemFichaTecnica> _ingredientes;
  late List<ItemFichaTecnicaEmbalagem> _embalagens;

  // Chaves estáveis (uma por item), para que remover um item do meio não faça
  // outra linha herdar o estado (texto digitado) da linha removida.
  late List<Key> _chavesIngredientes;
  late List<Key> _chavesEmbalagens;
  late bool _possuiFichaTecnica;
  late bool _isEmbalagem;
  late bool _podeSerVendido;
  late bool _calcularPrecoVendaUsandoMargemLucro = false;
  late double _margemLucro = 0;

  /// Fonte única dos valores de custo exibidos e salvos.
  late CalculadoraCustoProduto _custos;
  late CalculadoraPrecoVendaProduto _calculadoraPrecoVenda;

  bool get _isEdicao => widget.produtoId != null;

  // ---------------------------------------------------------------------------
  // Ciclo de vida
  // ---------------------------------------------------------------------------

  @override
  void initState() {
    super.initState();
    final id = widget.produtoId;
    final original = id == null ? null : _repo.produtoPorId(id);

    _produtoOriginal = original;
    _ingredientesDisponiveis = _repo.produtos.where((p) => p.id != id).toList()
      ..sort((a, b) => a.nome.compareTo(b.nome));
    _embalagensDisponiveis = _ingredientesDisponiveis
        .where((p) => p.isEmbalagem)
        .toList();

    _ingredientes = original?.fichaTecnica.map((i) => i.copy()).toList() ?? [];
    _embalagens =
        original?.fichaTecnicaEmbalagem.map((i) => i.copy()).toList() ?? [];
    _chavesIngredientes = _gerarChaves(_ingredientes.length);
    _chavesEmbalagens = _gerarChaves(_embalagens.length);
    _possuiFichaTecnica = original?.possuiFichaTecnica ?? false;
    _isEmbalagem = original?.isEmbalagem ?? false;
    _podeSerVendido = original?.podeSerVendido ?? false;

    _custos = CalculadoraCustoProduto(
      rendimentoReceita: original?.rendimentoReceita ?? 0,
      custoFichaTecnica: _ingredientes.fold<double>(
        0,
        (soma, item) => soma + _repo.custoItemFicha(item),
      ),
      custoOperacional: original?.custoOperacional ?? 0,
      custoUnitarioEmbalagem: _embalagens.fold<double>(
        0,
        (soma, item) => soma + _repo.custoItemFichaEmbalagem(item),
      ),
    );

    _calculadoraPrecoVenda = CalculadoraPrecoVendaProduto.calcularMargemLucro(
      custos: _custos,
      precoVenda: _produtoOriginal?.precoVenda ?? 0,
    );

    _dadosIniciais = _montarDadosIniciais(original);
  }

  List<Key> _gerarChaves(int quantidade) =>
      List.generate(quantidade, (_) => UniqueKey());

  Map<String, dynamic> _montarDadosIniciais(Produto? p) {
    return {
      'nome': p?.nome ?? '',
      'ativo': p?.ativo ?? true,
      'podeSerVendido': p?.podeSerVendido ?? _podeSerVendido,
      'podeSerComprado': p?.podeSerComprado ?? false,
      'possuiFichaTecnica': _possuiFichaTecnica,
      'isEmbalagem': _isEmbalagem,
      'tempoPreparoMinutos': (p?.tempoPreparoMinutos ?? 0).toString(),
      'rendimentoReceita': (p?.rendimentoReceita ?? 0).toString(),
      'custoMedio': (p?.custoMedio ?? 0.0).toDecimal(),
      // Formato pt-BR (vírgula), senão "12.5" seria lido como 125 ao parsear.
      'saldoEstoque': formatarNumero(p?.saldoEstoque ?? 0.0)
          .replaceAll('.', ','),
      'unidadeEstoqueId': p?.unidadeEstoqueId,
      'unidadeConsumoId': p?.unidadeConsumoId,
      'calcularPrecoVendaUsandoMargemLucro': false,
      'precoVenda': (p?.precoVenda ?? 0.0).toDecimal(),
      'margemLucro': _calculadoraPrecoVenda.margemLucro.toDecimal(),
    };
  }

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: _isEdicao ? 'Editar produto' : 'Novo produto',
      actions: [
        IconButton(
          tooltip: 'Unidades de medida',
          icon: const Icon(Icons.straighten),
          onPressed: () => context.push('/unidades').then((_) {
            if (mounted) setState(() {});
          }),
        ),
        if (_possuiFichaTecnica && _ingredientes.isNotEmpty)
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
        initialValue: _dadosIniciais,
        child: ResponsiveFormLayout(
          padding: AppSpacing.screenPadding,
          primaryFlex: 5,
          secondaryFlex: 6,
          primary: [
            _buildDadosDoProduto(),
            if (!_possuiFichaTecnica) _buildPrecoVenda(),
            if (_possuiFichaTecnica && !_isEmbalagem) ...[
              _buildRendimentoPreparo(),
              _buildTabelaCusto(),
              _buildPrecoVenda(),
            ],
          ],
          secondary: [
            if (!_isEmbalagem && _podeSerVendido) _buildEmbalagem(),
            if (_possuiFichaTecnica && !_isEmbalagem) _buildFichaTecnica(),
          ],
          footer: FilledButton.icon(
            onPressed: () => _salvar(
              onSuccess: (_) {
                if (mounted) context.pop();
              },
            ),
            icon: const Icon(Icons.check),
            label: const Text('Salvar produto'),
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Seções
  // ---------------------------------------------------------------------------

  Widget _buildDadosDoProduto() {
    return SectionCard(
      title: 'Dados do produto',
      child: Column(
        spacing: AppSpacing.sm,
        children: [
          const AppTextField(
            name: 'nome',
            label: 'Nome do produto',
            icon: Icons.cake_outlined,
          ),
          _linha([
            _buildSwitch('ativo', 'Ativo'),
            _buildSwitch(
              'isEmbalagem',
              'É embalagem',
              onChanged: _alterarIsEmbalagem,
            ),
          ]),
          _linha([
            _buildSwitch('podeSerComprado', 'Pode ser comprado'),
            _buildSwitch(
              'podeSerVendido',
              'Pode ser vendido',
              onChanged: (value) =>
                  setState(() => _podeSerVendido = value ?? false),
            ),
          ]),
          if (!_isEmbalagem) ...[
            _linha([
              _buildUnidadeEstoqueDropdown(),
              _buildUnidadeConsumoDropdown(),
            ]),
            _buildSwitch(
              'possuiFichaTecnica',
              'Possui ficha técnica',
              onChanged: (value) =>
                  setState(() => _possuiFichaTecnica = value ?? false),
            ),
          ],
          if (_possuiFichaTecnica)
            _buildSaldoEstoque()
          else
            _linha([_buildSaldoEstoque(), _buildCustoMedio()]),
        ],
      ),
    );
  }

  Widget _buildEmbalagem() {
    return _buildSecaoItens(
      titulo: 'Embalagem',
      disponiveis: _embalagensDisponiveis,
      onAdicionar: _adicionarEmbalagem,
      child: _buildListaItens(
        disponiveis: _embalagensDisponiveis,
        quantidade: _embalagens.length,
        mensagemSemProdutos:
            'Cadastre produtos marcados como "É embalagem" para usá-los aqui.',
        mensagemVazia: 'Nenhum item de embalagem foi adicionado. Use "Adicionar item" para começar.',
        buildLinha: _buildLinhaEmbalagem,
      ),
    );
  }

  Widget _buildFichaTecnica() {
    return _buildSecaoItens(
      titulo: 'Itens da ficha técnica',
      disponiveis: _ingredientesDisponiveis,
      onAdicionar: _adicionarIngrediente,
      child: _buildListaItens(
        disponiveis: _ingredientesDisponiveis,
        quantidade: _ingredientes.length,
        mensagemSemProdutos:
            'Cadastre outros produtos para poder montar a ficha técnica.',
        mensagemVazia:
            'Nenhum item adicionado. Use "Adicionar item" para começar.',
        buildLinha: _buildLinhaIngrediente,
      ),
    );
  }

  Widget _buildRendimentoPreparo() {
    return SectionCard(
      title: 'Rendimento e preparo',
      child: _linha(
        [
          _buildCampoDeCusto('rendimentoReceita', 'Rendimento'),
          _buildCampoDeCusto(
            'tempoPreparoMinutos',
            'Tempo de preparo (minutos)',
          ),
        ],
        flex: [1, 2],
      ),
    );
  }

  Widget _buildTabelaCusto() {
    final custoHora = _repo.empresa.custoOperacionalPorHora;

    return SectionCard(
      title: 'Tabela de custos',
      child: Column(
        children: [
          _buildLinhaCusto(
            'Custo operacional da receita',
            '${custoHora.toCurrency()}/hora, ver cadastro da empresa',
            _custos.custoOperacional,
          ),
          _buildLinhaCusto(
            'Custo total da embalagem',
            'Custo total de embalagens para a receita',
            _custos.custoTotalEmbalagem,
          ),
          _buildLinhaCusto(
            'Custo total dos itens da receita',
            'Soma de todos os custos dos itens da receita',
            _custos.custoFichaTecnica,
          ),
          _buildLinhaCusto(
            'Custo unitário de cada ${_produtoOriginal?.unidadeConsumoId}',
            'Custo por unidade do produto',
            _custos.custoRendimentoUnitario,
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Componentes reutilizáveis da tela
  // ---------------------------------------------------------------------------

  /// Linha de campos lado a lado, com largura proporcional a [flex].
  Widget _linha(List<Widget> filhos, {List<int> flex = const []}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: AppSpacing.md,
      children: [
        for (var i = 0; i < filhos.length; i++)
          Expanded(flex: i < flex.length ? flex[i] : 1, child: filhos[i]),
      ],
    );
  }

  Widget _buildSwitch(
    String name,
    String titulo, {
    ValueChanged<bool?>? onChanged,
  }) {
    return FormBuilderSwitch(
      name: name,
      title: Text(titulo),
      onChanged: onChanged,
    );
  }

  /// Seção com botão "Adicionar item" (embalagem e ficha técnica).
  Widget _buildSecaoItens({
    required String titulo,
    required List<Produto> disponiveis,
    required VoidCallback onAdicionar,
    required Widget child,
  }) {
    return SectionCard(
      title: titulo,
      trailing: TextButton.icon(
        onPressed: disponiveis.isEmpty ? null : onAdicionar,
        icon: const Icon(Icons.add),
        label: const Text('Adicionar item'),
      ),
      child: child,
    );
  }

  /// Lista de linhas de itens com mensagens de estado vazio.
  /// [buildLinha] pode devolver null para ignorar um item inválido.
  Widget _buildListaItens({
    required List<Produto> disponiveis,
    required int quantidade,
    required String mensagemSemProdutos,
    required String mensagemVazia,
    required Widget? Function(int index) buildLinha,
  }) {
    if (disponiveis.isEmpty) return Text(mensagemSemProdutos);
    if (quantidade == 0) return Text(mensagemVazia);

    final linhas = <Widget>[];
    for (var i = 0; i < quantidade; i++) {
      final linha = buildLinha(i);
      if (linha != null) linhas.add(linha);
    }
    return Column(spacing: AppSpacing.md, children: linhas);
  }

  Widget _buildLinhaCusto(String titulo, String explicacao, double valor) {
    final textTheme = Theme.of(context).textTheme;
    return ListTile(
      title: Row(
        children: [
          Expanded(child: Text(titulo, style: textTheme.bodyLarge)),
          Text(valor.toCurrency(), style: textTheme.bodyLarge),
        ],
      ),
      subtitle: Text(
        explicacao,
        style: textTheme.bodySmall?.copyWith(fontStyle: FontStyle.italic),
      ),
    );
  }

  AppNumberField _buildCampoDeCusto(String name, String label) {
    return AppNumberField(
      name: name,
      label: label,
      required: false,
      min: 0,
      onChanged: (_) => _atualizarCustos(),
    );
  }

  AppNumberField _buildSaldoEstoque() {
    return const AppNumberField(
      name: 'saldoEstoque',
      label: 'Saldo em estoque',
      icon: Icons.inventory_2_outlined,
      min: 0,
      readOnly: true,
    );
  }

  AppNumberField _buildCustoMedio() {
    return const AppNumberField(
      name: 'custoMedio',
      label: 'Custo médio',
      icon: Icons.attach_money,
      suffixText: 'R\$',
      min: 0,
    );
  }

  // ---------------------------------------------------------------------------
  // Preço de venda
  // ---------------------------------------------------------------------------
  Widget _buildPrecoVenda() {
    if (!_podeSerVendido) {
      return SizedBox.shrink();
    }

    return SectionCard(
      title: "Preço de venda",
      child: Column(
        spacing: AppSpacing.sm,
        children: [
          _buildSwitch(
            'calcularPrecoVendaUsandoMargemLucro',
            'Calcular usando margem de lucro',
            onChanged: (value) => setState(
              () => _calcularPrecoVendaUsandoMargemLucro = value ?? false,
            ),
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: AppSpacing.md,
            children: [
              Expanded(
                child: AppNumberField(
                  name: 'precoVenda',
                  label: _calcularPrecoVendaUsandoMargemLucro
                      ? 'Margem de lucro (%)'
                      : 'Preço (R\$)',
                  icon: Icons.attach_money,
                  suffixText: 'R\$',
                  min: 0,
                  onChanged: _onPrecoVendaChanged,
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      _calcularPrecoVendaUsandoMargemLucro
                          ? 'Preço (R\$)'
                          : 'Margem de lucro (%)',
                      textAlign: TextAlign.end,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    Text(
                      _calcularPrecoVendaUsandoMargemLucro
                          ? _calculadoraPrecoVenda.precoVenda.toCurrency()
                          : _calculadoraPrecoVenda.margemLucro.toPercentage(),
                      textAlign: TextAlign.end,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ],
                ),
              ),
            ],
          ),
          Row(
            spacing: AppSpacing.md,
            children: [
              Expanded(
                child: Text(
                  'Lucro: ${_calculadoraPrecoVenda.lucroReal.toCurrency()}',
                  style: Theme.of(context).textTheme.bodySmall,
                  textAlign: TextAlign.end,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Unidades de medida
  // ---------------------------------------------------------------------------

  Widget _buildUnidadeEstoqueDropdown() {
    return FormBuilderGroupedDropdownField<String>(
      name: 'unidadeEstoqueId',
      label: 'Unidade de estoque',
      icon: Icons.straighten,
      validator: FormBuilderValidators.required(
        errorText: 'Selecione a unidade',
      ),
      groups: _gruposDeUnidades(),
      itemBuilder: (id) => _repo.unidadePorId(id).sigla,
      onChanged: _sugerirUnidadeConsumo,
    );
  }

  Widget _buildUnidadeConsumoDropdown() {
    return FormBuilderGroupedDropdownField<String>(
      name: 'unidadeConsumoId',
      label: 'Unidade de consumo',
      icon: Icons.sell,
      validator: FormBuilderValidators.required(
        errorText: 'Selecione a unidade',
      ),
      groups: _gruposDeUnidades(),
      itemBuilder: (id) => _repo.unidadePorId(id).sigla,
    );
  }

  /// Ao escolher a unidade de estoque, sugere a mesma unidade para consumo
  /// enquanto esta ainda não foi preenchida.
  void _sugerirUnidadeConsumo(String? unidadeEstoqueId) {
    final consumo = _formKey.currentState?.fields['unidadeConsumoId'];
    if (unidadeEstoqueId != null && consumo?.value == null) {
      consumo?.didChange(unidadeEstoqueId);
    }
  }

  /// Unidades agrupadas por tipo (peso, volume, unidade), ordenadas por nome.
  List<AppDropdownGroup<String>> _gruposDeUnidades() {
    final grupos = <AppDropdownGroup<String>>[];
    for (final grupo in GrupoUnidade.values) {
      final unidades = _repo.unidadesDoGrupo(grupo)
        ..sort((a, b) => a.nome.compareTo(b.nome));
      if (unidades.isEmpty) continue;
      grupos.add(
        AppDropdownGroup<String>(
          name: grupo.label,
          items: unidades.map((u) => u.id).toList(),
        ),
      );
    }
    return grupos;
  }

  void _alterarIsEmbalagem(bool? value) {
    setState(() {
      _isEmbalagem = value ?? false;
      if (_isEmbalagem) {
        final campos = _formKey.currentState?.fields;
        campos?['unidadeEstoqueId']?.didChange(_unidadeEmbalagem);
        campos?['unidadeConsumoId']?.didChange(_unidadeEmbalagem);
      }
    });
  }

  // ---------------------------------------------------------------------------
  // Itens (embalagem e ficha técnica)
  // ---------------------------------------------------------------------------

  Widget? _buildLinhaEmbalagem(int i) {
    final item = _embalagens[i];
    if (_repo.produtoPorId(item.produtoEmbalagemId) == null) return null;

    return ItemFichaEmbalagemRow(
      key: _chavesEmbalagens[i],
      item: item,
      embalagens: _embalagensDisponiveis,
      custoLinha: _repo.custoItemFichaEmbalagem(item),
      onChanged: (novo) => _alterarItens(() => _embalagens[i] = novo),
      onRemover: () => _alterarItens(() {
        _embalagens.removeAt(i);
        _chavesEmbalagens.removeAt(i);
      }),
    );
  }

  Widget? _buildLinhaIngrediente(int i) {
    final item = _ingredientes[i];

    // Item recém-adicionado, ainda sem ingrediente escolhido.
    if (item.produtoIngredienteId.isEmpty) {
      return ItemFichaRow(
        key: _chavesIngredientes[i],
        item: item,
        ingredientes: _ingredientesDisponiveis,
        unidadesCompativeis: const [],
        custoLinha: 0,
        onChanged: (novo) => _alterarItens(() => _ingredientes[i] = novo),
        onRemover: () => _alterarItens(() {
          _ingredientes.removeAt(i);
          _chavesIngredientes.removeAt(i);
        }),
      );
    }

    final ingrediente = _repo.produtoPorId(item.produtoIngredienteId);
    if (ingrediente == null) return null;

    final grupo = _repo.unidadePorId(ingrediente.unidadeConsumoId).grupo;

    return ItemFichaRow(
      key: _chavesIngredientes[i],
      item: item,
      ingredientes: _ingredientesDisponiveis,
      unidadesCompativeis: _repo.unidadesDoGrupo(grupo),
      custoLinha: _repo.custoItemFicha(item),
      onChanged: (novo) => _alterarItens(() => _ingredientes[i] = novo),
      onRemover: () => _alterarItens(() {
        _ingredientes.removeAt(i);
        _chavesIngredientes.removeAt(i);
      }),
    );
  }

  void _adicionarEmbalagem() {
    final primeiro = _embalagensDisponiveis.first;
    _alterarItens(() {
      _embalagens.insert(
        0,
        ItemFichaTecnicaEmbalagem(produtoEmbalagemId: primeiro.id),
      );
      _chavesEmbalagens.insert(0, UniqueKey());
    });
  }

  void _adicionarIngrediente() {
    _alterarItens(() {
      _ingredientes.insert(
        0,
        ItemFichaTecnica(
          produtoIngredienteId: '',
          quantidade: 0,
          unidadeId: '',
        ),
      );
      _chavesIngredientes.insert(0, UniqueKey());
    });
  }

  /// Aplica a alteração nas listas de itens e recalcula os custos.
  void _alterarItens(VoidCallback alteracao) {
    alteracao();
    _atualizarCustos();
  }

  // ---------------------------------------------------------------------------
  // Cálculo de custos
  // ---------------------------------------------------------------------------

  void _atualizarCustos() {
    final custoFicha = _ingredientes.fold<double>(
      0,
      (soma, item) => soma + _repo.custoItemFicha(item),
    );
    final custoEmbalagem = _embalagens.fold<double>(
      0,
      (soma, item) => soma + _repo.custoItemFichaEmbalagem(item),
    );
    final horasDePreparo = _lerNumero('tempoPreparoMinutos') / 60;

    _formKey.currentState?.fields['custoMedio']?.didChange(
      custoFicha.toDecimal(),
    );

    setState(() {
      _custos = CalculadoraCustoProduto(
        rendimentoReceita: _lerNumero('rendimentoReceita').round(),
        custoFichaTecnica: custoFicha,
        custoOperacional:
            _repo.empresa.custoOperacionalPorHora * horasDePreparo,
        custoUnitarioEmbalagem: custoEmbalagem,
      );
    });
  }

  double _lerNumero(String campo) {
    return _numero(_formKey.currentState?.fields[campo]?.value);
  }

  /// Converte o valor bruto de um campo (num ou texto pt-BR) em double.
  static double _numero(dynamic valor) {
    return switch (valor) {
      num n => n.toDouble(),
      String s => s.toDouble() ?? 0.0,
      _ => 0.0,
    };
  }

  // ---------------------------------------------------------------------------
  // Ações
  // ---------------------------------------------------------------------------

  void _imprimirFichaTecnica() {
    _salvar(onSuccess: FichaTecnicaPdf.imprimir);
  }

  Future<void> _salvar({required ValueChanged<Produto> onSuccess}) async {
    final form = _formKey.currentState;
    if (form == null || !form.saveAndValidate()) {
      _mostrarMensagem('Revise os campos obrigatórios do produto.');
      return;
    }

    try {
      final produto = _montarProduto(form.value);
      await _repo.salvarProduto(produto);
      onSuccess(produto);
    } catch (error) {
      _mostrarMensagem('Não foi possível salvar o produto: $error');
    }
  }

  Produto _montarProduto(Map<String, dynamic> valores) {
    final possuiFicha = !_isEmbalagem && _possuiFichaTecnica;

    return Produto(
      id: _produtoOriginal?.id ?? _repo.novoId(),
      nome: valores['nome']?.toString().trim() ?? '',
      ativo: valores['ativo'] == true,
      podeSerVendido: valores['podeSerVendido'] != false,
      podeSerComprado: valores['podeSerComprado'] != false,
      isEmbalagem: _isEmbalagem,
      possuiFichaTecnica: possuiFicha,
      tempoPreparoMinutos: _isEmbalagem
          ? 0
          : _numero(valores['tempoPreparoMinutos']).round(),
      custoMedio: possuiFicha
          ? _custos.custoFichaTecnica
          : _numero(valores['custoMedio']),
      // Campo somente leitura: preserva o valor real em vez de reparsear o texto.
      saldoEstoque: _produtoOriginal?.saldoEstoque ?? 0,
      unidadeEstoqueId: _isEmbalagem
          ? _unidadeEmbalagem
          : valores['unidadeEstoqueId'] as String,
      unidadeConsumoId: _isEmbalagem
          ? _unidadeEmbalagem
          : valores['unidadeConsumoId'] as String,
      rendimentoReceita: _isEmbalagem
          ? 0
          : _numero(valores['rendimentoReceita']).round(),
      fichaTecnica: possuiFicha
          ? _ingredientes
                .where(
                  (i) => i.produtoIngredienteId.isNotEmpty && i.quantidade > 0,
                )
                .toList()
          : [],
      fichaTecnicaEmbalagem: _embalagens,
      custoOperacional: _custos.custoOperacional,
      precoVenda: _podeSerVendido ? _calculadoraPrecoVenda.precoVenda : 0,
    );
  }

  Future<void> _excluirProduto() async {
    final produto = _produtoOriginal;
    if (produto == null) return;

    final confirmar = await confirmarExclusao(
      context,
      titulo: 'Excluir produto',
      mensagem:
          'Deseja excluir "${produto.nome}"? Essa ação não pode ser desfeita.',
    );
    if (!confirmar) return;

    await _repo.excluirProduto(produto.id);
    if (mounted) context.pop();
  }

  void _mostrarMensagem(String texto) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(texto)));
  }

  void _onPrecoVendaChanged(String? value) {
    setState(() {
      double valor = _numero(value);

      if (_calcularPrecoVendaUsandoMargemLucro) {
        _calculadoraPrecoVenda = _calculadoraPrecoVenda.recalcular(
          margemLucro: valor,
        );
      } else {
        _calculadoraPrecoVenda =
            CalculadoraPrecoVendaProduto.calcularMargemLucro(
              custos: _calculadoraPrecoVenda.custos,
              precoVenda: valor,
            );
      }
    });
  }
}
