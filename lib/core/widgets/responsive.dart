import 'package:flutter_animate/flutter_animate.dart';
import 'package:material_ui/material_ui.dart';

/// Largura a partir da qual o menu lateral substitui a gaveta (tablet).
const double kLarguraTablet = 840;

/// Largura a partir da qual o menu lateral aparece expandido (desktop).
const double kLarguraDesktop = 1200;

/// Largura a partir da qual formulários passam a usar duas colunas.
const double kLarguraTelaGrande = 900;

/// Centraliza o conteúdo e limita sua largura em telas grandes.
class ContentWidth extends StatelessWidget {
  final Widget child;
  final double maxWidth;
  final EdgeInsetsGeometry padding;

  const ContentWidth({
    super.key,
    required this.child,
    this.maxWidth = 1280,
    this.padding = const EdgeInsets.fromLTRB(16, 16, 16, 96),
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: Padding(padding: padding, child: child),
      ),
    );
  }
}

/// Distribui os cartões em quantas colunas couberem (mínimo [minItemWidth]).
class ResponsiveCardGrid extends StatelessWidget {
  final List<Widget> children;
  final double minItemWidth;
  final double spacing;

  const ResponsiveCardGrid({
    super.key,
    required this.children,
    this.minItemWidth = 420,
    this.spacing = 12,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final largura = constraints.maxWidth;
        final colunas = ((largura + spacing) / (minItemWidth + spacing))
            .floor()
            .clamp(1, 4);
        final larguraItem = (largura - spacing * (colunas - 1)) / colunas;
        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: [
            for (var i = 0; i < children.length; i++)
              SizedBox(
                width: larguraItem,
                child: children[i],
              ).entranceAnimation(i),
          ],
        );
      },
    );
  }
}

/// Layout de formulário: coluna única no celular e duas colunas em telas
/// grandes ([secondary] vai para a direita). [footer] fica ao final.
class ResponsiveFormLayout extends StatelessWidget {
  final List<Widget> primary;
  final List<Widget> secondary;
  final Widget? footer;
  final EdgeInsetsGeometry padding;
  final int primaryFlex;
  final int secondaryFlex;
  final double singleColumnMaxWidth;

  const ResponsiveFormLayout({
    super.key,
    required this.primary,
    this.secondary = const [],
    this.footer,
    this.padding = const EdgeInsets.fromLTRB(16, 16, 16, 32),
    this.primaryFlex = 1,
    this.secondaryFlex = 1,
    this.singleColumnMaxWidth = 760,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final duasColunas =
            constraints.maxWidth >= kLarguraTelaGrande && secondary.isNotEmpty;
        final corpo = duasColunas
            ? Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: primaryFlex,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: primary,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    flex: secondaryFlex,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: secondary,
                    ),
                  ),
                ],
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [...primary, ...secondary],
              );
        final rodape = footer;
        return SingleChildScrollView(
          child: ContentWidth(
            maxWidth: duasColunas ? 1280 : singleColumnMaxWidth,
            padding: padding,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                corpo,
                if (rodape != null) ...[
                  const SizedBox(height: 8),
                  duasColunas
                      ? Align(
                          alignment: Alignment.centerRight,
                          child: SizedBox(width: 420, child: rodape),
                        )
                      : rodape,
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Animação de entrada padrão: surge com leve deslize, em cascata pelo [indice].
extension EntranceAnimation on Widget {
  Widget entranceAnimation(int indice, {Duration? duracao}) {
    final atraso = Duration(milliseconds: 45 * (indice > 12 ? 12 : indice));
    return animate()
        .fadeIn(
          duration: duracao ?? 350.ms,
          delay: atraso,
          curve: Curves.easeOut,
        )
        .slideY(
          begin: 0.08,
          end: 0,
          duration: duracao ?? 350.ms,
          delay: atraso,
          curve: Curves.easeOutCubic,
        );
  }
}

/// Lista rolável de cartões que vira grade conforme a largura disponível.
class ResponsiveCardList extends StatelessWidget {
  final int itemCount;
  final IndexedWidgetBuilder itemBuilder;
  final double minItemWidth;

  const ResponsiveCardList({
    super.key,
    required this.itemCount,
    required this.itemBuilder,
    this.minItemWidth = 420,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: ContentWidth(
        child: ResponsiveCardGrid(
          minItemWidth: minItemWidth,
          children: [
            for (var i = 0; i < itemCount; i++) itemBuilder(context, i),
          ],
        ),
      ),
    );
  }
}

/// [ListView] com conteúdo centralizado e limitado a [maxWidth]; a barra de
/// rolagem continua na borda da tela.
class CenteredListView extends StatelessWidget {
  final List<Widget> children;
  final double maxWidth;
  final double verticalPadding;

  const CenteredListView({
    super.key,
    required this.children,
    this.maxWidth = 760,
    this.verticalPadding = 16,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final horizontal = ((constraints.maxWidth - maxWidth) / 2).clamp(
          16.0,
          double.infinity,
        );
        return ListView(
          padding: EdgeInsets.fromLTRB(
            horizontal,
            verticalPadding,
            horizontal,
            verticalPadding + 16,
          ),
          children: children,
        );
      },
    );
  }
}
