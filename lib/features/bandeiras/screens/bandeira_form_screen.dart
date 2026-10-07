import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/app_number_field.dart';
import '../../../core/widgets/app_scaffold.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/responsive.dart';
import '../../../core/widgets/section_card.dart';
import '../../../shared/data/app_repository.dart';
import '../../../shared/models/cartao_credito.dart';

class BandeiraFormScreen extends StatefulWidget {
  final String? bandeiraId;

  const BandeiraFormScreen({super.key, this.bandeiraId});

  @override
  State<BandeiraFormScreen> createState() => _BandeiraFormScreenState();
}

class _BandeiraFormScreenState extends State<BandeiraFormScreen> {
  final _formKey = GlobalKey<FormBuilderState>();
  final _repo = AppRepository.instance;
  BandeiraCartaoCredito? _original;

  bool get _isEdicao => widget.bandeiraId != null;

  @override
  void initState() {
    super.initState();
    if (_isEdicao) _original = _repo.bandeiraPorId(widget.bandeiraId!);
  }

  @override
  Widget build(BuildContext context) {
    if (_isEdicao && _original == null) {
      return const AppScaffold(
        title: 'Bandeira não encontrada',
        body: EmptyState(mensagem: 'A bandeira solicitada não existe.'),
      );
    }
    return AppScaffold(
      title: _isEdicao ? 'Editar bandeira' : 'Nova bandeira',
      body: FormBuilder(
        key: _formKey,
        autovalidateMode: AutovalidateMode.onUserInteraction,
        initialValue: {
          'nome': _original?.nome ?? '',
          'taxa': formatarParaCampo(_original?.taxa ?? 0),
        },
        child: CenteredListView(
          children: [
            SectionCard(
              title: 'Dados da bandeira',
              child: Column(
                spacing: AppSpacing.md,
                children: [
                  const AppTextField(
                    name: 'nome',
                    label: 'Nome da bandeira',
                    icon: Icons.contactless_outlined,
                  ),
                  const AppNumberField(
                    name: 'taxa',
                    label: 'Taxa',
                    icon: Icons.percent,
                    suffixText: '%',
                    min: 0,
                  ),
                  Text(
                    'A taxa é aplicada sobre cada parcela das vendas no '
                    'cartão e vai para o campo "Taxas e impostos" do '
                    'lançamento. Alterá-la não muda lançamentos já criados.',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            FilledButton.icon(
              onPressed: _salvar,
              icon: const Icon(Icons.check),
              label: const Text('Salvar bandeira'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _salvar() async {
    if (_formKey.currentState?.saveAndValidate() != true) return;
    final valores = _formKey.currentState!.value;
    final nome = (valores['nome'] as String).trim();
    final taxa = (valores['taxa'] as num?)?.toDouble() ?? 0;
    final diasParaRecebimento = 1;

    if (taxa > 100) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('A taxa não pode passar de 100%.')),
      );
      return;
    }

    final repetida = _repo.bandeirasCartaoCredito.any(
      (b) =>
          b.id != _original?.id && b.nome.toLowerCase() == nome.toLowerCase(),
    );

    if (repetida) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Já existe uma bandeira com esse nome.')),
      );
      return;
    }
    await _repo.salvarBandeiraCartao(
      BandeiraCartaoCredito(
        id: _original?.id ?? _repo.novoId(),
        nome: nome,
        taxa: taxa,
        diasParaRecebimento: diasParaRecebimento,
      ),
    );
    if (mounted) context.pop();
  }
}
