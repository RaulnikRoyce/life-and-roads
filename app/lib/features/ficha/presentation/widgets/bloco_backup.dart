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
    this.automatico,
  });

  final VoidCallback aoEnviar;
  final VoidCallback aoRestaurar;
  final VoidCallback aoCopiar;
  final VoidCallback aoColar;

  /// Quando o backup automático gravou pela última vez. Null se nunca.
  final DateTime? automatico;

  static String _quando(DateTime d) {
    final agora = DateTime.now();
    final minutos = agora.difference(d).inMinutes;
    if (minutos < 1) return 'agora';
    if (minutos < 60) return 'há $minutos min';
    final horas = agora.difference(d).inHours;
    if (horas < 24) return 'há $horas h';
    final dias = agora.difference(d).inDays;
    return dias == 1 ? 'ontem' : 'há $dias dias';
  }

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
          automatico == null
              ? 'Uma cópia fica em Download, na pasta life.and.roads. Envie '
                    'para o Drive ou o WhatsApp e restaure de lá.'
              : 'Salvo sozinho em Download, na pasta life.and.roads, '
                    '${_quando(automatico!)}. Envie para o Drive ou o '
                    'WhatsApp e restaure de lá.',
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
