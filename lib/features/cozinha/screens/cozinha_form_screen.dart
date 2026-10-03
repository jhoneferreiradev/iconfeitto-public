import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/utils/formatters.dart';
import '../../../core/widgets/app_date_time_field.dart';
import '../../../core/widgets/app_grouped_dropdown.dart';
import '../../../core/widgets/app_number_field.dart';
import '../../../core/widgets/app_scaffold.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/form_builder_grouped_dropdown_field.dart';
import '../../../core/widgets/form_builder_searchable_dropdown_field.dart';
import '../../../core/widgets/section_card.dart';
import '../../../shared/data/app_repository.dart';
import '../../../shared/models/grupo_unidade.dart';
import '../../../shared/models/item_ficha_tecnica.dart';
import '../../../shared/models/operacao.dart';
import '../../../shared/models/produto.dart';
import '../../../shared/models/tipo_item.dart';
import '../pdf/fabricacao_pdf.dart';
import 'cozinha_list_screen.dart';

/// Registro de fabricação. Com [fabricacaoId] a tela abre somente para leitura,
/// pois fabricações não podem ser editadas.
class CozinhaFormScreen extends StatefulWidget {
  final String? fabricacaoId;

  const CozinhaFormScreen({super.key, this.fabricacaoId});

  @override
  State<CozinhaFormScreen> createState() => _CozinhaFormScreenState();
}

class _CozinhaFormScreenState extends State<CozinhaFormScreen> {
  final _formKey = GlobalKey<FormBuilderState>();
  final _repo = AppRepository.instance;
  String? _produtoId;
  List<ItemFichaTecnica> _ficha = [];
  // Muda a cada produto escolhido para recriar os campos da ficha.
  int _geracao = 0;

  bool get _somenteLeitura => widget.fabricacaoId != null;

  Fabricacao? get _fabricacao {
    final id = widget.fabricacaoId;
    if (id == null) return null;
    for (final fabricacao in _repo.fabricacoes) {
      if (fabricacao.id == id) return fabricacao;
    }
    return null;
  }

  @override
  void initState() {
    super.initState();
    final fabricacao = _fabricacao;
    if (fabricacao != null) {
      _produtoId = fabricacao.produtoId;
      _ficha = fabricacao.fichaTecnica.map((item) => item.copy()).toList();
    }
  }

  bool _temFicha(Produto? produto) =>
      produto != null &&
      TipoItem.tiposFabricacao.contains(produto.tipo) &&
      produto.possuiFichaTecnica &&
      produto.fichaTecnica.isNotEmpty;

  @override
  Widget build(BuildContext context) {
    final fabricacao = _fabricacao;
    if (_somenteLeitura && fabricacao == null) {
      return const AppScaffold(
        title: 'Fabricação não encontrada',
        body: EmptyState(mensagem: 'A fabricação solicitada não existe.'),
      );
    }
    final produtos =
        _repo.produtos
            .where(
              (p) => p.id == fabricacao?.produtoId || (p.ativo && _temFicha(p)),
            )
            .toList()
          ..sort((a, b) => a.nome.compareTo(b.nome));
    return AppScaffold(
      title: _somenteLeitura ? 'Fabricação' : 'Registrar fabricação',
      actions: [
        if (fabricacao != null) ...[
          IconButton(
            icon: const Icon(Icons.print_outlined),
            tooltip: 'Imprimir',
            onPressed: () => FabricacaoPdf.imprimir(fabricacao),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline),
            tooltip: 'Excluir',
            onPressed: () async {
              final excluida = await confirmarExclusaoFabricacao(
                context,
                fabricacao,
              );
              if (excluida && context.mounted) context.pop();
            },
          ),
        ],
      ],
      body: FormBuilder(
        key: _formKey,
        initialValue: {
          'data': fabricacao?.data ?? DateTime.now(),
          'produto': fabricacao?.produtoId,
          'quantidade': fabricacao == null
              ? ''
              : formatarParaCampo(fabricacao.quantidade),
        },
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
          children: [
            SectionCard(
              title: 'Produção',
              child: IgnorePointer(
                ignoring: _somenteLeitura,
                child: Column(
                  children: [
                    const AppDateTimeField(
                      name: 'data',
                      label: 'Data de fabricação',
                    ),
                    const SizedBox(height: 12),
                    FormBuilderSearchableDropdownField<String>(
                      name: 'produto',
                      label: 'Produto fabricado',
                      validator: FormBuilderValidators.required(
                        errorText: 'Selecione o produto',
                      ),
                      items: produtos.map((p) => p.id).toList(),
                      itemBuilder: (id) =>
                          produtos.firstWhere((p) => p.id == id).nome,
                      onChanged: _selecionarProduto,
                    ),
                    const SizedBox(height: 12),
                    const AppNumberField(
                      name: 'quantidade',
                      label: 'Quantidade fabricada',
                      min: 0.0001,
                    ),
                  ],
                ),
              ),
            ),
            if (_produtoId != null) ...[
              const SizedBox(height: 12),
              SectionCard(
                title: 'Ficha técnica desta fabricação',
                child: IgnorePointer(
                  ignoring: _somenteLeitura,
                  child: _buildFicha(),
                ),
              ),
            ],
            if (!_somenteLeitura) ...[
              const SizedBox(height: 8),
              FilledButton.icon(
                onPressed: _salvar,
                icon: const Icon(Icons.check),
                label: const Text('Registrar fabricação'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildFicha() {
    if (_ficha.isEmpty) {
      return const Text('Este produto não possui itens na ficha técnica.');
    }
    return Column(
      children: [for (var i = 0; i < _ficha.length; i++) _buildItemFicha(i)],
    );
  }

  Widget _buildItemFicha(int i) {
    final item = _ficha[i];
    final ingrediente = _repo.produtoPorId(item.produtoIngredienteId);
    return Padding(
      key: ValueKey('ficha_${_geracao}_$i'),
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(top: 14),
                  child: Text(ingrediente?.nome ?? 'Ingrediente'),
                ),
              ),
              SizedBox(
                width: 110,
                child: AppNumberField(
                  name: _campo('q', i),
                  label: 'Quantidade',
                  min: 0,
                  initialValue: item.quantidade == 0
                      ? ''
                      : formatarParaCampo(item.quantidade),
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(width: 130, child: _buildUnidadeFichaDropdown(i)),
            ],
          ),
          if (!_somenteLeitura && _temFicha(ingrediente))
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.info_outline,
                    size: 16,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Este item possui ficha técnica: a fabricação também '
                      'será feita para ele, na quantidade necessária.',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  String _campo(String tipo, int indice) => 'f${_geracao}_${tipo}_$indice';

  Widget _buildUnidadeFichaDropdown(int index) {
    final unidades = {for (final u in _repo.unidades) u.id: u};
    return FormBuilderGroupedDropdownField<String>(
      name: _campo('u', index),
      label: 'Unidade',
      initialValue: _ficha[index].unidadeId,
      validator: FormBuilderValidators.required(
        errorText: 'Selecione a unidade',
      ),
      groups: [
        for (final grupo in GrupoUnidade.values)
          if (_repo.unidadesDoGrupo(grupo).isNotEmpty)
            AppDropdownGroup<String>(
              name: grupo.label,
              items:
                  (_repo.unidadesDoGrupo(grupo)
                        ..sort((a, b) => a.nome.compareTo(b.nome)))
                      .map((u) => u.id)
                      .toList(),
            ),
      ],
      itemBuilder: (id) => unidades[id]?.sigla ?? '',
    );
  }

  void _selecionarProduto(String? id) {
    if (id == null || _somenteLeitura) return;
    final produto = _repo.produtoPorId(id);
    setState(() {
      _geracao++;
      _produtoId = id;
      _ficha = produto?.fichaTecnica.map((item) => item.copy()).toList() ?? [];
    });
  }

  Future<void> _salvar() async {
    if (_formKey.currentState?.saveAndValidate() != true ||
        _produtoId == null) {
      return;
    }
    final valores = _formKey.currentState!.value;
    final data = valores['data'] as DateTime;
    final quantidade = valores['quantidade'] as double;
    final ficha = [
      for (var i = 0; i < _ficha.length; i++)
        ItemFichaTecnica(
          produtoIngredienteId: _ficha[i].produtoIngredienteId,
          quantidade: valores[_campo('q', i)] as double? ?? 0,
          unidadeId: valores[_campo('u', i)] as String,
        ),
    ];

    final quantidadePorIngrediente = <String, double>{};
    for (var i = 0; i < ficha.length; i++) {
      final item = ficha[i];
      final ingrediente = _repo.produtoPorId(item.produtoIngredienteId);
      if (ingrediente == null || !_temFicha(ingrediente)) continue;
      final necessaria =
          item.quantidade *
          quantidade *
          _repo.unidadePorId(item.unidadeId).fatorParaBase /
          _repo.unidadePorId(ingrediente.unidadeEstoqueId).fatorParaBase;
      quantidadePorIngrediente.update(
        ingrediente.id,
        (atual) => atual + necessaria,
        ifAbsent: () => necessaria,
      );
    }

    final fabricacoes = <Fabricacao>[
      for (final entrada in quantidadePorIngrediente.entries)
        if (entrada.value > 0)
          Fabricacao(
            id: _repo.novoId(),
            data: data,
            produtoId: entrada.key,
            quantidade: entrada.value,
            fichaTecnica: _repo
                .produtoPorId(entrada.key)!
                .fichaTecnica
                .map((item) => item.copy())
                .toList(),
          ),
      Fabricacao(
        id: _repo.novoId(),
        data: data,
        produtoId: _produtoId!,
        quantidade: quantidade,
        fichaTecnica: ficha,
      ),
    ];

    try {
      await _repo.salvarFabricacoes(fabricacoes);
      if (mounted) context.pop();
    } on SaldoEstoqueInsuficienteException catch (error) {
      _avisar(error.message);
    } on StateError catch (error) {
      _avisar(error.message);
    }
  }

  void _avisar(String mensagem) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(mensagem)));
  }
}
