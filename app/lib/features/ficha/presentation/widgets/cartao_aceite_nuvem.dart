import 'package:flutter/material.dart';
import 'package:life_and_roads/tema.dart';

/// Para quem já tinha conta antes da caderneta na nuvem (ADR 0038). Até a
/// resposta, nada sobe: o interruptor nasce ligado, e sem este cartão
/// abastecimentos e pinos iriam para o servidor sem a pessoa ter lido.
class CartaoAceiteNuvem extends StatelessWidget {
  const CartaoAceiteNuvem({
    super.key,
    required this.aoAceitar,
    required this.aoDesligar,
    required this.aoMostrarTermos,
    required this.aoMostrarPrivacidade,
    this.ocupado = false,
  });

  final VoidCallback aoAceitar;
  final VoidCallback aoDesligar;
  final VoidCallback aoMostrarTermos;
  final VoidCallback aoMostrarPrivacidade;

  /// Esperando a API: os botões ficam parados para não mandar duas vezes.
  final bool ocupado;

  static const titulo = 'A conta agora guarda a caderneta inteira';
  static const texto =
      'Abastecimentos, serviços, pinos, PSI, km de óleo e corrente e a '
      'validade da CNH vão cifrados para a sua conta e voltam se você trocar '
      'de celular. A foto fica só neste aparelho. Você pode desligar quando '
      'quiser no bloco Conta.';

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context).textTheme;
    return CartaoOficina(
      destaque: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(titulo, style: tema.titleMedium),
          const SizedBox(height: 8),
          Text(texto, style: tema.bodyMedium),
          Wrap(
            children: [
              TextButton(
                onPressed: aoMostrarTermos,
                child: const Text('Termos de uso'),
              ),
              TextButton(
                onPressed: aoMostrarPrivacidade,
                child: const Text('Privacidade'),
              ),
            ],
          ),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: ocupado ? null : aoDesligar,
                  child: const Text('Desligar'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton(
                  onPressed: ocupado ? null : aoAceitar,
                  child: const Text('Aceito, manter ligado'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
