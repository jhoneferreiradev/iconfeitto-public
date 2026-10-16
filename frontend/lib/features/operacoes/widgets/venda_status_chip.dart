import 'package:material_ui/material_ui.dart';

import '../../../shared/models/operacao.dart';

/// Selo colorido com o andamento da venda.
class VendaStatusChip extends StatelessWidget {
  final StatusVenda status;

  const VendaStatusChip({super.key, required this.status});

  static Color cor(BuildContext context, StatusVenda status) {
    final scheme = Theme.of(context).colorScheme;
    switch (status) {
      case StatusVenda.pedido:
        return const Color(0xFF3A86FF);
      case StatusVenda.emProducao:
        return const Color(0xFFFF9F5A);
      case StatusVenda.aguardandoRetirada:
        return const Color(0xFF7C6BD6);
      case StatusVenda.emEntrega:
        return const Color(0xFF00A6A6);
      case StatusVenda.entregue:
        return const Color(0xFF2E9E5B);
      case StatusVenda.cancelada:
        return scheme.error;
    }
  }

  @override
  Widget build(BuildContext context) {
    final cor = VendaStatusChip.cor(context, status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: cor.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        status.label,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
          color: cor,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
