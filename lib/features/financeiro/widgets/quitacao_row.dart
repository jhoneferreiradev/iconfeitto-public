import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:iconfeitto/core/widgets/app_date_time_field.dart';
import 'package:iconfeitto/core/widgets/app_number_field.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/formatters.dart';
import '../../../shared/models/lancamento_financeiro.dart';

class QuitacaoRow extends StatefulWidget {
  final Quitacao quitacao;
  final ValueChanged<Quitacao> onChanged;
  final VoidCallback onRemover;
  const QuitacaoRow({
    super.key,
    required this.quitacao,
    required this.onChanged,
    required this.onRemover,
  });

  @override
  State<QuitacaoRow> createState() => _QuitacaoRowState();
}

class _QuitacaoRowState extends State<QuitacaoRow> {
  late Map<String, dynamic> valoresIniciais;

  @override
  void initState() {
    super.initState();
    valoresIniciais = {
      'dataQuitacao': widget.quitacao.dataQuitacao,
      'valorQuitacao': widget.quitacao.valorQuitado.toDecimal(),
    };
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return FormBuilder(
      key: GlobalKey<FormBuilderState>(),
      initialValue: valoresIniciais,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest.withValues(
            alpha: 0.4,
          ),
          borderRadius: BorderRadius.circular(AppSpacing.borderRadiusMd),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: AppSpacing.sm,
          children: [
            Row(
              spacing: AppSpacing.sm,
              children: [
                Expanded(
                  child: AppDateTimeField(
                    name: 'dataQuitacao',
                    label: "Quitado em",
                    onChanged: (data) {
                      widget.quitacao.dataQuitacao = data ?? DateTime.now();
                    },
                  ),
                ),
                Expanded(
                  child: AppNumberField(
                    name: 'valorQuitacao',
                    label: "Valor quitado",
                    onChanged: (valor) {
                      widget.quitacao.valorQuitado = valor?.toDouble() ?? 0;
                    },
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  tooltip: 'Remover item',
                  onPressed: widget.onRemover,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
