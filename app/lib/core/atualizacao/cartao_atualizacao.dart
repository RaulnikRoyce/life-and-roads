import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:life_and_roads/core/atualizacao/atualizacao_controller.dart';
import 'package:life_and_roads/tema.dart';

class CartaoAtualizacao extends ConsumerWidget {
  const CartaoAtualizacao({super.key, this.somenteAviso = false});
  final bool somenteAviso;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!ref.watch(atualizacaoSuportadaProvider)) {
      return const SizedBox.shrink();
    }
    final estado = ref.watch(atualizacaoControllerProvider);
    if (somenteAviso && !estado.disponivel) return const SizedBox.shrink();
    final ctrl = ref.read(atualizacaoControllerProvider.notifier);
    final ocupado = estado.verificando || estado.abrindo;
    return CartaoOficina(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            estado.disponivel
                ? 'Nova versão ${estado.publicada!.versao}'
                : 'Atualizações do app',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          if (estado.instalada != null)
            Text('Versão instalada ${estado.instalada!.descricao}.'),
          if (estado.disponivel)
            const Text(
              'Baixe o APK oficial e confirme a instalação no Android.',
            )
          else if (estado.situacao == SituacaoAtualizacao.atualizado)
            const Text('Nenhuma versão estável mais nova foi encontrada.')
          else if (estado.situacao == SituacaoAtualizacao.preparando)
            Text(
              'A versão ${estado.publicada!.versao} ainda está sendo preparada. Consulte novamente mais tarde.',
            )
          else
            const Text(
              'Consulte as versões oficiais quando tiver acesso à internet.',
            ),
          if (estado.erro != null) ...[
            const SizedBox(height: 8),
            Text(estado.erro!),
          ],
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              if (estado.disponivel)
                FilledButton.icon(
                  onPressed: ocupado ? null : ctrl.baixar,
                  style: FilledButton.styleFrom(minimumSize: const Size(0, 44)),
                  icon: const Icon(Icons.download_outlined),
                  label: Text(
                    estado.abrindo ? 'Abrindo download' : 'Baixar APK',
                  ),
                ),
              if (!somenteAviso)
                OutlinedButton(
                  onPressed: ocupado ? null : () => ctrl.verificar(),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(0, 44),
                  ),
                  child: Text(
                    estado.verificando
                        ? 'Verificando'
                        : 'Verificar atualização',
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
