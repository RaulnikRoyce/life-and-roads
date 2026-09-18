import 'package:flutter/material.dart';
import 'package:life_and_roads/core/sync/status_sync.dart';
import 'package:life_and_roads/core/sync/texto_sync.dart';
import 'package:life_and_roads/core/widgets/movimento.dart';

/// Estado do servidor numa linha, com "Sincronizar agora". Só com conta.
class LinhaSync extends StatelessWidget {
  const LinhaSync({
    super.key,
    required this.meta,
    required this.sincronizando,
    required this.aoSincronizar,
    this.offline = false,
  });

  final MetadadoSync meta;
  final bool sincronizando;

  /// A última tentativa de falar com o servidor falhou.
  final bool offline;
  final VoidCallback aoSincronizar;

  @override
  Widget build(BuildContext context) {
    final texto = textoSync(meta, offline: offline);
    if (texto == null) return const SizedBox.shrink();
    final tema = Theme.of(context);
    final pendente = meta.deveReenviar || offline;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Pulso(
          gatilho: sincronizando,
          child: Icon(
            sincronizando
                ? Icons.cloud_sync_outlined
                : pendente
                ? Icons.cloud_upload_outlined
                : Icons.cloud_done_outlined,
            size: 18,
            color: pendente ? tema.colorScheme.error : tema.colorScheme.primary,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: AnimatedSwitcher(
            duration: Movimento.curto,
            child: Text(
              sincronizando ? 'Conferindo com o servidor.' : texto,
              key: ValueKey(sincronizando ? 'conferindo' : texto),
              style: tema.textTheme.bodyMedium,
            ),
          ),
        ),
        TextButton.icon(
          onPressed: sincronizando ? null : aoSincronizar,
          icon: const Icon(Icons.sync, size: 18),
          label: const Text('Sincronizar agora'),
        ),
      ],
    );
  }
}
