import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';

import '../../../core/utils/formatters.dart';
import '../../../core/widgets/responsive.dart';

const List<String> _mesesCurtos = [
  'jan',
  'fev',
  'mar',
  'abr',
  'mai',
  'jun',
  'jul',
  'ago',
  'set',
  'out',
  'nov',
  'dez',
];

const List<String> _mesesLongos = [
  'janeiro',
  'fevereiro',
  'março',
  'abril',
  'maio',
  'junho',
  'julho',
  'agosto',
  'setembro',
  'outubro',
  'novembro',
  'dezembro',
];

const List<String> _diasSemana = [
  'segunda-feira',
  'terça-feira',
  'quarta-feira',
  'quinta-feira',
  'sexta-feira',
  'sábado',
  'domingo',
];

String mesCurto(DateTime data) => _mesesCurtos[data.month - 1];

String mesLongo(DateTime data) => _mesesLongos[data.month - 1];

String dataPorExtenso(DateTime data) =>
    '${_diasSemana[data.weekday - 1]}, ${data.day} de ${mesLongo(data)}';

String diaMes(DateTime data) =>
    '${data.day.toString().padLeft(2, '0')}/${data.month.toString().padLeft(2, '0')}';

String saudacao(DateTime agora) {
  if (agora.hour < 12) return 'Bom dia';
  if (agora.hour < 18) return 'Boa tarde';
  return 'Boa noite';
}

/// Valores curtos para os eixos dos gráficos (ex.: 1,2 mil).
String moedaCompacta(double valor) {
  final abs = valor.abs();
  if (abs >= 1000000) return '${_umaCasa(valor / 1000000)} mi';
  if (abs >= 1000) return '${_umaCasa(valor / 1000)} mil';
  return valor.round().toString();
}

String _umaCasa(double v) {
  final texto = v.toStringAsFixed(1).replaceAll('.', ',');
  return texto.endsWith(',0') ? texto.substring(0, texto.length - 2) : texto;
}

TextStyle? estiloEixo(BuildContext context) =>
    Theme.of(context).textTheme.labelSmall
        ?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant);

/// Teto do eixo Y em quatro intervalos "redondos" (1, 2, 2,5, 5 ou 10 x 10^n).
double tetoDoEixo(double maximo) {
  if (maximo <= 0) return 100;
  final bruto = maximo * 1.1 / 4;
  final ordem = math.pow(10, (math.log(bruto) / math.ln10).floor()).toDouble();
  final normalizado = bruto / ordem;
  final passo = switch (normalizado) {
    <= 1 => 1.0,
    <= 2 => 2.0,
    <= 2.5 => 2.5,
    <= 5 => 5.0,
    _ => 10.0,
  };
  return passo * ordem * 4;
}

/// Quadradinho colorido + texto, para legendas de gráficos.
class Legenda extends StatelessWidget {
  final Color cor;
  final String texto;

  const Legenda({super.key, required this.cor, required this.texto});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: cor,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 6),
        Text(texto, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}

/// Cartão base dos blocos do dashboard, com título e subtítulo.
class DashCard extends StatelessWidget {
  final String titulo;
  final String? subtitulo;
  final Widget? acao;
  final Widget child;

  const DashCard({
    super.key,
    required this.titulo,
    this.subtitulo,
    this.acao,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        titulo,
                        style: tema.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      if (subtitulo != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          subtitulo!,
                          style: tema.textTheme.bodySmall?.copyWith(
                            color: tema.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                ?acao,
              ],
            ),
            const SizedBox(height: 16),
            child,
          ],
        ),
      ),
    );
  }
}

/// Mensagem exibida no lugar de um gráfico sem dados.
class SemDados extends StatelessWidget {
  final String mensagem;
  final IconData icon;
  final double altura;

  const SemDados({
    super.key,
    required this.mensagem,
    this.icon = Icons.insights_outlined,
    this.altura = 200,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return SizedBox(
      height: altura,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 40, color: scheme.outline),
            const SizedBox(height: 8),
            Text(
              mensagem,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium
                  ?.copyWith(color: scheme.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }
}

/// Número que "sobe" até o valor final quando aparece ou muda.
class ValorAnimado extends StatelessWidget {
  final double valor;
  final String Function(double valor) formatar;
  final TextStyle? style;

  const ValorAnimado({
    super.key,
    required this.valor,
    this.formatar = formatarMoeda,
    this.style,
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: valor),
      duration: const Duration(milliseconds: 900),
      curve: Curves.easeOutCubic,
      builder: (context, v, _) => FittedBox(
        fit: BoxFit.scaleDown,
        alignment: Alignment.centerLeft,
        child: Text(formatar(v), style: style, maxLines: 1),
      ),
    );
  }
}

/// Executa a animação de crescimento de um gráfico na primeira exibição.
class CrescimentoAnimado extends StatelessWidget {
  final Widget Function(BuildContext context, double progresso) builder;
  final Duration duracao;

  const CrescimentoAnimado({
    super.key,
    required this.builder,
    this.duracao = const Duration(milliseconds: 1000),
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: duracao,
      curve: Curves.easeOutCubic,
      builder: (context, t, _) => builder(context, t),
    );
  }
}

/// Distribui blocos em duas colunas (proporção [flexEsquerda]:[flexDireita])
/// em telas largas e em coluna única nas demais.
class LinhaResponsiva extends StatelessWidget {
  final Widget esquerda;
  final Widget direita;
  final int flexEsquerda;
  final int flexDireita;

  const LinhaResponsiva({
    super.key,
    required this.esquerda,
    required this.direita,
    this.flexEsquerda = 3,
    this.flexDireita = 2,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < kLarguraTelaGrande - 100) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [esquerda, const SizedBox(height: 16), direita],
          );
        }
        return IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(flex: flexEsquerda, child: esquerda),
              const SizedBox(width: 16),
              Expanded(flex: flexDireita, child: direita),
            ],
          ),
        );
      },
    );
  }
}
