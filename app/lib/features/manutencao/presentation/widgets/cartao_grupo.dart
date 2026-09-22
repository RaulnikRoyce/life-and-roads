import 'package:flutter/material.dart';
import 'package:life_and_roads/tema.dart';

/// Um rótulo e o valor dele dentro de um [CartaoGrupo]. Valor nulo ou vazio
/// aparece como "-".
class ParGrupo {
  const ParGrupo(this.rotulo, this.valor);

  final String rotulo;
  final String? valor;
}

/// Grupo da manutenção como cartão: ícone, título em caixa alta e os valores
/// em duas colunas. O cartão inteiro abre a folha de edição do grupo.
class CartaoGrupo extends StatelessWidget {
  const CartaoGrupo({
    super.key,
    required this.icone,
    required this.titulo,
    required this.pares,
    required this.onTap,
  });

  final IconData icone;
  final String titulo;
  final List<ParGrupo> pares;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colunas = telaEstreita(context) ? 1 : 2;
    // Mesma cara do CartaoOficina (cor, raio e recuo), mas o fundo é um
    // Material para a tinta do toque aparecer por cima dele e o toque
    // passar pelo conteúdo. Igual à LinhaData.
    return Material(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(Oficina.raio),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CabecalhoGrupo(icone: icone, titulo: titulo),
              for (var i = 0; i < pares.length; i += colunas)
                Padding(
                  padding: const EdgeInsets.only(top: 14),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      for (var j = 0; j < colunas; j++)
                        Expanded(
                          child: i + j < pares.length
                              ? _Par(pares[i + j])
                              : const SizedBox.shrink(),
                        ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Cabeçalho dos cartões da manutenção: ícone em círculo, título em caixa
/// alta e, à direita, o ícone de ajuste ou o que [acao] mandar.
class CabecalhoGrupo extends StatelessWidget {
  const CabecalhoGrupo({
    super.key,
    required this.icone,
    required this.titulo,
    this.acao,
  });

  final IconData icone;
  final String titulo;

  /// O que fica à direita. Sem nada, mostra o ícone de ajuste.
  final Widget? acao;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: Oficina.latao.withValues(alpha: 0.16),
            shape: BoxShape.circle,
          ),
          child: Icon(icone, size: 18, color: Oficina.latao),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            titulo.toUpperCase(),
            style: tema.textTheme.labelLarge?.copyWith(
              fontSize: 12,
              letterSpacing: 1.2,
              color: Oficina.latao,
            ),
          ),
        ),
        acao ?? const Icon(Icons.tune, size: 18, color: Oficina.mute),
      ],
    );
  }
}

class _Par extends StatelessWidget {
  const _Par(this.par);

  final ParGrupo par;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final valor = par.valor;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            par.rotulo.toUpperCase(),
            style: tema.textTheme.labelLarge?.copyWith(
              fontSize: 10,
              letterSpacing: 1.2,
              color: Oficina.mute,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            valor == null || valor.isEmpty ? '-' : valor,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: tema.textTheme.titleMedium?.copyWith(fontSize: 15),
          ),
        ],
      ),
    );
  }
}
