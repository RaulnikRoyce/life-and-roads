import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:life_and_roads/api.dart';
import 'package:life_and_roads/backup.dart';
import 'package:life_and_roads/ficha/catalogo.dart';
import 'package:life_and_roads/ficha/foto.dart';
import 'package:life_and_roads/manutencao/extra.dart';
import 'package:image_picker/image_picker.dart';
import 'package:life_and_roads/tema.dart';
import 'package:life_and_roads/viagem/calculo.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Ficha da única moto da v1.
/// Sem placa, chassi, RENAVAM. Com conta, a ficha vai para a API (porta 3001).
class TelaFicha extends StatefulWidget {
  const TelaFicha({super.key});

  @override
  State<TelaFicha> createState() => _TelaFichaState();
}

class _TelaFichaState extends State<TelaFicha> {
  static const _chaveFicha = ApiCaderneta.chaveFicha;
  static const _chaveToken = ApiCaderneta.chaveToken;
  static const _chaveEmail = 'email_life_and_roads';
  static const _anoMin = 1980;

  final _email = TextEditingController();
  final _senha = TextEditingController();
  final _servidor = TextEditingController();
  final _marca = TextEditingController();
  final _modelo = TextEditingController();
  final _ano = TextEditingController();
  final _cilindrada = TextEditingController();
  final _kmLitro = TextEditingController();
  final _kmLitroAlcool = TextEditingController();
  final _kmAtual = TextEditingController();
  final _tanque = TextEditingController();
  final _personalizacoes = TextEditingController();
  final _psiDianteiro = TextEditingController();
  final _psiTraseiro = TextEditingController();

  bool _carregando = true;
  String? _token;
  String? _emailLogado;
  String _combustivel = 'gasolina';
  Uint8List? _foto;
  String? _dicaCatalogo;
  bool _fichaSalva = false;
  bool _flex = true;
  UsoCatalogo? _usoCatalogo;

  @override
  void initState() {
    super.initState();
    _marca.addListener(_aoMudarAutonomia);
    _modelo.addListener(_aoMudarAutonomia);
    _kmLitro.addListener(_aoMudarAutonomia);
    _kmLitroAlcool.addListener(_aoMudarAutonomia);
    _kmAtual.addListener(_aoMudarAutonomia);
    _tanque.addListener(_aoMudarAutonomia);
    _psiDianteiro.addListener(_aoMudarAutonomia);
    _psiTraseiro.addListener(_aoMudarAutonomia);
    _carregar();
  }

  @override
  void dispose() {
    _email.dispose();
    _senha.dispose();
    _servidor.dispose();
    _marca.dispose();
    _modelo.dispose();
    _ano.dispose();
    _cilindrada.dispose();
    _kmLitro.dispose();
    _kmLitroAlcool.dispose();
    _kmAtual.dispose();
    _tanque.dispose();
    _personalizacoes.dispose();
    _psiDianteiro.dispose();
    _psiTraseiro.dispose();
    super.dispose();
  }

  void _aoMudarAutonomia() {
    if (mounted) setState(() {});
  }

  String _texto(Object? valor, int max) {
    final t = '${valor ?? ''}'.trim();
    if (t.length <= max) return t;
    return t.substring(0, max);
  }

  void _aplicarFicha(Map<String, dynamic> mapa) {
    _marca.text = _texto(mapa['marca'], 40);
    _modelo.text = _texto(mapa['modelo'], 60);
    _ano.text = _texto(mapa['ano'], 4);
    _cilindrada.text = _texto(mapa['cilindrada'], 4);
    _kmLitro.text = _texto(mapa['kmLitro'], 5);
    _kmLitroAlcool.text = _texto(mapa['kmLitroAlcool'], 5);
    _combustivel = combustivelDe(mapa['combustivel']).name;
    _kmAtual.text = _texto(mapa['kmAtual'], 7);
    _tanque.text = _texto(mapa['tanqueLitros'], 5);
    _personalizacoes.text = _texto(mapa['personalizacoes'], 200);
    final psiD = '${mapa['psiDianteiro'] ?? ''}'.trim();
    if (psiD.isNotEmpty) _psiDianteiro.text = _texto(psiD, 3);
    final psiT = '${mapa['psiTraseiro'] ?? ''}'.trim();
    if (psiT.isNotEmpty) _psiTraseiro.text = _texto(psiT, 3);
  }

  Future<void> _carregar() async {
    await ApiCaderneta.carregarBase();
    _servidor.text = ApiCaderneta.base;
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString(_chaveToken);
    _emailLogado = prefs.getString(_chaveEmail);

    final bruto = prefs.getString(_chaveFicha);
    if (bruto != null) {
      try {
        final mapa = jsonDecode(bruto);
        if (mapa is Map<String, dynamic>) _aplicarFicha(mapa);
      } on FormatException {
        // Dado local inválido: ignora.
      }
    }

    final token = _token;
    if (token != null && token.isNotEmpty) {
      try {
        final remota = await ApiCaderneta.buscarFicha(token);
        if (remota != null) _aplicarFicha(remota);
      } catch (_) {
        // Sem API: fica o que já estava neste aparelho.
      }
    }

    _foto = await FotoMoto.carregar();

    if (mounted) {
      setState(() {
        _fichaSalva =
            _marca.text.trim().isNotEmpty && _modelo.text.trim().isNotEmpty;
        _flex = _fichaSalva
            ? _kmLitroAlcool.text.trim().isNotEmpty
            : true;
        _carregando = false;
      });
    }
  }

  Map<String, dynamic> _fichaLocal() {
    return {
      'marca': _marca.text.trim(),
      'modelo': _modelo.text.trim(),
      'ano': _ano.text.trim(),
      'cilindrada': _cilindrada.text.trim(),
      'kmLitro': _kmLitro.text.trim().replaceAll(',', '.'),
      'kmLitroAlcool': _kmLitroAlcool.text.trim().replaceAll(',', '.'),
      'combustivel': _combustivel,
      'kmAtual': _kmAtual.text.trim().replaceAll(',', '.'),
      'tanqueLitros': _tanque.text.trim().replaceAll(',', '.'),
      'personalizacoes': _personalizacoes.text.trim(),
      'psiDianteiro': _psiDianteiro.text.trim(),
      'psiTraseiro': _psiTraseiro.text.trim(),
    };
  }

  Map<String, dynamic> _fichaApi() {
    final ano = _ano.text.trim();
    final cc = _cilindrada.text.trim();
    return {
      'marca': _marca.text.trim(),
      'modelo': _modelo.text.trim(),
      'ano': ano.isEmpty ? null : int.parse(ano),
      'cilindrada': cc.isEmpty ? null : int.parse(cc),
      'kmLitro': double.parse(_kmLitro.text.trim().replaceAll(',', '.')),
      'kmLitroAlcool': _kmLitroAlcool.text.trim().isEmpty
          ? null
          : double.parse(_kmLitroAlcool.text.trim().replaceAll(',', '.')),
      'combustivel': _combustivel,
      'kmAtual': double.parse(_kmAtual.text.trim().replaceAll(',', '.')),
      'tanqueLitros': _tanque.text.trim().isEmpty
          ? null
          : double.parse(_tanque.text.trim().replaceAll(',', '.')),
      'personalizacoes': _personalizacoes.text.trim(),
    };
  }

  String? _erroNumeros() {
    final ano = _ano.text.trim();
    if (ano.isNotEmpty) {
      final n = int.tryParse(ano);
      final max = DateTime.now().year + 1;
      if (n == null || n < _anoMin || n > max) {
        return 'Ano entre $_anoMin e $max.';
      }
    }

    final cc = _cilindrada.text.trim();
    if (cc.isNotEmpty) {
      final n = int.tryParse(cc);
      if (n == null || n < 50 || n > 2000) {
        return 'Cilindrada em cc, entre 50 e 2000.';
      }
    }

    final kmL = double.tryParse(_kmLitro.text.trim().replaceAll(',', '.'));
    if (kmL == null || kmL < 5 || kmL > 80) {
      return 'km/l da gasolina entre 5 e 80.';
    }

    final alcoolBruto = _kmLitroAlcool.text.trim();
    if (alcoolBruto.isNotEmpty) {
      final a = double.tryParse(alcoolBruto.replaceAll(',', '.'));
      if (a == null || a < 5 || a > 80) {
        return 'km/l do álcool entre 5 e 80.';
      }
    }

    final km = double.tryParse(_kmAtual.text.trim().replaceAll(',', '.'));
    if (km == null || km < 0 || km > 999999) {
      return 'km atual entre 0 e 999999.';
    }

    final tanqueBruto = _tanque.text.trim();
    if (tanqueBruto.isNotEmpty) {
      final t = double.tryParse(tanqueBruto.replaceAll(',', '.'));
      if (t == null || t < 2 || t > 40) {
        return 'Tanque em litros, entre 2 e 40.';
      }
    }

    final psiD = _psiDianteiro.text.trim();
    if (psiD.isNotEmpty) {
      final n = int.tryParse(psiD);
      if (n == null || n < 15 || n > 50) {
        return 'PSI dianteiro entre 15 e 50.';
      }
    }
    final psiT = _psiTraseiro.text.trim();
    if (psiT.isNotEmpty) {
      final n = int.tryParse(psiT);
      if (n == null || n < 15 || n > 50) {
        return 'PSI traseiro entre 15 e 50.';
      }
    }

    return null;
  }

  Future<void> _salvarLocal() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_chaveFicha, jsonEncode(_fichaLocal()));
  }

  Future<void> _salvar() async {
    if (_marca.text.trim().isEmpty || _modelo.text.trim().isEmpty) {
      _aviso('Marca e modelo são obrigatórios.');
      return;
    }

    final erro = _erroNumeros();
    if (erro != null) {
      _aviso(erro);
      return;
    }

    await _salvarLocal();
    if (mounted) setState(() => _fichaSalva = true);

    final token = _token;
    if (token == null || token.isEmpty) {
      _aviso('Salva neste aparelho. Entre na conta para não perder na troca de celular.');
      return;
    }

    try {
      await ApiCaderneta.salvarFicha(token, _fichaApi());
      if (!mounted) return;
      _aviso('Ficha no servidor. Trocar de celular: entre com o mesmo e-mail.');
    } on FalhaApi catch (e) {
      _aviso(e.mensagem);
    } catch (_) {
      _aviso('API fora do ar. A ficha ficou só neste aparelho.');
    }
  }

  Future<void> _guardarSessao(String token, String email) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_chaveToken, token);
    await prefs.setString(_chaveEmail, email);
    _senha.clear();
    setState(() {
      _token = token;
      _emailLogado = email;
    });
  }

  Future<void> _gravarServidor() async {
    await ApiCaderneta.definirBase(_servidor.text);
    _servidor.text = ApiCaderneta.base;
  }

  Future<void> _cadastrar() async {
    final email = _email.text.trim().toLowerCase();
    final senha = _senha.text;
    if (email.isEmpty || senha.length < 8) {
      _aviso('E-mail e senha de no mínimo 8 caracteres.');
      return;
    }
    await _gravarServidor();
    try {
      await ApiCaderneta.registrar(email, senha);
      final login = await ApiCaderneta.login(email, senha);
      await _guardarSessao(login['token'] as String, login['email'] as String);
      if (!mounted) return;
      _aviso('Conta criada. Agora salve a ficha para ela ir ao servidor.');
    } on FalhaApi catch (e) {
      _aviso(e.mensagem);
    } catch (_) {
      _aviso('API fora do ar. No celular, use o IP do PC na porta 3001.');
    }
  }

  Future<void> _entrar() async {
    final email = _email.text.trim().toLowerCase();
    final senha = _senha.text;
    if (email.isEmpty || senha.isEmpty) {
      _aviso('Informe e-mail e senha.');
      return;
    }
    await _gravarServidor();
    try {
      final login = await ApiCaderneta.login(email, senha);
      await _guardarSessao(login['token'] as String, login['email'] as String);
      final remota = await ApiCaderneta.buscarFicha(login['token'] as String);
      if (remota != null) _aplicarFicha(remota);
      if (!mounted) return;
      _aviso('Entrou. A ficha do servidor, se existir, já veio.');
    } on FalhaApi catch (e) {
      _aviso(e.mensagem);
    } catch (_) {
      _aviso('API fora do ar. No celular, use o IP do PC na porta 3001.');
    }
  }

  Future<void> _sair() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_chaveToken);
    await prefs.remove(_chaveEmail);
    _senha.clear();
    setState(() {
      _token = null;
      _emailLogado = null;
    });
  }

  Future<void> _preencherDoCatalogo(ModeloCatalogo modelo) async {
    setState(() {
      _marca.text = modelo.marca;
      _modelo.text = modelo.modelo;
      _cilindrada.text = '${modelo.cilindradaCc}';
      _kmLitro.text = modelo.kmPorLitro.toStringAsFixed(0);
      _flex = modelo.flex;
      _kmLitroAlcool.text = modelo.kmPorLitroAlcool == null
          ? ''
          : modelo.kmPorLitroAlcool!.toStringAsFixed(0);
      if (!modelo.flex) _combustivel = 'gasolina';
      _tanque.text = modelo.tanqueLitros.toString().replaceAll('.', ',');
      _dicaCatalogo = modelo.dica;
      _psiDianteiro.text = '${modelo.psiDianteiro}';
      _psiTraseiro.text = '${modelo.psiTraseiro}';
    });
    final extra = await ManutencaoExtra.carregar();
    await ManutencaoExtra.salvar(
      ManutencaoExtra(
        oleoKmUltima: extra.oleoKmUltima,
        oleoKmIntervalo: modelo.oleoKm.toDouble(),
        correnteKmUltima: extra.correnteKmUltima,
        correnteKmIntervalo: (modelo.correnteKm ?? extra.correnteKmIntervalo)
            .toDouble(),
        cnhProxima: extra.cnhProxima,
      ),
    );
  }

  double? get _autonomiaGasolina {
    final kmL = double.tryParse(_kmLitro.text.trim().replaceAll(',', '.'));
    final tanque = double.tryParse(_tanque.text.trim().replaceAll(',', '.'));
    if (kmL == null || tanque == null) return null;
    return autonomiaKm(tanqueLitros: tanque, kmPorLitro: kmL);
  }

  double? get _autonomiaAlcool {
    final kmL = double.tryParse(_kmLitroAlcool.text.trim().replaceAll(',', '.'));
    final tanque = double.tryParse(_tanque.text.trim().replaceAll(',', '.'));
    if (kmL == null || tanque == null) return null;
    return autonomiaKm(tanqueLitros: tanque, kmPorLitro: kmL);
  }

  void _aviso(String texto) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(texto)));
  }

  Future<void> _escolherFoto() async {
    final fonte = kIsWeb
        ? ImageSource.gallery
        : await showModalBottomSheet<ImageSource>(
            context: context,
            backgroundColor: Oficina.couro,
            builder: (ctx) => SafeArea(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ListTile(
                    leading: const Icon(Icons.photo_camera, color: Oficina.latao),
                    title: const Text('Câmera'),
                    onTap: () => Navigator.pop(ctx, ImageSource.camera),
                  ),
                  ListTile(
                    leading: const Icon(Icons.photo_library, color: Oficina.latao),
                    title: const Text('Galeria'),
                    onTap: () => Navigator.pop(ctx, ImageSource.gallery),
                  ),
                ],
              ),
            ),
          );
    if (fonte == null) return;

    final XFile? arquivo;
    try {
      arquivo = await ImagePicker().pickImage(
        source: fonte,
        maxWidth: 720,
        maxHeight: 720,
        imageQuality: 65,
      );
    } catch (_) {
      if (!mounted) return;
      _aviso('Não deu para abrir a câmera. Tente a galeria.');
      return;
    }
    if (arquivo == null) return;
    final bytes = await arquivo.readAsBytes();
    if (bytes.length > 400000) {
      if (!mounted) return;
      _aviso('Foto grande demais. Escolha outra.');
      return;
    }
    await FotoMoto.salvar(bytes);
    if (!mounted) return;
    setState(() => _foto = bytes);
  }

  Future<void> _apagarFoto() async {
    await FotoMoto.apagar();
    if (!mounted) return;
    setState(() => _foto = null);
  }

  @override
  Widget build(BuildContext context) {
    if (_carregando) {
      return const Center(child: CircularProgressIndicator());
    }

    final logado = _token != null && _token!.isNotEmpty;

    return ListView(
      padding: paddingOficina(context),
      children: [
        TituloOficina(
          'Sua moto',
          subtitulo: _fichaSalva
              ? 'Sem placa, chassi ou RENAVAM.'
              : 'Catálogo ou marca e modelo. Sem placa, chassi ou RENAVAM.',
        ),
        const SizedBox(height: 20),
        _cartaoResumo(context),
        const SizedBox(height: 22),
        if (_fichaSalva) ...[
          _blocoAjustar(setup: false),
        ] else ...[
          _catalogo(),
          const SizedBox(height: 14),
          _camposIdentidade(),
          _camposConsumo(),
          FilledButton(
            onPressed: _salvar,
            child: const Text('Salvar ficha'),
          ),
          const SizedBox(height: 12),
          _blocoAjustar(setup: true),
        ],
        const SizedBox(height: 28),
        _blocoBackup(),
        const SizedBox(height: 12),
        _blocoConta(logado),
      ],
    );
  }

  Widget _catalogo() {
    final lista = catalogoFiltrado(_usoCatalogo);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SegmentedButton<String>(
          showSelectedIcon: false,
          segments: const [
            ButtonSegment(value: 'cidade', label: Text('Cidade')),
            ButtonSegment(value: 'estrada', label: Text('Estrada')),
            ButtonSegment(value: 'todas', label: Text('Todas')),
          ],
          selected: {
            _usoCatalogo == UsoCatalogo.cidade
                ? 'cidade'
                : _usoCatalogo == UsoCatalogo.estrada
                    ? 'estrada'
                    : 'todas',
          },
          onSelectionChanged: (s) {
            setState(() {
              final v = s.first;
              _usoCatalogo = v == 'cidade'
                  ? UsoCatalogo.cidade
                  : v == 'estrada'
                      ? UsoCatalogo.estrada
                      : null;
            });
          },
        ),
        const SizedBox(height: 12),
        DropdownMenu<ModeloCatalogo>(
          key: ValueKey(_usoCatalogo),
          label: const Text('Modelo comum (opcional)'),
          expandedInsets: EdgeInsets.zero,
          enableFilter: true,
          requestFocusOnTap: true,
          dropdownMenuEntries: [
            for (final m in lista)
              DropdownMenuEntry(value: m, label: m.rotulo),
          ],
          onSelected: (m) {
            if (m != null) _preencherDoCatalogo(m);
          },
        ),
        const SizedBox(height: 10),
        Text(
          'Cidade, estrada ou todas. Valores de uso misto — ajuste com a sua média.',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        if (_dicaCatalogo != null && _dicaCatalogo!.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(_dicaCatalogo!, style: Theme.of(context).textTheme.bodyMedium),
        ],
      ],
    );
  }

  Widget _camposIdentidade() {
    return DuplaCampos(
      esquerda: _campo(_marca, 'Marca', max: 40),
      direita: _campo(_modelo, 'Modelo', max: 60),
    );
  }

  Widget _camposConsumo() {
    final gasolina = _campo(
      _kmLitro,
      'km/l gasolina',
      teclado: const TextInputType.numberWithOptions(decimal: true),
      max: 5,
      filtros: [FilteringTextInputFormatter.allow(RegExp(r'[0-9,.]'))],
    );
    final alcool = _campo(
      _kmLitroAlcool,
      'km/l álcool',
      teclado: const TextInputType.numberWithOptions(decimal: true),
      max: 5,
      filtros: [FilteringTextInputFormatter.allow(RegExp(r'[0-9,.]'))],
    );
    final km = _campo(
      _kmAtual,
      'km do painel',
      teclado: const TextInputType.numberWithOptions(decimal: true),
      max: 7,
      filtros: [FilteringTextInputFormatter.allow(RegExp(r'[0-9,.]'))],
    );
    final tanque = _campo(
      _tanque,
      'Tanque (litros)',
      teclado: const TextInputType.numberWithOptions(decimal: true),
      max: 5,
      filtros: [FilteringTextInputFormatter.allow(RegExp(r'[0-9,.]'))],
    );
    return Column(
      children: [
        DuplaCampos(
          esquerda: gasolina,
          direita: _flex ? alcool : km,
        ),
        DuplaCampos(
          esquerda: _flex ? km : tanque,
          direita: _flex ? tanque : const SizedBox.shrink(),
        ),
      ],
    );
  }

  Widget _camposExtra() {
    return Column(
      children: [
        DuplaCampos(
          esquerda: _campo(
            _ano,
            'Ano',
            teclado: TextInputType.number,
            max: 4,
            filtros: [FilteringTextInputFormatter.digitsOnly],
          ),
          direita: _campo(
            _cilindrada,
            'Cilindrada (cc)',
            teclado: TextInputType.number,
            max: 4,
            filtros: [FilteringTextInputFormatter.digitsOnly],
          ),
        ),
        DuplaCampos(
          esquerda: _campo(
            _psiDianteiro,
            'PSI dianteiro',
            teclado: TextInputType.number,
            max: 3,
            filtros: [FilteringTextInputFormatter.digitsOnly],
          ),
          direita: _campo(
            _psiTraseiro,
            'PSI traseiro',
            teclado: TextInputType.number,
            max: 3,
            filtros: [FilteringTextInputFormatter.digitsOnly],
          ),
        ),
        _campo(
          _personalizacoes,
          'Personalizações (baú, escape — sem placa)',
          linhas: 3,
          max: 200,
        ),
      ],
    );
  }

  Widget _blocoAjustar({required bool setup}) {
    return ExpansionTile(
      tilePadding: EdgeInsets.zero,
      childrenPadding: const EdgeInsets.only(bottom: 8),
      leading: const Icon(Icons.tune, color: Oficina.latao),
      title: Text(
        setup ? 'Mais números' : 'Ajustar números',
        style: Theme.of(context).textTheme.titleMedium,
      ),
      subtitle: Text(
        setup
            ? 'Ano, pneu e personalização. Opcional agora.'
            : 'Catálogo, média, tanque e pneu.',
        style: Theme.of(context).textTheme.bodyMedium,
      ),
      children: [
        if (!setup) ...[
          _catalogo(),
          const SizedBox(height: 14),
          _camposIdentidade(),
          _camposConsumo(),
        ],
        _camposExtra(),
        if (!setup)
          FilledButton(
            onPressed: _salvar,
            child: const Text('Salvar ficha'),
          ),
      ],
    );
  }

  Widget _cartaoResumo(BuildContext context) {
    final nome = '${_marca.text.trim()} ${_modelo.text.trim()}'.trim();
    final km = double.tryParse(_kmAtual.text.trim().replaceAll(',', '.'));
    final gas = double.tryParse(_kmLitro.text.trim().replaceAll(',', '.'));
    final alcool = double.tryParse(_kmLitroAlcool.text.trim().replaceAll(',', '.'));
    final auto = _autonomiaGasolina;
    return CartaoOficina(
      destaque: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: SizedBox(
              height: 196,
              width: double.infinity,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  if (_foto != null)
                    Image.memory(_foto!, fit: BoxFit.cover)
                  else
                    ColoredBox(
                      color: Oficina.asfalto,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.two_wheeler,
                            color: Oficina.latao,
                            size: 48,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Toque para a foto',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ],
                      ),
                    ),
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: _escolherFoto,
                      onLongPress: _foto == null ? null : _apagarFoto,
                      child: const SizedBox.expand(),
                    ),
                  ),
                  if (_foto != null)
                    Positioned(
                      right: 8,
                      top: 8,
                      child: IconButton.filled(
                        style: IconButton.styleFrom(
                          backgroundColor: Oficina.asfalto.withValues(alpha: 0.7),
                          foregroundColor: Oficina.creme,
                          visualDensity: VisualDensity.compact,
                        ),
                        tooltip: 'Remover foto',
                        onPressed: _apagarFoto,
                        icon: const Icon(Icons.close, size: 18),
                      ),
                    ),
                  Positioned(
                    right: 8,
                    bottom: 8,
                    child: IgnorePointer(
                      child: Icon(
                        Icons.photo_camera_outlined,
                        color: Oficina.latao.withValues(alpha: 0.9),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            nome.isEmpty ? 'Sua moto' : nome,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              StatOficina(
                'PAINEL',
                km == null ? '—' : '${km.toStringAsFixed(0)} km',
              ),
              StatOficina(
                'GASOLINA',
                gas == null ? '—' : '${gas.toStringAsFixed(0)} km/l',
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              if (_flex)
                StatOficina(
                  'ÁLCOOL',
                  alcool == null ? '—' : '${alcool.toStringAsFixed(0)} km/l',
                ),
              StatOficina(
                'PNEU',
                _psiDianteiro.text.trim().isEmpty &&
                        _psiTraseiro.text.trim().isEmpty
                    ? '—'
                    : '${_psiDianteiro.text.trim().isEmpty ? '—' : _psiDianteiro.text.trim()}/'
                        '${_psiTraseiro.text.trim().isEmpty ? '—' : _psiTraseiro.text.trim()}',
              ),
              if (!_flex) const Expanded(child: SizedBox()),
            ],
          ),
          if (auto != null || (_flex && _autonomiaAlcool != null)) ...[
            const SizedBox(height: 14),
            Text(
              [
                if (auto != null) 'Gasolina ${auto.toStringAsFixed(0)} km',
                if (_flex && _autonomiaAlcool != null)
                  'álcool ${_autonomiaAlcool!.toStringAsFixed(0)} km',
              ].join(' · '),
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ],
      ),
    );
  }

  Widget _blocoBackup() {
    return Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        tilePadding: EdgeInsets.zero,
        childrenPadding: const EdgeInsets.only(bottom: 8),
        leading: const Icon(Icons.save_alt, color: Oficina.latao),
        title: Text(
          'Backup neste aparelho',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        subtitle: Text(
          'Copia a caderneta. Sem login e sem placa.',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        children: [
          OutlinedButton(
            onPressed: _copiarBackup,
            child: const Text('Copiar backup'),
          ),
          const SizedBox(height: 8),
          OutlinedButton(
            onPressed: _colarBackup,
            child: const Text('Colar backup'),
          ),
        ],
      ),
    );
  }

  Future<void> _copiarBackup() async {
    final texto = await BackupCaderneta.exportar();
    await Clipboard.setData(ClipboardData(text: texto));
    if (!mounted) return;
    _aviso('Backup copiado. Guarde num lugar seu.');
  }

  Future<void> _colarBackup() async {
    final clip = await Clipboard.getData(Clipboard.kTextPlain);
    final texto = clip?.text?.trim() ?? '';
    if (texto.isEmpty) {
      _aviso('Área de transferência vazia.');
      return;
    }
    final erro = await BackupCaderneta.restaurar(texto);
    if (!mounted) return;
    if (erro != null) {
      _aviso(erro);
      return;
    }
    await _carregar();
    _aviso('Caderneta restaurada neste aparelho.');
  }

  Widget _blocoConta(bool logado) {
    return Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        tilePadding: EdgeInsets.zero,
        childrenPadding: const EdgeInsets.only(bottom: 8),
        leading: const Icon(Icons.lock_outline, color: Oficina.latao),
        title: Text(
          logado ? (_emailLogado ?? 'Conta') : 'Conta (opcional)',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        subtitle: Text(
          logado
              ? 'Ficha sincroniza com o servidor'
              : 'Só para a ficha não sumir na troca de celular.',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        children: [
          if (logado)
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton(onPressed: _sair, child: const Text('Sair')),
            )
          else ...[
            _campo(
              _servidor,
              'Servidor (http://IP:3001 no celular)',
              max: 120,
              teclado: TextInputType.url,
            ),
            _campo(_email, 'E-mail da conta', max: 255, teclado: TextInputType.emailAddress),
            _campo(_senha, 'Senha (mín. 8)', max: 72, senha: true),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _cadastrar,
                    child: const Text('Cadastrar'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: _entrar,
                    child: const Text('Entrar'),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _campo(
    TextEditingController controller,
    String rotulo, {
    TextInputType? teclado,
    int linhas = 1,
    int max = 80,
    bool senha = false,
    List<TextInputFormatter>? filtros,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: controller,
        keyboardType: teclado,
        maxLines: senha ? 1 : linhas,
        maxLength: max,
        obscureText: senha,
        inputFormatters: filtros,
        decoration: InputDecoration(
          labelText: rotulo,
          counterText: '',
        ),
      ),
    );
  }
}
