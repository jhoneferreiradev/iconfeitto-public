import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import 'app_navigation.dart';

/// AppBar + corpo padronizados para todas as telas do app.
///
/// Dentro do [AppShell], nas telas principais mostra o botão de menu (celular)
/// e, nas demais, o botão voltar.
class AppScaffold extends StatelessWidget {
  final String title;
  final Widget body;
  final List<Widget>? actions;
  final Widget? floatingActionButton;

  const AppScaffold({
    super.key,
    required this.title,
    required this.body,
    this.actions,
    this.floatingActionButton,
  });

  @override
  Widget build(BuildContext context) {
    final shell = AppShellScope.maybeOf(context);
    final mostrarMenu =
        shell != null && shell.ehRaiz && !shell.menuLateralVisivel;
    final voltarParaInicio =
        shell != null && shell.ehRaiz && shell.uri.path != '/';

    final scaffold = Scaffold(
      appBar: AppBar(
        title: Text(title),
        actions: actions,
        leading: mostrarMenu
            ? IconButton(
                tooltip: 'Abrir menu',
                icon: const Icon(Icons.menu),
                onPressed: shell.abrirMenu,
              )
            : null,
        automaticallyImplyLeading: !(shell != null && shell.ehRaiz),
      ),
      body: SafeArea(child: body),
      floatingActionButton: floatingActionButton,
    );

    if (!voltarParaInicio) return scaffold;
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) context.go('/');
      },
      child: scaffold,
    );
  }
}
