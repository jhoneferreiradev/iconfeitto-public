import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/widgets/app_date_time_field.dart';
import '../../../core/widgets/app_grouped_dropdown.dart';
import '../../../core/widgets/app_number_field.dart';
import '../../../core/widgets/app_scaffold.dart';
import '../../../core/widgets/form_builder_grouped_dropdown_field.dart';
import '../../../core/widgets/form_builder_searchable_dropdown_field.dart';
import '../../../core/widgets/section_card.dart';
import '../../../shared/data/app_repository.dart';
import '../../../shared/models/grupo_unidade.dart';
import '../../../shared/models/item_ficha_tecnica.dart';
import '../../../shared/models/operacao.dart';

class CozinhaFormScreen extends StatefulWidget {
  const CozinhaFormScreen({super.key});

  @override
  State<CozinhaFormScreen> createState() => _CozinhaFormScreenState();
}

class _CozinhaFormScreenState extends State<CozinhaFormScreen> {
  final _formKey = GlobalKey<FormBuilderState>();
  final _repo = AppRepository.instance;
  String? _produtoId;
  List<ItemFichaTecnica> _ficha = [];

  @override
  Widget build(BuildContext context) {
    final produtos = _repo.produtos.where((p) => p.ativo).toList()
      ..sort((a, b) => a.nome.compareTo(b.nome));
    return AppScaffold(
      title: 'Registrar fabricação',
      body: FormBuilder(
        key: _formKey,
        initialValue: {'data': DateTime.now(), 'quantidade': ''},
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
          children: [
            SectionCard(
              title: 'Produção',
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
            if (_produtoId != null) ...[
              const SizedBox(height: 12),
              SectionCard(
                title: 'Ficha técnica desta fabricação',
                child: _buildFicha(),
              ),
            ],
            const SizedBox(height: 8),
            FilledButton.icon(
              onPressed: _salvar,
              icon: const Icon(Icons.check),
              label: const Text('Registrar fabricação'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFicha() {
    if (_ficha.isEmpty)
      return const Text('Este produto não possui itens na ficha técnica.');
    return Column(
      children: [
        for (var i = 0; i < _ficha.length; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    _repo.produtoPorId(_ficha[i].produtoIngredienteId)?.nome ??
                        'Ingrediente',
                  ),
                ),
                SizedBox(
                  width: 110,
                  child: AppNumberField(
                    name: 'ficha_q_$i',
                    label: 'Quantidade',
                    min: 0,
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(width: 130, child: _buildUnidadeFichaDropdown(i)),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildUnidadeFichaDropdown(int index) {
    final ingrediente = _repo.produtoPorId(_ficha[index].produtoIngredienteId);
    final unidadesCompativeis = ingrediente == null
        ? _repo.unidades
        : _repo.unidadesDoGrupo(
            _repo.unidadePorId(ingrediente.unidadeEstoqueId).grupo,
          );
    return FormBuilderGroupedDropdownField<String>(
      name: 'ficha_u_$index',
      label: 'Unidade',
      initialValue: _ficha[index].unidadeId,
      groups: [
        AppDropdownGroup(
          name: unidadesCompativeis.isEmpty
              ? ''
              : unidadesCompativeis.first.grupo.label,
          items: unidadesCompativeis.map((u) => u.id).toList(),
        ),
      ],
      itemBuilder: (id) =>
          unidadesCompativeis.firstWhere((u) => u.id == id).sigla,
      itemComparator: (a, b) => unidadesCompativeis
          .firstWhere((u) => u.id == a)
          .nome
          .compareTo(unidadesCompativeis.firstWhere((u) => u.id == b).nome),
    );
  }

  void _selecionarProduto(String? id) {
    if (id == null) return;
    final produto = _repo.produtoPorId(id);
    setState(() {
      _produtoId = id;
      _ficha = produto?.fichaTecnica.map((item) => item.copy()).toList() ?? [];
    });
    for (var i = 0; i < _ficha.length; i++) {
      _formKey.currentState?.patchValue({
        'ficha_q_$i': _ficha[i].quantidade == 0
            ? ''
            : _ficha[i].quantidade.toString(),
        'ficha_u_$i': _ficha[i].unidadeId,
      });
    }
  }

  Future<void> _salvar() async {
    if (_formKey.currentState?.saveAndValidate() != true ||
        _produtoId == null) {
      return;
    }
    final valores = _formKey.currentState!.value;
    final ficha = [
      for (var i = 0; i < _ficha.length; i++)
        ItemFichaTecnica(
          produtoIngredienteId: _ficha[i].produtoIngredienteId,
          quantidade: valores['ficha_q_$i'] as double? ?? 0,
          unidadeId: valores['ficha_u_$i'] as String,
        ),
    ];
    await _repo.salvarFabricacao(
      Fabricacao(
        id: _repo.novoId(),
        data: valores['data'] as DateTime,
        produtoId: _produtoId!,
        quantidade: valores['quantidade'] as double,
        fichaTecnica: ficha,
      ),
    );
    if (mounted) context.pop();
  }
}
