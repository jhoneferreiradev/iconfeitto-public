import 'package:material_ui/material_ui.dart';

Future<bool> confirmarExclusao(
  BuildContext context, {
  required String titulo,
  required String mensagem,
}) async {
  final resultado = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(titulo),
      content: Text(mensagem),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
        FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Excluir')),
      ],
    ),
  );
  return resultado ?? false;
}
