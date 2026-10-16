import 'package:material_ui/material_ui.dart';

import '../../../core/utils/formatters.dart';
import '../../../shared/models/forma_pagamento.dart';
import '../../../shared/models/lancamento_financeiro.dart';
import '../data/financeiro_filtro.dart';

/// Barra de filtros da análise financeira: período, origem, forma de
/// pagamento, situação e pessoa.
class FinanceiroFiltroBar extends StatelessWidget {
  final FiltroFinanceiro filtro;
  final List<PessoaFinanceiro> pessoas;
  final ValueChanged<FiltroFinanceiro> aoAlterar;

  const FinanceiroFiltroBar({
    super.key,
    required this.filtro,
    required this.pessoas,
    required this.aoAlterar,
  });

  static const _rotulosOrigem = {
    TipoOperacaoOrigem.venda: 'Vendas',
    TipoOperacaoOrigem.compra: 'Compras',
    TipoOperacaoOrigem.avulso: 'Lançamentos avulsos',
  };

  Future<void> _escolherPeriodo(BuildContext context) async {
    final atual = filtro.intervalo(DateTime.now());
    final escolhido = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      initialDateRange: DateTimeRange(start: atual.inicio, end: atual.fim),
    );
    if (escolhido == null) return;
    aoAlterar(
      filtro.copyWith(
        periodo: PeriodoFinanceiro.personalizado,
        inicioPersonalizado: escolhido.start,
        fimPersonalizado: escolhido.end,
      ),
    );
  }

  Widget _dropdown<T>({
    required String rotulo,
    required T? valor,
    required List<(T?, String)> itens,
    required ValueChanged<T?> aoSelecionar,
  }) {
    return SizedBox(
      width: 220,
      child: DropdownButtonFormField<T?>(
        key: ValueKey('$rotulo-$valor'),
        initialValue: valor,
        isExpanded: true,
        decoration: InputDecoration(
          labelText: rotulo,
          isDense: true,
          border: const OutlineInputBorder(),
        ),
        items: [
          for (final item in itens)
            DropdownMenuItem<T?>(
              value: item.$1,
              child: Text(item.$2, overflow: TextOverflow.ellipsis),
            ),
        ],
        onChanged: aoSelecionar,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final intervalo = filtro.intervalo(DateTime.now());
    final pessoasOrdenadas = [...pessoas]
      ..sort((a, b) {
        final porTipo = a.tipoPessoaFinanceiro.label.compareTo(
          b.tipoPessoaFinanceiro.label,
        );
        return porTipo != 0 ? porTipo : a.nome.compareTo(b.nome);
      });

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.filter_alt_outlined,
                  color: tema.colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Filtros',
                    style: tema.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                if (filtro.alterado)
                  TextButton.icon(
                    onPressed: () => aoAlterar(const FiltroFinanceiro()),
                    icon: const Icon(Icons.filter_alt_off_outlined),
                    label: const Text('Limpar'),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final periodo in PeriodoFinanceiro.values)
                  ChoiceChip(
                    label: Text(periodo.label),
                    selected: filtro.periodo == periodo,
                    avatar: periodo == PeriodoFinanceiro.personalizado
                        ? const Icon(Icons.date_range_outlined, size: 18)
                        : null,
                    onSelected: (_) =>
                        periodo == PeriodoFinanceiro.personalizado
                        ? _escolherPeriodo(context)
                        : aoAlterar(filtro.copyWith(periodo: periodo)),
                  ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              'Período: ${intervalo.inicio.toFormattedDate()} a '
              '${intervalo.fim.toFormattedDate()}',
              style: tema.textTheme.bodySmall?.copyWith(
                color: tema.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                _dropdown<TipoOperacaoOrigem>(
                  rotulo: 'Origem',
                  valor: filtro.origem,
                  itens: [
                    (null, 'Todas'),
                    for (final entrada in _rotulosOrigem.entries)
                      (entrada.key, entrada.value),
                  ],
                  aoSelecionar: (origem) =>
                      aoAlterar(filtro.copyWith(origem: origem)),
                ),
                _dropdown<FormaPagamento>(
                  rotulo: 'Forma de pagamento',
                  valor: filtro.forma,
                  itens: [
                    (null, 'Todas'),
                    for (final forma in FormaPagamento.values)
                      (forma, forma.label),
                  ],
                  aoSelecionar: (forma) =>
                      aoAlterar(filtro.copyWith(forma: forma)),
                ),
                // _dropdown<SituacaoFinanceira>(
                //   rotulo: 'Situação (previsto)',
                //   valor: filtro.situacao,
                //   itens: [
                //     for (final situacao in SituacaoFinanceira.values)
                //       (situacao, situacao.label),
                //   ],
                //   aoSelecionar: (situacao) => aoAlterar(
                //     filtro.copyWith(
                //       situacao: situacao ?? SituacaoFinanceira.todas,
                //     ),
                //   ),
                // ),
                _dropdown<PessoaFinanceiro>(
                  rotulo: 'Pessoa',
                  valor: filtro.pessoa,
                  itens: [
                    (null, 'Todas'),
                    for (final pessoa in pessoasOrdenadas)
                      (
                        pessoa,
                        '${pessoa.tipoPessoaFinanceiro.label} :: ${pessoa.nome}',
                      ),
                  ],
                  aoSelecionar: (pessoa) =>
                      aoAlterar(filtro.copyWith(pessoa: pessoa)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
