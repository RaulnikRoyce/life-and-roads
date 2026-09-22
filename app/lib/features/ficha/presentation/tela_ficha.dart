import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:life_and_roads/backup.dart';
import 'package:life_and_roads/core/database/armazem_kv.dart';
import 'package:life_and_roads/core/database/chaves_kv.dart';
import 'package:life_and_roads/core/backup/backup_automatico.dart';
import 'package:life_and_roads/core/permissoes/mensagens_permissao.dart';
import 'package:life_and_roads/core/widgets/cartao_conflito.dart';
import 'package:life_and_roads/core/widgets/linha_sync.dart';
import 'package:life_and_roads/features/ficha/domain/ficha_moto.dart';
import 'package:life_and_roads/features/ficha/data/enviar_caderneta.dart';
import 'package:life_and_roads/features/ficha/data/escolher_caderneta.dart';
import 'package:life_and_roads/features/ficha/domain/usecases/enviar_caderneta_arquivo.dart';
import 'package:life_and_roads/features/ficha/domain/usecases/importar_caderneta_arquivo.dart';
import 'package:life_and_roads/features/ficha/presentation/ficha_controller.dart';
import 'package:life_and_roads/features/ficha/presentation/widgets/bloco_backup.dart';
import 'package:life_and_roads/features/ficha/presentation/widgets/bloco_conta.dart';
import 'package:life_and_roads/features/ficha/presentation/widgets/busca_modelo.dart';
import 'package:life_and_roads/core/monitor/crash.dart';
import 'package:life_and_roads/features/ficha/presentation/widgets/convite_conta.dart';
import 'package:life_and_roads/features/ficha/presentation/widgets/folha_recusa_conta.dart';
import 'package:life_and_roads/features/ficha/presentation/widgets/campo_oficina.dart';
import 'package:life_and_roads/features/ficha/presentation/widgets/folha_recuperar_senha.dart';
import 'package:life_and_roads/features/ficha/presentation/widgets/painel_moto.dart';
import 'package:life_and_roads/features/ficha/presentation/widgets/primeiros_passos.dart';
import 'package:life_and_roads/ficha/catalogo.dart';
import 'package:life_and_roads/ficha/foto.dart';
import 'package:life_and_roads/manutencao/extra.dart';
import 'package:image_picker/image_picker.dart';
import 'package:life_and_roads/core/widgets/movimento.dart';
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
  ModeloCatalogo? _escolhidoCatalogo;

  /// Carimbo do backup que grava sozinho em Download.
  DateTime? _backupAutomaticoEm;

  /// Convite de conta: some quando o piloto dispensa.
  bool _conviteDispensado = true;

  /// Recebe valor quando o convite é aceito: abre o bloco Conta e rola
  /// até ele. A chave também identifica o bloco na árvore.
  GlobalKey? _chaveConta;
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
    _relerBackupAutomatico();
    ArmazemKv.lerTexto(ChavesKv.conviteContaDispensado).then((v) {
      if (mounted) setState(() => _conviteDispensado = v == 'sim');
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

  /// Aceitou o convite: some com ele, abre a conta e rola até lá.
  Future<void> _irParaConta() async {
    final chave = GlobalKey();
    setState(() {
      _conviteDispensado = true;
      _chaveConta = chave;
    });
    await ArmazemKv.gravarTexto(ChavesKv.conviteContaDispensado, 'sim');
    await WidgetsBinding.instance.endOfFrame;
    final alvo = chave.currentContext;
    // O mounted que importa é o do bloco alvo, não o desta tela.
    if (alvo == null || !alvo.mounted) return;
    await Scrollable.ensureVisible(
      alvo,
      duration: Movimento.medio,
      curve: Movimento.curva,
      alignment: 0.2,
    );
  }

  Future<void> _dispensarConvite() async {
    setState(() => _conviteDispensado = true);
    await ArmazemKv.gravarTexto(ChavesKv.conviteContaDispensado, 'sim');
    if (!mounted) return;
    final motivo = await FolhaRecusaConta.abrir(context);
    if (motivo == null || motivo.isEmpty) return;
    relatarRecusaDeConta(motivo);
    if (mounted) _aviso('Obrigado. Isso ajuda a melhorar o app.');
  }

  Future<void> _relerBackupAutomatico() async {
    final em = await BackupAutomatico.ultimoEm();
    if (mounted) setState(() => _backupAutomaticoEm = em);
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
    _kmLitroAlcool.text = ficha.kmLitroAlcool == null
        ? ''
        : _fmt(ficha.kmLitroAlcool!);
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

  /// Salva com a validação da entidade; a tela troca para o painel ao
  /// receber a ficha salva do controller.
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

  /// Folha em dois passos. Cada callback devolve o erro do controller
  /// (null quando deu certo) para a folha mostrar sem depender do snackbar,
  /// que fica atrás dela. O servidor vai do campo, como em [_entrar].
  Future<void> _esqueciSenha() {
    return FolhaRecuperarSenha.abrir(
      context,
      emailInicial: _email.text.trim().toLowerCase(),
      aoEnviar: (email) async {
        await _ctrl.recuperarSenha(email: email, servidor: _servidor.text);
        if (!mounted) return null;
        return ref.read(fichaControllerProvider).erro;
      },
      aoRedefinir: (email, codigo, senhaNova) async {
        await _ctrl.redefinirSenha(
          email: email,
          codigo: codigo,
          senhaNova: senhaNova,
          servidor: _servidor.text,
        );
        if (!mounted) return null;
        final erro = ref.read(fichaControllerProvider).erro;
        if (erro == null) {
          _email.text = email;
          _senha.clear();
        }
        return erro;
      },
    );
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
    final kmL = double.tryParse(
      _kmLitroAlcool.text.trim().replaceAll(',', '.'),
    );
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
            builder: (ctx) => SafeArea(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ListTile(
                    leading: const Icon(
                      Icons.photo_camera,
                      color: Oficina.latao,
                    ),
                    title: const Text('Câmera'),
                    onTap: () => Navigator.pop(ctx, ImageSource.camera),
                  ),
                  ListTile(
                    leading: const Icon(
                      Icons.photo_library,
                      color: Oficina.latao,
                    ),
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
        // Com uma folha modal por cima (recuperar senha), ela mesma mostra o
        // erro; o snackbar ficaria na fila atrás dela e apareceria depois.
        final telaVisivel = ModalRoute.of(context)?.isCurrent ?? true;
        if (telaVisivel && atual.erro != null && atual.erro != anterior?.erro) {
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
      return Esqueleto(linhas: const [26, 16, 196, 22, 16, 16]);
    }

    final logado = estado.logado;
    final fichaSalva = estado.salvo;

    final margem = paddingOficina(context);
    // Com ficha salva, o painel sangra até as bordas; o resto fica na margem.
    final lateral = fichaSalva
        ? EdgeInsets.symmetric(horizontal: margem.left)
        : EdgeInsets.zero;

    return EntradaSuave(
      child: ListView(
        padding: fichaSalva ? EdgeInsets.only(bottom: margem.bottom) : margem,
        children: [
          if (estado.sincronizando) const LinearProgressIndicator(minHeight: 2),
          // Conflito é raro e pede decisão: vem antes de tudo.
          if (estado.emConflito)
            Padding(
              padding: EdgeInsets.fromLTRB(margem.left, 8, margem.right, 12),
              child: CartaoConflito(
                titulo: 'Ficha diferente no servidor',
                resumoRemoto: estado.remoto!.nome,
                aoManter: () =>
                    ref.read(fichaControllerProvider.notifier).manterLocal(),
                aoUsarServidor: () =>
                    ref.read(fichaControllerProvider.notifier).usarRemoto(),
              ),
            ),
          if (fichaSalva)
            _painel()
          else
            PrimeirosPassos(
              marca: _marca,
              modelo: _modelo,
              kmLitro: _kmLitro,
              kmLitroAlcool: _kmLitroAlcool,
              kmAtual: _kmAtual,
              flex: _flex,
              aoFlex: (flex) => setState(() {
                _flex = flex;
                if (!flex) _combustivel = 'gasolina';
              }),
              aoCatalogo: _preencherDoCatalogo,
              aoConcluir: _salvar,
            ),
          ..._naMargem(lateral, [
            if (logado && !estado.emConflito) ...[
              const SizedBox(height: 8),
              LinhaSync(
                meta: estado.sync,
                sincronizando: estado.sincronizando,
                offline: estado.offline,
                aoSincronizar: () =>
                    ref.read(fichaControllerProvider.notifier).carregar(),
              ),
            ],
            SizedBox(height: fichaSalva ? 40 : 36),
            // Só com a ficha pronta e sem conta: antes disso não há o que
            // perder, e o convite viraria barreira na porta.
            if (fichaSalva && !logado && !_conviteDispensado) ...[
              ConviteConta(
                aoCriar: _irParaConta,
                aoDispensar: _dispensarConvite,
              ),
              const SizedBox(height: 12),
            ],
            BlocoBackup(
              automatico: _backupAutomaticoEm,
              aoEnviar: _enviarBackup,
              aoRestaurar: _restaurarDeArquivo,
              aoCopiar: _copiarBackup,
              aoColar: _colarBackup,
            ),
            const SizedBox(height: 12),
            BlocoConta(
              chave: _chaveConta,
              logado: logado,
              email: estado.email,
              reenviar: estado.sync.deveReenviar,
              emailCtrl: _email,
              senhaCtrl: _senha,
              senhaAtualCtrl: _senhaAtual,
              senhaNovaCtrl: _senhaNova,
              servidorCtrl: _servidor,
              aoEntrar: _entrar,
              aoCadastrar: _cadastrar,
              aoSair: _sair,
              aoTrocarSenha: _trocarSenha,
              aoEsqueciSenha: _esqueciSenha,
              aoExcluirConta: _excluirConta,
              aoMostrarTexto: _mostrarTexto,
            ),
          ]),
        ],
      ),
    );
  }

  /// Itens continuam diretos no ListView (rolagem preguiçosa), cada um
  /// com a margem lateral. Com ficha salva, o painel acima sangra até a borda.
  List<Widget> _naMargem(EdgeInsets margem, List<Widget> filhos) => [
    for (final f in filhos) Padding(padding: margem, child: f),
  ];

  /// Painel da moto salva: foto, nome, km grande e pastilhas.
  Widget _painel() {
    final nome = '${_marca.text.trim()} ${_modelo.text.trim()}'.trim();
    final km = double.tryParse(_kmAtual.text.trim().replaceAll(',', '.'));
    final gas = double.tryParse(_kmLitro.text.trim().replaceAll(',', '.'));
    final alcool = double.tryParse(
      _kmLitroAlcool.text.trim().replaceAll(',', '.'),
    );
    final psiD = _psiDianteiro.text.trim();
    final psiT = _psiTraseiro.text.trim();
    final auto = _autonomiaGasolina;
    final autoAlcool = _flex ? _autonomiaAlcool : null;

    String semDecimal(double? v) => v == null ? '-' : v.toStringAsFixed(0);

    return PainelMoto(
      foto: _foto,
      nome: nome,
      combustivel: _flex ? 'Flex' : '',
      km: km,
      pastilhas: [
        Pastilha(
          icone: Icons.local_gas_station_outlined,
          valor: '${semDecimal(gas)} km/l',
          rotulo: 'GASOLINA',
        ),
        if (_flex)
          Pastilha(
            icone: Icons.eco_outlined,
            valor: '${semDecimal(alcool)} km/l',
            rotulo: 'ÁLCOOL',
          ),
        Pastilha(
          icone: Icons.tire_repair_outlined,
          valor: psiD.isEmpty && psiT.isEmpty
              ? '-'
              : '${psiD.isEmpty ? '-' : psiD}/${psiT.isEmpty ? '-' : psiT}',
          rotulo: 'PNEU PSI',
        ),
        if (auto != null)
          Pastilha(
            icone: Icons.route_outlined,
            valor: '${semDecimal(auto)} km',
            rotulo: 'ALCANCE',
          ),
        if (autoAlcool != null)
          Pastilha(
            icone: Icons.route_outlined,
            valor: '${semDecimal(autoAlcool)} km',
            rotulo: 'ALCANCE ÁLCOOL',
          ),
      ],
      aoFoto: _escolherFoto,
      aoApagarFoto: _apagarFoto,
      aoAjustar: _abrirAjuste,
    );
  }

  /// Formulário completo numa folha que sobe. Salvar fecha a folha.
  Future<void> _abrirAjuste() async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (ctx) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.88,
        minChildSize: 0.5,
        maxChildSize: 0.96,
        builder: (ctx, rolagem) => Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(ctx).bottom),
          child: ListView(
            controller: rolagem,
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 14),
                  decoration: BoxDecoration(
                    color: Oficina.mute.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Text(
                'Ajustar números',
                style: Theme.of(ctx).textTheme.headlineSmall,
              ),
              const SizedBox(height: 4),
              Text(
                'Catálogo, média, tanque e pneu.',
                style: Theme.of(ctx).textTheme.bodyMedium,
              ),
              const SizedBox(height: 16),
              _catalogo(),
              const SizedBox(height: 14),
              _camposIdentidade(),
              _camposConsumo(),
              _camposExtra(),
              FilledButton(
                onPressed: () async {
                  final tentativa = _tentarFicha();
                  if (tentativa.erro != null) {
                    _aviso(tentativa.erro!);
                    return;
                  }
                  await _ctrl.salvar(tentativa.ficha!);
                  if (ctx.mounted) Navigator.of(ctx).pop();
                },
                child: const Text('Salvar ficha'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _catalogo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CampoBuscaModelo(
          escolhido: _escolhidoCatalogo,
          aoTocar: () async {
            final m = await BuscaModelo.abrir(context);
            if (m == null || !mounted) return;
            setState(() => _escolhidoCatalogo = m);
            await _preencherDoCatalogo(m);
          },
        ),
        const SizedBox(height: 10),
        Text(
          _dicaCatalogo?.isNotEmpty == true
              ? _dicaCatalogo!
              : 'A busca preenche consumo, tanque e pneus. Valores de uso '
                    'misto, ajuste com a sua média.',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      ],
    );
  }

  Widget _camposIdentidade() {
    return DuplaCampos(
      esquerda: CampoOficina(_marca, 'Marca', max: 40),
      direita: CampoOficina(_modelo, 'Modelo', max: 60),
    );
  }

  Widget _camposConsumo() {
    final gasolina = CampoOficina(
      _kmLitro,
      'Km com 1 L de gasolina',
      teclado: const TextInputType.numberWithOptions(decimal: true),
      max: 5,
      filtros: [FilteringTextInputFormatter.allow(RegExp(r'[0-9,.]'))],
    );
    final alcool = CampoOficina(
      _kmLitroAlcool,
      'Km com 1 L de álcool',
      teclado: const TextInputType.numberWithOptions(decimal: true),
      max: 5,
      filtros: [FilteringTextInputFormatter.allow(RegExp(r'[0-9,.]'))],
    );
    final km = CampoOficina(
      _kmAtual,
      'Km no painel agora',
      teclado: const TextInputType.numberWithOptions(decimal: true),
      max: 7,
      filtros: [FilteringTextInputFormatter.allow(RegExp(r'[0-9,.]'))],
    );
    final tanque = CampoOficina(
      _tanque,
      'Tanque (litros)',
      teclado: const TextInputType.numberWithOptions(decimal: true),
      max: 5,
      filtros: [FilteringTextInputFormatter.allow(RegExp(r'[0-9,.]'))],
    );
    return Column(
      children: [
        DuplaCampos(esquerda: gasolina, direita: _flex ? alcool : km),
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
          esquerda: CampoOficina(
            _ano,
            'Ano',
            teclado: TextInputType.number,
            max: 4,
            filtros: [FilteringTextInputFormatter.digitsOnly],
          ),
          direita: CampoOficina(
            _cilindrada,
            'Cilindrada (cc)',
            teclado: TextInputType.number,
            max: 4,
            filtros: [FilteringTextInputFormatter.digitsOnly],
          ),
        ),
        DuplaCampos(
          esquerda: CampoOficina(
            _psiDianteiro,
            'PSI dianteiro',
            teclado: TextInputType.number,
            max: 3,
            filtros: [FilteringTextInputFormatter.digitsOnly],
          ),
          direita: CampoOficina(
            _psiTraseiro,
            'PSI traseiro',
            teclado: TextInputType.number,
            max: 3,
            filtros: [FilteringTextInputFormatter.digitsOnly],
          ),
        ),
        CampoOficina(
          _personalizacoes,
          'Personalizações (baú, escape, sem placa)',
          linhas: 3,
          max: 200,
        ),
      ],
    );
  }

  Future<void> _copiarBackup() async {
    final texto = await BackupCaderneta.exportar();
    await Clipboard.setData(ClipboardData(text: texto));
    if (!mounted) return;
    _aviso('Backup copiado. Guarde num lugar seu.');
  }

  Future<void> _enviarBackup() async {
    final r = await const EnviarCadernetaArquivo(enviar: enviarCaderneta)
        .executar();
    if (!mounted) return;
    if (r.erro != null) {
      _aviso(r.erro!);
      return;
    }
    _aviso('Backup enviado. Guarde num lugar seu.');
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

  Future<void> _restaurarDeArquivo() async {
    final texto = await escolherCadernetaJson();
    if (!mounted) return;
    if (texto == null) return; // cancelou
    final erro = await const ImportarCadernetaArquivo().executar(texto);
    if (!mounted) return;
    if (erro != null) {
      _aviso(erro);
      return;
    }
    await _ctrl.carregar();
    _aviso('Caderneta restaurada neste aparelho.');
  }
}
