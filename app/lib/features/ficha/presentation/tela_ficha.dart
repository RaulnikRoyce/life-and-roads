import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:life_and_roads/backup.dart';
import 'package:life_and_roads/core/config/ambiente.dart';
import 'package:life_and_roads/core/legal/textos.dart';
import 'package:life_and_roads/core/permissoes/mensagens_permissao.dart';
import 'package:life_and_roads/core/widgets/cartao_conflito.dart';
import 'package:life_and_roads/features/ficha/domain/ficha_moto.dart';
import 'package:life_and_roads/features/ficha/domain/usecases/exportar_caderneta_arquivo.dart';
import 'package:life_and_roads/features/ficha/domain/usecases/importar_caderneta_arquivo.dart';
import 'package:life_and_roads/features/ficha/presentation/ficha_controller.dart';
import 'package:life_and_roads/ficha/catalogo.dart';
import 'package:life_and_roads/ficha/foto.dart';
import 'package:life_and_roads/manutencao/extra.dart';
import 'package:image_picker/image_picker.dart';
import 'package:life_and_roads/tema.dart';
import 'package:life_and_roads/viagem/calculo.dart';

/// Ficha da única moto da v1.
/// Sem placa, chassi, RENAVAM. Persistência e conta passam pelos repositórios.
class TelaFicha extends ConsumerStatefulWidget {
  const TelaFicha({super.key});

  @override
  ConsumerState<TelaFicha> createState() => _TelaFichaState();
}

class _TelaFichaState extends ConsumerState<TelaFicha> {
  final _email = TextEditingController();
  final _senha = TextEditingController();
  final _senhaAtual = TextEditingController();
  final _senhaNova = TextEditingController();
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

  String _combustivel = 'gasolina';
  Uint8List? _foto;
  String? _dicaCatalogo;
  bool _flex = true;
  UsoCatalogo? _usoCatalogo;
  Timer? _debounceKm;
  bool _aplicando = false;
  bool _salvandoKm = false;

  @override
  void initState() {
    super.initState();
    _marca.addListener(_aoMudarAutonomia);
    _modelo.addListener(_aoMudarAutonomia);
    _kmLitro.addListener(_aoMudarAutonomia);
    _kmLitroAlcool.addListener(_aoMudarAutonomia);
    _kmAtual.addListener(_aoMudarAutonomia);
    _kmAtual.addListener(_agendarSalvarKm);
    _tanque.addListener(_aoMudarAutonomia);
    _psiDianteiro.addListener(_aoMudarAutonomia);
    _psiTraseiro.addListener(_aoMudarAutonomia);
    Future<void>.microtask(() {
      if (mounted) ref.read(fichaControllerProvider.notifier).carregar();
    });
    FotoMoto.carregar().then((bytes) {
      if (mounted) setState(() => _foto = bytes);
    });
  }

  @override
  void dispose() {
    _debounceKm?.cancel();
    _kmAtual.removeListener(_agendarSalvarKm);
    _email.dispose();
    _senha.dispose();
    _senhaAtual.dispose();
    _senhaNova.dispose();
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

  void _agendarSalvarKm() {
    _debounceKm?.cancel();
    if (_aplicando || _salvandoKm) return;
    _debounceKm = Timer(const Duration(milliseconds: 800), _salvarKmSilencioso);
  }

  Future<void> _salvarKmSilencioso() async {
    if (!mounted || _aplicando || _salvandoKm) return;
    final gravada = ref.read(fichaControllerProvider).ficha;
    if (gravada == null || !gravada.preenchida) return;
    final tentativa = _tentarFicha();
    if (tentativa.erro != null || tentativa.ficha == null) return;
    if (tentativa.ficha!.kmAtual == gravada.kmAtual) return;
    _salvandoKm = true;
    try {
      await _ctrl.salvar(tentativa.ficha!, silencioso: true);
    } finally {
      _salvandoKm = false;
    }
  }

  String _fmt(double n) {
    if (n == n.roundToDouble()) return n.toStringAsFixed(0);
    return n.toString().replaceAll('.', ',');
  }

  void _aplicarEntidade(FichaMoto ficha) {
    _aplicando = true;
    _debounceKm?.cancel();
    _marca.text = ficha.marca;
    _modelo.text = ficha.modelo;
    _ano.text = ficha.ano?.toString() ?? '';
    _cilindrada.text = ficha.cilindrada?.toString() ?? '';
    _kmLitro.text = _fmt(ficha.kmLitro);
    _kmLitroAlcool.text =
        ficha.kmLitroAlcool == null ? '' : _fmt(ficha.kmLitroAlcool!);
    _combustivel = ficha.combustivel.name;
    _kmAtual.text = _fmt(ficha.kmAtual);
    _tanque.text = ficha.tanqueLitros == null ? '' : _fmt(ficha.tanqueLitros!);
    _personalizacoes.text = ficha.personalizacoes;
    if (ficha.psiDianteiro != null) {
      _psiDianteiro.text = '${ficha.psiDianteiro}';
    }
    if (ficha.psiTraseiro != null) {
      _psiTraseiro.text = '${ficha.psiTraseiro}';
    }
    _flex = ficha.preenchida ? ficha.flex : true;
    _aplicando = false;
  }

  FichaController get _ctrl => ref.read(fichaControllerProvider.notifier);

  ({FichaMoto? ficha, String? erro}) _tentarFicha() {
    return FichaMoto.tentar(
      marca: _marca.text,
      modelo: _modelo.text,
      ano: _ano.text,
      cilindrada: _cilindrada.text,
      kmLitro: _kmLitro.text,
      kmLitroAlcool: _kmLitroAlcool.text,
      combustivel: combustivelDe(_combustivel),
      kmAtual: _kmAtual.text,
      tanqueLitros: _tanque.text,
      personalizacoes: _personalizacoes.text,
      psiDianteiro: _psiDianteiro.text,
      psiTraseiro: _psiTraseiro.text,
    );
  }

  Future<void> _salvar() async {
    final tentativa = _tentarFicha();
    if (tentativa.erro != null) {
      _aviso(tentativa.erro!);
      return;
    }
    await _ctrl.salvar(tentativa.ficha!);
  }

  Future<void> _cadastrar() async {
    await _ctrl.cadastrar(
      email: _email.text.trim().toLowerCase(),
      senha: _senha.text,
      servidor: _servidor.text,
    );
    _senha.clear();
  }

  Future<void> _entrar() async {
    await _ctrl.entrar(
      email: _email.text.trim().toLowerCase(),
      senha: _senha.text,
      servidor: _servidor.text,
    );
    _senha.clear();
  }

  Future<void> _sair() => _ctrl.sair();

  Future<void> _trocarSenha() async {
    await _ctrl.trocarSenha(
      senhaAtual: _senhaAtual.text,
      senhaNova: _senhaNova.text,
    );
    if (!mounted) return;
    if (ref.read(fichaControllerProvider).erro == null) {
      _senhaAtual.clear();
      _senhaNova.clear();
    }
  }

  Future<void> _excluirConta() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Excluir conta?'),
        content: const Text(
          'Apaga e-mail, ficha, datas e o último ponto no servidor. '
          'A caderneta neste aparelho continua.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );
    if (ok == true) await _ctrl.excluirConta();
  }

  void _mostrarTexto(String titulo, String corpo) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(titulo),
        content: SingleChildScrollView(child: Text(corpo)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Fechar'),
          ),
        ],
      ),
    );
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
        cnhCincoAnos: extra.cnhCincoAnos,
      ),
    );
    await _aplicarSilhueta(modelo);
  }

  Future<void> _aplicarSilhueta(ModeloCatalogo modelo) async {
    try {
      final dados = await rootBundle.load(modelo.assetSilhueta);
      final bytes = dados.buffer.asUint8List();
      await FotoMoto.salvar(bytes);
      if (mounted) setState(() => _foto = bytes);
    } catch (_) {
      // Sem asset (teste) a ficha ainda preenche; o piloto troca a foto depois.
    }
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
      _aviso(MensagensPermissao.camera);
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
    ref.listen(fichaControllerProvider, (anterior, atual) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        if (atual.aviso != null && atual.aviso != anterior?.aviso) {
          _aviso(atual.aviso!);
        }
        if (atual.erro != null && atual.erro != anterior?.erro) {
          _aviso(atual.erro!);
        }
        if (atual.ficha != null && atual.ficha != anterior?.ficha) {
          _aplicarEntidade(atual.ficha!);
        }
        if (atual.servidor.isNotEmpty && atual.servidor != _servidor.text) {
          _servidor.text = atual.servidor;
        }
      });
    });

    final estado = ref.watch(fichaControllerProvider);
    if (estado.carregando) {
      return const Center(child: CircularProgressIndicator());
    }

    final logado = estado.logado;
    final fichaSalva = estado.salvo;

    return ListView(
      padding: paddingOficina(context),
      children: [
        TituloOficina(
          'Sua moto',
          subtitulo: fichaSalva
              ? 'Sem placa, chassi ou RENAVAM.'
              : 'Catálogo ou marca e modelo. Sem placa, chassi ou RENAVAM.',
        ),
        if (estado.offline && !estado.emConflito) ...[
          const SizedBox(height: 12),
          Text(
            'Sem API, caderneta neste aparelho.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
        const SizedBox(height: 20),
        if (estado.emConflito) ...[
          CartaoConflito(
            titulo: 'Ficha diferente no servidor',
            resumoRemoto: estado.remoto!.nome,
            aoManter: () =>
                ref.read(fichaControllerProvider.notifier).manterLocal(),
            aoUsarServidor: () =>
                ref.read(fichaControllerProvider.notifier).usarRemoto(),
          ),
          const SizedBox(height: 16),
        ],
        _cartaoResumo(context),
        const SizedBox(height: 22),
        if (fichaSalva) ...[
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
        _blocoConta(logado, estado.email, estado.sync.deveReenviar),
      ],
    );
  }

  Widget _catalogo() {
    final lista = catalogoFiltrado(_usoCatalogo);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: SegmentedButton<String>(
          showSelectedIcon: false,
          style: const ButtonStyle(
            visualDensity: VisualDensity.compact,
          ),
          segments: const [
            ButtonSegment(value: 'cidade', label: Text('Cidade')),
            ButtonSegment(value: 'estrada', label: Text('Estrada')),
            ButtonSegment(value: 'esporte', label: Text('Esportiva')),
            ButtonSegment(value: 'todas', label: Text('Todas')),
          ],
          selected: {
            _usoCatalogo == UsoCatalogo.cidade
                ? 'cidade'
                : _usoCatalogo == UsoCatalogo.estrada
                    ? 'estrada'
                    : _usoCatalogo == UsoCatalogo.esporte
                        ? 'esporte'
                        : 'todas',
          },
          onSelectionChanged: (s) {
            setState(() {
              final v = s.first;
              _usoCatalogo = v == 'cidade'
                  ? UsoCatalogo.cidade
                  : v == 'estrada'
                      ? UsoCatalogo.estrada
                      : v == 'esporte'
                          ? UsoCatalogo.esporte
                          : null;
            });
          },
        ),
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
          'Cidade, estrada, esportiva ou todas. Valores de uso misto, ajuste com a sua média.',
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
      'Km com 1 L de gasolina',
      teclado: const TextInputType.numberWithOptions(decimal: true),
      max: 5,
      filtros: [FilteringTextInputFormatter.allow(RegExp(r'[0-9,.]'))],
    );
    final alcool = _campo(
      _kmLitroAlcool,
      'Km com 1 L de álcool',
      teclado: const TextInputType.numberWithOptions(decimal: true),
      max: 5,
      filtros: [FilteringTextInputFormatter.allow(RegExp(r'[0-9,.]'))],
    );
    final km = _campo(
      _kmAtual,
      'Km no painel agora',
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
          'Personalizações (baú, escape, sem placa)',
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
                            'Adicionar foto',
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
                km == null ? '-' : '${km.toStringAsFixed(0)} km',
              ),
              StatOficina(
                'GASOLINA',
                gas == null ? '-' : '${gas.toStringAsFixed(0)} km',
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              if (_flex)
                StatOficina(
                  'ÁLCOOL',
                  alcool == null ? '-' : '${alcool.toStringAsFixed(0)} km',
                ),
              StatOficina(
                'PNEU',
                _psiDianteiro.text.trim().isEmpty &&
                        _psiTraseiro.text.trim().isEmpty
                    ? '-'
                    : '${_psiDianteiro.text.trim().isEmpty ? '-' : _psiDianteiro.text.trim()}/'
                        '${_psiTraseiro.text.trim().isEmpty ? '-' : _psiTraseiro.text.trim()}',
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
          'Copia ou salva a caderneta. Sem login e sem placa.',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        children: [
          OutlinedButton(
            onPressed: _copiarBackup,
            child: const Text('Copiar backup'),
          ),
          const SizedBox(height: 8),
          OutlinedButton(
            onPressed: _salvarBackupArquivo,
            child: const Text('Salvar arquivo'),
          ),
          const SizedBox(height: 8),
          OutlinedButton(
            onPressed: _colarBackup,
            child: const Text('Colar backup'),
          ),
          const SizedBox(height: 8),
          OutlinedButton(
            onPressed: _restaurarBackupArquivo,
            child: const Text('Restaurar do arquivo'),
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

  Future<void> _salvarBackupArquivo() async {
    final r = await const ExportarCadernetaArquivo().executar();
    if (!mounted) return;
    if (r.erro != null) {
      _aviso(r.erro!);
      return;
    }
    _aviso('Caderneta salva neste aparelho.');
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
    await _ctrl.carregar();
    _aviso('Caderneta restaurada neste aparelho.');
  }

  Future<void> _restaurarBackupArquivo() async {
    final erro = await const ImportarCadernetaArquivo().executar();
    if (!mounted) return;
    if (erro != null) {
      _aviso(erro);
      return;
    }
    await _ctrl.carregar();
    _aviso('Caderneta restaurada neste aparelho.');
  }

  Widget _blocoConta(bool logado, String? email, bool reenviar) {
    return Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        tilePadding: EdgeInsets.zero,
        childrenPadding: const EdgeInsets.only(bottom: 8),
        leading: const Icon(Icons.lock_outline, color: Oficina.latao),
        title: Text(
          logado ? (email ?? 'Conta') : 'Conta (opcional)',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        subtitle: Text(
          logado
              ? (reenviar
                  ? 'Ficha neste aparelho. Reenvia quando a API voltar.'
                  : 'Ficha sincroniza com o servidor')
              : 'Evita perder a ficha ao trocar de celular.',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        children: [
          if (logado) ...[
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton(onPressed: _sair, child: const Text('Sair')),
            ),
            _campo(_senhaAtual, 'Senha atual', max: 72, senha: true),
            _campo(_senhaNova, 'Senha nova (mín. 8)', max: 72, senha: true),
            Align(
              alignment: Alignment.centerLeft,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: FilledButton(
                  onPressed: _trocarSenha,
                  child: const Text('Trocar senha'),
                ),
              ),
            ),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton(
                onPressed: _excluirConta,
                child: const Text('Excluir conta no servidor'),
              ),
            ),
          ] else ...[
            if (Ambiente.exibeCampoServidor)
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
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton(
              onPressed: () => _mostrarTexto('Termos de uso', termosResumo),
              child: const Text('Termos de uso'),
            ),
          ),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton(
              onPressed: () =>
                  _mostrarTexto('Privacidade', privacidadeResumo),
              child: const Text('Privacidade'),
            ),
          ),
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
