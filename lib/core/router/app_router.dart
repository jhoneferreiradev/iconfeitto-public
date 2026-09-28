import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../features/clientes/screens/cliente_form_screen.dart';
import '../../features/clientes/screens/cliente_list_screen.dart';
import '../../features/cozinha/screens/cozinha_form_screen.dart';
import '../../features/cozinha/screens/cozinha_list_screen.dart';
import '../../features/dashboard/screens/dashboard_screen.dart';
import '../../features/empresa/screens/empresa_form_screen.dart';
import '../../features/estoque/screens/estoque_screen.dart';
import '../../features/fornecedores/screens/fornecedor_form_screen.dart';
import '../../features/fornecedores/screens/fornecedor_list_screen.dart';
import '../../features/operacoes/screens/operacao_screens.dart';
import '../../features/produtos/screens/produto_form_screen.dart';
import '../../features/produtos/screens/produto_list_screen.dart';
import '../../features/unidades/screens/unidade_form_screen.dart';
import '../../features/unidades/screens/unidade_list_screen.dart';
import '../widgets/app_scaffold.dart';
import '../widgets/empty_state.dart';

final GoRouter appRouter = GoRouter(
  initialLocation: '/',
  errorBuilder: (context, state) => AppScaffold(
    title: 'Página não encontrada',
    body: EmptyState(
      mensagem: 'Não foi possível encontrar "${state.uri}".',
      icon: Icons.error_outline,
    ),
  ),
  routes: [
    GoRoute(path: '/', builder: (context, state) => const DashboardScreen()),
    GoRoute(
      path: '/clientes',
      builder: (context, state) => const ClienteListScreen(),
    ),
    GoRoute(
      path: '/clientes/novo',
      builder: (context, state) => const ClienteFormScreen(),
    ),
    GoRoute(
      path: '/clientes/:id/editar',
      builder: (context, state) =>
          ClienteFormScreen(clienteId: state.pathParameters['id']),
    ),
    GoRoute(
      path: '/produtos',
      builder: (context, state) => const ProdutoListScreen(),
    ),
    GoRoute(
      path: '/produtos/novo',
      builder: (context, state) =>
          const ProdutoFormScreen(key: ValueKey('produto-novo')),
    ),
    GoRoute(
      path: '/produtos/:id/editar',
      builder: (context, state) => ProdutoFormScreen(
        key: ValueKey('produto-${state.pathParameters['id']}'),
        produtoId: state.pathParameters['id'],
      ),
    ),
    GoRoute(
      path: '/unidades',
      builder: (context, state) => const UnidadeListScreen(),
    ),
    GoRoute(
      path: '/unidades/nova',
      builder: (context, state) => const UnidadeFormScreen(),
    ),
    GoRoute(
      path: '/unidades/:id/editar',
      builder: (context, state) =>
          UnidadeFormScreen(unidadeId: state.pathParameters['id']),
    ),
    GoRoute(
      path: '/fornecedores',
      builder: (context, state) => const FornecedorListScreen(),
    ),
    GoRoute(
      path: '/fornecedores/novo',
      builder: (context, state) => const FornecedorFormScreen(),
    ),
    GoRoute(
      path: '/fornecedores/:id/editar',
      builder: (context, state) =>
          FornecedorFormScreen(fornecedorId: state.pathParameters['id']),
    ),
    GoRoute(
      path: '/compras',
      builder: (context, state) =>
          const OperacaoListScreen(tipo: OperacaoTipo.compra()),
    ),
    GoRoute(
      path: '/compras/nova',
      builder: (context, state) =>
          const OperacaoFormScreen(tipo: OperacaoTipo.compra()),
    ),
    GoRoute(
      path: '/vendas',
      builder: (context, state) =>
          const OperacaoListScreen(tipo: OperacaoTipo.venda()),
    ),
    GoRoute(
      path: '/vendas/nova',
      builder: (context, state) =>
          const OperacaoFormScreen(tipo: OperacaoTipo.venda()),
    ),
    GoRoute(
      path: '/cozinha',
      builder: (context, state) => const CozinhaListScreen(),
    ),
    GoRoute(
      path: '/cozinha/nova',
      builder: (context, state) => const CozinhaFormScreen(),
    ),
    GoRoute(
      path: '/estoque',
      builder: (context, state) => const EstoqueScreen(),
    ),
    GoRoute(
      path: '/empresa',
      builder: (context, state) => const EmpresaFormScreen(),
    ),
  ],
);
