import 'dart:math' as math;
import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:life_and_roads/api.dart';
import 'package:life_and_roads/core/widgets/movimento.dart';
import 'package:life_and_roads/features/mapa/presentation/tela_destino.dart';
import 'package:life_and_roads/features/mapa/presentation/widgets/bilhete_viagem.dart';
import 'package:life_and_roads/features/viagem/domain/precos_litro.dart';
import 'package:life_and_roads/features/viagem/presentation/viagem_controller.dart';
import 'package:life_and_roads/features/viagem/presentation/viagem_estado.dart';
import 'package:life_and_roads/tema.dart';
import 'package:life_and_roads/viagem/calculo.dart';

/// Cartão flutuante na base do mapa, com dois estados.
///
/// Recolhido, as ações do mapa (rastrear, onde estou, traçar trajeto) e uma
/// linha de ajuda. Aberto, a calculadora da viagem: km (digitados ou vindos
/// do trajeto), combustível, os preços do dia e o [BilheteViagem] com o
/// resultado. Os preços vivem no estado do controller; quem os edita é a
/// aba Posto.
class CartaoViagem extends ConsumerStatefulWidget {
  const CartaoViagem({
    super.key,
    required this.rastreando,
    required this.temPonto,
    required this.autonomiaKm,
    required this.aoRastrear,
    required this.aoParar,
    required this.aoOndeEstou,
  });

  final bool rastreando;
  final bool temPonto;

  /// Km com o tanque cheio pela ficha. Raio do círculo do mapa.
  final double? autonomiaKm;
  final VoidCallback aoRastrear;
  final VoidCallback aoParar;
  final VoidCallback aoOndeEstou;

  @override
  ConsumerState<CartaoViagem> createState() => _CartaoViagemState();
}

class _CartaoViagemState extends ConsumerState<CartaoViagem> {
  final _km = TextEditingController();
  var _aberto = false;
  var _tracando = false;

  /// Km do último cálculo. O campo pode mudar depois; o cupom não.
  double? _kmCalculado;

  ViagemController get _ctrl => ref.read(viagemControllerProvider.notifier);

  @override
  void dispose() {
    _km.dispose();
    super.dispose();
  }

  void _abrir() => setState(() => _aberto = true);

  void _recolher() {
    FocusManager.instance.primaryFocus?.unfocus();
    setState(() => _aberto = false);
  }

  /// A TelaDestino devolve os km de estrada; eles preenchem o campo e
  /// abrem a calculadora. Guarda de toque duplo, como nas folhas.
  Future<void> _tracarTrajeto() async {
    if (_tracando) return;
    _tracando = true;
    try {
      final km = await Navigator.of(context)
          .push<double>(MaterialPageRoute(builder: (_) => const TelaDestino()));
      if (!mounted || km == null) return;
      setState(() {
        _km.text = BilheteViagem.kmTexto(km);
        _aberto = true;
      });
      _ctrl.limparResultado();
    } finally {
      _tracando = false;
    }
  }

  /// O listen da aba Posto (montada no IndexedStack) avisa o erro quando a
  /// mensagem muda. Quando ela repete, quem avisa é este cartão, como faz
  /// a folha do abastecimento.
  Future<void> _calcular() async {
    FocusManager.instance.primaryFocus?.unfocus();
    final km = ApiCaderneta.numero(_km.text);
    final erroAntes = ref.read(viagemControllerProvider).erro;
    await _ctrl.calcular(
      km: km,
      precos: ref.read(viagemControllerProvider).precos,
    );
    if (!mounted) return;
    final estado = ref.read(viagemControllerProvider);
    final erro = estado.erro;
    if (erro != null) {
      if (erro == erroAntes) _aviso(erro);
      return;
    }
    setState(() => _kmCalculado = km);
  }

  void _aviso(String texto) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(texto)));
  }

  String _linhaPrecos(PrecosLitro precos) {
    final pg = ApiCaderneta.numero(precos.gasolina);
    final pa = ApiCaderneta.numero(precos.alcool);
    final partes = [
      if (pg != null) 'gasolina R\$ ${BilheteViagem.reaisTexto(pg)}',
      if (pa != null) 'álcool R\$ ${BilheteViagem.reaisTexto(pa)}',
    ];
    if (partes.isEmpty) return 'Informe os preços na aba Posto.';
    return 'Preços de hoje: ${partes.join(', ')}. Ajuste na aba Posto.';
  }

  String? _avisoTanque(ViagemEstado estado) {
    final resultado = estado.resultado;
    final tanque = estado.tanqueLitros;
    if (resultado == null || tanque == null) return null;
    final cabe = cabeNoTanque(
      litrosViagem: resultado.litros,
      tanqueLitros: tanque,
    );
    if (cabe == null) return null;
    final t = BilheteViagem.litrosTexto(tanque);
    if (cabe) return 'Cabe no tanque de $t L.';
    return 'Ultrapassa o tanque de $t L. '
        'A viagem precisa de ${BilheteViagem.litrosTexto(resultado.litros)} L.';
  }

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final inferior = MediaQuery.paddingOf(context).bottom;
    final tetoTela = MediaQuery.sizeOf(context).height * 0.6;

    return LayoutBuilder(
      builder: (context, limites) {
        final margem = 12 + inferior;
        // Nunca mais que 60% da tela nem mais que o espaço do mapa (o
        // teclado encolhe o corpo). O LayoutBuilder recebe a altura do
        // Stack pelo Align da TelaMapa.
        final teto = limites.maxHeight.isFinite
            ? math.max(120.0, math.min(tetoTela, limites.maxHeight - margem))
            : tetoTela;

        return Padding(
          padding: EdgeInsets.fromLTRB(12, 0, 12, margem),
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(Oficina.raio),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x40000000),
                  blurRadius: 16,
                  offset: Offset(0, 6),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(Oficina.raio),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
                child: ColoredBox(
                  color: tema.colorScheme.surface.withValues(alpha: 0.90),
                  child: AnimatedSize(
                    duration: Movimento.medio,
                    curve: Movimento.curva,
                    alignment: Alignment.bottomCenter,
                    child: AnimatedSwitcher(
                      duration: Movimento.curto,
                      switchInCurve: Movimento.curva,
                      switchOutCurve: Movimento.curva,
                      child: _aberto
                          ? KeyedSubtree(
                              key: const ValueKey('aberto'),
                              child: _abertoConteudo(context, teto),
                            )
                          : KeyedSubtree(
                              key: const ValueKey('recolhido'),
                              child: _recolhidoConteudo(context),
                            ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _botaoTracar(ThemeData tema) {
    return FilledButton.tonalIcon(
      onPressed: _tracarTrajeto,
      // O tema dá largura infinita ao botão; solto numa Row isso estoura.
      style: FilledButton.styleFrom(
        backgroundColor: Oficina.latao.withValues(alpha: 0.18),
        foregroundColor: tema.colorScheme.onSurface,
        minimumSize: const Size(0, 52),
      ),
      icon: const Icon(Icons.route_outlined, size: 18),
      label: const Text('Traçar trajeto'),
    );
  }

  Widget _recolhidoConteudo(BuildContext context) {
    final tema = Theme.of(context);
    final estreita = telaEstreita(context);
    final autonomia = widget.autonomiaKm;

    final rastrear = FilledButton(
      onPressed: widget.rastreando ? widget.aoParar : widget.aoRastrear,
      child: Text(widget.rastreando ? 'Parar' : 'Rastrear'),
    );
    final ondeEstou = OutlinedButton.icon(
      onPressed: widget.aoOndeEstou,
      style: OutlinedButton.styleFrom(minimumSize: const Size(0, 52)),
      icon: const Icon(Icons.ios_share, size: 18),
      label: const Text('Onde estou'),
    );
    final tracar = _botaoTracar(tema);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(child: rastrear),
              if (widget.temPonto) ...[
                const SizedBox(width: 10),
                // Em tela estreita os dois dividem a linha; na larga o
                // trajeto entra ao lado.
                if (estreita) Expanded(child: ondeEstou) else ondeEstou,
              ],
              if (!estreita) ...[const SizedBox(width: 10), tracar],
            ],
          ),
          if (estreita) ...[const SizedBox(height: 10), tracar],
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (widget.temPonto && autonomia != null)
                      Text(
                        'Alcance com tanque cheio: '
                        '${autonomia.toStringAsFixed(0)} km em linha reta.',
                        style: tema.textTheme.bodyMedium,
                      ),
                    Text(
                      'Toque longo no mapa marca posto ou oficina.',
                      style: tema.textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              TextButton(
                onPressed: _abrir,
                style: TextButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                ),
                child: const Text('Calcular viagem'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _abertoConteudo(BuildContext context, double teto) {
    final tema = Theme.of(context);
    final estado = ref.watch(viagemControllerProvider);
    final resultado = estado.resultado;
    final kmCupom = _kmCalculado;

    return ConstrainedBox(
      constraints: BoxConstraints(maxHeight: teto),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 6, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'VIAGEM',
                    style: tema.textTheme.labelLarge?.copyWith(
                      fontSize: 11,
                      letterSpacing: 1.4,
                      color: Oficina.mute,
                    ),
                  ),
                ),
                IconButton(
                  tooltip: 'Recolher',
                  onPressed: _recolher,
                  color: Oficina.mute,
                  icon: const Icon(Icons.expand_more),
                ),
              ],
            ),
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: TextField(
                    controller: _km,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    maxLength: 8,
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[0-9,.]')),
                    ],
                    decoration: const InputDecoration(
                      labelText: 'Km da viagem',
                      counterText: '',
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                _botaoTracar(tema),
              ],
            ),
            const SizedBox(height: 12),
            SegmentedButton<Combustivel>(
              segments: const [
                ButtonSegment(
                  value: Combustivel.gasolina,
                  label: Text('Gasolina'),
                ),
                ButtonSegment(value: Combustivel.alcool, label: Text('Álcool')),
              ],
              selected: {estado.combustivelViagem},
              onSelectionChanged: (s) => _ctrl.definirCombustivel(s.first),
            ),
            const SizedBox(height: 10),
            Text(
              _linhaPrecos(estado.precos),
              style: tema.textTheme.bodyMedium?.copyWith(color: Oficina.mute),
            ),
            const SizedBox(height: 12),
            FilledButton(onPressed: _calcular, child: const Text('Calcular')),
            if (resultado != null && kmCupom != null) ...[
              const SizedBox(height: 14),
              EntradaSuave(
                chave: resultado,
                child: BilheteViagem(
                  km: kmCupom,
                  combustivel: estado.combustivelViagem,
                  litros: resultado.litros,
                  reais: resultado.reais,
                  avisoTanque: _avisoTanque(estado),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
