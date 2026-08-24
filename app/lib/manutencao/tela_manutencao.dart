import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:life_and_roads/api.dart';
import 'package:life_and_roads/manutencao/extra.dart';
import 'package:life_and_roads/manutencao/lembrete.dart';
import 'package:life_and_roads/manutencao/servicos.dart';
import 'package:life_and_roads/tema.dart';
import 'package:life_and_roads/viagem/calculo.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Oficina, km, papelada e CNH. Serviço e km ficam neste aparelho.
class TelaManutencao extends StatefulWidget {
  const TelaManutencao({super.key});

  @override
  State<TelaManutencao> createState() => _TelaManutencaoState();
}

class _TelaManutencaoState extends State<TelaManutencao> {
  static const _chave = 'manutencao_v1';

  DateTime? _oleoUltima;
  DateTime? _oleoProxima;
  DateTime? _revisaoUltima;
  DateTime? _pneusUltima;
  DateTime? _pneusProxima;
  DateTime? _ipvaProxima;
  DateTime? _seguroProxima;
  DateTime? _licenciamentoProxima;
  DateTime? _cnhProxima;
  bool _carregando = true;
  double? _kmAtual;
  List<RegistroServico> _servicos = [];

  final _oleoKmUltima = TextEditingController();
  final _oleoKmIntervalo = TextEditingController(text: '4000');
  final _correnteKmUltima = TextEditingController();
  final _correnteKmIntervalo = TextEditingController(text: '1000');
  final _servicoTipo = TextEditingController();
  final _servicoKm = TextEditingController();
  final _servicoReais = TextEditingController();

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  @override
  void dispose() {
    _oleoKmUltima.dispose();
    _oleoKmIntervalo.dispose();
    _correnteKmUltima.dispose();
    _correnteKmIntervalo.dispose();
    _servicoTipo.dispose();
    _servicoKm.dispose();
    _servicoReais.dispose();
    super.dispose();
  }

  DateTime? _deIso(Object? valor) {
    final t = '${valor ?? ''}'.trim();
    if (t.length < 10) return null;
    return DateTime.tryParse(t.substring(0, 10));
  }

  String? _paraIso(DateTime? d) {
    if (d == null) return null;
    final m = d.month.toString().padLeft(2, '0');
    final dia = d.day.toString().padLeft(2, '0');
    return '${d.year}-$m-$dia';
  }

  String _rotulo(DateTime? d) {
    if (d == null) return 'Toque para escolher';
    final m = d.month.toString().padLeft(2, '0');
    final dia = d.day.toString().padLeft(2, '0');
    return '$dia/$m/${d.year}';
  }

  Map<String, dynamic> _mapa() => {
        'oleoUltima': _paraIso(_oleoUltima),
        'oleoProxima': _paraIso(_oleoProxima),
        'revisaoUltima': _paraIso(_revisaoUltima),
        'pneusUltima': _paraIso(_pneusUltima),
        'pneusProxima': _paraIso(_pneusProxima),
        'ipvaProxima': _paraIso(_ipvaProxima),
        'seguroProxima': _paraIso(_seguroProxima),
        'licenciamentoProxima': _paraIso(_licenciamentoProxima),
      };

  void _aplicar(Map<String, dynamic> mapa) {
    _oleoUltima = _deIso(mapa['oleoUltima']);
    _oleoProxima = _deIso(mapa['oleoProxima']);
    _revisaoUltima = _deIso(mapa['revisaoUltima']);
    _pneusUltima = _deIso(mapa['pneusUltima']);
    _pneusProxima = _deIso(mapa['pneusProxima']);
    _ipvaProxima = _deIso(mapa['ipvaProxima']);
    _seguroProxima = _deIso(mapa['seguroProxima']);
    _licenciamentoProxima = _deIso(mapa['licenciamentoProxima']);
  }

  void _aplicarExtra(ManutencaoExtra extra) {
    _oleoKmUltima.text = extra.oleoKmUltima == null
        ? ''
        : extra.oleoKmUltima!.toStringAsFixed(0);
    _oleoKmIntervalo.text = extra.oleoKmIntervalo.toStringAsFixed(0);
    _correnteKmUltima.text = extra.correnteKmUltima == null
        ? ''
        : extra.correnteKmUltima!.toStringAsFixed(0);
    _correnteKmIntervalo.text = extra.correnteKmIntervalo.toStringAsFixed(0);
    _cnhProxima = _deIso(extra.cnhProxima);
  }

  ManutencaoExtra _extraAtual() {
    return ManutencaoExtra(
      oleoKmUltima: ApiCaderneta.numero(_oleoKmUltima.text),
      oleoKmIntervalo: ApiCaderneta.numero(_oleoKmIntervalo.text) ?? 4000,
      correnteKmUltima: ApiCaderneta.numero(_correnteKmUltima.text),
      correnteKmIntervalo: ApiCaderneta.numero(_correnteKmIntervalo.text) ?? 1000,
      cnhProxima: _paraIso(_cnhProxima),
    );
  }

  Future<void> _carregar() async {
    final prefs = await SharedPreferences.getInstance();
    final bruto = prefs.getString(_chave);
    if (bruto != null) {
      try {
        final mapa = jsonDecode(bruto);
        if (mapa is Map<String, dynamic>) _aplicar(mapa);
      } on FormatException {
        // ignora
      }
    }

    final token = prefs.getString(ApiCaderneta.chaveToken);
    if (token != null && token.isNotEmpty) {
      try {
        final remota = await ApiCaderneta.buscarManutencao(token);
        if (remota != null) _aplicar(remota);
      } catch (_) {
        // fica o local
      }
    }

    final fichaBruto = prefs.getString(ApiCaderneta.chaveFicha);
    if (fichaBruto != null) {
      try {
        final mapa = jsonDecode(fichaBruto);
        if (mapa is Map<String, dynamic>) {
          _kmAtual = ApiCaderneta.numero(mapa['kmAtual']);
        }
      } on FormatException {
        // ignora
      }
    }

    _aplicarExtra(await ManutencaoExtra.carregar());
    _servicos = await HistoricoServico.carregar();

    if (mounted) setState(() => _carregando = false);
  }

  int? _dias(DateTime? proxima) {
    if (proxima == null) return null;
    final hoje = DateTime.now();
    final a = DateTime(hoje.year, hoje.month, hoje.day);
    final b = DateTime(proxima.year, proxima.month, proxima.day);
    return b.difference(a).inDays;
  }

  String? _alerta(String peca, DateTime? proxima) {
    final d = _dias(proxima);
    if (d == null) return null;
    if (d < 0) return '$peca atrasado há ${-d} dia(s).';
    if (d == 0) return '$peca vence hoje.';
    if (d <= 14) return '$peca em $d dia(s).';
    return null;
  }

  String? _alertaKm(String peca, double? ultima, double intervalo) {
    final kmAtual = _kmAtual;
    if (kmAtual == null || ultima == null) return null;
    final proxima = kmDaProximaTroca(kmUltima: ultima, intervaloKm: intervalo);
    if (proxima == null) return null;
    final falta = kmAteATroca(kmAtual: kmAtual, kmProxima: proxima);
    if (falta == null) return null;
    if (falta < 0) return '$peca atrasado ${-falta} km.';
    if (falta <= 200) return '$peca em $falta km.';
    return null;
  }

  Future<void> _escolher(void Function(DateTime?) setar, DateTime? atual) async {
    final agora = DateTime.now();
    final escolhida = await showDatePicker(
      context: context,
      initialDate: atual ?? agora,
      firstDate: DateTime(2000),
      lastDate: DateTime(agora.year + 5),
    );
    if (escolhida == null) return;
    setState(() => setar(escolhida));
  }

  Future<void> _salvar() async {
    if (_oleoUltima != null &&
        _oleoProxima != null &&
        _oleoProxima!.isBefore(_oleoUltima!)) {
      _aviso('Próximo óleo não pode ser antes da última troca.');
      return;
    }
    if (_pneusUltima != null &&
        _pneusProxima != null &&
        _pneusProxima!.isBefore(_pneusUltima!)) {
      _aviso('Próximos pneus não podem ser antes da última troca.');
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_chave, jsonEncode(_mapa()));
    await ManutencaoExtra.salvar(_extraAtual());
    await agendarLembretes(
      oleo: _oleoProxima,
      pneus: _pneusProxima,
      ipva: _ipvaProxima,
      seguro: _seguroProxima,
      licenciamento: _licenciamentoProxima,
      cnh: _cnhProxima,
    );

    final token = prefs.getString(ApiCaderneta.chaveToken);
    if (token == null || token.isEmpty) {
      _aviso('Salva neste aparelho. Entre na Ficha para ir ao servidor.');
      return;
    }

    try {
      await ApiCaderneta.salvarManutencao(token, _mapa());
      if (!mounted) return;
      _aviso('Manutenção no servidor. Km, serviço e CNH ficam neste aparelho.');
    } on FalhaApi catch (e) {
      _aviso(e.mensagem);
    } catch (_) {
      _aviso('API fora do ar. Ficou só neste aparelho.');
    }
  }

  Future<void> _registrarServico() async {
    final tipo = _servicoTipo.text.trim();
    final km = ApiCaderneta.numero(_servicoKm.text);
    final reais = ApiCaderneta.numero(_servicoReais.text);
    if (tipo.isEmpty || km == null || reais == null) {
      _aviso('Informe o serviço, o km do painel e o valor.');
      return;
    }
    final registro = RegistroServico.deJson({
      'em': DateTime.now().toIso8601String(),
      'tipo': tipo,
      'kmPainel': km,
      'reais': reais,
    });
    if (registro == null) {
      _aviso('km até 999999, valor até R\$ 20.000.');
      return;
    }
    final lista = await HistoricoServico.acrescentar(registro);
    setState(() {
      _servicos = lista;
      _servicoTipo.clear();
      _servicoKm.clear();
      _servicoReais.clear();
    });
    _aviso('Serviço neste aparelho.');
  }

  void _aviso(String texto) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(texto)));
  }

  String _br(double n, {int casas = 0}) =>
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
    if (_carregando) {
      return const Center(child: CircularProgressIndicator());
    }

    final extra = _extraAtual();
    final alertas = [
      _alerta('Óleo', _oleoProxima),
      _alertaKm('Óleo', extra.oleoKmUltima, extra.oleoKmIntervalo),
      _alertaKm('Corrente', extra.correnteKmUltima, extra.correnteKmIntervalo),
      _alerta('Pneus', _pneusProxima),
      _alerta('IPVA', _ipvaProxima),
      _alerta('Seguro', _seguroProxima),
      _alerta('Licenciamento', _licenciamentoProxima),
      _alerta('CNH', _cnhProxima),
    ].whereType<String>().toList();

    return ListView(
      padding: paddingOficina(context),
      children: [
        TituloOficina(
          'Manutenção',
          subtitulo: _kmAtual == null
              ? 'Oficina, km e papelada. Preencha o km na Ficha para o aviso por hodômetro.'
              : 'Painel ${_br(_kmAtual!)} km. Aviso por data e por km.',
        ),
        if (alertas.isNotEmpty) ...[
          const SizedBox(height: 16),
          CartaoOficina(
            destaque: true,
            child: Text(
              alertas.join('\n'),
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
        ],
        const SizedBox(height: 22),
        _rotuloGrupo('Óleo e corrente'),
        _linha('Óleo — última', _oleoUltima, (d) => _oleoUltima = d),
        _linha('Óleo — próxima', _oleoProxima, (d) => _oleoProxima = d),
        DuplaCampos(
          esquerda: _campo(_oleoKmUltima, 'Óleo — último km'),
          direita: _campo(_oleoKmIntervalo, 'Óleo a cada (km)'),
        ),
        DuplaCampos(
          esquerda: _campo(_correnteKmUltima, 'Corrente — último km'),
          direita: _campo(_correnteKmIntervalo, 'Corrente a cada (km)'),
        ),
        _linha('Revisão geral — última', _revisaoUltima, (d) => _revisaoUltima = d),
        const SizedBox(height: 8),
        _rotuloGrupo('Pneus'),
        _linha('Pneus — última', _pneusUltima, (d) => _pneusUltima = d),
        _linha('Pneus — próxima', _pneusProxima, (d) => _pneusProxima = d),
        const SizedBox(height: 20),
        TituloOficina(
          'Papelada',
          subtitulo: 'IPVA, seguro, licenciamento e CNH: só a data. Sem foto da carteira.',
        ),
        const SizedBox(height: 16),
        _linha('IPVA — próxima', _ipvaProxima, (d) => _ipvaProxima = d),
        _linha('Seguro — próxima', _seguroProxima, (d) => _seguroProxima = d),
        _linha(
          'Licenciamento — próxima',
          _licenciamentoProxima,
          (d) => _licenciamentoProxima = d,
        ),
        _linha('CNH — vencimento', _cnhProxima, (d) => _cnhProxima = d),
        const SizedBox(height: 8),
        FilledButton(
          onPressed: _salvar,
          child: const Text('Salvar manutenção'),
        ),
        const SizedBox(height: 28),
        TituloOficina(
          'Oficina',
          subtitulo: 'Histórico neste aparelho: serviço, km e reais.',
        ),
        const SizedBox(height: 16),
        _campo(_servicoTipo, 'Serviço (óleo, pneu, relação…)'),
        DuplaCampos(
          esquerda: _campo(_servicoKm, 'km do painel'),
          direita: _campo(_servicoReais, 'Valor (R\$)'),
        ),
        OutlinedButton(
          onPressed: _registrarServico,
          child: const Text('Registrar serviço'),
        ),
        if (_servicos.isNotEmpty) ...[
          const SizedBox(height: 16),
          for (final s in _servicos)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: CartaoOficina(
                child: Text(
                  '${_dataCurta(s.em)}  ${s.tipo}\n'
                  '${_br(s.kmPainel)} km · R\$ ${_br(s.reais, casas: 2)}',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
            ),
        ],
      ],
    );
  }

  Widget _rotuloGrupo(String texto) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(
        texto.toUpperCase(),
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: Oficina.latao,
              fontSize: 12,
            ),
      ),
    );
  }

  Widget _campo(TextEditingController c, String rotulo) {
    final servico = rotulo.startsWith('Serviço');
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: c,
        keyboardType: servico
            ? TextInputType.text
            : const TextInputType.numberWithOptions(decimal: true),
        maxLength: servico ? 40 : 8,
        inputFormatters: servico
            ? null
            : [FilteringTextInputFormatter.allow(RegExp(r'[0-9,.]'))],
        decoration: InputDecoration(
          labelText: rotulo,
          counterText: '',
        ),
      ),
    );
  }

  Widget _linha(String rotulo, DateTime? valor, void Function(DateTime?) setar) {
    return LinhaData(
      rotulo: rotulo,
      valor: _rotulo(valor),
      onTap: () => _escolher(setar, valor),
      onLimpar: valor == null ? null : () => setState(() => setar(null)),
    );
  }
}
