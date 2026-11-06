import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:life_and_roads/api.dart';
import 'package:life_and_roads/core/widgets/estado_vazio.dart';
import 'package:life_and_roads/core/widgets/folha_oficina.dart';
import 'package:life_and_roads/core/widgets/movimento.dart';
import 'package:life_and_roads/features/manutencao/presentation/widgets/cartao_grupo.dart';
import 'package:life_and_roads/features/viagem/domain/precos_litro.dart';
import 'package:life_and_roads/features/viagem/domain/usecases/resumo_consumo.dart';
import 'package:life_and_roads/features/viagem/domain/usecases/identificar_consumo.dart';
import 'package:life_and_roads/features/viagem/presentation/viagem_controller.dart';
import 'package:life_and_roads/features/viagem/presentation/viagem_estado.dart';
import 'package:life_and_roads/features/viagem/presentation/widgets/grafico_consumo.dart';
import 'package:life_and_roads/features/viagem/presentation/widgets/painel_posto.dart';
import 'package:life_and_roads/features/viagem/presentation/widgets/painel_marcador.dart';
import 'package:life_and_roads/tema.dart';
import 'package:life_and_roads/viagem/calculo.dart';

/// Posto: o custo por km real como painel, os preços do dia e os
/// abastecimentos. Registrar fica numa folha. Persistência e ficha passam
/// pelos repositórios; a calculadora da viagem vive na aba Viagem.
class TelaPosto extends ConsumerStatefulWidget {
  const TelaPosto({super.key, this.visivel = true});

  /// IndexedStack deixa a tela montada. Recarrega a ficha ao voltar para esta aba.
  final bool visivel;

  @override
  ConsumerState<TelaPosto> createState() => _TelaPostoState();
}

class _TelaPostoState extends ConsumerState<TelaPosto> {
  final _preco = TextEditingController();
  final _precoAlcool = TextEditingController();
  final _kmPainel = TextEditingController();
  final _litrosAbastecidos = TextEditingController();
  var _precosAplicados = false;
  final _valorPago = TextEditingController();
  final _totalBarras = TextEditingController();
  final _barrasAntes = TextEditingController();
  final _barrasDepois = TextEditingController();
  bool _tanqueCheio = false, _usarBarras = false;
  bool _excluindo = false;

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
  void didUpdateWidget(TelaPosto oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.visivel && !oldWidget.visivel) {
      _ctrl.relerFicha();
    }
  }

  @override
  void dispose() {
    _preco.removeListener(_aoMudarPreco);
    _precoAlcool.removeListener(_aoMudarPreco);
    _valorPago.dispose();
    _totalBarras.dispose();
    _barrasAntes.dispose();
    _barrasDepois.dispose();
    _preco.dispose();
    _precoAlcool.dispose();
    _kmPainel.dispose();
    _litrosAbastecidos.dispose();
    super.dispose();
  }

  void _aoMudarPreco() {
    if (!mounted) return;
    // Antes de aplicar o preço carregado, o campo vazio não pode
    // sobrescrever o que veio do disco.
    if (_precosAplicados) _ctrl.definirPrecos(_precosAtuais);
    setState(() {});
  }

  PrecosLitro get _precosAtuais =>
      PrecosLitro(gasolina: _preco.text, alcool: _precoAlcool.text);

  Future<void> _registrarAbastecimento() async {
    await _ctrl.registrarAbastecimento(
      valorPago: ApiCaderneta.numero(_valorPago.text),
      tanqueCheio: _tanqueCheio,
      totalBarras: _usarBarras ? int.tryParse(_totalBarras.text) : null,
      barrasAntes: _usarBarras ? int.tryParse(_barrasAntes.text) : null,
      barrasDepois: _usarBarras ? int.tryParse(_barrasDepois.text) : null,
      kmPainel: ApiCaderneta.numero(_kmPainel.text),
      litros: ApiCaderneta.numero(_litrosAbastecidos.text),
      precos: _precosAtuais,
    );
  }

  /// Devolve true quando gravou e limpa os campos. Com erro, a folha fica
  /// aberta e o snackbar mostra o motivo por cima dela.
  Future<bool> _confirmarAbastecimento() async {
    if (_usarBarras &&
        (int.tryParse(_totalBarras.text) == null ||
            int.tryParse(_barrasAntes.text) == null ||
            int.tryParse(_barrasDepois.text) == null)) {
      _aviso('Informe números inteiros nos três campos do marcador.');
      return false;
    }
    final erroAntes = ref.read(viagemControllerProvider).erro;
    await _registrarAbastecimento();
    if (!mounted) return false;
    final erro = ref.read(viagemControllerProvider).erro;
    if (erro != null) {
      // O listen só avisa quando a mensagem muda; a mesma falha duas vezes
      // seguidas avisa por aqui.
      if (erro == erroAntes) _aviso(erro);
      return false;
    }
    _valorPago.clear();
    _barrasAntes.clear();
    _barrasDepois.clear();
    _tanqueCheio = false;
    _kmPainel.clear();
    _litrosAbastecidos.clear();
    return true;
  }

  Future<void> _abrirAbastecimento() {
    return abrirFolhaOficina(
      context,
      titulo: 'Registrar abastecimento',
      subtitulo: 'Registre também os parciais. Entre dois tanques cheios, o app mede o consumo do período.',
      campos: (_) => [
        // A folha é outra rota; o Consumer a redesenha quando o combustível
        // muda no controller.
        Consumer(
          builder: (context, ref, _) => _seletor(
            ref.watch(viagemControllerProvider).combustivelAbastecimento,
            _ctrl.definirCombustivelAbastecimento,
          ),
        ),
        DuplaCampos(
          esquerda: _campo(_kmPainel, 'Km no painel agora'),
          direita: _campo(_litrosAbastecidos, 'Litros abastecidos'),
        ),
        _campo(_valorPago, 'Valor pago em reais, opcional'),
        const Text(
          'Se informar o valor pago, o preço por litro será calculado. Caso contrário, usa o preço do dia.',
        ),
        StatefulBuilder(
          builder: (context, atualizar) => Column(
            children: [
              SwitchListTile(
                title: const Text('Completou o tanque?'),
                subtitle: const Text('Use sempre o mesmo nível ao completar.'),
                value: _tanqueCheio,
                onChanged: (v) => atualizar(() => _tanqueCheio = v),
              ),
              SwitchListTile(
                title: const Text('Registrar barrinhas do painel'),
                subtitle: const Text(
                  'Opcional para qualquer moto. Não representa uma medida exata em litros.',
                ),
                value: _usarBarras,
                onChanged: (v) => atualizar(() => _usarBarras = v),
              ),
              if (_usarBarras) ...[
                _campo(_totalBarras, 'Total de barras do painel'),
                DuplaCampos(
                  esquerda: _campo(_barrasAntes, 'Barras antes'),
                  direita: _campo(_barrasDepois, 'Barras depois'),
                ),
                const Text(
                  'Leia com a moto na mesma posição. Ao completar o tanque, estas leituras ajudam a calibrar o marcador.',
                ),
              ],
            ],
          ),
        ),
      ],
      acao: 'Registrar',
      rotuloOcupado: 'Registrando',
      aoConfirmar: _confirmarAbastecimento,
    );
  }

  void _aviso(String texto) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(texto)));
  }

  Future<void> _excluirAbastecimento(
    RegistroAbastecimento r,
    int indice,
  ) async {
    if (_excluindo) return;
    _excluindo = true;
    try {
      final estado = ref.read(viagemControllerProvider);
      final voltaKm =
          indice == 0 &&
          estado.historico.length > 1 &&
          estado.ficha?.kmAtual == r.kmPainel;
      final confirmar = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Excluir abastecimento?'),
          content: Text(
            'Remover o registro de ${GraficoConsumo.dataCurta(r.em)}, '
            'com ${PainelPosto.milhar(r.kmPainel)} km no painel e ${_br(r.litros)} L? '
            'Os consumos, custos e a calibração das barrinhas serão atualizados. '
            '${voltaKm ? 'O km da Ficha voltará ao último abastecimento restante.' : 'O km atual da Ficha será mantido.'} '
            'Esta ação não pode ser desfeita.',
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
      if (confirmar != true || !mounted) return;
      final ok = await _ctrl.excluirAbastecimento(indice: indice, original: r);
      if (!ok && mounted) {
        _aviso(
          ref.read(viagemControllerProvider).erro ??
              'Aguarde a gravação em andamento.',
        );
      }
    } finally {
      _excluindo = false;
    }
  }

  Future<void> _editarAbastecimento(RegistroAbastecimento r, int indice) async {
    final km = TextEditingController(text: '${r.kmPainel}');
    final litros = TextEditingController(text: '${r.litros}');
    final valor = TextEditingController(text: '${r.reais}');
    final total = TextEditingController(text: r.totalBarras?.toString() ?? '');
    final antes = TextEditingController(text: r.barrasAntes?.toString() ?? '');
    final depois = TextEditingController(
      text: r.barrasDepois?.toString() ?? '',
    );
    var combustivel = r.combustivel;
    var cheio = r.tanqueCheio;
    var barras = r.totalBarras != null;
    try {
      await abrirFolhaOficina(
        context,
        titulo: 'Editar abastecimento',
        subtitulo: 'A data será mantida. Os consumos e custos seguintes serão recalculados. Confira o valor pago ao corrigir os litros.',
        campos: (atualizar) => [
          _seletor(combustivel, (v) => atualizar(() => combustivel = v)),
          DuplaCampos(
            esquerda: _campo(km, 'Km no painel'),
            direita: _campo(litros, 'Litros abastecidos'),
          ),
          _campo(valor, 'Valor pago em reais'),
          if (r.tipoConsumo == 'legado')
            const Text(
              'Este registro usa o método anterior. Ao salvar, informe se o tanque foi completado para usar o cálculo atual.',
            ),
          SwitchListTile(
            title: const Text('Completou o tanque?'),
            value: cheio,
            onChanged: (v) => atualizar(() => cheio = v),
          ),
          SwitchListTile(
            title: const Text('Registrar barrinhas do painel'),
            value: barras,
            onChanged: (v) => atualizar(() => barras = v),
          ),
          if (barras) ...[
            _campo(total, 'Total de barras do painel'),
            DuplaCampos(
              esquerda: _campo(antes, 'Barras antes'),
              direita: _campo(depois, 'Barras depois'),
            ),
          ],
        ],
        acao: 'Salvar correção',
        aoConfirmar: () async {
          if (barras &&
              [total, antes, depois].any((c) => int.tryParse(c.text) == null)) {
            _aviso('Informe números inteiros nos três campos do marcador.');
            return false;
          }
          final pago = ApiCaderneta.numero(valor.text);
          if (pago == null) {
            _aviso('Informe o valor pago.');
            return false;
          }
          final ok = await _ctrl.editarAbastecimento(
            indice: indice,
            original: r,
            kmPainel: ApiCaderneta.numero(km.text),
            litros: ApiCaderneta.numero(litros.text),
            valorPago: pago,
            combustivel: combustivel,
            tanqueCheio: cheio,
            totalBarras: barras ? int.tryParse(total.text) : null,
            barrasAntes: barras ? int.tryParse(antes.text) : null,
            barrasDepois: barras ? int.tryParse(depois.text) : null,
          );
          if (!ok && mounted) {
            _aviso(
              ref.read(viagemControllerProvider).erro ??
                  'Aguarde a gravação em andamento.',
            );
          }
          return ok;
        },
      );
    } finally {
      for (final c in [km, litros, valor, total, antes, depois]) {
        c.dispose();
      }
    }
  }

  String _br(double n, {int casas = 1}) =>
      n.toStringAsFixed(casas).replaceAll('.', ',');

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
        // Na abertura e a cada carga nova, que depois da abertura só vem
        // quando a caderneta da conta chega (ADR 0038).
        final cargaTerminou = anterior?.carregando == true && !atual.carregando;
        if (!atual.carregando && (!_precosAplicados || cargaTerminou)) {
          _preco.text = atual.precos.gasolina;
          _precoAlcool.text = atual.precos.alcool;
          for (final r in atual.historico) {
            if (r.totalBarras != null) {
              _totalBarras.text = r.totalBarras.toString();
              break;
            }
          }
          _precosAplicados = true;
        }
      });
    });

    final estado = ref.watch(viagemControllerProvider);
    if (estado.carregando) {
      return Esqueleto(linhas: const [26, 16, 48, 56, 56]);
    }

    final historico = estado.historico;
    final medidos = historico.where((r) => r.medido).toList();
    final pg = ApiCaderneta.numero(_preco.text);
    final pa = ApiCaderneta.numero(_precoAlcool.text);
    final kg = estado.kmLitroGasolina;
    final ka = estado.kmLitroAlcool;
    final custoGas = pg == null || kg == null
        ? null
        : custoPorKmCombustivel(precoLitro: pg, kmPorLitro: kg);
    final custoAlcool = pa == null || ka == null
        ? null
        : custoPorKmCombustivel(precoLitro: pa, kmPorLitro: ka);

    // O número grande: a média real dos postos. Sem posto, a estimativa
    // pela ficha com a bomba mais barata de hoje.
    double? custoPorKm;
    String origem;
    // Só intervalos entre postos contam; o primeiro registro não tem.
    final intervalos = medidos.length;
    const identificar = IdentificarConsumo();
    final origemMedida = identificar.custoHistorico(historico);
    if (intervalos > 0) {
      custoPorKm = custoMedioPorKm(medidos);
      origem = origemMedida!.titulo;
    } else if (custoGas != null || custoAlcool != null) {
      custoPorKm = custoGas == null
          ? custoAlcool
          : custoAlcool == null
          ? custoGas
          : (custoAlcool < custoGas ? custoAlcool : custoGas);
      final usandoAlcool =
          custoAlcool != null && (custoGas == null || custoAlcool < custoGas);
      origem =
          'Estimado para ${usandoAlcool ? 'álcool' : 'gasolina'} pela Ficha e pelo preço de hoje';
    } else {
      final temPreco = pg != null || pa != null;
      origem = temPreco && kg == null && ka == null
          ? 'informe o consumo na Ficha'
          : 'informe os preços';
    }

    String? fraseVencedor;
    if (pg != null && pa != null && kg != null && ka != null) {
      if (custoGas != null && custoAlcool != null) {
        final vence = combustivelMaisBarato(
          precoGasolina: pg,
          precoAlcool: pa,
          kmLitroGasolina: kg,
          kmLitroAlcool: ka,
        );
        fraseVencedor = switch (vence) {
          Combustivel.alcool => 'Hoje o álcool custa menos.',
          Combustivel.gasolina => 'Hoje a gasolina custa menos.',
          null => 'Gasolina e álcool custam parecido hoje.',
        };
      }
    }

    final tanque = estado.tanqueLitros;
    final autonomia = tanque == null || kg == null
        ? null
        : autonomiaKm(tanqueLitros: tanque, kmPorLitro: kg);

    return EntradaSuave(
      child: ListView(
        padding: paddingOficina(context),
        children: [
          PainelPosto(
            custoPorKm: custoPorKm,
            origem: origem,
            detalheCusto: origemMedida?.explicacao,
            origemConsumo: identificar.gasolina(historico),
            fraseVencedor: fraseVencedor,
            postos: historico.length,
            kmComUmLitro: mediaKmPorLitro(medidos, Combustivel.gasolina) ?? kg,
            autonomiaKm: autonomia,
            barras: const ResumoConsumo().executar(historico).barras,
          ),
          const SizedBox(height: 16),
          PainelMarcador(ficha: estado.ficha, historico: historico),
          const SizedBox(height: 16),
          _cartaoAbastecimento(estado),
        ],
      ),
    );
  }

  Widget _cartaoAbastecimento(ViagemEstado estado) {
    final tema = Theme.of(context);
    final estreita = telaEstreita(context);
    final historico = estado.historico;
    final kmAtual = estado.kmAtual;
    final divisor = tema.colorScheme.onSurface.withValues(alpha: 0.08);
    // Alvo de toque de 48 px (tapTargetSize) com o botão de 40 px.
    final botao = FilledButton.tonal(
      onPressed: _abrirAbastecimento,
      style: FilledButton.styleFrom(
        backgroundColor: Oficina.latao.withValues(alpha: 0.18),
        foregroundColor: tema.colorScheme.onSurface,
        minimumSize: const Size(0, 40),
        tapTargetSize: MaterialTapTargetSize.padded,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        textStyle: tema.textTheme.labelLarge?.copyWith(
          fontSize: 13,
          letterSpacing: 0.8,
        ),
      ),
      child: const Text('Registrar abastecimento'),
    );

    return CartaoOficina(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CabecalhoGrupo(
            icone: Icons.local_gas_station_outlined,
            titulo: 'Abastecimento',
            // Em tela estreita o botão desce para a linha de baixo, inteiro.
            acao: estreita ? const SizedBox.shrink() : botao,
          ),
          if (estreita) ...[
            const SizedBox(height: 12),
            SizedBox(width: double.infinity, child: botao),
          ],
          const SizedBox(height: 12),
          Text(
            kmAtual == null
                ? 'Ainda falta o km do painel na Ficha.'
                : 'Último km gravado: ${PainelPosto.milhar(kmAtual)}.',
            style: tema.textTheme.bodyMedium,
          ),
          const SizedBox(height: 16),
          Text(
            'PREÇOS DO DIA',
            style: tema.textTheme.labelLarge?.copyWith(
              fontSize: 10,
              letterSpacing: 1.2,
              color: Oficina.mute,
            ),
          ),
          const SizedBox(height: 8),
          // Campo com a cor de cartão sumiria no cartão; mesma regra da folha.
          Theme(
            data: temaSobreCartao(tema),
            child: DuplaCampos(
              esquerda: _campo(_preco, 'Preço gasolina (R\$)'),
              direita: _campo(_precoAlcool, 'Preço álcool (R\$)'),
            ),
          ),
          if (historico.isEmpty)
            const EstadoVazio(
              icone: Icons.local_gas_station_outlined,
              titulo: 'Nenhum abastecimento ainda',
              frase: 'Registre todos os abastecimentos. Complete o tanque para iniciar um período de medição.',
            )
          else
            // Cascata: cada posto entra 40 ms depois do anterior (até o 8º).
            for (final (i, r) in historico.indexed)
              EntradaSuave(
                atraso: Duration(milliseconds: 40 * i.clamp(0, 8)),
                deslocamento: 8,
                child: _linhaPosto(
                  r,
                  divisor,
                  rodouCom: combustivelDoIntervalo(historico, i),
                  indice: i,
                ),
              ),
        ],
      ),
    );
  }

  /// [rodouCom] é o combustível que estava no tanque no intervalo (o do
  /// posto anterior); só aparece quando difere do abastecido.
  Widget _linhaPosto(
    RegistroAbastecimento r,
    Color divisor, {
    required Combustivel? rodouCom,
    required int indice,
  }) {
    final tema = Theme.of(context);
    final identificacao = const IdentificarConsumo().registro(r);
    final exibirConsumo =
        r.temConsumo &&
        identificacao.tipo != TipoOrigemConsumo.indisponivel &&
        identificacao.tipo != TipoOrigemConsumo.referencia;
    final combustivelPeriodo = r.medido ? r.combustivelMedido : rodouCom;
    final rodou =
        r.tipoConsumo == 'medidoMisto' ||
            combustivelPeriodo == null ||
            combustivelPeriodo == r.combustivel
        ? ''
        : ', rodou com ${rotuloCombustivel(combustivelPeriodo).toLowerCase()}';
    return Column(
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
                  GraficoConsumo.dataCurta(r.em),
                  style: tema.textTheme.labelLarge?.copyWith(
                    fontSize: 11,
                    color: Oficina.mute,
                  ),
                ),
              ),
              Text(
                rotuloCombustivel(r.combustivel),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: tema.textTheme.titleMedium?.copyWith(fontSize: 15),
              ),
              const SizedBox(width: 12),
              // O combustível ocupa só a palavra; os números ficam com o
              // resto da linha, alinhados à direita.
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Wrap(
                      alignment: WrapAlignment.end,
                      spacing: 4,
                      children: [
                        TextButton.icon(
                          onPressed: () => _editarAbastecimento(r, indice),
                          icon: const Icon(Icons.edit_outlined, size: 18),
                          label: const Text('Editar'),
                        ),
                        TextButton.icon(
                          onPressed: () => _excluirAbastecimento(r, indice),
                          icon: const Icon(Icons.delete_outline, size: 18),
                          label: const Text('Excluir'),
                          style: TextButton.styleFrom(
                            foregroundColor: tema.colorScheme.error,
                          ),
                        ),
                      ],
                    ),
                    Text('${PainelPosto.milhar(r.kmPainel)} km no painel'),
                    if (r.totalBarras != null)
                      Text(
                        '${r.barrasAntes} → ${r.barrasDepois} de ${r.totalBarras} barras',
                      ),
                    if (r.tipoConsumo != 'legado')
                      Text(r.tanqueCheio ? 'Tanque cheio' : 'Parcial'),
                    Tooltip(
                      message: identificacao.explicacao,
                      child: Text(identificacao.titulo),
                    ),
                    Text(
                      'Compra de ${_br(r.litros)} L · R\$ ${_br(r.reais, casas: 2)}',
                      textAlign: TextAlign.end,
                      style: tema.textTheme.bodyMedium,
                    ),
                    if (exibirConsumo)
                      Text(
                        r.medido
                            ? '${_br(r.kmMedidos!, casas: 0)} km · ${_br(r.litrosMedidos!)} L no período'
                            : '${_br(r.kmRodados, casas: 0)} km desde o anterior',
                        textAlign: TextAlign.end,
                      ),
                    if (exibirConsumo)
                      Text(
                        '${PainelPosto.km(r.kmPorLitro)} km com 1 L$rodou',
                        textAlign: TextAlign.end,
                      ),
                    if (exibirConsumo)
                      Text(
                        r.medido
                            ? 'Custo do período R\$ ${_br(r.reaisMedidos!, casas: 2)} · R\$ ${_br(r.reaisPorKm, casas: 2)} por km'
                            : 'R\$ ${_br(r.reaisPorKm, casas: 2)} por km'
                                  '${r.tipoConsumo == 'legado' ? ' pelo método anterior' : ' estimados'}',
                        textAlign: TextAlign.end,
                        style: tema.textTheme.bodyMedium,
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _seletor(Combustivel atual, ValueChanged<Combustivel> aoMudar) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: SegmentedButton<Combustivel>(
        segments: const [
          ButtonSegment(value: Combustivel.gasolina, label: Text('Gasolina')),
          ButtonSegment(value: Combustivel.alcool, label: Text('Álcool')),
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
        decoration: InputDecoration(labelText: rotulo, counterText: ''),
      ),
    );
  }
}
