import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:life_and_roads/core/widgets/movimento.dart';
import 'package:life_and_roads/tema.dart';

/// Uma aba da barra inferior.
class Aba {
  const Aba({required this.titulo, required this.icone, IconData? ativo})
    : iconeAtivo = ativo ?? icone;

  final String titulo;
  final IconData icone;

  /// Versão preenchida para a aba ativa.
  final IconData iconeAtivo;
}

/// Barra inferior com a pastilha deslizando entre as abas.
///
/// No lugar do NavigationBar do Material, cujo indicador só aparece e some.
/// A pastilha segue o dedo com uma curva curta, o ícone preenche na aba
/// ativa e o toque dá um retorno tátil discreto no Android.
class BarraAbas extends StatelessWidget {
  const BarraAbas({
    super.key,
    required this.abas,
    required this.indice,
    required this.aoEscolher,
  });

  final List<Aba> abas;
  final int indice;
  final ValueChanged<int> aoEscolher;

  static const altura = 72.0;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final escuro = tema.brightness == Brightness.dark;
    final fundo = escuro ? Oficina.faixa : const Color(0xFFEDE8E0);
    final mute = escuro ? Oficina.mute : const Color(0xFF6E6E6E);

    return Material(
      color: fundo,
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: altura,
          child: LayoutBuilder(
            builder: (context, box) {
              final largura = box.maxWidth / abas.length;
              const pastilhaW = 64.0;
              const pastilhaH = 32.0;
              return Stack(
                children: [
                  // Pastilha que desliza.
                  AnimatedPositioned(
                    duration: Movimento.medio,
                    curve: Movimento.curva,
                    left: largura * indice + (largura - pastilhaW) / 2,
                    top: 12,
                    width: pastilhaW,
                    height: pastilhaH,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: Oficina.latao.withValues(alpha: 0.28),
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                  Row(
                    children: [
                      for (var i = 0; i < abas.length; i++)
                        Expanded(
                          child: _ItemAba(
                            aba: abas[i],
                            ativa: i == indice,
                            mute: mute,
                            aoTocar: () {
                              if (i == indice) return;
                              HapticFeedback.selectionClick();
                              aoEscolher(i);
                            },
                          ),
                        ),
                    ],
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _ItemAba extends StatelessWidget {
  const _ItemAba({
    required this.aba,
    required this.ativa,
    required this.mute,
    required this.aoTocar,
  });

  final Aba aba;
  final bool ativa;
  final Color mute;
  final VoidCallback aoTocar;

  @override
  Widget build(BuildContext context) {
    final cor = ativa ? Oficina.latao : mute;
    return Semantics(
      button: true,
      selected: ativa,
      label: aba.titulo,
      child: InkResponse(
        onTap: aoTocar,
        radius: 36,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              height: 32,
              child: Center(
                child: AnimatedSwitcher(
                  duration: Movimento.curto,
                  transitionBuilder: (filho, anim) => ScaleTransition(
                    scale: Tween(begin: 0.8, end: 1.0).animate(anim),
                    child: FadeTransition(opacity: anim, child: filho),
                  ),
                  child: Icon(
                    ativa ? aba.iconeAtivo : aba.icone,
                    key: ValueKey(ativa),
                    size: 24,
                    color: cor,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 4),
            AnimatedDefaultTextStyle(
              duration: Movimento.curto,
              style: GoogleFonts.oswald(
                fontSize: 11,
                letterSpacing: 0.4,
                fontWeight: ativa ? FontWeight.w600 : FontWeight.w400,
                color: cor,
              ),
              child: Text(aba.titulo),
            ),
          ],
        ),
      ),
    );
  }
}
