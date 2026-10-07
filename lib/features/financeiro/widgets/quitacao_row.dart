import 'package:material_ui/material_ui.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/app_date_time_field.dart';
import '../../../core/widgets/app_number_field.dart';
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
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: AppSpacing.sm,
      children: [
        Row(
          spacing: AppSpacing.sm,
          children: [
            Expanded(
              child: AppDateTimeField(
                name: 'dataQuitacao_${widget.quitacao.id}',
                label: "Quitado em",
                initialValue: widget.quitacao.dataQuitacao,
                onChanged: (data) {
                  widget.quitacao.dataQuitacao = data ?? DateTime.now();
                  widget.onChanged(widget.quitacao);
                },
              ),
            ),
            Expanded(
              child: AppNumberField(
                name: 'valorQuitacao_${widget.quitacao.id}',
                label: "Valor quitado",
                initialValue: widget.quitacao.valorQuitado.toDecimal(),
                onChanged: (valor) {
                  widget.quitacao.valorQuitado = valor?.toDouble() ?? 0;
                  widget.onChanged(widget.quitacao);
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
    );
  }
}
