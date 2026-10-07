import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import 'responsive.dart';

/// Item de navegação principal (menu lateral, gaveta e barra inferior).
class AppDestino {
  final String label;
  final String? labelCurto;
  final IconData icon;
  final IconData selectedIcon;
  final String route;
  final bool Function(Uri uri) ativo;

  const AppDestino({
    required this.label,
    this.labelCurto,
    required this.icon,
    required this.selectedIcon,
    required this.route,
    required this.ativo,
  });
}

class AppGrupoNavegacao {
  final String? titulo;
  final List<AppDestino> destinos;

  const AppGrupoNavegacao(this.titulo, this.destinos);
}

bool _prefixo(Uri uri, String prefixo) =>
    uri.path == prefixo || uri.path.startsWith('$prefixo/');

bool _doEstoque(Uri uri) => uri.queryParameters['grupo'] == 'estoque';

final AppDestino destinoInicio = AppDestino(
  label: 'Dashboard',
  labelCurto: 'Início',
  icon: Icons.space_dashboard_outlined,
  selectedIcon: Icons.space_dashboard,
  route: '/',
  ativo: (uri) => uri.path == '/',
);

final AppDestino destinoVendas = AppDestino(
  label: 'Vendas',
  icon: Icons.point_of_sale_outlined,
  selectedIcon: Icons.point_of_sale,
  route: '/vendas',
  ativo: (uri) => _prefixo(uri, '/vendas'),
);

final AppDestino destinoCozinha = AppDestino(
  label: 'Fabricação',
  icon: Icons.soup_kitchen_outlined,
  selectedIcon: Icons.soup_kitchen,
  route: '/cozinha',
  ativo: (uri) => _prefixo(uri, '/cozinha'),
);

final AppDestino destinoEstoque = AppDestino(
  label: 'Estoque',
  icon: Icons.warehouse_outlined,
  selectedIcon: Icons.warehouse,
  route: '/estoque',
  ativo: (uri) => _prefixo(uri, '/estoque'),
);

final List<AppGrupoNavegacao> gruposNavegacao = [
  AppGrupoNavegacao(null, [destinoInicio]),
  AppGrupoNavegacao('Operações', [
    AppDestino(
      label: 'Compras',
      icon: Icons.shopping_cart_outlined,
      selectedIcon: Icons.shopping_cart,
      route: '/compras',
      ativo: (uri) => _prefixo(uri, '/compras'),
    ),
    destinoVendas,
    destinoCozinha,
    destinoEstoque,
  ]),



  AppGrupoNavegacao('Financeiro', [
    AppDestino(
      label: 'Lançamentos',
      icon: Icons.attach_money_outlined,
      selectedIcon: Icons.attach_money,
      route: '/financeiro/lancamentos',
      ativo: (uri) => _prefixo(uri, '/financeiro/lancamentos'),
    ),
    AppDestino(
      label: 'Cartões de crédito',
      icon: Icons.credit_card_outlined,
      selectedIcon: Icons.credit_card,
      route: '/cartoes',
      ativo: (uri) => _prefixo(uri, '/cartoes'),
    ),
    AppDestino(
      label: 'Bandeiras',
      icon: Icons.contactless_outlined,
      selectedIcon: Icons.contactless,
      route: '/bandeiras',
      ativo: (uri) => _prefixo(uri, '/bandeiras'),
    ),
  ]),

  AppGrupoNavegacao('Cadastros', [
    AppDestino(
      label: 'Insumos e embalagens',
      icon: Icons.egg_outlined,
      selectedIcon: Icons.egg,
      route: '/itens/insumos',
      ativo: (uri) =>
          _prefixo(uri, '/itens/insumos') ||
          (_prefixo(uri, '/produtos') && _doEstoque(uri)),
    ),
    AppDestino(
      label: 'Produtos e preparos',
      icon: Icons.cake_outlined,
      selectedIcon: Icons.cake,
      route: '/itens/produtos',
      ativo: (uri) =>
          _prefixo(uri, '/itens/produtos') ||
          (_prefixo(uri, '/produtos') && !_doEstoque(uri)),
    ),
    AppDestino(
      label: 'Clientes',
      icon: Icons.people_outline,
      selectedIcon: Icons.people,
      route: '/clientes',
      ativo: (uri) => _prefixo(uri, '/clientes'),
    ),
    AppDestino(
      label: 'Fornecedores',
      icon: Icons.local_shipping_outlined,
      selectedIcon: Icons.local_shipping,
      route: '/fornecedores',
      ativo: (uri) => _prefixo(uri, '/fornecedores'),
    ),
    AppDestino(
      label: 'Unidades de medida',
      icon: Icons.straighten_outlined,
      selectedIcon: Icons.straighten,
      route: '/unidades',
      ativo: (uri) => _prefixo(uri, '/unidades'),
    ),
  ]),
  AppGrupoNavegacao('Ajustes', [
    AppDestino(
      label: 'Minha empresa',
      icon: Icons.storefront_outlined,
      selectedIcon: Icons.storefront,
      route: '/empresa',
      ativo: (uri) => _prefixo(uri, '/empresa'),
    ),
  ]),
];

/// Destinos exibidos na barra inferior do celular (o restante fica no menu).
final List<AppDestino> destinosBarraInferior = [
  destinoInicio,
  destinoVendas,
  destinoCozinha,
  destinoEstoque,
];

/// Rotas "raiz" de cada seção: nelas o menu é exibido no lugar do botão voltar.
const List<String> _rotasRaiz = [
  '/',
  '/compras',
  '/vendas',
  '/cozinha',
  '/estoque',
  '/clientes',
  '/fornecedores',
  '/unidades',
  '/cartoes',
  '/bandeiras',
  '/empresa',
  '/produtos',
  '/itens/insumos',
  '/itens/produtos',
  '/financeiro/lancamentos',
];

bool ehRotaRaiz(Uri uri) => _rotasRaiz.contains(uri.path);

/// Informações do layout compartilhadas com as telas abaixo do [AppShell].
class AppShellScope extends InheritedWidget {
  final bool menuLateralVisivel;
  final Uri uri;
  final VoidCallback abrirMenu;

  const AppShellScope({
    super.key,
    required this.menuLateralVisivel,
    required this.uri,
    required this.abrirMenu,
    required super.child,
  });

  static AppShellScope? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<AppShellScope>();

  bool get ehRaiz => ehRotaRaiz(uri);

  @override
  bool updateShouldNotify(AppShellScope old) =>
      menuLateralVisivel != old.menuLateralVisivel || uri != old.uri;
}

/// Estrutura adaptável: menu lateral (tablet/desktop) ou gaveta + barra
/// inferior (celular).
class AppShell extends StatefulWidget {
  final Uri uri;
  final Widget child;

  const AppShell({super.key, required this.uri, required this.child});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();

  void _abrirMenu() => _scaffoldKey.currentState?.openDrawer();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final largura = constraints.maxWidth;
        final lateral = largura >= kLarguraTablet;
        final expandido = largura >= kLarguraDesktop;
        final scope = AppShellScope(
          menuLateralVisivel: lateral,
          uri: widget.uri,
          abrirMenu: _abrirMenu,
          child: widget.child,
        );

        if (lateral) {
          return Row(
            children: [
              _MenuLateral(uri: widget.uri, expandido: expandido),
              Expanded(child: scope),
            ],
          );
        }

        final mostrarBarra = ehRotaRaiz(widget.uri);
        return Scaffold(
          key: _scaffoldKey,
          drawer: Drawer(
            child: SafeArea(
              child: _ListaNavegacao(
                uri: widget.uri,
                expandido: true,
                aoNavegar: () => Navigator.of(context).pop(),
              ),
            ),
          ),
          body: scope,
          bottomNavigationBar: AnimatedSize(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOutCubic,
            alignment: Alignment.topCenter,
            child: mostrarBarra
                ? _BarraInferior(uri: widget.uri, abrirMenu: _abrirMenu)
                : const SizedBox(width: double.infinity),
          ),
        );
      },
    );
  }
}

class _BarraInferior extends StatelessWidget {
  final Uri uri;
  final VoidCallback abrirMenu;

  const _BarraInferior({required this.uri, required this.abrirMenu});

  @override
  Widget build(BuildContext context) {
    final indice = destinosBarraInferior.indexWhere((d) => d.ativo(uri));
    return NavigationBar(
      selectedIndex: indice < 0 ? destinosBarraInferior.length : indice,
      labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
      onDestinationSelected: (i) {
        if (i == destinosBarraInferior.length) {
          abrirMenu();
        } else {
          context.go(destinosBarraInferior[i].route);
        }
      },
      destinations: [
        for (final d in destinosBarraInferior)
          NavigationDestination(
            icon: Icon(d.icon),
            selectedIcon: Icon(d.selectedIcon),
            label: d.labelCurto ?? d.label,
          ),
        const NavigationDestination(icon: Icon(Icons.menu), label: 'Menu'),
      ],
    );
  }
}

class _MenuLateral extends StatelessWidget {
  final Uri uri;
  final bool expandido;

  const _MenuLateral({required this.uri, required this.expandido});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOutCubic,
      width: expandido ? 272 : 84,
      decoration: BoxDecoration(
        color: scheme.surface,
        border: Border(
          right: BorderSide(
            color: scheme.outlineVariant.withValues(alpha: 0.6),
          ),
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: SafeArea(
          child: _ListaNavegacao(uri: uri, expandido: expandido),
        ),
      ),
    );
  }
}

class _ListaNavegacao extends StatelessWidget {
  final Uri uri;
  final bool expandido;
  final VoidCallback? aoNavegar;

  const _ListaNavegacao({
    required this.uri,
    required this.expandido,
    this.aoNavegar,
  });

  @override
  Widget build(BuildContext context) {
    // Durante a animação do menu lateral, só mostra os textos quando cabem.
    return LayoutBuilder(
      builder: (context, constraints) =>
          _montar(context, expandido && constraints.maxWidth >= 220),
    );
  }

  Widget _montar(BuildContext context, bool expandido) {
    final scheme = Theme.of(context).colorScheme;
    var indice = 0;
    return ListView(
      padding: EdgeInsets.symmetric(
        horizontal: expandido ? 12 : 10,
        vertical: 12,
      ),
      children: [
        _Marca(expandido: expandido),
        const SizedBox(height: 12),
        for (final grupo in gruposNavegacao) ...[
          if (grupo.titulo != null)
            if (expandido)
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 16, 12, 6),
                child: Text(
                  grupo.titulo!.toUpperCase(),
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                    letterSpacing: 1.1,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              )
            else
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                child: Divider(),
              ),
          for (final destino in grupo.destinos)
            _ItemMenu(
                  destino: destino,
                  selecionado: destino.ativo(uri),
                  expandido: expandido,
                  aoNavegar: aoNavegar,
                )
                .animate()
                .fadeIn(duration: 300.ms, delay: (30 * indice++).ms)
                .slideX(begin: -0.1, end: 0, duration: 300.ms),
        ],
      ],
    );
  }
}

class _Marca extends StatelessWidget {
  final bool expandido;

  const _Marca({required this.expandido});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final logo = Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [scheme.primary, scheme.tertiary],
        ),
      ),
      child: Icon(Icons.cake, color: scheme.onPrimary),
    );
    if (!expandido) return Center(child: logo);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Row(
        children: [
          logo,
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'iConfeitto',
                  style: Theme.of(context).textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.w800),
                ),
                Text(
                  'Gestão da confeitaria',
                  style: Theme.of(context).textTheme.bodySmall
                      ?.copyWith(color: scheme.onSurfaceVariant),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ItemMenu extends StatelessWidget {
  final AppDestino destino;
  final bool selecionado;
  final bool expandido;
  final VoidCallback? aoNavegar;

  const _ItemMenu({
    required this.destino,
    required this.selecionado,
    required this.expandido,
    this.aoNavegar,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final cor = selecionado
        ? scheme.onPrimaryContainer
        : scheme.onSurfaceVariant;
    final icone = Icon(
      selecionado ? destino.selectedIcon : destino.icon,
      color: cor,
      size: 24,
    );
    final conteudo = AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOut,
      height: 48,
      padding: EdgeInsets.symmetric(horizontal: expandido ? 14 : 0),
      decoration: BoxDecoration(
        color: selecionado ? scheme.primaryContainer : Colors.transparent,
        borderRadius: BorderRadius.circular(14),
      ),
      child: expandido
          ? Row(
              children: [
                icone,
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    destino.label,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: cor,
                      fontWeight: selecionado
                          ? FontWeight.w700
                          : FontWeight.w500,
                    ),
                  ),
                ),
              ],
            )
          : Center(child: icone),
    );
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Tooltip(
        message: expandido ? '' : destino.label,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () {
            aoNavegar?.call();
            if (!selecionado) context.go(destino.route);
          },
          child: conteudo,
        ),
      ),
    );
  }
}
