import 'package:flutter/material.dart';
import 'package:life_and_roads/core/backup/pasta_download.dart';
import 'package:life_and_roads/core/texto/tempo_relativo.dart';
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

  /// Texto do bloco, nos três estados que existem.
  ///
  /// Sem pasta Download (iPhone, navegador) o app não promete cópia
  /// nenhuma, porque ali ela não acontece.
  static String texto({required bool temPasta, DateTime? em}) {
    const fim = 'Envie para o Drive ou o WhatsApp e restaure de lá.';
    if (!temPasta) return 'Guarde uma cópia da caderneta fora do aparelho. $fim';
    if (em == null) {
      return 'Uma cópia fica em Download, na pasta life.and.roads. $fim';
    }
    return 'Salvo sozinho em Download, na pasta life.and.roads, '
        '${haQuanto(em)}. $fim';
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
          texto(temPasta: PastaDownload.disponivel, em: automatico),
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
