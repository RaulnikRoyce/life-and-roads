import 'package:flutter/material.dart';
import 'package:life_and_roads/core/widgets/movimento.dart';
import 'package:life_and_roads/ficha/catalogo.dart';
import 'package:life_and_roads/tema.dart';

/// Busca no catálogo. Campo de digitar em cima, categorias em seguida e a
/// lista com o que importa para escolher.
///
/// O catálogo passou de 116 modelos e cresce; rolar a lista inteira deixou
/// de servir. O campo fica visível o tempo todo, com o cursor dentro, para
/// não depender de o piloto descobrir que dá para digitar.
class BuscaModelo extends StatefulWidget {
  const BuscaModelo({super.key, this.uso});

  /// Categoria marcada ao abrir. Null é "todas".
  final UsoCatalogo? uso;

  /// Abre a folha e devolve o modelo escolhido, ou null.
  static Future<ModeloCatalogo?> abrir(
    BuildContext context, {
    UsoCatalogo? uso,
  }) {
    return showModalBottomSheet<ModeloCatalogo>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => BuscaModelo(uso: uso),
    );
  }

  /// Minúsculas e sem acento, para "tenere" achar "Ténéré".
  static String semAcento(String texto) {
    const com = 'áàâãäéèêëíìîïóòôõöúùûüçñ';
    const sem = 'aaaaaeeeeiiiiooooouuuucn';
    final b = StringBuffer();
    for (final c in texto.toLowerCase().split('')) {
      final i = com.indexOf(c);
      b.write(i == -1 ? c : sem[i]);
    }
    return b.toString();
  }

  /// Casa quando cada pedaço do que foi digitado aparece na marca ou no
  /// modelo, em qualquer ordem. "hon 160" acha a Honda CG 160.
  static List<ModeloCatalogo> filtrar(
    List<ModeloCatalogo> lista,
    String busca,
  ) {
    final termos = semAcento(busca).split(' ').where((t) => t.isNotEmpty);
    if (termos.isEmpty) return lista;
    return [
      for (final m in lista)
        if (termos.every(
          (t) => semAcento('${m.marca} ${m.rotulo}').contains(t),
        ))
          m,
    ];
  }

  @override
  State<BuscaModelo> createState() => _BuscaModeloState();
}

class _BuscaModeloState extends State<BuscaModelo> {
  late final TextEditingController _busca = TextEditingController()
    ..addListener(() => setState(() {}));
  late UsoCatalogo? _uso = widget.uso;

  @override
  void dispose() {
    _busca.dispose();
    super.dispose();
  }

  static const _categorias = <(String, UsoCatalogo?)>[
    ('Todas', null),
    ('Cidade', UsoCatalogo.cidade),
    ('Trail', UsoCatalogo.trail),
    ('Estrada', UsoCatalogo.estrada),
    ('Esportiva', UsoCatalogo.esporte),
  ];

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final achados = BuscaModelo.filtrar(catalogoFiltrado(_uso), _busca.text);
    final teclado = MediaQuery.viewInsetsOf(context).bottom;

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.9,
      minChildSize: 0.5,
      maxChildSize: 0.96,
      builder: (ctx, rolagem) => Padding(
        padding: EdgeInsets.only(bottom: teclado),
        child: Column(
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                margin: const EdgeInsets.only(top: 8, bottom: 12),
                decoration: BoxDecoration(
                  color: Oficina.mute.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
              child: TextField(
                controller: _busca,
                autofocus: true,
                textInputAction: TextInputAction.search,
                decoration: InputDecoration(
                  hintText: 'Busque a marca ou o modelo',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _busca.text.isEmpty
                      ? null
                      : IconButton(
                          tooltip: 'Limpar',
                          icon: const Icon(Icons.close),
                          onPressed: () => _busca.clear(),
                        ),
                ),
              ),
            ),
            SizedBox(
              height: 40,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: _categorias.length,
                separatorBuilder: (_, _) => const SizedBox(width: 8),
                itemBuilder: (context, i) {
                  final (rotulo, uso) = _categorias[i];
                  return ChoiceChip(
                    label: Text(rotulo),
                    selected: _uso == uso,
                    showCheckmark: false,
                    onSelected: (_) => setState(() => _uso = uso),
                  );
                },
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: achados.isEmpty
                  ? _vazio(tema)
                  : ListView.separated(
                      controller: rolagem,
                      padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
                      itemCount: achados.length,
                      separatorBuilder: (_, _) => Divider(
                        height: 1,
                        color: tema.colorScheme.onSurface.withValues(
                          alpha: 0.08,
                        ),
                      ),
                      itemBuilder: (context, i) => _Linha(
                        modelo: achados[i],
                        aoTocar: () => Navigator.pop(context, achados[i]),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _vazio(ThemeData tema) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Nenhuma moto com esse nome', style: tema.textTheme.titleMedium),
          const SizedBox(height: 6),
          Text(
            'Feche a busca e escreva marca e modelo à mão. Os números você '
            'ajusta depois pela sua média.',
            style: tema.textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}

class _Linha extends StatelessWidget {
  const _Linha({required this.modelo, required this.aoTocar});

  final ModeloCatalogo modelo;
  final VoidCallback aoTocar;

  static String _numero(double v) {
    final t = v.toStringAsFixed(v == v.roundToDouble() ? 0 : 1);
    return t.replaceAll('.', ',');
  }

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final detalhe = [
      '${modelo.cilindradaCc} cc',
      'tanque ${_numero(modelo.tanqueLitros)} L',
      '${_numero(modelo.kmPorLitro)} km com 1 L',
    ].join(' · ');

    return InkWell(
      onTap: aoTocar,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    modelo.rotulo,
                    style: tema.textTheme.titleMedium?.copyWith(fontSize: 15),
                  ),
                  const SizedBox(height: 2),
                  Text(detalhe, style: tema.textTheme.bodyMedium),
                ],
              ),
            ),
            if (modelo.flex)
              Container(
                margin: const EdgeInsets.only(left: 10),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: Oficina.latao.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  'FLEX',
                  style: tema.textTheme.labelLarge?.copyWith(
                    fontSize: 10,
                    letterSpacing: 1.2,
                    color: Oficina.latao,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Campo que abre a busca. Mostra o modelo escolhido ou o convite.
class CampoBuscaModelo extends StatelessWidget {
  const CampoBuscaModelo({
    super.key,
    required this.escolhido,
    required this.aoTocar,
  });

  final ModeloCatalogo? escolhido;
  final VoidCallback aoTocar;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final vazio = escolhido == null;
    return EntradaSuave(
      chave: escolhido?.rotulo,
      deslocamento: 6,
      child: Material(
        color: tema.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(Oficina.raio),
        child: InkWell(
          borderRadius: BorderRadius.circular(Oficina.raio),
          onTap: aoTocar,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 12, 14),
            child: Row(
              children: [
                const Icon(Icons.search, size: 20, color: Oficina.latao),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    vazio ? 'Buscar a moto no catálogo' : escolhido!.rotulo,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: vazio
                        ? tema.textTheme.bodyMedium
                        : tema.textTheme.titleMedium?.copyWith(fontSize: 15),
                  ),
                ),
                Icon(
                  vazio ? Icons.chevron_right : Icons.edit_outlined,
                  size: 20,
                  color: Oficina.mute,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
