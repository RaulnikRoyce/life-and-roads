import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:life_and_roads/features/manutencao/presentation/avisos_controller.dart';
import 'package:life_and_roads/tema.dart';

class BotaoSininho extends ConsumerWidget {
  const BotaoSininho({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final estado = ref.watch(avisosControllerProvider);
    final n = estado.naoLidas;
    return IconButton(
      tooltip: n == 0 ? 'Avisos' : 'Avisos ($n)',
      onPressed: () => _abrir(context, ref),
      icon: Badge(
        isLabelVisible: n > 0,
        label: Text(n > 9 ? '9+' : '$n'),
        child: const Icon(Icons.notifications_outlined),
      ),
    );
  }

  Future<void> _abrir(BuildContext context, WidgetRef ref) async {
    final ctrl = ref.read(avisosControllerProvider.notifier);
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
      builder: (ctx) {
        return Consumer(
          builder: (ctx, ref, _) {
            final estado = ref.watch(avisosControllerProvider);
            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Avisos',
                      style: Theme.of(ctx).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 12),
                    if (estado.avisos.isEmpty)
                      Text(
                        'Nada vencendo agora.',
                        style: Theme.of(ctx).textTheme.bodyMedium,
                      )
                    else ...[
                      for (final a in estado.avisos)
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text(a.texto),
                          trailing: estado.lidos.contains(a.id)
                              ? null
                              : const Icon(
                                  Icons.circle,
                                  size: 10,
                                  color: Oficina.latao,
                                ),
                          onTap: () => ctrl.marcarLido(a.id),
                        ),
                      TextButton(
                        onPressed: ctrl.marcarTodos,
                        child: const Text('Marcar todos como lidos'),
                      ),
                    ],
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
