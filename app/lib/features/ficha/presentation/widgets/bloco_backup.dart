import 'package:flutter/material.dart';
import 'package:life_and_roads/tema.dart';

/// Seção "Backup neste aparelho" da Ficha. Só botões; quem faz é a tela.
class BlocoBackup extends StatelessWidget {
  const BlocoBackup({
    super.key,
    required this.aoEnviar,
    required this.aoRestaurar,
    required this.aoCopiar,
    required this.aoColar,
  });

  final VoidCallback aoEnviar;
  final VoidCallback aoRestaurar;
  final VoidCallback aoCopiar;
  final VoidCallback aoColar;

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        tilePadding: EdgeInsets.zero,
        childrenPadding: const EdgeInsets.only(bottom: 8),
        leading: const Icon(Icons.save_alt, color: Oficina.latao),
        title: Text(
          'Backup neste aparelho',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        subtitle: Text(
          'Envie o arquivo para o Drive ou o WhatsApp e restaure de lá. '
          'Sem login e sem placa.',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        children: [
          FilledButton.icon(
            onPressed: aoEnviar,
            icon: const Icon(Icons.ios_share),
            label: const Text('Enviar backup'),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: aoRestaurar,
            icon: const Icon(Icons.folder_open),
            label: const Text('Restaurar de um arquivo'),
          ),
          const SizedBox(height: 8),
          OutlinedButton(
            onPressed: aoCopiar,
            child: const Text('Copiar backup'),
          ),
          const SizedBox(height: 8),
          OutlinedButton(onPressed: aoColar, child: const Text('Colar backup')),
        ],
      ),
    );
  }
}
