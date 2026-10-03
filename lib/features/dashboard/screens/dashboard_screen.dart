import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/widgets/app_scaffold.dart';
import '../../../shared/data/app_repository.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final repo = AppRepository.instance;
    return AnimatedBuilder(
      animation: repo,
      builder: (context, _) {
        return AppScaffold(
          title: 'Visão geral',
          drawer: _buildDrawer(context),
          body: ListView(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
            children: [
              Text(
                'Acessos rápidos',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 12),
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 1.45,
                children: [
                  _QuickAccess(
                    label: 'Nova compra',
                    icon: Icons.shopping_cart_outlined,
                    onTap: () => context.push('/compras/nova'),
                  ),
                  _QuickAccess(
                    label: 'Nova venda',
                    icon: Icons.point_of_sale_outlined,
                    onTap: () => context.push('/vendas/nova'),
                  ),
                  _QuickAccess(
                    label: 'Registrar fabricação',
                    icon: Icons.factory_outlined,
                    onTap: () => context.push('/cozinha/nova'),
                  ),
                  _QuickAccess(
                    label: 'Ver estoque',
                    icon: Icons.inventory_2_outlined,
                    onTap: () => context.push('/estoque'),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Text('Resumo', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _SummaryTile(
                      label: 'Itens',
                      value: '${repo.produtos.length}',
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _SummaryTile(
                      label: 'Clientes',
                      value: '${repo.clientes.length}',
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _SummaryTile(
                      label: 'Fornecedores',
                      value: '${repo.fornecedores.length}',
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDrawer(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          const DrawerHeader(child: Text('Confeitaria Admin')),
          _drawerItem(context, 'Dashboard', Icons.dashboard_outlined, '/'),
          _drawerItem(
            context,
            'Insumos, materiais e embalagens',
            Icons.inventory_2_outlined,
            '/itens/insumos',
          ),
          _drawerItem(
            context,
            'Produtos e preparos',
            Icons.cake_outlined,
            '/itens/produtos',
          ),
          _drawerItem(
            context,
            'Compras',
            Icons.shopping_cart_outlined,
            '/compras',
          ),
          _drawerItem(
            context,
            'Vendas',
            Icons.point_of_sale_outlined,
            '/vendas',
          ),
          _drawerItem(context, 'Cozinha', Icons.factory_outlined, '/cozinha'),
          _drawerItem(
            context,
            'Estoque',
            Icons.inventory_2_outlined,
            '/estoque',
          ),
          _drawerItem(context, 'Clientes', Icons.person_outline, '/clientes'),
          _drawerItem(
            context,
            'Fornecedores',
            Icons.business_outlined,
            '/fornecedores',
          ),
          _drawerItem(context, 'Unidades', Icons.straighten, '/unidades'),
          const Divider(),
          _drawerItem(
            context,
            'Empresa',
            Icons.storefront_outlined,
            '/empresa',
          ),
        ],
      ),
    );
  }

  Widget _drawerItem(
    BuildContext context,
    String label,
    IconData icon,
    String route,
  ) {
    return ListTile(
      leading: Icon(icon),
      title: Text(label),
      onTap: () {
        Navigator.pop(context);
        context.push(route);
      },
    );
  }
}

class _QuickAccess extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  const _QuickAccess({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 30),
              const SizedBox(height: 8),
              Text(label, textAlign: TextAlign.center),
            ],
          ),
        ),
      ),
    );
  }
}

class _SummaryTile extends StatelessWidget {
  final String label;
  final String value;

  const _SummaryTile({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Text(value, style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 4),
            Text(label, textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}
