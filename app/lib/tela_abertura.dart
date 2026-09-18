import 'package:flutter/material.dart';
import 'package:life_and_roads/core/marca/logo_pintor.dart';
import 'package:life_and_roads/core/widgets/movimento.dart';
import 'package:life_and_roads/tema.dart';

/// Abertura: a logo se desenha (capacetes, disco, fitas), o crédito entra,
/// e a logo voa para a barra superior quando as abas aparecem.
class TelaAbertura extends StatefulWidget {
  const TelaAbertura({super.key, required this.aoTerminar});

  final VoidCallback aoTerminar;

  /// Tag do [Hero] compartilhado com a barra superior.
  static const heroLogo = 'logo-life-and-roads';

  /// Desenho + pausa para ler o crédito.
  static const duracao = Duration(milliseconds: 2500);
  static const _desenho = Duration(milliseconds: 1900);

  @override
  State<TelaAbertura> createState() => _TelaAberturaState();
}

class _TelaAberturaState extends State<TelaAbertura>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl = AnimationController(
    vsync: this,
    duration: TelaAbertura._desenho,
  );

  @override
  void initState() {
    super.initState();
    _ctrl.forward();
    Future<void>.delayed(TelaAbertura.duracao, () {
      if (mounted) widget.aoTerminar();
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final escuro = tema.brightness == Brightness.dark;
    final mute = tema.textTheme.bodyMedium?.color ?? Oficina.mute;
    // Crédito entra quando as fitas já estão no lugar.
    final credito = CurvedAnimation(
      parent: _ctrl,
      curve: const Interval(0.72, 1, curve: Curves.easeOutCubic),
    );
    // Halo atrás do disco: sobe com o disco e fica.
    final halo = CurvedAnimation(
      parent: _ctrl,
      curve: const Interval(0.5, 0.9, curve: Curves.easeOut),
    );

    return Scaffold(
      backgroundColor: tema.scaffoldBackgroundColor,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              alignment: Alignment.center,
              children: [
                AnimatedBuilder(
                  animation: halo,
                  builder: (context, _) => Container(
                    width: 300,
                    height: 300,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          Oficina.latao.withValues(
                            alpha: (escuro ? 0.22 : 0.14) * halo.value,
                          ),
                          Oficina.latao.withValues(alpha: 0),
                        ],
                      ),
                    ),
                  ),
                ),
                Hero(
                  tag: TelaAbertura.heroLogo,
                  child: LogoAnimada(progresso: _ctrl, tamanho: 190),
                ),
              ],
            ),
            const SizedBox(height: 8),
            FadeTransition(
              opacity: credito,
              child: SlideTransition(
                position: Tween(
                  begin: const Offset(0, 0.4),
                  end: Offset.zero,
                ).animate(credito),
                child: Text(
                  'developed by Raulnik Royce',
                  style: tema.textTheme.bodyMedium?.copyWith(
                    color: mute,
                    letterSpacing: 0.4,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Rota das abas: a abertura sai em fade enquanto a logo voa para a barra.
Route<void> rotaPrincipal(Widget principal) {
  return PageRouteBuilder<void>(
    transitionDuration: Movimento.longo,
    reverseTransitionDuration: Movimento.curto,
    pageBuilder: (_, _, _) => principal,
    transitionsBuilder: (_, animacao, _, filho) => FadeTransition(
      opacity: CurvedAnimation(parent: animacao, curve: Movimento.curva),
      child: filho,
    ),
  );
}
