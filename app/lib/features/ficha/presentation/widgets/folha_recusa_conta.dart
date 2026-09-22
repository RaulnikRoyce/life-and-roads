import 'package:flutter/material.dart';
import 'package:life_and_roads/tema.dart';

/// Pergunta por que o piloto dispensou o convite de criar conta.
///
/// Responder é opcional, e dispensar funciona do mesmo jeito sem resposta.
/// O texto vai para o servidor sem e-mail, sem id e sem nada da caderneta,
/// pela mesma rota anônima dos crashes.
class FolhaRecusaConta extends StatefulWidget {
  const FolhaRecusaConta({super.key});

  /// Abre e devolve o motivo, ou null quando o piloto não quis dizer.
  static Future<String?> abrir(BuildContext context) {
    return showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => const FolhaRecusaConta(),
    );
  }

  /// Motivos comuns, para responder num toque.
  static const motivos = [
    'Não quero dar meu e-mail',
    'Não entendi para que serve',
    'Depois eu faço',
    'Não confio ainda',
  ];

  @override
  State<FolhaRecusaConta> createState() => _FolhaRecusaContaState();
}

class _FolhaRecusaContaState extends State<FolhaRecusaConta> {
  final _outro = TextEditingController();
  String? _escolhido;

  @override
  void dispose() {
    _outro.dispose();
    super.dispose();
  }

  String? get _resposta {
    final digitado = _outro.text.trim();
    if (digitado.isNotEmpty) return digitado;
    return _escolhido;
  }

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
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
          Center(
            child: Container(
              width: 36,
              height: 4,
              margin: const EdgeInsets.only(bottom: 14),
              decoration: BoxDecoration(
                color: Oficina.mute.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Text('Por que não agora?', style: tema.textTheme.headlineSmall),
          const SizedBox(height: 6),
          Text(
            'Responder é opcional e ajuda a melhorar o app. Vai sem o seu '
            'e-mail e sem nada da sua caderneta.',
            style: tema.textTheme.bodyMedium,
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final m in FolhaRecusaConta.motivos)
                ChoiceChip(
                  label: Text(m),
                  selected: _escolhido == m,
                  showCheckmark: false,
                  onSelected: (v) => setState(() => _escolhido = v ? m : null),
                ),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _outro,
            maxLength: 200,
            maxLines: 2,
            textCapitalization: TextCapitalization.sentences,
            onChanged: (_) => setState(() {}),
            decoration: const InputDecoration(
              labelText: 'Outro motivo (opcional)',
              counterText: '',
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Prefiro não dizer'),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: FilledButton(
                  onPressed: _resposta == null
                      ? null
                      : () => Navigator.pop(context, _resposta),
                  child: const Text('Enviar'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
