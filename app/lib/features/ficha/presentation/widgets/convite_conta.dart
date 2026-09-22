import 'package:flutter/material.dart';
import 'package:life_and_roads/core/widgets/movimento.dart';
import 'package:life_and_roads/tema.dart';

/// Convite para criar conta, mostrado depois que há o que perder.
///
/// A conta é opcional de propósito, e o app funciona inteiro sem ela. O
/// convite só aparece com a ficha já preenchida e sem conta, porque é aí
/// que trocar de celular custa caro. O piloto pode dispensar, e não volta.
class ConviteConta extends StatelessWidget {
  const ConviteConta({
    super.key,
    required this.aoCriar,
    required this.aoDispensar,
  });

  final VoidCallback aoCriar;
  final VoidCallback aoDispensar;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    return EntradaSuave(
      deslocamento: 8,
      child: CartaoOficina(
        destaque: true,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: Oficina.latao.withValues(alpha: 0.16),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.lock_outline,
                    size: 18,
                    color: Oficina.latao,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Guarde a caderneta na sua conta',
                    style: tema.textTheme.titleMedium?.copyWith(fontSize: 16),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              'Com conta, a ficha e as datas voltam quando você trocar de '
              'celular. O app continua funcionando sem ela.',
              style: tema.textTheme.bodyMedium,
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                TextButton(
                  onPressed: aoDispensar,
                  child: const Text('Agora não'),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: FilledButton(
                    onPressed: aoCriar,
                    child: const Text('Criar conta'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
