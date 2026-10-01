import 'package:material_ui/material_ui.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/app_searchable_dropdown.dart';
import '../../../shared/models/produto.dart';

/// Casca visual comum das linhas de item (ficha técnica e embalagem):
/// seletor de produto + botão remover, conteúdo extra e subtotal.
class ItemFichaCard extends StatelessWidget {
  final Widget seletor;
  final VoidCallback onRemover;
  final double custoLinha;
  final List<Widget> children;

  const ItemFichaCard({
    super.key,
    required this.seletor,
    required this.onRemover,
    required this.custoLinha,
    this.children = const [],
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(AppSpacing.borderRadiusMd),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: AppSpacing.sm,
        children: [
          Row(
            children: [
              Expanded(child: seletor),
              IconButton(
                icon: const Icon(Icons.close),
                tooltip: 'Remover item',
                onPressed: onRemover,
              ),
            ],
          ),
          ...children,
          Align(
            alignment: Alignment.centerRight,
            child: Text(
              'Subtotal: ${custoLinha.toCurrency()}',
              style: theme.textTheme.bodySmall,
            ),
          ),
        ],
      ),
    );
  }
}

/// Dropdown pesquisável de produtos, ordenado por nome. Trabalha com ids.
class SeletorDeProduto extends StatelessWidget {
  final String label;
  final List<Produto> produtos;
  final String? selecionadoId;
  final ValueChanged<String> onChanged;

  const SeletorDeProduto({
    super.key,
    required this.label,
    required this.produtos,
    required this.selecionadoId,
    required this.onChanged,
  });

  Produto _porId(String id) => produtos.firstWhere((p) => p.id == id);

  @override
  Widget build(BuildContext context) {
    final valido = produtos.any((p) => p.id == selecionadoId);

    return AppSearchableDropdown<String>(
      label: label,
      icon: Icons.egg_alt_outlined,
      value: valido ? selecionadoId : null,
      items: produtos.map((p) => p.id).toList(),
      itemBuilder: (id) => _porId(id).nome,
      itemComparator: (a, b) => _porId(a).nome.compareTo(_porId(b).nome),
      onChanged: (novoId) {
        if (novoId != null) onChanged(novoId);
      },
    );
  }
}
