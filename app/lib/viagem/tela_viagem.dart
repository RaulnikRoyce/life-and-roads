import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:life_and_roads/api.dart';
import 'package:life_and_roads/mapa/tela_destino.dart';
import 'package:life_and_roads/tema.dart';
import 'package:life_and_roads/viagem/calculo.dart';
import 'package:life_and_roads/viagem/historico.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Viagem: km ÷ km/l × preço. Abastecimento: km do painel − km da ficha ÷ litros.
class TelaViagem extends StatefulWidget {
  const TelaViagem({super.key});

  @override
  State<TelaViagem> createState() => _TelaViagemState();
}

class _TelaViagemState extends State<TelaViagem> {
  static const _chavePreco = 'preco_litro_v1';
  static const _chavePrecoAlcool = 'preco_alcool_v1';

  final _kmViagem = TextEditingController();
  final _preco = TextEditingController();
  final _precoAlcool = TextEditingController();
  final _kmPainel = TextEditingController();
  final _litrosAbastecidos = TextEditingController();

  double? _kmLitroGasolina;
  double? _kmLitroAlcool;
  double? _kmAtual;
  double? _tanqueLitros;
  Combustivel _combustivelViagem = Combustivel.gasolina;
  Combustivel _combustivelAbastecimento = Combustivel.gasolina;
  ResultadoViagem? _resultado;
  List<RegistroAbastecimento> _historico = [];
  bool _carregando = true;

  @override
  void initState() {
    super.initState();
    _preco.addListener(_aoMudarPreco);
    _precoAlcool.addListener(_aoMudarPreco);
    _carregar();
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

  double? _numero(String bruto) => ApiCaderneta.numero(bruto);

  double? get _kmLitroViagem => _combustivelViagem == Combustivel.alcool
      ? _kmLitroAlcool
      : _kmLitroGasolina;

  Future<void> _carregar() async {
    final prefs = await SharedPreferences.getInstance();
    _preco.text = prefs.getString(_chavePreco) ?? '';
    _precoAlcool.text = prefs.getString(_chavePrecoAlcool) ?? '';

    final bruto = prefs.getString(ApiCaderneta.chaveFicha);
    if (bruto != null) {
      try {
        final mapa = jsonDecode(bruto);
        if (mapa is Map<String, dynamic>) _aplicarFicha(mapa);
      } on FormatException {
        // ignora
      }
    }

    final token = prefs.getString(ApiCaderneta.chaveToken);
    if (token != null && token.isNotEmpty) {
      try {
        final remota = await ApiCaderneta.buscarFicha(token);
        if (remota != null) _aplicarFicha(remota);
      } catch (_) {
        // fica o local
      }
    }

    _historico = await HistoricoAbastecimento.carregar();

    if (mounted) setState(() => _carregando = false);
  }

  void _aplicarFicha(Map<String, dynamic> mapa) {
    _kmLitroGasolina = ApiCaderneta.numero(mapa['kmLitro']);
    _kmLitroAlcool = ApiCaderneta.numero(mapa['kmLitroAlcool']);
    _kmAtual = ApiCaderneta.numero(mapa['kmAtual']);
    _tanqueLitros = ApiCaderneta.numero(mapa['tanqueLitros']);
    final comb = combustivelDe(mapa['combustivel']);
    _combustivelViagem = comb;
    _combustivelAbastecimento = comb;
  }

  double? get _precoDoCombustivel {
    return _combustivelViagem == Combustivel.alcool
        ? _numero(_precoAlcool.text)
        : _numero(_preco.text);
  }

  Future<void> _calcular() async {
    final km = _numero(_kmViagem.text);
    final preco = _precoDoCombustivel;
    if (km == null || preco == null) {
      _aviso(
        _combustivelViagem == Combustivel.alcool
            ? 'Informe os km da viagem e o preço do álcool.'
            : 'Informe os km da viagem e o preço da gasolina.',
      );
      return;
    }
    final kmL = _kmLitroViagem;
    if (kmL == null) {
      _aviso(
        _combustivelViagem == Combustivel.alcool
            ? 'Falta o km/l do álcool. Abasteça com álcool ou preencha na Ficha.'
            : 'Preencha o km/l da gasolina na Ficha antes de calcular.',
      );
      return;
    }

    final r = calcularViagem(
      km: km,
      kmPorLitro: kmL,
      precoLitro: preco,
    );
    if (r == null) {
      _aviso('Valores fora da faixa. km até 5000, preço do litro entre 2 e 20.');
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_chavePreco, _preco.text.trim());
    await prefs.setString(_chavePrecoAlcool, _precoAlcool.text.trim());
    setState(() => _resultado = r);
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
      _resultado = null;
    });
  }

  Future<void> _registrarAbastecimento() async {
    final kmPainel = _numero(_kmPainel.text);
    final litros = _numero(_litrosAbastecidos.text);
    final preco = _combustivelAbastecimento == Combustivel.alcool
        ? _numero(_precoAlcool.text)
        : _numero(_preco.text);
    if (kmPainel == null || litros == null) {
      _aviso('Informe o km do painel no posto e os litros deste combustível.');
      return;
    }
    if (preco == null) {
      _aviso(
        _combustivelAbastecimento == Combustivel.alcool
            ? 'Informe o preço do álcool para gravar o R\$/km.'
            : 'Informe o preço da gasolina para gravar o R\$/km.',
      );
      return;
    }
    if (_kmAtual == null) {
      _aviso('Preencha o km atual na Ficha antes do abastecimento.');
      return;
    }

    final consumo = consumoDoPainel(
      kmAnterior: _kmAtual!,
      kmPainel: kmPainel,
      litros: litros,
    );
    if (consumo == null) {
      _aviso(
        'km do painel tem que ser maior que o da ficha '
        '(${_br(_kmAtual!, casas: 0)}). Litros entre 0,5 e 40.',
      );
      return;
    }

    final registro = registroDoPosto(
      consumo: consumo,
      litros: litros,
      precoLitro: preco,
      kmPainel: kmPainel,
      combustivel: _combustivelAbastecimento,
    );
    if (registro == null) {
      _aviso('Preço do litro entre 2 e 20.');
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    final bruto = prefs.getString(ApiCaderneta.chaveFicha);
    if (bruto == null) {
      _aviso('Salve a Ficha primeiro.');
      return;
    }

    Map<String, dynamic> mapa;
    try {
      mapa = jsonDecode(bruto) as Map<String, dynamic>;
    } on FormatException {
      _aviso('Ficha local inválida. Abra a Ficha e salve de novo.');
      return;
    }

    final kmL = consumo.kmPorLitro.toStringAsFixed(1);
    mapa['kmAtual'] = kmPainel.toStringAsFixed(0);
    mapa['combustivel'] = _combustivelAbastecimento.name;
    if (_combustivelAbastecimento == Combustivel.alcool) {
      mapa['kmLitroAlcool'] = kmL;
    } else {
      mapa['kmLitro'] = kmL;
    }
    await prefs.setString(ApiCaderneta.chaveFicha, jsonEncode(mapa));

    final token = prefs.getString(ApiCaderneta.chaveToken);
    if (token != null && token.isNotEmpty) {
      try {
        await ApiCaderneta.salvarFicha(token, ApiCaderneta.fichaParaApi(mapa));
      } catch (_) {
        // local já gravou
      }
    }

    await prefs.setString(_chavePreco, _preco.text.trim());
    await prefs.setString(_chavePrecoAlcool, _precoAlcool.text.trim());
    final historico = await HistoricoAbastecimento.acrescentar(registro);

    setState(() {
      _kmAtual = kmPainel;
      if (_combustivelAbastecimento == Combustivel.alcool) {
        _kmLitroAlcool = consumo.kmPorLitro;
      } else {
        _kmLitroGasolina = consumo.kmPorLitro;
      }
      _combustivelViagem = _combustivelAbastecimento;
      _historico = historico;
    });
    _aviso(
      '${_br(consumo.kmRodados, casas: 0)} km ÷ ${_br(litros)} L '
      '= ${_br(consumo.kmPorLitro)} km/l · '
      'R\$ ${_br(registro.reaisPorKm, casas: 2)}/km.',
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

  double? get _custoMedio => custoMedioPorKm(_historico);

  String? get _dicaFlex {
    final pg = _numero(_preco.text);
    final pa = _numero(_precoAlcool.text);
    final kg = _kmLitroGasolina;
    final ka = _kmLitroAlcool;
    if (pg == null || pa == null || kg == null || ka == null) return null;
    return textoDicaFlex(
      precoGasolina: pg,
      precoAlcool: pa,
      kmLitroGasolina: kg,
      kmLitroAlcool: ka,
    );
  }

  Widget? _cartaoFlex() {
    final pg = _numero(_preco.text);
    final pa = _numero(_precoAlcool.text);
    final kg = _kmLitroGasolina;
    final ka = _kmLitroAlcool;
    if (pg == null || pa == null || kg == null || ka == null) return null;
    final gas = custoPorKmCombustivel(precoLitro: pg, kmPorLitro: kg);
    final alcool = custoPorKmCombustivel(precoLitro: pa, kmPorLitro: ka);
    if (gas == null || alcool == null) return null;
    final vence = combustivelMaisBarato(
      precoGasolina: pg,
      precoAlcool: pa,
      kmLitroGasolina: kg,
      kmLitroAlcool: ka,
    );
    final melhor = vence == Combustivel.alcool ? alcool : gas;
    final nome = vence == null
        ? 'Tanto faz'
        : rotuloCombustivel(vence);
    final dica = _dicaFlex;
    return CartaoOficina(
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
            'R\$ ${_br(melhor, casas: 2)}/km',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: Oficina.creme,
                  fontSize: 36,
                  height: 1.1,
                ),
          ),
          if (dica != null) ...[
            const SizedBox(height: 8),
            Text(dica, style: Theme.of(context).textTheme.bodyMedium),
          ],
          const SizedBox(height: 12),
          Text(
            'Gasolina R\$ ${_br(gas, casas: 2)}/km · '
            'álcool R\$ ${_br(alcool, casas: 2)}/km',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }

  String get _subtituloViagem {
    final kmL = _kmLitroViagem;
    final nome = rotuloCombustivel(_combustivelViagem).toLowerCase();
    if (kmL == null) {
      return 'Falta o km/l de $nome. Sem ele não dá para estimar o combustível.';
    }
    final auto = _tanqueLitros == null
        ? null
        : autonomiaKm(tanqueLitros: _tanqueLitros!, kmPorLitro: kmL);
    if (auto == null) {
      return 'Usando ${_br(kmL)} km/l de $nome. '
          'Informe o tanque na Ficha para saber se a viagem cabe.';
    }
    return 'Usando ${_br(kmL)} km/l de $nome. '
        'Tanque ${_br(_tanqueLitros!)} L — autonomia cheio ${_br(auto, casas: 0)} km.';
  }

  String? get _avisoTanque {
    final r = _resultado;
    final tanque = _tanqueLitros;
    if (r == null || tanque == null) return null;
    final cabe = cabeNoTanque(litrosViagem: r.litros, tanqueLitros: tanque);
    if (cabe == null) return null;
    if (cabe) {
      return 'Cabe no tanque de ${_br(tanque)} L.';
    }
    return 'Não cabe: tanque ${_br(tanque)} L, precisa ${_br(r.litros)} L.';
  }

  @override
  Widget build(BuildContext context) {
    if (_carregando) {
      return const Center(child: CircularProgressIndicator());
    }

    final flex = _cartaoFlex();

    return ListView(
      padding: paddingOficina(context),
      children: [
        TituloOficina(
          'Viagem',
          subtitulo: _subtituloViagem,
        ),
        if (_historico.isNotEmpty) ...[
          const SizedBox(height: 16),
          CartaoOficina(
            child: Row(
              children: [
                StatOficina(
                  'R\$/KM',
                  _custoMedio == null
                      ? '—'
                      : _br(_custoMedio!, casas: 2),
                ),
                StatOficina('POSTOS', '${_historico.length}'),
                StatOficina(
                  'ÚLTIMO KM/L',
                  _br(_historico.first.kmPorLitro),
                ),
              ],
            ),
          ),
        ],
        const SizedBox(height: 16),
        _seletor(
          _combustivelViagem,
          (c) => setState(() {
            _combustivelViagem = c;
            _combustivelAbastecimento = c;
            _resultado = null;
          }),
        ),
        DuplaCampos(
          esquerda: _campo(_preco, 'Preço gasolina (R\$)'),
          direita: _campo(_precoAlcool, 'Preço álcool (R\$)'),
        ),
        if (flex != null) ...[
          flex,
          const SizedBox(height: 16),
        ],
        _campo(_kmViagem, 'km desta viagem'),
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
        if (_resultado != null) ...[
          const SizedBox(height: 16),
          CartaoOficina(
            destaque: true,
            child: Column(
              children: [
                Text(
                  rotuloCombustivel(_combustivelViagem).toUpperCase(),
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                Text(
                  '${_br(_resultado!.litros)} L',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                Text(
                  'R\$ ${_br(_resultado!.reais, casas: 2)}',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                if (_avisoTanque != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    _avisoTanque!,
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
          subtitulo: _kmAtual == null
              ? 'Falta o km atual na Ficha.'
              : 'Último km da ficha: ${_br(_kmAtual!, casas: 0)}. '
                  'Use o preço da gasolina ou do álcool acima. '
                  'Km do painel − esse km, ÷ litros = km/l e R\$/km.',
        ),
        const SizedBox(height: 16),
        DuplaCampos(
          esquerda: _campo(_kmPainel, 'km do painel no posto'),
          direita: _campo(_litrosAbastecidos, 'Litros deste combustível'),
        ),
        OutlinedButton(
          onPressed: _registrarAbastecimento,
          child: const Text('Registrar abastecimento'),
        ),
        if (_historico.isNotEmpty) ...[
          const SizedBox(height: 24),
          TituloOficina(
            'Postos',
            subtitulo: 'Neste aparelho. Sem placa.',
          ),
          const SizedBox(height: 12),
          for (final r in _historico) _linhaPosto(context, r),
        ],
      ],
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
              '${_br(r.kmPorLitro)} km/l',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 4),
            Text(
              'R\$ ${_br(r.reais, casas: 2)} · R\$ ${_br(r.reaisPorKm, casas: 2)}/km',
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
