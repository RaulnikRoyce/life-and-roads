import 'package:flutter/material.dart';
import 'package:life_and_roads/manutencao/regras.dart';

/// Folha para escolher uma data: digitada, atalhos ou calendário.
///
/// Dona do próprio controller: ele só é descartado quando a folha sai da
/// árvore, depois da animação de fechar. Descartar antes (como era feito na
/// tela) quebrava o campo durante a saída.
class FolhaData extends StatefulWidget {
  const FolhaData({super.key, required this.rotulo, required this.atual});

  final String rotulo;
  final DateTime? atual;

  /// Abre a folha e devolve a data escolhida, ou null.
  static Future<DateTime?> abrir(
    BuildContext context, {
    required String rotulo,
    required DateTime? atual,
  }) {
    return showModalBottomSheet<DateTime>(
      context: context,
      isScrollControlled: true,
      builder: (_) => FolhaData(rotulo: rotulo, atual: atual),
    );
  }

  @override
  State<FolhaData> createState() => _FolhaDataState();
}

class _FolhaDataState extends State<FolhaData> {
  late final TextEditingController _digitada = TextEditingController(
    text: widget.atual == null ? '' : dataBr(widget.atual!),
  );
  final _agora = DateTime.now();

  @override
  void dispose() {
    _digitada.dispose();
    super.dispose();
  }

  void _usar(String texto) {
    final d = parseDataBr(texto);
    if (d != null) Navigator.pop(context, d);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        16,
        20,
        16 +
            MediaQuery.viewInsetsOf(context).bottom +
            MediaQuery.paddingOf(context).bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(widget.rotulo, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 12),
          TextField(
            controller: _digitada,
            keyboardType: TextInputType.datetime,
            autofocus: true,
            decoration: const InputDecoration(labelText: 'Data (13/08/26)'),
            onSubmitted: _usar,
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ActionChip(
                label: const Text('Hoje'),
                onPressed: () => Navigator.pop(context, soDia(_agora)),
              ),
              ActionChip(
                label: const Text('Há 1 mês'),
                onPressed: () =>
                    Navigator.pop(context, acrescentarMeses(_agora, -1)),
              ),
              ActionChip(
                label: const Text('Há 4 meses'),
                onPressed: () =>
                    Navigator.pop(context, acrescentarMeses(_agora, -4)),
              ),
              ActionChip(
                label: const Text('Há 6 meses'),
                onPressed: () =>
                    Navigator.pop(context, acrescentarMeses(_agora, -6)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: () async {
              final cal = await showDatePicker(
                context: context,
                initialDate: widget.atual ?? _agora,
                firstDate: DateTime(2000),
                lastDate: DateTime(_agora.year + 15),
              );
              if (cal == null || !context.mounted) return;
              Navigator.pop(context, cal);
            },
            child: const Text('Calendário'),
          ),
          FilledButton(
            onPressed: () => _usar(_digitada.text),
            child: const Text('Usar esta data'),
          ),
        ],
      ),
    );
  }
}
