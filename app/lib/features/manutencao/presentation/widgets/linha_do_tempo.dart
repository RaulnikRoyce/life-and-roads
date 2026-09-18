import 'package:flutter/material.dart';
import 'package:life_and_roads/core/widgets/movimento.dart';
import 'package:life_and_roads/features/manutencao/domain/usecases/montar_linha_do_tempo.dart';
import 'package:life_and_roads/tema.dart';

/// Vencimentos da oficina em ordem de urgência, cada um com a barra de
/// quanto do intervalo já passou. Verde folgado, âmbar chegando, vinho
/// atrasado. Entram em cascata.
class LinhaDoTempo extends StatelessWidget {
  const LinhaDoTempo({super.key, required this.itens});

  final List<ItemLinhaDoTempo> itens;

  static Color corDe(EstadoItem e) => switch (e) {
    EstadoItem.emDia => const Color(0xFF5E8C61),
    EstadoItem.atencao => const Color(0xFFC98A2B),
    EstadoItem.atrasado => Oficina.latao,
  };

  static IconData iconeDe(String id) => switch (id) {
    'oleo' || 'oleo-km' => Icons.oil_barrel_outlined,
    'corrente-km' => Icons.link_outlined,
    'pneus' => Icons.tire_repair_outlined,
    'ipva' || 'licenciamento' => Icons.description_outlined,
    'seguro' => Icons.shield_outlined,
    'cnh' => Icons.badge_outlined,
    _ => Icons.build_outlined,
  };

  @override
  Widget build(BuildContext context) {
    if (itens.isEmpty) return const SizedBox.shrink();
    return CartaoOficina(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Próximos vencimentos',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 4),
          for (var i = 0; i < itens.length; i++)
            EntradaSuave(
              atraso: Duration(milliseconds: 50 * i),
              deslocamento: 8,
              child: _Linha(item: itens[i], ultima: i == itens.length - 1),
            ),
        ],
      ),
    );
  }
}

class _Linha extends StatelessWidget {
  const _Linha({required this.item, required this.ultima});

  final ItemLinhaDoTempo item;
  final bool ultima;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final cor = LinhaDoTempo.corDe(item.estado);
    final trilho = tema.colorScheme.onSurface.withValues(alpha: 0.08);
    return Padding(
      padding: EdgeInsets.only(top: 12, bottom: ultima ? 0 : 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: cor.withValues(alpha: 0.16),
              shape: BoxShape.circle,
            ),
            child: Icon(LinhaDoTempo.iconeDe(item.id), size: 18, color: cor),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        item.titulo,
                        style: tema.textTheme.titleMedium?.copyWith(
                          fontSize: 15,
                        ),
                      ),
                    ),
                    if (item.estado == EstadoItem.atrasado)
                      Text(
                        'ATRASADO',
                        style: tema.textTheme.labelLarge?.copyWith(
                          fontSize: 10,
                          color: cor,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(item.detalhe, style: tema.textTheme.bodyMedium),
                const SizedBox(height: 8),
                // Barra: cresce do zero até a fração ao entrar.
                ClipRRect(
                  borderRadius: BorderRadius.circular(3),
                  child: SizedBox(
                    height: 5,
                    child: Stack(
                      children: [
                        ColoredBox(
                          color: trilho,
                          child: const SizedBox.expand(),
                        ),
                        TweenAnimationBuilder<double>(
                          tween: Tween(begin: 0, end: item.fracao),
                          duration: Movimento.longo,
                          curve: Movimento.curva,
                          builder: (context, f, _) => FractionallySizedBox(
                            alignment: Alignment.centerLeft,
                            widthFactor: f,
                            child: ColoredBox(
                              color: cor,
                              child: const SizedBox.expand(),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
