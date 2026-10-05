import 'package:flutter_animate/flutter_animate.dart';
import 'package:material_ui/material_ui.dart';

class EmptyState extends StatelessWidget {
  final String mensagem;
  final IconData icon;
  const EmptyState({
    super.key,
    required this.mensagem,
    this.icon = Icons.inbox_outlined,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: scheme.primaryContainer.withValues(alpha: 0.5),
                  ),
                  child: Icon(icon, size: 48, color: scheme.primary),
                )
                .animate()
                .scale(
                  begin: const Offset(0.6, 0.6),
                  duration: 500.ms,
                  curve: Curves.easeOutBack,
                )
                .fadeIn(duration: 300.ms),
            const SizedBox(height: 16),
            ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 360),
                  child: Text(
                    mensagem,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyLarge
                        ?.copyWith(color: scheme.onSurfaceVariant),
                  ),
                )
                .animate()
                .fadeIn(delay: 150.ms, duration: 400.ms)
                .slideY(
                  begin: 0.2,
                  end: 0,
                  duration: 400.ms,
                  curve: Curves.easeOut,
                ),
          ],
        ),
      ),
    );
  }
}
