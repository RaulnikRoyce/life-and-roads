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
import 'package:life_and_roads/features/viagem/presentation/viagem_controller.dart';
import 'package:life_and_roads/features/viagem/presentation/viagem_estado.dart';
import 'package:life_and_roads/features/viagem/presentation/widgets/grafico_consumo.dart';
import 'package:life_and_roads/features/viagem/presentation/widgets/painel_posto.dart';
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
      kmPainel: ApiCaderneta.numero(_kmPainel.text),
      litros: ApiCaderneta.numero(_litrosAbastecidos.text),
      precos: _precosAtuais,
    );
  }

  /// Devolve true quando gravou e limpa os campos. Com erro, a folha fica
  /// aberta e o snackbar mostra o motivo por cima dela.
  Future<bool> _confirmarAbastecimento() async {
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
    _kmPainel.clear();
    _litrosAbastecidos.clear();
    return true;
  }

  Future<void> _abrirAbastecimento() {
    return abrirFolhaOficina(
      context,
      titulo: 'Registrar abastecimento',
      subtitulo: 'Combustível, km do painel e litros.',
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
      ],
      acao: 'Registrar',
      rotuloOcupado: 'Registrando',
      aoConfirmar: _confirmarAbastecimento,
    );
  }

  void _aviso(String texto) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(texto)));
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
        if (!_precosAplicados && !atual.carregando) {
          _preco.text = atual.precos.gasolina;
          _precoAlcool.text = atual.precos.alcool;
          _precosAplicados = true;
        }
      });
    });

    final estado = ref.watch(viagemControllerProvider);
    if (estado.carregando) {
      return Esqueleto(linhas: const [26, 16, 48, 56, 56]);
    }

    final historico = estado.historico;
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
    if (historico.isNotEmpty) {
      custoPorKm = custoMedioPorKm(historico);
      origem = historico.length == 1
          ? 'pelo último posto'
          : 'média de ${historico.length} postos';
    } else if (custoGas != null || custoAlcool != null) {
      custoPorKm = custoGas == null
          ? custoAlcool
          : custoAlcool == null
          ? custoGas
          : (custoAlcool < custoGas ? custoAlcool : custoGas);
      origem = 'pela ficha e os preços de hoje';
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
            fraseVencedor: fraseVencedor,
            postos: historico.length,
            kmComUmLitro: historico.isNotEmpty
                ? historico.first.kmPorLitro
                : kg,
            autonomiaKm: autonomia,
            barras: const ResumoConsumo().executar(historico).barras,
          ),
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
              frase: 'Registre o primeiro para ver o consumo real da moto.',
            )
          else
            // Cascata: cada posto entra 40 ms depois do anterior (até o 8º).
            for (final (i, r) in historico.indexed)
              EntradaSuave(
                atraso: Duration(milliseconds: 40 * i.clamp(0, 8)),
                deslocamento: 8,
                child: _linhaPosto(r, divisor),
              ),
        ],
      ),
    );
  }

  Widget _linhaPosto(RegistroAbastecimento r, Color divisor) {
    final tema = Theme.of(context);
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
                    Text(
                      '${_br(r.kmRodados, casas: 0)} km · ${_br(r.litros)} L · '
                      '${PainelPosto.km(r.kmPorLitro)} km com 1 L',
                      textAlign: TextAlign.end,
                      style: tema.textTheme.bodyMedium,
                    ),
                    Text(
                      'R\$ ${_br(r.reais, casas: 2)} · '
                      'R\$ ${_br(r.reaisPorKm, casas: 2)} por km',
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
