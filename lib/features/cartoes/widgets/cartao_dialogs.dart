import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/utils/formatters.dart';
import '../../../shared/data/app_repository.dart';
import '../../../shared/models/cartao_credito.dart';
import '../../../shared/models/lancamento_financeiro.dart';

/// Texto de ajuda para dias de vencimento que não existem em todos os meses.
String? avisoDiaVencimento(int? dia) {
  if (dia == null || dia < 29) return null;
  return 'Em meses com menos de $dia dias (ex.: fevereiro), o vencimento '
      'será no último dia do mês.';
}

/// Cadastro rápido de cartão de crédito (usado dentro das compras).
Future<PessoaFinanceiro?> cadastrarCartaoRapido(BuildContext context) async {
  final repo = AppRepository.instance;
  final nomeController = TextEditingController();
  var diaVencimento = 10;
  var diasFechamento = 7;
  String? erro;

  final cartao = await showDialog<CartaoCredito>(
    context: context,
    builder: (context) => StatefulBuilder(
      builder: (context, setState) => AlertDialog(
        title: const Text('Novo cartão'),
        content: SizedBox(
          width: 480,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nomeController,
                  autofocus: true,
                  decoration: InputDecoration(
                    labelText: 'Nome do cartão',
                    errorText: erro,
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<int>(
                  initialValue: diaVencimento,
                  decoration: InputDecoration(
                    labelText: 'Dia de vencimento da fatura',
                    helperText: avisoDiaVencimento(diaVencimento),
                    helperMaxLines: 3,
                  ),
                  items: [
                    for (var dia = 1; dia <= 31; dia++)
                      DropdownMenuItem(value: dia, child: Text('Dia $dia')),
                  ],
                  onChanged: (dia) => setState(() => diaVencimento = dia ?? 10),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<int>(
                  initialValue: diasFechamento,
                  decoration: const InputDecoration(
                    labelText: 'Dias para fechamento (antes do vencimento)',
                  ),
                  items: [
                    for (var dias = 0; dias <= 30; dias++)
                      DropdownMenuItem(
                        value: dias,
                        child: Text(dias == 1 ? '1 dia' : '$dias dias'),
                      ),
                  ],
                  onChanged: (dias) =>
                      setState(() => diasFechamento = dias ?? 7),
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
          FilledButton(
            onPressed: () {
              final nome = nomeController.text.trim();
              if (nome.isEmpty) {
                setState(() => erro = 'Informe o nome do cartão');
                return;
              }
              if (repo.cartoesCredito.any(
                (c) => c.nome.toLowerCase() == nome.toLowerCase(),
              )) {
                setState(() => erro = 'Já existe um cartão com esse nome');
                return;
              }
              Navigator.pop(
                context,
                CartaoCredito(
                  id: repo.novoId(),
                  nome: nome,
                  diaVencimento: diaVencimento,
                  diasFechamento: diasFechamento,
                ),
              );
            },
            child: const Text('Criar'),
          ),
        ],
      ),
    ),
  );
  nomeController.dispose();
  if (cartao == null) return null;
  return repo.salvarCartaoCredito(cartao);
}

/// Cadastro rápido de bandeira de cartão (usado dentro das vendas).
Future<PessoaFinanceiro?> cadastrarBandeiraRapida(BuildContext context) async {
  final repo = AppRepository.instance;
  final nomeController = TextEditingController();
  final taxaController = TextEditingController(text: '0');
  final diasParaRecebimentoController = TextEditingController(text: '0');
  String? erroNome;
  String? erroTaxa;

  final bandeira = await showDialog<BandeiraCartaoCredito>(
    context: context,
    builder: (context) => StatefulBuilder(
      builder: (context, setState) => AlertDialog(
        title: const Text('Nova bandeira de cartão'),
        content: SizedBox(
          width: 480,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nomeController,
                  autofocus: true,
                  decoration: InputDecoration(
                    labelText: 'Nome da bandeira',
                    errorText: erroNome,
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: taxaController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[0-9,]')),
                  ],
                  decoration: InputDecoration(
                    labelText: 'Taxa',
                    suffixText: '%',
                    errorText: erroTaxa,
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: diasParaRecebimentoController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: false,
                  ),
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                  ],
                  decoration: const InputDecoration(
                    labelText: 'Dias para recebimento',
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
          FilledButton(
            onPressed: () {
              final nome = nomeController.text.trim();
              final taxa = taxaController.text.trim().toDouble();
              erroNome = null;
              erroTaxa = null;
              if (nome.isEmpty) erroNome = 'Informe o nome da bandeira';
              if (erroNome == null &&
                  repo.bandeirasCartaoCredito.any(
                    (b) => b.nome.toLowerCase() == nome.toLowerCase(),
                  )) {
                erroNome = 'Já existe uma bandeira com esse nome';
              }
              if (taxa == null || taxa < 0 || taxa > 100) {
                erroTaxa = 'Informe uma taxa entre 0 e 100';
              }
              if (erroNome != null || erroTaxa != null) {
                setState(() {});
                return;
              }
              Navigator.pop(
                context,
                BandeiraCartaoCredito(
                  id: repo.novoId(),
                  nome: nome,
                  taxa: taxa!,
                  diasParaRecebimento: int.tryParse(diasParaRecebimentoController.text) ?? 0,
                ),
              );
            },
            child: const Text('Criar'),
          ),
        ],
      ),
    ),
  );
  nomeController.dispose();
  taxaController.dispose();
  if (bandeira == null) return null;
  return repo.salvarBandeiraCartao(bandeira);
}
