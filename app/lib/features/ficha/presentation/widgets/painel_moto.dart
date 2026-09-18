import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:life_and_roads/core/widgets/movimento.dart';
import 'package:life_and_roads/tema.dart';

/// Um número da moto numa pastilha: ícone, valor e rótulo.
class Pastilha {
  const Pastilha({
    required this.icone,
    required this.valor,
    required this.rotulo,
  });

  final IconData icone;
  final String valor;
  final String rotulo;
}

/// A moto como painel, não como formulário.
///
/// Foto sangrando até as bordas com o nome por cima, o km do painel em
/// número grande (o que o piloto mais olha) e os demais números em
/// pastilhas que entram em cascata. Editar fica atrás de "Ajustar números".
class PainelMoto extends StatelessWidget {
  const PainelMoto({
    super.key,
    required this.foto,
    required this.nome,
    required this.combustivel,
    required this.km,
    required this.pastilhas,
    required this.aoFoto,
    required this.aoApagarFoto,
    required this.aoAjustar,
  });

  final Uint8List? foto;
  final String nome;

  /// Etiqueta sobre a foto ("Flex"). Vazio quando não há o que destacar.
  final String combustivel;
  final double? km;
  final List<Pastilha> pastilhas;
  final VoidCallback aoFoto;
  final VoidCallback aoApagarFoto;
  final VoidCallback aoAjustar;

  static const alturaFoto = 250.0;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final fundo = tema.scaffoldBackgroundColor;
    final lateral = paddingOficina(context).left;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Foto até a borda, derretendo no fundo da tela.
        SizedBox(
          height: alturaFoto,
          width: double.infinity,
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (foto != null)
                Image.memory(foto!, fit: BoxFit.cover, gaplessPlayback: true)
              else
                ColoredBox(
                  color: tema.colorScheme.surfaceContainerHighest,
                  child: Icon(
                    Icons.two_wheeler,
                    size: 96,
                    color: Oficina.latao.withValues(alpha: 0.5),
                  ),
                ),
              DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    stops: const [0.0, 0.45, 1.0],
                    colors: [
                      fundo.withValues(alpha: 0.0),
                      fundo.withValues(alpha: 0.15),
                      fundo,
                    ],
                  ),
                ),
              ),
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: aoFoto,
                  onLongPress: foto == null ? null : aoApagarFoto,
                  child: const SizedBox.expand(),
                ),
              ),
              Positioned(
                right: lateral - 4,
                top: 8,
                child: IconButton.filledTonal(
                  tooltip: foto == null ? 'Adicionar foto' : 'Trocar foto',
                  onPressed: aoFoto,
                  style: IconButton.styleFrom(
                    backgroundColor: fundo.withValues(alpha: 0.55),
                    foregroundColor: tema.colorScheme.onSurface,
                  ),
                  icon: const Icon(Icons.photo_camera_outlined, size: 20),
                ),
              ),
              Positioned(
                left: lateral,
                right: lateral,
                bottom: 6,
                child: EntradaSuave(
                  deslocamento: 8,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (combustivel.isNotEmpty) ...[
                        _Etiqueta(combustivel.toUpperCase()),
                        const SizedBox(height: 6),
                      ],
                      Text(
                        nome.isEmpty ? 'Sua moto' : nome,
                        style: tema.textTheme.headlineSmall?.copyWith(
                          fontSize: 30,
                          height: 1.05,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),

        // Km do painel: o número grande.
        Padding(
          padding: EdgeInsets.fromLTRB(lateral, 6, lateral, 0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'PAINEL',
                      style: tema.textTheme.labelLarge?.copyWith(
                        fontSize: 11,
                        letterSpacing: 1.4,
                        color: Oficina.mute,
                      ),
                    ),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        if (km == null)
                          Text(
                            '-',
                            style: tema.textTheme.headlineSmall?.copyWith(
                              fontSize: 52,
                            ),
                          )
                        else
                          NumeroAnimado(
                            valor: km!,
                            formatar: (v) => _milhar(v),
                            style: tema.textTheme.headlineSmall?.copyWith(
                              fontSize: 52,
                              height: 1.05,
                              letterSpacing: 0.5,
                            ),
                          ),
                        const SizedBox(width: 6),
                        Text(
                          'km',
                          style: tema.textTheme.titleLarge?.copyWith(
                            color: Oficina.mute,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              TextButton.icon(
                onPressed: aoAjustar,
                icon: const Icon(Icons.tune, size: 18),
                label: const Text('Ajustar números'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),

        // Pastilhas em cascata.
        SizedBox(
          height: 84,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: EdgeInsets.symmetric(horizontal: lateral),
            itemCount: pastilhas.length,
            separatorBuilder: (_, _) => const SizedBox(width: 10),
            itemBuilder: (context, i) => EntradaSuave(
              atraso: Duration(milliseconds: 60 * i),
              deslocamento: 10,
              child: _CartaoPastilha(pastilhas[i]),
            ),
          ),
        ),
      ],
    );
  }

  static String _milhar(double v) {
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

class _Etiqueta extends StatelessWidget {
  const _Etiqueta(this.texto);

  final String texto;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: Oficina.latao,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        texto,
        style: Theme.of(context).textTheme.labelLarge
            ?.copyWith(fontSize: 10, color: Colors.white),
      ),
    );
  }
}

class _CartaoPastilha extends StatelessWidget {
  const _CartaoPastilha(this.p);

  final Pastilha p;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    return Container(
      width: 118,
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      decoration: BoxDecoration(
        color: tema.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Icon(p.icone, size: 18, color: Oficina.latao),
          Text(
            p.valor,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: tema.textTheme.titleMedium?.copyWith(fontSize: 18),
          ),
          Text(
            p.rotulo,
            style: tema.textTheme.labelLarge?.copyWith(
              fontSize: 10,
              letterSpacing: 1.2,
              color: Oficina.mute,
            ),
          ),
        ],
      ),
    );
  }
}
