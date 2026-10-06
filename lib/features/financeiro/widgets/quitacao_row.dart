import 'package:material_ui/material_ui.dart';

import '../../../core/utils/formatters.dart';
import '../../../shared/models/lancamento_financeiro.dart';
import 'quitacao_card.dart';

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
  late final TextEditingController _dataQuitacaoControler;
  late final TextEditingController _valorQuitacaoController;

  @override
  void initState() {
    super.initState();
    _dataQuitacaoControler = TextEditingController(
      text: widget.quitacao.dataQuitacao.toFormattedDate(),
    );
    _valorQuitacaoController = TextEditingController(
      text: widget.quitacao.valorQuitado.toDecimal(),
    );
  }

  @override
  void dispose() {
    _dataQuitacaoControler.dispose();
    _valorQuitacaoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return QuitacaoCard(
      seletor: TextField(
        controller: _dataQuitacaoControler,
        decoration: const InputDecoration(labelText: 'Data de quitação'),
        onChanged: (value) {
          final novaData = DateTime.tryParse(value);
          if (novaData != null) {
            widget.quitacao.dataQuitacao = novaData;
            widget.onChanged(widget.quitacao);
          }
        },
      ),
      onRemover: widget.onRemover,
      custoLinha: widget.quitacao.valorQuitado,
    );
  }
}
