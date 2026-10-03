import 'package:material_ui/material_ui.dart';

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
            for (final filho in children)
              SizedBox(width: larguraItem, child: filho),
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
