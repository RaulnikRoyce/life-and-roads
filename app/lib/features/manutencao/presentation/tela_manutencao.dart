import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:life_and_roads/api.dart';
import 'package:life_and_roads/core/permissoes/mensagens_permissao.dart';
import 'package:life_and_roads/core/widgets/cartao_conflito.dart';
import 'package:life_and_roads/features/manutencao/data/agenda_manutencao_model.dart';
import 'package:life_and_roads/features/manutencao/domain/agenda_manutencao.dart';
import 'package:life_and_roads/features/manutencao/domain/usecases/montar_avisos_caderneta.dart';
import 'package:life_and_roads/features/manutencao/presentation/avisos_controller.dart';
import 'package:life_and_roads/features/manutencao/presentation/manutencao_controller.dart';
import 'package:life_and_roads/manutencao/extra.dart';
import 'package:life_and_roads/manutencao/lembrete.dart';
import 'package:life_and_roads/manutencao/regras.dart';
import 'package:life_and_roads/manutencao/servicos.dart';
import 'package:life_and_roads/tema.dart';

/// Oficina, km, papelada e CNH. Persistência passa pelo repositório.
class TelaManutencao extends ConsumerStatefulWidget {
  const TelaManutencao({super.key, this.visivel = true});

  final bool visivel;

  @override
  ConsumerState<TelaManutencao> createState() => _TelaManutencaoState();
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
      correnteKmIntervalo: ApiCaderneta.numero(_correnteKmIntervalo.text) ?? 1000,
      cnhProxima: AgendaManutencaoModel.paraIso(_cnhProxima),
      cnhCincoAnos: _cnhCincoAnos,
    );
  }

  Future<void> _editarData({
    required String rotulo,
    required DateTime? atual,
    required void Function(DateTime?) setar,
  }) async {
    final digitada = TextEditingController(
      text: atual == null ? '' : dataBr(atual),
    );
    final agora = DateTime.now();
    final escolhida = await showModalBottomSheet<DateTime>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.fromLTRB(
            20,
            16,
            20,
            16 + MediaQuery.viewInsetsOf(ctx).bottom + MediaQuery.paddingOf(ctx).bottom,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(rotulo, style: Theme.of(ctx).textTheme.titleMedium),
              const SizedBox(height: 12),
              TextField(
                controller: digitada,
                keyboardType: TextInputType.datetime,
                autofocus: true,
                decoration: const InputDecoration(
                  labelText: 'Data (13/08/26)',
                ),
                onSubmitted: (t) {
                  final d = parseDataBr(t);
                  if (d != null) Navigator.pop(ctx, d);
                },
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  ActionChip(
                    label: const Text('Hoje'),
                    onPressed: () => Navigator.pop(ctx, soDia(agora)),
                  ),
                  ActionChip(
                    label: const Text('Há 1 mês'),
                    onPressed: () =>
                        Navigator.pop(ctx, acrescentarMeses(agora, -1)),
                  ),
                  ActionChip(
                    label: const Text('Há 4 meses'),
                    onPressed: () =>
                        Navigator.pop(ctx, acrescentarMeses(agora, -4)),
                  ),
                  ActionChip(
                    label: const Text('Há 6 meses'),
                    onPressed: () =>
                        Navigator.pop(ctx, acrescentarMeses(agora, -6)),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () async {
                  final cal = await showDatePicker(
                    context: ctx,
                    initialDate: atual ?? agora,
                    firstDate: DateTime(2000),
                    lastDate: DateTime(agora.year + 15),
                  );
                  if (cal == null || !ctx.mounted) return;
                  Navigator.pop(ctx, cal);
                },
                child: const Text('Calendário'),
              ),
              FilledButton(
                onPressed: () {
                  final d = parseDataBr(digitada.text);
                  if (d == null) return;
                  Navigator.pop(ctx, d);
                },
                child: const Text('Usar esta data'),
              ),
            ],
          ),
        );
      },
    );
    digitada.dispose();
    if (escolhida == null || !mounted) return;
    setState(() => setar(escolhida));
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
    _cnhProxima =
        d == null ? null : proximaCnh(d, cincoAnos: _cnhCincoAnos);
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

  Future<void> _registrarServico() async {
    final tipo = _servicoTipo.text.trim();
    final km = ApiCaderneta.numero(_servicoKm.text);
    final reais = ApiCaderneta.numero(_servicoReais.text);
    if (tipo.isEmpty || km == null || reais == null) {
      _aviso('Informe o serviço, o km no painel e o valor.');
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
    _servicoTipo.clear();
    _servicoKm.clear();
    _servicoReais.clear();
    await _ctrl.acrescentarServico(registro);
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
        if (mudou) setState(() {});
      });
    });

    final estado = ref.watch(manutencaoControllerProvider);
    if (estado.carregando) {
      return const Center(child: CircularProgressIndicator());
    }

    final extra = _extraAtual();
    final alertas = const MontarAvisosCaderneta()
        .executar(
          agenda: _agendaAtual(),
          extra: extra,
          kmAtual: _kmAtual,
        )
        .map((a) => a.texto)
        .toList();

    return ListView(
      padding: paddingOficina(context),
      children: [
        TituloOficina(
          'Manutenção',
          subtitulo: _kmAtual == null
              ? 'Óleo, pneus e documentos. Informe o km na Ficha para o aviso por km.'
              : 'Painel ${_br(_kmAtual!)} km. Aviso por data e por km.',
        ),
        if (estado.emConflito) ...[
          const SizedBox(height: 16),
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
        ],
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
        _linha('Data da última troca', _oleoUltima, _setOleoUltima),
        _linha(
          'Próxima troca (o app sugere seis meses depois)',
          _oleoProxima,
          (d) => _oleoProxima = d,
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
        const SizedBox(height: 8),
        _linha('Revisão geral, última', _revisaoUltima, (d) => _revisaoUltima = d),
        const SizedBox(height: 8),
        _rotuloGrupo('Pneus'),
        _linha('Pneus, última', _pneusUltima, _setPneusUltima),
        _linha('Pneus, próxima', _pneusProxima, (d) => _pneusProxima = d),
        const SizedBox(height: 20),
        TituloOficina(
          'Documentos',
          subtitulo:
              'IPVA, seguro e licenciamento voltam na mesma data no ano seguinte. CNH dura 10 ou 5 anos. Sem foto da carteira.',
        ),
        const SizedBox(height: 16),
        _linha(
          'IPVA, próxima',
          _ipvaProxima,
          (d) => _setAnual((v) => _ipvaProxima = v, d),
        ),
        _linha(
          'Seguro, próxima',
          _seguroProxima,
          (d) => _setAnual((v) => _seguroProxima = v, d),
        ),
        _linha(
          'Licenciamento, próxima',
          _licenciamentoProxima,
          (d) => _setAnual((v) => _licenciamentoProxima = v, d),
        ),
        _linha('CNH, vencimento', _cnhProxima, _setCnh),
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
                  _cnhProxima =
                      proximaCnh(_cnhProxima!, cincoAnos: _cnhCincoAnos);
                }
              });
            },
          ),
        ),
        const SizedBox(height: 8),
        FilledButton(
          onPressed: _salvar,
          child: const Text('Salvar manutenção'),
        ),
        const SizedBox(height: 28),
        TituloOficina(
          'Oficina',
          subtitulo: 'O que você pagou na loja (opcional).',
        ),
        const SizedBox(height: 16),
        _campo(_servicoTipo, 'Serviço (óleo, pneu, relação…)'),
        DuplaCampos(
          esquerda: _campo(_servicoKm, 'Km no painel agora'),
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
      onTap: () => _editarData(rotulo: rotulo, atual: valor, setar: setar),
      onLimpar: valor == null ? null : () => setState(() => setar(null)),
    );
  }
}
