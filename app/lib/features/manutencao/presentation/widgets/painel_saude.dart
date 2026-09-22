import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:life_and_roads/core/widgets/movimento.dart';
import 'package:life_and_roads/features/manutencao/domain/usecases/montar_linha_do_tempo.dart';
import 'package:life_and_roads/features/manutencao/presentation/widgets/linha_do_tempo.dart';
import 'package:life_and_roads/tema.dart';

/// A saúde da moto num anel: o vencimento mais urgente com o número grande
/// (dias ou km que faltam), o estado dele e quantos itens há em cada estado.
///
/// Recebe a lista já ordenada por [MontarLinhaDoTempo], do mais urgente ao
/// mais folgado, e usa o primeiro item.
class PainelSaude extends StatelessWidget {
  const PainelSaude({super.key, required this.itens, this.kmAtual});

  final List<ItemLinhaDoTempo> itens;
  final double? kmAtual;

  static const _anel = 132.0;
  static const _espessura = 10.0;

  /// Quanto falta para o item, na unidade dele. `ordem` guarda dias para
  /// data e km dividido por 50 para km (a régua de [MontarLinhaDoTempo], que
  /// põe os dois na mesma fila). Aqui a régua volta. Negativo = atrasado.
  static int falta(ItemLinhaDoTempo item) =>
      item.porKm ? (item.ordem * 50).round() : item.ordem.round();

  /// "dias", "km", "dias atrás" ou "km atrás".
  static String unidade(ItemLinhaDoTempo item) {
    final n = falta(item);
    final base = item.porKm ? 'km' : (n.abs() == 1 ? 'dia' : 'dias');
    return n < 0 ? '$base atrás' : base;
  }

  static String rotuloEstado(EstadoItem e) => switch (e) {
    EstadoItem.atrasado => 'atrasado',
    EstadoItem.atencao => 'atenção',
    EstadoItem.emDia => 'em dia',
  };

  /// Cor do estado para texto pequeno. No tema claro o âmbar e o verde
  /// puros ficam abaixo de 4,5:1 sobre o fundo, então o texto puxa 40 %
  /// para o onSurface. Anel, ponto e fundo da ficha seguem com a cor pura.
  static Color corTexto(ThemeData tema, Color cor) =>
      tema.brightness == Brightness.light
      ? Color.lerp(cor, tema.colorScheme.onSurface, 0.4)!
      : cor;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final proximo = itens.isEmpty ? null : itens.first;
    final cor = proximo == null
        ? Oficina.mute
        : LinhaDoTempo.corDe(proximo.estado);

    final atrasados = itens
        .where((i) => i.estado == EstadoItem.atrasado)
        .length;
    final atencao = itens.where((i) => i.estado == EstadoItem.atencao).length;
    final emDia = itens.where((i) => i.estado == EstadoItem.emDia).length;

    return EntradaSuave(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _Anel(
                fracao: proximo?.fracao ?? 0,
                cor: cor,
                child: proximo == null
                    ? const Icon(
                        Icons.build_outlined,
                        size: 34,
                        color: Oficina.mute,
                      )
                    : _Numero(item: proximo),
              ),
              const SizedBox(width: 18),
              Expanded(
                child: proximo == null
                    ? Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Sem vencimentos',
                            style: tema.textTheme.headlineSmall?.copyWith(
                              fontSize: 26,
                              height: 1.05,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Toque num grupo abaixo para começar.',
                            style: tema.textTheme.bodyMedium,
                          ),
                        ],
                      )
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'PRÓXIMO',
                            style: tema.textTheme.labelLarge?.copyWith(
                              fontSize: 11,
                              letterSpacing: 1.4,
                              color: Oficina.mute,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            proximo.titulo,
                            style: tema.textTheme.headlineSmall?.copyWith(
                              fontSize: 26,
                              height: 1.05,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            proximo.detalhe,
                            style: tema.textTheme.bodyMedium,
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Container(
                                width: 7,
                                height: 7,
                                decoration: BoxDecoration(
                                  color: cor,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                rotuloEstado(proximo.estado),
                                style: tema.textTheme.labelLarge?.copyWith(
                                  fontSize: 11,
                                  letterSpacing: 1.2,
                                  color: corTexto(tema, cor),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
              ),
            ],
          ),
          if (atrasados + atencao + emDia > 0) ...[
            const SizedBox(height: 14),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if (atrasados > 0)
                  _Ficha(
                    texto: atrasados == 1
                        ? '1 atrasado'
                        : '$atrasados atrasados',
                    cor: LinhaDoTempo.corDe(EstadoItem.atrasado),
                  ),
                if (atencao > 0)
                  _Ficha(
                    texto: '$atencao atenção',
                    cor: LinhaDoTempo.corDe(EstadoItem.atencao),
                  ),
                if (emDia > 0)
                  _Ficha(
                    texto: '$emDia em dia',
                    cor: LinhaDoTempo.corDe(EstadoItem.emDia),
                  ),
              ],
            ),
          ],
          const SizedBox(height: 12),
          Text(
            kmAtual == null
                ? 'Informe o km na Ficha para o aviso por km.'
                : 'Painel ${_milhar(kmAtual!)} km',
            style: tema.textTheme.bodyMedium?.copyWith(color: Oficina.mute),
          ),
        ],
      ),
    );
  }

  static String _milhar(num v) {
    final n = v.round().toString();
    final b = StringBuffer();
    for (var i = 0; i < n.length; i++) {
      final resto = n.length - i;
      b.write(n[i]);
      if (resto > 1 && resto % 3 == 1) b.write('.');
    }
    return b.toString();
  }
}

/// Número grande dentro do anel e a unidade embaixo.
class _Numero extends StatelessWidget {
  const _Numero({required this.item});

  final ItemLinhaDoTempo item;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        FittedBox(
          fit: BoxFit.scaleDown,
          child: NumeroAnimado(
            valor: PainelSaude.falta(item).abs().toDouble(),
            formatar: item.porKm
                ? PainelSaude._milhar
                : (v) => v.round().toString(),
            style: tema.textTheme.headlineSmall?.copyWith(
              fontSize: 40,
              height: 1,
            ),
          ),
        ),
        const SizedBox(height: 2),
        Text(
          PainelSaude.unidade(item),
          style: tema.textTheme.labelLarge?.copyWith(
            fontSize: 11,
            letterSpacing: 1.2,
            color: Oficina.mute,
          ),
        ),
      ],
    );
  }
}

/// Trilho apagado com o arco na cor do estado. O arco cresce do zero até a
/// fração ao entrar e, quando a fração muda, parte de onde estava.
class _Anel extends StatelessWidget {
  const _Anel({required this.fracao, required this.cor, required this.child});

  final double fracao;
  final Color cor;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final trilho = Theme.of(context).colorScheme.onSurface
        .withValues(alpha: 0.08);
    return SizedBox(
      width: PainelSaude._anel,
      height: PainelSaude._anel,
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: fracao),
        duration: Movimento.longo,
        curve: Movimento.curva,
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(PainelSaude._espessura + 4),
            child: child,
          ),
        ),
        builder: (context, f, filho) => CustomPaint(
          painter: _AnelPainter(fracao: f, cor: cor, trilho: trilho),
          child: filho,
        ),
      ),
    );
  }
}

class _AnelPainter extends CustomPainter {
  const _AnelPainter({
    required this.fracao,
    required this.cor,
    required this.trilho,
  });

  final double fracao;
  final Color cor;
  final Color trilho;

  @override
  void paint(Canvas canvas, Size size) {
    final centro = size.center(Offset.zero);
    final raio = (size.shortestSide - PainelSaude._espessura) / 2;
    canvas.drawCircle(
      centro,
      raio,
      Paint()
        ..color = trilho
        ..style = PaintingStyle.stroke
        ..strokeWidth = PainelSaude._espessura,
    );
    if (fracao <= 0) return;
    canvas.drawArc(
      Rect.fromCircle(center: centro, radius: raio),
      -math.pi / 2,
      2 * math.pi * fracao.clamp(0.0, 1.0),
      false,
      Paint()
        ..color = cor
        ..style = PaintingStyle.stroke
        ..strokeWidth = PainelSaude._espessura
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(_AnelPainter old) =>
      old.fracao != fracao || old.cor != cor || old.trilho != trilho;
}

/// Ficha pequena de contagem: "2 atrasados", "1 atenção", "4 em dia".
/// O fundo usa a cor pura do estado; o texto passa por [PainelSaude.corTexto].
class _Ficha extends StatelessWidget {
  const _Ficha({required this.texto, required this.cor});

  final String texto;
  final Color cor;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: cor.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        texto,
        style: tema.textTheme.labelLarge?.copyWith(
          fontSize: 11,
          color: PainelSaude.corTexto(tema, cor),
        ),
      ),
    );
  }
}
