import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/utils/formatters.dart';
import '../../../shared/data/app_repository.dart';
import '../../../shared/models/operacao.dart';
import '../../../shared/models/produto.dart';

/// Ajuste de saldo e custo médio com data (hoje ou retroativa).
Future<void> mostrarAjusteEstoque(BuildContext context, Produto produto) async {
  final repo = AppRepository.instance;
  final sigla = repo.unidadePorId(produto.unidadeEstoqueId).sigla;
  final resultado = await showDialog<_DadosAjuste>(
    context: context,
    builder: (context) => _AjusteDialog(produto: produto, sigla: sigla),
  );
  if (resultado == null || !context.mounted) return;
  await _executar(
    context,
    () => repo.ajustarEstoque(
      produto.id,
      resultado.saldo,
      resultado.custo,
      data: resultado.data,
    ),
  );
}

/// Saída de estoque para consumo próprio, com data (hoje ou retroativa).
Future<void> mostrarSaidaConsumo(BuildContext context, Produto produto) async {
  final repo = AppRepository.instance;
  final sigla = repo.unidadePorId(produto.unidadeEstoqueId).sigla;
  final resultado = await showDialog<_DadosConsumo>(
    context: context,
    builder: (context) => _ConsumoDialog(produto: produto, sigla: sigla),
  );
  if (resultado == null || !context.mounted) return;
  await _executar(
    context,
    () => repo.registrarConsumo(
      produto.id,
      resultado.quantidade,
      data: resultado.data,
    ),
  );
}

Future<void> _executar(
  BuildContext context,
  Future<void> Function() operacao,
) async {
  try {
    await operacao();
  } on SaldoEstoqueInsuficienteException catch (error) {
    if (context.mounted) _avisar(context, error.message);
  } on StateError catch (error) {
    if (context.mounted) _avisar(context, error.message);
  }
}

void _avisar(BuildContext context, String mensagem) {
  ScaffoldMessenger.of(
    context,
  ).showSnackBar(SnackBar(content: Text(mensagem)));
}

class _DadosAjuste {
  final double saldo;
  final double custo;
  final DateTime data;

  const _DadosAjuste(this.saldo, this.custo, this.data);
}

class _DadosConsumo {
  final double quantidade;
  final DateTime data;

  const _DadosConsumo(this.quantidade, this.data);
}

final _somenteNumeros = FilteringTextInputFormatter.allow(RegExp(r'[0-9,.]'));

/// Botão de data que não aceita datas futuras.
class _CampoData extends StatelessWidget {
  final DateTime data;
  final ValueChanged<DateTime> aoAlterar;

  const _CampoData({required this.data, required this.aoAlterar});

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      icon: const Icon(Icons.event_outlined),
      label: Text('Data: ${data.toFormattedDate()}'),
      onPressed: () async {
        final escolhida = await showDatePicker(
          context: context,
          initialDate: data,
          firstDate: DateTime(2000),
          lastDate: DateTime.now(),
        );
        if (escolhida != null) aoAlterar(escolhida);
      },
    );
  }
}

class _AjusteDialog extends StatefulWidget {
  final Produto produto;
  final String sigla;

  const _AjusteDialog({required this.produto, required this.sigla});

  @override
  State<_AjusteDialog> createState() => _AjusteDialogState();
}

class _AjusteDialogState extends State<_AjusteDialog> {
  late final _saldo = TextEditingController(
    text: widget.produto.saldoEstoque.toDecimal(),
  );
  late final _custo = TextEditingController(
    text: widget.produto.custoMedio.toDecimal(),
  );
  var _data = DateTime.now();
  String? _erro;

  @override
  void dispose() {
    _saldo.dispose();
    _custo.dispose();
    super.dispose();
  }

  void _aplicar() {
    final saldo = _saldo.text.toDouble();
    final custo = _custo.text.toDouble();
    if (saldo == null || custo == null || saldo < 0 || custo < 0) {
      setState(() => _erro = 'Informe um saldo e um custo válidos.');
      return;
    }
    Navigator.pop(context, _DadosAjuste(saldo, custo, _data));
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Ajustar ${widget.produto.nome}'),
      content: SizedBox(
        width: 420,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                controller: _saldo,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                inputFormatters: [_somenteNumeros],
                decoration: InputDecoration(
                  labelText: 'Saldo',
                  suffixText: widget.sigla,
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _custo,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                inputFormatters: [_somenteNumeros],
                decoration: const InputDecoration(
                  labelText: 'Custo médio',
                  prefixText: 'R\$ ',
                ),
              ),
              const SizedBox(height: 12),
              _CampoData(
                data: _data,
                aoAlterar: (data) => setState(() => _data = data),
              ),
              const SizedBox(height: 8),
              Text(
                'O ajuste define o saldo e o custo do produto na data '
                'escolhida e vale para tudo o que vier depois dela. Em datas '
                'passadas, vale ao fim do dia.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              if (_erro != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    _erro!,
                    style: TextStyle(color: Theme.of(context).colorScheme.error),
                  ),
                ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        FilledButton(onPressed: _aplicar, child: const Text('Aplicar')),
      ],
    );
  }
}

class _ConsumoDialog extends StatefulWidget {
  final Produto produto;
  final String sigla;

  const _ConsumoDialog({required this.produto, required this.sigla});

  @override
  State<_ConsumoDialog> createState() => _ConsumoDialogState();
}

class _ConsumoDialogState extends State<_ConsumoDialog> {
  final _quantidade = TextEditingController();
  var _data = DateTime.now();
  String? _erro;

  @override
  void dispose() {
    _quantidade.dispose();
    super.dispose();
  }

  void _registrar() {
    final quantidade = _quantidade.text.toDouble();
    if (quantidade == null || quantidade <= 0) {
      setState(() => _erro = 'Informe uma quantidade maior que zero.');
      return;
    }
    Navigator.pop(context, _DadosConsumo(quantidade, _data));
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Saída para consumo - ${widget.produto.nome}'),
      content: SizedBox(
        width: 420,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                controller: _quantidade,
                autofocus: true,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                inputFormatters: [_somenteNumeros],
                decoration: InputDecoration(
                  labelText: 'Quantidade',
                  suffixText: widget.sigla,
                  helperText:
                      'Saldo atual: ${widget.produto.saldoEstoque.toDecimal()} ${widget.sigla}',
                ),
              ),
              const SizedBox(height: 12),
              _CampoData(
                data: _data,
                aoAlterar: (data) => setState(() => _data = data),
              ),
              if (_erro != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    _erro!,
                    style: TextStyle(color: Theme.of(context).colorScheme.error),
                  ),
                ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        FilledButton(onPressed: _registrar, child: const Text('Registrar')),
      ],
    );
  }
}
