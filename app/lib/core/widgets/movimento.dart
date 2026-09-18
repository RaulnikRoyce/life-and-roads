import 'package:flutter/material.dart';

/// Durações do app. Curtas de propósito: movimento aqui confirma ação e
/// dá hierarquia, não enfeita. Nada em loop (bateria e testes).
class Movimento {
  Movimento._();

  static const curto = Duration(milliseconds: 180);
  static const medio = Duration(milliseconds: 320);
  static const longo = Duration(milliseconds: 480);
  static const curva = Curves.easeOutCubic;
}

/// Conteúdo entra com fade e um leve deslize para cima. Uma vez, ao montar
/// ou quando [chave] muda (troca de aba, dado novo).
class EntradaSuave extends StatelessWidget {
  const EntradaSuave({
    super.key,
    required this.child,
    this.chave,
    this.deslocamento = 12,
    this.duracao = Movimento.medio,
    this.atraso = Duration.zero,
  });

  final Widget child;
  final Object? chave;
  final double deslocamento;
  final Duration duracao;

  /// Espera antes de entrar. Itens em cascata usam 40 a 60 ms cada.
  final Duration atraso;

  @override
  Widget build(BuildContext context) {
    final total = duracao + atraso;
    final inicio = atraso.inMilliseconds / total.inMilliseconds;
    return TweenAnimationBuilder<double>(
      key: ValueKey(chave),
      tween: Tween(begin: 0, end: 1),
      duration: total,
      curve: Interval(inicio, 1, curve: Movimento.curva),
      child: child,
      builder: (context, t, filho) => Opacity(
        opacity: t,
        child: Transform.translate(
          offset: Offset(0, deslocamento * (1 - t)),
          child: filho,
        ),
      ),
    );
  }
}

/// Número que conta do valor anterior até o novo. Usado no painel da moto
/// e no resultado da viagem, onde o olho fica.
class NumeroAnimado extends StatelessWidget {
  const NumeroAnimado({
    super.key,
    required this.valor,
    required this.formatar,
    this.style,
    this.textAlign,
    this.duracao = Movimento.longo,
  });

  final double valor;
  final String Function(double) formatar;
  final TextStyle? style;
  final TextAlign? textAlign;
  final Duration duracao;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(end: valor),
      duration: duracao,
      curve: Movimento.curva,
      builder: (context, v, _) =>
          Text(formatar(v), style: style, textAlign: textAlign),
    );
  }
}

/// Esqueleto no lugar do spinner: blocos com a forma do que vai aparecer.
/// Um pulso só (não fica piscando), depois o conteúdo entra por cima.
class Esqueleto extends StatelessWidget {
  const Esqueleto({super.key, this.linhas = const [196, 22, 16, 16]});

  /// Alturas dos blocos, de cima para baixo.
  final List<double> linhas;

  @override
  Widget build(BuildContext context) {
    final cor = Theme.of(context).colorScheme.surfaceContainerHighest;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.4, end: 0.9),
      duration: const Duration(milliseconds: 700),
      curve: Curves.easeInOut,
      builder: (context, o, filho) => Opacity(opacity: o, child: filho),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (final h in linhas) ...[
              Container(
                height: h,
                width: h < 20 ? 220 : double.infinity,
                decoration: BoxDecoration(
                  color: cor,
                  borderRadius: BorderRadius.circular(h < 20 ? 6 : 12),
                ),
              ),
              const SizedBox(height: 14),
            ],
          ],
        ),
      ),
    );
  }
}

/// Um pulso de escala quando [gatilho] muda. Sininho com aviso novo,
/// ícone de sync ao terminar.
class Pulso extends StatelessWidget {
  const Pulso({super.key, required this.gatilho, required this.child});

  final Object? gatilho;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      key: ValueKey(gatilho),
      tween: Tween(begin: 1.3, end: 1),
      duration: Movimento.medio,
      curve: Curves.elasticOut,
      child: child,
      builder: (context, s, filho) => Transform.scale(scale: s, child: filho),
    );
  }
}
