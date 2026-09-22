import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:life_and_roads/api.dart';
import 'package:life_and_roads/core/permissoes/mensagens_permissao.dart';
import 'package:life_and_roads/core/widgets/cartao_conflito.dart';
import 'package:life_and_roads/core/widgets/linha_sync.dart';
import 'package:life_and_roads/features/manutencao/data/agenda_manutencao_model.dart';
import 'package:life_and_roads/features/manutencao/domain/agenda_manutencao.dart';
import 'package:life_and_roads/features/manutencao/domain/usecases/montar_avisos_caderneta.dart';
import 'package:life_and_roads/features/manutencao/domain/usecases/montar_linha_do_tempo.dart';
import 'package:life_and_roads/features/manutencao/presentation/widgets/cartao_grupo.dart';
import 'package:life_and_roads/features/manutencao/presentation/widgets/folha_data.dart';
import 'package:life_and_roads/features/manutencao/presentation/widgets/linha_do_tempo.dart';
import 'package:life_and_roads/features/manutencao/presentation/widgets/painel_saude.dart';
import 'package:life_and_roads/features/manutencao/presentation/avisos_controller.dart';
import 'package:life_and_roads/features/manutencao/presentation/manutencao_controller.dart';
import 'package:life_and_roads/manutencao/extra.dart';
import 'package:life_and_roads/manutencao/lembrete.dart';
import 'package:life_and_roads/manutencao/regras.dart';
import 'package:life_and_roads/manutencao/servicos.dart';
import 'package:life_and_roads/core/widgets/estado_vazio.dart';
import 'package:life_and_roads/core/widgets/movimento.dart';
import 'package:life_and_roads/tema.dart';

/// Oficina, km, papelada e CNH como painel: o vencimento mais urgente no
/// anel, a linha do tempo e um cartão por grupo. Editar fica numa folha
/// por grupo. Persistência passa pelo repositório.
class TelaManutencao extends ConsumerStatefulWidget {
  const TelaManutencao({super.key, this.visivel = true});

  final bool visivel;

  @override
  ConsumerState<TelaManutencao> createState() => _TelaManutencaoState();
}

/// Um grupo da manutenção: o que o cartão mostra e o que a folha edita.
class _Grupo {
  const _Grupo({
    required this.titulo,
    required this.icone,
    required this.subtitulo,
    required this.pares,
    required this.campos,
  });

  final String titulo;
  final IconData icone;
  final String subtitulo;
  final List<ParGrupo> pares;

  /// Campos da folha. Recebe o setState da folha para ela se redesenhar.
  final List<Widget> Function(StateSetter folha) campos;
}

class _TelaManutencaoState extends ConsumerState<TelaManutencao> {
  DateTime? _oleoUltima;
  DateTime? _oleoProxima;
  DateTime? _revisaoUltima;
  DateTime? _pneusUltima;
  DateTime? _pneusProxima;
  DateTime? _ipvaProxima;
  DateTime? _seguroProxima;
  DateTime? _licenciamentoProxima;
  DateTime? _cnhProxima;
  bool _cnhCincoAnos = false;
  double? _kmAtual;
  List<RegistroServico> _servicos = [];

  final _oleoKmUltima = TextEditingController();
  final _oleoKmIntervalo = TextEditingController(text: '4000');
  final _correnteKmUltima = TextEditingController();
  final _correnteKmIntervalo = TextEditingController(text: '1000');
  final _servicoTipo = TextEditingController();
  final _servicoKm = TextEditingController();
  final _servicoReais = TextEditingController();

  /// setState da folha de grupo aberta, se houver. A folha vive em outra
  /// rota, então o setState da tela não chega nela; quando a sync troca as
  /// datas por trás, a folha precisa redesenhar também.
  StateSetter? _redesenharFolha;

  ManutencaoController get _ctrl =>
      ref.read(manutencaoControllerProvider.notifier);

  @override
  void initState() {
    super.initState();
    Future<void>.microtask(() {
      if (mounted) _ctrl.carregar();
    });
  }

  @override
  void didUpdateWidget(TelaManutencao oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.visivel && !oldWidget.visivel) {
      _ctrl.relerKm();
    }
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

  String _rotulo(DateTime? d) {
    if (d == null) return 'Toque ou digite 13/08/26';
    return dataBr(d);
  }

  void _aplicarAgenda(AgendaManutencao agenda) {
    _oleoUltima = agenda.oleoUltima;
    _oleoProxima = agenda.oleoProxima;
    _revisaoUltima = agenda.revisaoUltima;
    _pneusUltima = agenda.pneusUltima;
    _pneusProxima = agenda.pneusProxima;
    _ipvaProxima = agenda.ipvaProxima;
    _seguroProxima = agenda.seguroProxima;
    _licenciamentoProxima = agenda.licenciamentoProxima;
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
    _cnhProxima = extra.cnhProxima == null
        ? null
        : AgendaManutencaoModel.deIso(extra.cnhProxima);
    _cnhCincoAnos = extra.cnhCincoAnos;
  }

  AgendaManutencao _agendaAtual() {
    return AgendaManutencao(
      oleoUltima: _oleoUltima,
      oleoProxima: _oleoProxima,
      revisaoUltima: _revisaoUltima,
      pneusUltima: _pneusUltima,
      pneusProxima: _pneusProxima,
      ipvaProxima: _ipvaProxima,
      seguroProxima: _seguroProxima,
      licenciamentoProxima: _licenciamentoProxima,
    );
  }

  ManutencaoExtra _extraAtual() {
    return ManutencaoExtra(
      oleoKmUltima: ApiCaderneta.numero(_oleoKmUltima.text),
      oleoKmIntervalo: ApiCaderneta.numero(_oleoKmIntervalo.text) ?? 4000,
      correnteKmUltima: ApiCaderneta.numero(_correnteKmUltima.text),
      correnteKmIntervalo:
          ApiCaderneta.numero(_correnteKmIntervalo.text) ?? 1000,
      cnhProxima: AgendaManutencaoModel.paraIso(_cnhProxima),
      cnhCincoAnos: _cnhCincoAnos,
    );
  }

  /// Abre a folha de data e aplica a escolha na tela e na folha do grupo,
  /// para o valor novo aparecer nas duas na hora.
  Future<void> _editarData({
    required String rotulo,
    required DateTime? atual,
    required void Function(DateTime?) setar,
    required StateSetter folha,
  }) async {
    final escolhida = await FolhaData.abrir(
      context,
      rotulo: rotulo,
      atual: atual,
    );
    if (escolhida == null || !mounted) return;
    setState(() => setar(escolhida));
    folha(() {});
  }

  void _setOleoUltima(DateTime? d) {
    _oleoUltima = d;
    if (d == null) return;
    _oleoProxima = acrescentarMeses(d, 6);
    if (_oleoKmUltima.text.isEmpty && _kmAtual != null) {
      _oleoKmUltima.text = _kmAtual!.toStringAsFixed(0);
    }
  }

  void _setPneusUltima(DateTime? d) {
    _pneusUltima = d;
    if (d != null) _pneusProxima = acrescentarMeses(d, 12);
  }

  void _setAnual(void Function(DateTime?) setar, DateTime? d) {
    setar(d == null ? null : proximaAnual(d));
  }

  void _setCnh(DateTime? d) {
    _cnhProxima = d == null ? null : proximaCnh(d, cincoAnos: _cnhCincoAnos);
  }

  Future<void> _salvar() async {
    await _ctrl.salvar(_agendaAtual(), _extraAtual());
    final avisos = const MontarAvisosCaderneta().executar(
      agenda: _agendaAtual(),
      extra: _extraAtual(),
      kmAtual: _kmAtual,
    );
    final r = await agendarLembretes(
      oleo: _oleoProxima,
      pneus: _pneusProxima,
      ipva: _ipvaProxima,
      seguro: _seguroProxima,
      licenciamento: _licenciamentoProxima,
      cnh: _cnhProxima,
      kmAtrasados: avisos.where((a) => a.atrasado && a.porKm).toList(),
      dispararKmAgora: true,
    );
    if (r == ResultadoLembrete.permissaoNegada && mounted) {
      _aviso(MensagensPermissao.notificacao);
    }
    await ref.read(avisosControllerProvider.notifier).recarregar();
  }

  /// Devolve true quando registrou. Campo vazio ou fora do limite avisa
  /// em snackbar e devolve false, e a folha fica aberta.
  Future<bool> _registrarServico() async {
    final tipo = _servicoTipo.text.trim();
    final km = ApiCaderneta.numero(_servicoKm.text);
    final reais = ApiCaderneta.numero(_servicoReais.text);
    if (tipo.isEmpty || km == null || reais == null) {
      _aviso('Informe o serviço, o km no painel e o valor.');
      return false;
    }
    final registro = RegistroServico.deJson({
      'em': DateTime.now().toIso8601String(),
      'tipo': tipo,
      'kmPainel': km,
      'reais': reais,
    });
    if (registro == null) {
      _aviso('km até 999999, valor até R\$ 20.000.');
      return false;
    }
    _servicoTipo.clear();
    _servicoKm.clear();
    _servicoReais.clear();
    await _ctrl.acrescentarServico(registro);
    return true;
  }

  void _aviso(String texto) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(texto)));
  }

  static String _milhar(num v) {
    final n = v.round().toString();
    final b = StringBuffer();
    for (var i = 0; i < n.length; i++) {
      final resto = n.length - i;
      b.write(n[i]);
      if (resto > 1 && resto % 3 == 1) b.write('.');
    }
    return b.toString();
  }

  /// "1.234,50".
  static String _reais(double v) {
    final partes = v.toStringAsFixed(2).split('.');
    return '${_milhar(int.parse(partes[0]))},${partes[1]}';
  }

  String _dataCurta(String iso) {
    final d = DateTime.tryParse(iso);
    if (d == null) return '';
    final dd = d.day.toString().padLeft(2, '0');
    final mm = d.month.toString().padLeft(2, '0');
    return '$dd/$mm';
  }

  String? _data(DateTime? d) => d == null ? null : dataBr(d);

  String? _km(String texto) {
    final n = ApiCaderneta.numero(texto);
    return n == null ? null : '${_milhar(n)} km';
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(manutencaoControllerProvider, (anterior, atual) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        if (atual.aviso != null && atual.aviso != anterior?.aviso) {
          _aviso(atual.aviso!);
        }
        if (atual.erro != null && atual.erro != anterior?.erro) {
          _aviso(atual.erro!);
        }
        var mudou = false;
        if (atual.agenda != anterior?.agenda) {
          _aplicarAgenda(atual.agenda);
          mudou = true;
        }
        if (atual.extra != anterior?.extra) {
          _aplicarExtra(atual.extra);
          mudou = true;
        }
        if (atual.servicos != anterior?.servicos) {
          _servicos = atual.servicos;
          mudou = true;
        }
        if (atual.kmAtual != anterior?.kmAtual) {
          _kmAtual = atual.kmAtual;
          mudou = true;
        }
        if (mudou) {
          setState(() {});
          _redesenharFolha?.call(() {});
        }
      });
    });

    final estado = ref.watch(manutencaoControllerProvider);
    if (estado.carregando) {
      return Esqueleto(linhas: const [132, 16, 96, 96, 96]);
    }

    // Um vencimento por linha, do mais urgente ao mais folgado. O primeiro
    // vai para o anel do painel.
    final linhaDoTempo = const MontarLinhaDoTempo().executar(
      agenda: _agendaAtual(),
      extra: _extraAtual(),
      kmAtual: _kmAtual,
    );
    final grupos = _grupos();

    return EntradaSuave(
      child: ListView(
        padding: paddingOficina(context),
        children: [
          if (estado.sincronizando) const LinearProgressIndicator(minHeight: 2),
          if (estado.logado && !estado.emConflito) ...[
            LinhaSync(
              meta: estado.sync,
              sincronizando: estado.sincronizando,
              offline: estado.offline,
              aoSincronizar: () =>
                  ref.read(manutencaoControllerProvider.notifier).carregar(),
            ),
            const SizedBox(height: 12),
          ],
          if (estado.emConflito) ...[
            CartaoConflito(
              titulo: 'Datas diferentes no servidor',
              resumoRemoto: estado.remoto!.oleoProxima == null
                  ? 'outras datas de oficina'
                  : 'próximo óleo em ${dataBr(estado.remoto!.oleoProxima!)}',
              aoManter: () =>
                  ref.read(manutencaoControllerProvider.notifier).manterLocal(),
              aoUsarServidor: () =>
                  ref.read(manutencaoControllerProvider.notifier).usarRemoto(),
            ),
            const SizedBox(height: 16),
          ],
          const SizedBox(height: 8),
          PainelSaude(itens: linhaDoTempo, kmAtual: _kmAtual),
          if (linhaDoTempo.isNotEmpty) ...[
            const SizedBox(height: 18),
            LinhaDoTempo(itens: linhaDoTempo),
          ],
          const SizedBox(height: 18),
          for (final (i, g) in grupos.indexed)
            EntradaSuave(
              atraso: Duration(milliseconds: 50 * i),
              deslocamento: 8,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: CartaoGrupo(
                  icone: g.icone,
                  titulo: g.titulo,
                  pares: g.pares,
                  onTap: () => _abrirGrupo(g),
                ),
              ),
            ),
          EntradaSuave(
            atraso: Duration(milliseconds: 50 * grupos.length),
            deslocamento: 8,
            child: _cartaoOficina(),
          ),
        ],
      ),
    );
  }

  List<_Grupo> _grupos() {
    return [
      _Grupo(
        titulo: 'Óleo e corrente',
        icone: Icons.oil_barrel_outlined,
        subtitulo: 'Datas e km da troca. O app sugere seis meses para o óleo.',
        pares: [
          ParGrupo('Última troca', _data(_oleoUltima)),
          ParGrupo('Próxima troca', _data(_oleoProxima)),
          ParGrupo('Km na troca', _km(_oleoKmUltima.text)),
          ParGrupo('A cada', _km(_oleoKmIntervalo.text)),
          ParGrupo('Corrente', _km(_correnteKmUltima.text)),
          ParGrupo('A cada', _km(_correnteKmIntervalo.text)),
          ParGrupo('Revisão geral', _data(_revisaoUltima)),
        ],
        campos: (folha) => [
          _linha('Data da última troca', _oleoUltima, _setOleoUltima, folha),
          _linha(
            'Próxima troca (o app sugere seis meses depois)',
            _oleoProxima,
            (d) => _oleoProxima = d,
            folha,
          ),
          DuplaCampos(
            esquerda: _campo(_oleoKmUltima, 'Km do painel na troca'),
            direita: _campo(_oleoKmIntervalo, 'Trocar a cada quantos km'),
          ),
          DuplaCampos(
            esquerda: _campo(_correnteKmUltima, 'Km do painel na corrente'),
            direita: _campo(_correnteKmIntervalo, 'Passar óleo a cada (km)'),
          ),
          Text(
            'Passe óleo na corrente de vez em quando (cerca de mil km). Isso lubrifica. A corrente continua a mesma.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 12),
          _linha(
            'Revisão geral, última',
            _revisaoUltima,
            (d) => _revisaoUltima = d,
            folha,
          ),
        ],
      ),
      _Grupo(
        titulo: 'Pneus',
        icone: Icons.tire_repair_outlined,
        subtitulo: 'Última troca e a próxima. O app sugere um ano depois.',
        pares: [
          ParGrupo('Última', _data(_pneusUltima)),
          ParGrupo('Próxima', _data(_pneusProxima)),
        ],
        campos: (folha) => [
          _linha('Pneus, última', _pneusUltima, _setPneusUltima, folha),
          _linha(
            'Pneus, próxima',
            _pneusProxima,
            (d) => _pneusProxima = d,
            folha,
          ),
        ],
      ),
      _Grupo(
        titulo: 'Documentos',
        icone: Icons.description_outlined,
        subtitulo: 'IPVA, seguro e licenciamento voltam na mesma data no ano seguinte.',
        pares: [
          ParGrupo('IPVA', _data(_ipvaProxima)),
          ParGrupo('Seguro', _data(_seguroProxima)),
          ParGrupo('Licenciamento', _data(_licenciamentoProxima)),
        ],
        campos: (folha) => [
          _linha(
            'IPVA, próxima',
            _ipvaProxima,
            (d) => _setAnual((v) => _ipvaProxima = v, d),
            folha,
          ),
          _linha(
            'Seguro, próxima',
            _seguroProxima,
            (d) => _setAnual((v) => _seguroProxima = v, d),
            folha,
          ),
          _linha(
            'Licenciamento, próxima',
            _licenciamentoProxima,
            (d) => _setAnual((v) => _licenciamentoProxima = v, d),
            folha,
          ),
        ],
      ),
      _Grupo(
        titulo: 'CNH',
        icone: Icons.badge_outlined,
        subtitulo: 'Vencimento da carteira, que dura 10 ou 5 anos. Sem foto da carteira.',
        pares: [
          ParGrupo('Vencimento', _data(_cnhProxima)),
          ParGrupo('Validade', _cnhCincoAnos ? '5 anos' : '10 anos'),
        ],
        campos: (folha) => [
          _linha('CNH, vencimento', _cnhProxima, _setCnh, folha),
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: SegmentedButton<bool>(
              showSelectedIcon: false,
              segments: const [
                ButtonSegment(value: false, label: Text('CNH 10 anos')),
                ButtonSegment(value: true, label: Text('CNH 5 anos')),
              ],
              selected: {_cnhCincoAnos},
              onSelectionChanged: (s) {
                setState(() {
                  _cnhCincoAnos = s.first;
                  if (_cnhProxima != null) {
                    _cnhProxima = proximaCnh(
                      _cnhProxima!,
                      cincoAnos: _cnhCincoAnos,
                    );
                  }
                });
                folha(() {});
              },
            ),
          ),
        ],
      ),
    ];
  }

  Future<void> _abrirGrupo(_Grupo g) {
    return _abrirFolha(
      titulo: g.titulo,
      subtitulo: g.subtitulo,
      campos: g.campos,
      acao: 'Salvar',
      aoConfirmar: () async {
        // Data errada (próxima antes da última) avisa e deixa a folha
        // aberta para corrigir; nada é gravado nem agendado.
        final erro = _agendaAtual().tentar();
        if (erro != null) {
          _aviso(erro);
          return false;
        }
        await _salvar();
        return true;
      },
    );
  }

  Future<void> _abrirServico() {
    return _abrirFolha(
      titulo: 'Registrar serviço',
      subtitulo: 'O que você pagou na loja. Fica neste aparelho.',
      campos: (_) => [
        _campo(_servicoTipo, 'Serviço (óleo, pneu, relação…)'),
        DuplaCampos(
          esquerda: _campo(_servicoKm, 'Km no painel agora'),
          direita: _campo(_servicoReais, 'Valor (R\$)'),
        ),
      ],
      acao: 'Registrar',
      aoConfirmar: _registrarServico,
    );
  }

  /// Folha que sobe com puxador, título, subtítulo, campos e o botão de
  /// confirmar. Fecha só quando [aoConfirmar] devolve true. O que foi
  /// digitado fica em memória ao fechar sem confirmar, como antes.
  ///
  /// O Scaffold dentro da folha faz o snackbar aparecer por cima dela
  /// (o ScaffoldMessenger mostra em todo Scaffold registrado).
  ///
  /// A folha tem o fundo de cartão, a mesma cor da LinhaData e do campo de
  /// texto. O Theme por dentro troca essa cor pelo fundo da tela, para a
  /// caixa tocável e os campos voltarem a aparecer.
  Future<void> _abrirFolha({
    required String titulo,
    required String subtitulo,
    required List<Widget> Function(StateSetter folha) campos,
    required String acao,
    required Future<bool> Function() aoConfirmar,
  }) async {
    final tema = Theme.of(context);
    final temaFolha = tema.copyWith(
      colorScheme: tema.colorScheme.copyWith(
        surfaceContainerHighest: tema.scaffoldBackgroundColor,
      ),
      inputDecorationTheme: tema.inputDecorationTheme.copyWith(
        fillColor: tema.scaffoldBackgroundColor,
      ),
    );
    // Enquanto confirma (com conta, espera a rede) o botão fica travado,
    // para um segundo toque não salvar de novo nem dar um pop a mais.
    var ocupado = false;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (ctx) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.7,
        minChildSize: 0.4,
        maxChildSize: 0.96,
        builder: (ctx, rolagem) => StatefulBuilder(
          builder: (ctx, setFolha) {
            _redesenharFolha = setFolha;
            return Theme(
              data: temaFolha,
              child: Scaffold(
                backgroundColor: Colors.transparent,
                body: ListView(
                  controller: rolagem,
                  padding: EdgeInsets.fromLTRB(
                    20,
                    8,
                    20,
                    24 + MediaQuery.paddingOf(ctx).bottom,
                  ),
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
                    Text(titulo, style: tema.textTheme.headlineSmall),
                    const SizedBox(height: 4),
                    Text(subtitulo, style: tema.textTheme.bodyMedium),
                    const SizedBox(height: 16),
                    ...campos(setFolha),
                    const SizedBox(height: 4),
                    FilledButton(
                      onPressed: ocupado
                          ? null
                          : () async {
                              setFolha(() => ocupado = true);
                              final ok = await aoConfirmar();
                              if (!ctx.mounted) return;
                              // Só fecha se a folha ainda é a rota de cima;
                              // um pop fora de hora tiraria a tela principal.
                              final noTopo =
                                  ModalRoute.of(ctx)?.isCurrent ?? false;
                              if (ok && noTopo) {
                                Navigator.of(ctx).pop();
                              } else {
                                setFolha(() => ocupado = false);
                              }
                            },
                      // Com conta e servidor lento, o salvar pode levar
                      // segundos; o texto muda para não parecer travado.
                      // Sem indicador em loop (regra do projeto).
                      child: Text(ocupado ? 'Salvando' : acao),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
    _redesenharFolha = null;
    // O cartão mostra o que ficou nos campos, salvo ou não.
    if (mounted) setState(() {});
  }

  Widget _cartaoOficina() {
    final tema = Theme.of(context);
    final total = _servicos.fold<double>(0, (t, s) => t + s.reais);
    final divisor = tema.colorScheme.onSurface.withValues(alpha: 0.08);
    return CartaoOficina(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CabecalhoGrupo(
            icone: Icons.build_outlined,
            titulo: 'Oficina',
            acao: FilledButton.tonal(
              onPressed: _abrirServico,
              style: FilledButton.styleFrom(
                backgroundColor: Oficina.latao.withValues(alpha: 0.18),
                foregroundColor: tema.colorScheme.onSurface,
                minimumSize: const Size(0, 36),
                padding: const EdgeInsets.symmetric(horizontal: 12),
                textStyle: tema.textTheme.labelLarge?.copyWith(
                  fontSize: 13,
                  letterSpacing: 0.8,
                ),
              ),
              child: const Text('Registrar serviço'),
            ),
          ),
          const SizedBox(height: 16),
          if (_servicos.isEmpty)
            const EstadoVazio(
              icone: Icons.build_outlined,
              titulo: 'Nenhum serviço ainda',
              frase: 'Troca de óleo, pneu, revisão. Fica neste aparelho.',
            )
          else ...[
            Text(
              'TOTAL',
              style: tema.textTheme.labelLarge?.copyWith(
                fontSize: 10,
                letterSpacing: 1.2,
                color: Oficina.mute,
              ),
            ),
            NumeroAnimado(
              valor: total,
              formatar: (v) => 'R\$ ${_reais(v)}',
              style: tema.textTheme.titleMedium?.copyWith(fontSize: 22),
            ),
            const SizedBox(height: 8),
            for (final (i, s) in _servicos.indexed)
              EntradaSuave(
                atraso: Duration(milliseconds: 40 * i.clamp(0, 8)),
                deslocamento: 8,
                child: Column(
                  children: [
                    Divider(height: 1, thickness: 1, color: divisor),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 44,
                            child: Text(
                              _dataCurta(s.em),
                              style: tema.textTheme.labelLarge?.copyWith(
                                fontSize: 11,
                                color: Oficina.mute,
                              ),
                            ),
                          ),
                          Expanded(
                            child: Text(
                              s.tipo,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: tema.textTheme.titleMedium?.copyWith(
                                fontSize: 15,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                '${_milhar(s.kmPainel)} km',
                                style: tema.textTheme.bodyMedium,
                              ),
                              Text(
                                'R\$ ${_reais(s.reais)}',
                                style: tema.textTheme.bodyMedium,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ],
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
        decoration: InputDecoration(labelText: rotulo, counterText: ''),
      ),
    );
  }

  Widget _linha(
    String rotulo,
    DateTime? valor,
    void Function(DateTime?) setar,
    StateSetter folha,
  ) {
    return LinhaData(
      rotulo: rotulo,
      valor: _rotulo(valor),
      onTap: () =>
          _editarData(rotulo: rotulo, atual: valor, setar: setar, folha: folha),
      onLimpar: valor == null
          ? null
          : () {
              setState(() => setar(null));
              folha(() {});
            },
    );
  }
}
