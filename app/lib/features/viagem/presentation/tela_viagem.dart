import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:life_and_roads/api.dart';
import 'package:life_and_roads/features/viagem/domain/precos_litro.dart';
import 'package:life_and_roads/features/viagem/domain/usecases/resumo_consumo.dart';
import 'package:life_and_roads/features/viagem/presentation/viagem_controller.dart';
import 'package:life_and_roads/features/mapa/presentation/tela_destino.dart';
import 'package:life_and_roads/tema.dart';
import 'package:life_and_roads/viagem/calculo.dart';

/// Viagem e posto. Persistência e ficha passam pelos repositórios.
class TelaViagem extends ConsumerStatefulWidget {
  const TelaViagem({super.key, this.visivel = true});

  /// IndexedStack deixa a tela montada. Recarrega a ficha ao voltar para esta aba.
  final bool visivel;

  @override
  ConsumerState<TelaViagem> createState() => _TelaViagemState();
}

class _TelaViagemState extends ConsumerState<TelaViagem> {
  final _kmViagem = TextEditingController();
  final _preco = TextEditingController();
  final _precoAlcool = TextEditingController();
  final _kmPainel = TextEditingController();
  final _litrosAbastecidos = TextEditingController();
  var _precosAplicados = false;

  ViagemController get _ctrl => ref.read(viagemControllerProvider.notifier);

  @override
  void initState() {
    super.initState();
    _preco.addListener(_aoMudarPreco);
    _precoAlcool.addListener(_aoMudarPreco);
    Future<void>.microtask(() {
      if (mounted) _ctrl.carregar();
    });
  }

  @override
  void didUpdateWidget(TelaViagem oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.visivel && !oldWidget.visivel) {
      _ctrl.relerFicha();
    }
  }

  @override
  void dispose() {
    _preco.removeListener(_aoMudarPreco);
    _precoAlcool.removeListener(_aoMudarPreco);
    _kmViagem.dispose();
    _preco.dispose();
    _precoAlcool.dispose();
    _kmPainel.dispose();
    _litrosAbastecidos.dispose();
    super.dispose();
  }

  void _aoMudarPreco() {
    if (mounted) setState(() {});
  }

  PrecosLitro get _precosAtuais => PrecosLitro(
        gasolina: _preco.text,
        alcool: _precoAlcool.text,
      );

  Future<void> _calcular() async {
    await _ctrl.calcular(
      km: ApiCaderneta.numero(_kmViagem.text),
      precos: _precosAtuais,
    );
  }

  Future<void> _marcarNoMapa() async {
    final km = await Navigator.of(context).push<double>(
      MaterialPageRoute(builder: (_) => const TelaDestino()),
    );
    if (!mounted || km == null) return;
    setState(() {
      _kmViagem.text = km < 10
          ? km.toStringAsFixed(1).replaceAll('.', ',')
          : km.toStringAsFixed(0);
    });
    _ctrl.limparResultado();
  }

  Future<void> _registrarAbastecimento() async {
    await _ctrl.registrarAbastecimento(
      kmPainel: ApiCaderneta.numero(_kmPainel.text),
      litros: ApiCaderneta.numero(_litrosAbastecidos.text),
      precos: _precosAtuais,
    );
  }

  void _aviso(String texto) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(texto)));
  }

  String _br(double n, {int casas = 1}) =>
      n.toStringAsFixed(casas).replaceAll('.', ',');

  String _dataCurta(String iso) {
    final d = DateTime.tryParse(iso);
    if (d == null) return '';
    final dd = d.day.toString().padLeft(2, '0');
    final mm = d.month.toString().padLeft(2, '0');
    return '$dd/$mm';
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(viagemControllerProvider, (anterior, atual) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        if (atual.aviso != null && atual.aviso != anterior?.aviso) {
          _aviso(atual.aviso!);
        }
        if (atual.erro != null && atual.erro != anterior?.erro) {
          _aviso(atual.erro!);
        }
        if (!_precosAplicados && !atual.carregando) {
          _preco.text = atual.precos.gasolina;
          _precoAlcool.text = atual.precos.alcool;
          _precosAplicados = true;
        }
      });
    });

    final estado = ref.watch(viagemControllerProvider);
    if (estado.carregando) {
      return const Center(child: CircularProgressIndicator());
    }

    final historico = estado.historico;
    final resultado = estado.resultado;
    final kmLitroGasolina = estado.kmLitroGasolina;
    final kmLitroAlcool = estado.kmLitroAlcool;
    final kmAtual = estado.kmAtual;
    final tanqueLitros = estado.tanqueLitros;
    final kmLitroViagem = estado.kmLitroViagem;
    final custoMedio = custoMedioPorKm(historico);
    final resumo = const ResumoConsumo().executar(historico);

    Widget? cartaoFlex;
    final pg = ApiCaderneta.numero(_preco.text);
    final pa = ApiCaderneta.numero(_precoAlcool.text);
    final kg = kmLitroGasolina;
    final ka = kmLitroAlcool;
    if (pg != null && pa != null && kg != null && ka != null) {
      final gas = custoPorKmCombustivel(precoLitro: pg, kmPorLitro: kg);
      final alcool = custoPorKmCombustivel(precoLitro: pa, kmPorLitro: ka);
      if (gas != null && alcool != null) {
        final vence = combustivelMaisBarato(
          precoGasolina: pg,
          precoAlcool: pa,
          kmLitroGasolina: kg,
          kmLitroAlcool: ka,
        );
        final melhor = vence == Combustivel.alcool ? alcool : gas;
        final nome = vence == null ? 'Tanto faz' : rotuloCombustivel(vence);
        final dica = textoDicaFlex(
          precoGasolina: pg,
          precoAlcool: pa,
          kmLitroGasolina: kg,
          kmLitroAlcool: ka,
        );
        cartaoFlex = CartaoOficina(
          destaque: true,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                nome.toUpperCase(),
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 4),
              Text(
                'Quanto sai cada km',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 4),
              Text(
                'R\$ ${_br(melhor, casas: 2)}',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: Oficina.creme,
                      fontSize: 36,
                      height: 1.1,
                    ),
              ),
              if (dica != null) ...[
                const SizedBox(height: 8),
                Text(
                  dica.contains('álcool') && (vence == Combustivel.alcool)
                      ? 'Hoje o álcool sai mais em conta neste rolê.'
                      : dica.contains('gasolina') && vence == Combustivel.gasolina
                          ? 'Hoje a gasolina sai mais em conta neste rolê.'
                          : 'Tanto faz gasolina ou álcool hoje.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ],
          ),
        );
      }
    }

    final nomeComb = rotuloCombustivel(estado.combustivelViagem).toLowerCase();
    String subtituloViagem;
    if (kmLitroViagem == null) {
      subtituloViagem =
          'Falta quanto a moto anda no $nomeComb. Preencha na Ficha.';
    } else {
      final auto = tanqueLitros == null
          ? null
          : autonomiaKm(tanqueLitros: tanqueLitros, kmPorLitro: kmLitroViagem);
      if (auto == null) {
        subtituloViagem =
            'Com $nomeComb, uns ${_br(kmLitroViagem)} km por litro. '
            'Informe o tanque na Ficha para saber se o rolê cabe.';
      } else {
        subtituloViagem =
            'Com $nomeComb, uns ${_br(kmLitroViagem)} km por litro. '
            'Tanque ${_br(tanqueLitros!)} L, cheio dá uns ${_br(auto, casas: 0)} km.';
      }
    }

    String? avisoTanque;
    if (resultado != null && tanqueLitros != null) {
      final cabe = cabeNoTanque(
        litrosViagem: resultado.litros,
        tanqueLitros: tanqueLitros,
      );
      if (cabe == true) {
        avisoTanque = 'Cabe no tanque de ${_br(tanqueLitros)} L.';
      } else if (cabe == false) {
        avisoTanque =
            'Não cabe no tanque (${_br(tanqueLitros)} L). Precisa uns ${_br(resultado.litros)} L.';
      }
    }

    return ListView(
      padding: paddingOficina(context),
      children: [
        TituloOficina(
          'Viagem',
          subtitulo: subtituloViagem,
        ),
        if (historico.isNotEmpty) ...[
          const SizedBox(height: 16),
          CartaoOficina(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    StatOficina(
                      'POR KM',
                      custoMedio == null ? '-' : _br(custoMedio, casas: 2),
                    ),
                    StatOficina('POSTOS', '${historico.length}'),
                    StatOficina(
                      'COM 1 L',
                      _br(historico.first.kmPorLitro),
                    ),
                  ],
                ),
                if (resumo.barras.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  for (final b in resumo.barras) _barraConsumo(b),
                ],
              ],
            ),
          ),
        ],
        const SizedBox(height: 16),
        _seletor(
          estado.combustivelViagem,
          _ctrl.definirCombustivel,
        ),
        DuplaCampos(
          esquerda: _campo(_preco, 'Preço gasolina (R\$)'),
          direita: _campo(_precoAlcool, 'Preço álcool (R\$)'),
        ),
        if (cartaoFlex != null) ...[
          cartaoFlex,
          const SizedBox(height: 16),
        ],
        _campo(_kmViagem, 'Km deste rolê'),
        OutlinedButton(
          onPressed: _marcarNoMapa,
          child: const Text('Marcar no mapa'),
        ),
        const SizedBox(height: 8),
        Text(
          'Km de estrada (precisa de internet). Sem sinal, digite os km na mão.',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: 12),
        FilledButton(
          onPressed: _calcular,
          child: const Text('Calcular'),
        ),
        if (resultado != null) ...[
          const SizedBox(height: 16),
          CartaoOficina(
            destaque: true,
            child: Column(
              children: [
                Text(
                  rotuloCombustivel(estado.combustivelViagem).toUpperCase(),
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                Text(
                  '${_br(resultado.litros)} L',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                Text(
                  'R\$ ${_br(resultado.reais, casas: 2)}',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                if (avisoTanque != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    avisoTanque,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ],
            ),
          ),
        ],
        const SizedBox(height: 32),
        TituloOficina(
          'Abastecimento',
          subtitulo: kmAtual == null
              ? 'Ainda falta o km do painel na Ficha.'
              : 'Último km gravado: ${_br(kmAtual, casas: 0)}. '
                  'Escolha gasolina ou álcool, o km no painel agora e os litros que entrou.',
        ),
        const SizedBox(height: 16),
        _seletor(
          estado.combustivelAbastecimento,
          _ctrl.definirCombustivelAbastecimento,
        ),
        DuplaCampos(
          esquerda: _campo(_kmPainel, 'Km no painel agora'),
          direita: _campo(_litrosAbastecidos, 'Litros que entrou'),
        ),
        OutlinedButton(
          onPressed: _registrarAbastecimento,
          child: const Text('Registrar abastecimento'),
        ),
        if (historico.isNotEmpty) ...[
          const SizedBox(height: 24),
          TituloOficina(
            'Postos',
            subtitulo: 'Neste aparelho, sem placa.',
          ),
          const SizedBox(height: 12),
          for (final r in historico) _linhaPosto(context, r),
        ],
      ],
    );
  }

  Widget _barraConsumo(BarraConsumo b) {
    final largura = b.fracao < 0.06 ? 0.06 : b.fracao;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${_dataCurta(b.registro.em)}  '
            'R\$ ${_br(b.registro.reaisPorKm, casas: 2)} por km',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 4),
          FractionallySizedBox(
            widthFactor: largura,
            alignment: Alignment.centerLeft,
            child: Container(
              height: 8,
              decoration: BoxDecoration(
                color: Oficina.latao,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _linhaPosto(BuildContext context, RegistroAbastecimento r) {
    final data = _dataCurta(r.em);
    final nome = rotuloCombustivel(r.combustivel);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: CartaoOficina(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              data.isEmpty ? nome : '$data  $nome',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 6),
            Text(
              '${_br(r.kmRodados, casas: 0)} km · ${_br(r.litros)} L · '
              '${_br(r.kmPorLitro)} km com 1 L',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 4),
            Text(
              'R\$ ${_br(r.reais, casas: 2)} · R\$ ${_br(r.reaisPorKm, casas: 2)} por km',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }

  Widget _seletor(Combustivel atual, ValueChanged<Combustivel> aoMudar) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: SegmentedButton<Combustivel>(
        segments: const [
          ButtonSegment(
            value: Combustivel.gasolina,
            label: Text('Gasolina'),
          ),
          ButtonSegment(
            value: Combustivel.alcool,
            label: Text('Álcool'),
          ),
        ],
        selected: {atual},
        onSelectionChanged: (s) => aoMudar(s.first),
      ),
    );
  }

  Widget _campo(TextEditingController c, String rotulo) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: c,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        maxLength: 8,
        inputFormatters: [
          FilteringTextInputFormatter.allow(RegExp(r'[0-9,.]')),
        ],
        decoration: InputDecoration(
          labelText: rotulo,
          counterText: '',
        ),
      ),
    );
  }
}
