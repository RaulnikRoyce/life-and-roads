import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:life_and_roads/core/widgets/movimento.dart';
import 'package:life_and_roads/features/ficha/presentation/widgets/campo_oficina.dart';
import 'package:life_and_roads/ficha/catalogo.dart';
import 'package:life_and_roads/tema.dart';

/// Primeira abertura: três perguntas, uma por tela, no lugar do formulário
/// inteiro. Qual moto, quanto marca o painel, gasolina ou flex. O resto
/// (ano, tanque, pneu, foto) fica em "Ajustar números" depois de salvar.
///
/// Os controllers são da tela: quem salva é ela, com a mesma validação de
/// sempre. Aqui só se conduz o preenchimento.
class PrimeirosPassos extends StatefulWidget {
  const PrimeirosPassos({
    super.key,
    required this.marca,
    required this.modelo,
    required this.kmLitro,
    required this.kmLitroAlcool,
    required this.kmAtual,
    required this.flex,
    required this.aoFlex,
    required this.aoCatalogo,
    required this.aoConcluir,
  });

  final TextEditingController marca;
  final TextEditingController modelo;
  final TextEditingController kmLitro;
  final TextEditingController kmLitroAlcool;
  final TextEditingController kmAtual;
  final bool flex;
  final ValueChanged<bool> aoFlex;
  final ValueChanged<ModeloCatalogo> aoCatalogo;
  final VoidCallback aoConcluir;

  /// Álcool rende perto de 70% da gasolina. Serve de ponto de partida
  /// quando o catálogo não tem o número.
  static const fatorAlcool = 0.7;

  @override
  State<PrimeirosPassos> createState() => _PrimeirosPassosState();
}

class _PrimeirosPassosState extends State<PrimeirosPassos> {
  int _passo = 0;
  bool _avancando = true;
  UsoCatalogo? _uso;
  ModeloCatalogo? _escolhido;

  /// Álcool que estava no campo quando o piloto marcou Gasolina; volta se
  /// ele marcar Flex de novo.
  String _alcoolGuardado = '';

  static const _titulos = [
    'Qual é a sua moto?',
    'Quanto marca o painel?',
    'Gasolina ou flex?',
  ];

  @override
  void initState() {
    super.initState();
    for (final c in _controllers) {
      c.addListener(_mudou);
    }
  }

  @override
  void dispose() {
    for (final c in _controllers) {
      c.removeListener(_mudou);
    }
    super.dispose();
  }

  List<TextEditingController> get _controllers => [
    widget.marca,
    widget.modelo,
    widget.kmLitro,
    widget.kmLitroAlcool,
    widget.kmAtual,
  ];

  void _mudou() {
    if (mounted) setState(() {});
  }

  static double? _numero(String t) =>
      double.tryParse(t.trim().replaceAll(',', '.'));

  bool get _podeSeguir => switch (_passo) {
    0 =>
      widget.marca.text.trim().isNotEmpty &&
          widget.modelo.text.trim().isNotEmpty,
    1 => _numero(widget.kmAtual.text) != null,
    // Álcool vazio passa: o Começar preenche com a estimativa.
    _ =>
      _numero(widget.kmLitro.text) != null &&
          (!widget.flex ||
              widget.kmLitroAlcool.text.trim().isEmpty ||
              _numero(widget.kmLitroAlcool.text) != null),
  };

  /// 70% da gasolina, arredondado. Null sem gasolina válida.
  int? get _alcoolEstimado {
    final gas = _numero(widget.kmLitro.text);
    return gas == null ? null : (gas * PrimeirosPassos.fatorAlcool).round();
  }

  bool get _vaiEstimar =>
      widget.flex &&
      widget.kmLitroAlcool.text.trim().isEmpty &&
      _alcoolEstimado != null;

  void _ir(int passo) {
    setState(() {
      _avancando = passo > _passo;
      _passo = passo;
    });
  }

  void _escolherFlex(bool flex) {
    widget.aoFlex(flex);
    if (!flex) {
      _alcoolGuardado = widget.kmLitroAlcool.text;
      widget.kmLitroAlcool.clear();
    } else if (widget.kmLitroAlcool.text.trim().isEmpty) {
      widget.kmLitroAlcool.text = _alcoolGuardado;
    }
  }

  void _concluir() {
    if (_vaiEstimar) widget.kmLitroAlcool.text = '$_alcoolEstimado';
    widget.aoConcluir();
  }

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _Progresso(passo: _passo, total: _titulos.length),
        const SizedBox(height: 18),
        AnimatedSize(
          duration: Movimento.medio,
          curve: Movimento.curva,
          alignment: Alignment.topCenter,
          child: AnimatedSwitcher(
            duration: Movimento.medio,
            switchInCurve: Movimento.curva,
            switchOutCurve: Movimento.curva,
            transitionBuilder: (filho, anim) => FadeTransition(
              opacity: anim,
              child: SlideTransition(
                position: Tween(
                  begin: Offset(_avancando ? 0.06 : -0.06, 0),
                  end: Offset.zero,
                ).animate(anim),
                child: filho,
              ),
            ),
            layoutBuilder: (atual, anteriores) => Stack(
              alignment: Alignment.topCenter,
              children: [...anteriores, ?atual],
            ),
            child: Column(
              key: ValueKey(_passo),
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_titulos[_passo], style: tema.textTheme.headlineSmall),
                const SizedBox(height: 16),
                switch (_passo) {
                  0 => _passoMoto(),
                  1 => _passoPainel(),
                  _ => _passoCombustivel(),
                },
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        // O tema estica o FilledButton na largura; Voltar fica ao lado,
        // com largura própria.
        Row(
          children: [
            if (_passo > 0) ...[
              TextButton(
                onPressed: () => _ir(_passo - 1),
                child: const Text('Voltar'),
              ),
              const SizedBox(width: 12),
            ],
            Expanded(
              child: FilledButton(
                onPressed: !_podeSeguir
                    ? null
                    : _passo < _titulos.length - 1
                    ? () => _ir(_passo + 1)
                    : _concluir,
                child: Text(
                  _passo < _titulos.length - 1 ? 'Continuar' : 'Começar',
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _passoMoto() {
    final tema = Theme.of(context);
    final lista = catalogoFiltrado(_uso);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: SegmentedButton<UsoCatalogo?>(
            showSelectedIcon: false,
            style: const ButtonStyle(visualDensity: VisualDensity.compact),
            segments: const [
              ButtonSegment(value: UsoCatalogo.cidade, label: Text('Cidade')),
              ButtonSegment(value: UsoCatalogo.trail, label: Text('Trail')),
              ButtonSegment(value: UsoCatalogo.estrada, label: Text('Estrada')),
              ButtonSegment(
                value: UsoCatalogo.esporte,
                label: Text('Esportiva'),
              ),
              ButtonSegment(value: null, label: Text('Todas')),
            ],
            selected: {_uso},
            onSelectionChanged: (s) => setState(() => _uso = s.first),
          ),
        ),
        const SizedBox(height: 12),
        DropdownMenu<ModeloCatalogo>(
          key: ValueKey(_uso),
          label: const Text('Escolher no catálogo'),
          expandedInsets: EdgeInsets.zero,
          enableFilter: true,
          requestFocusOnTap: true,
          initialSelection: _escolhido,
          dropdownMenuEntries: [
            for (final m in lista) DropdownMenuEntry(value: m, label: m.rotulo),
          ],
          onSelected: (m) {
            if (m == null) return;
            setState(() => _escolhido = m);
            widget.aoCatalogo(m);
          },
        ),
        const SizedBox(height: 8),
        Text(
          _escolhido?.dica.isNotEmpty == true
              ? _escolhido!.dica
              : 'Escolher no catálogo já preenche consumo, tanque e pneus. '
                    'Valores de uso misto, ajuste depois com a sua média.',
          style: tema.textTheme.bodyMedium,
        ),
        const SizedBox(height: 18),
        Text('Não achou? Marca e modelo', style: tema.textTheme.titleMedium),
        const SizedBox(height: 10),
        DuplaCampos(
          esquerda: CampoOficina(widget.marca, 'Marca', max: 40),
          direita: CampoOficina(widget.modelo, 'Modelo', max: 60),
        ),
      ],
    );
  }

  Widget _passoPainel() {
    final tema = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: widget.kmAtual,
          autofocus: true,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          maxLength: 7,
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'[0-9,.]')),
          ],
          style: tema.textTheme.headlineSmall?.copyWith(fontSize: 40),
          decoration: InputDecoration(
            labelText: 'Km no painel agora',
            counterText: '',
            suffixText: 'km',
            suffixStyle: tema.textTheme.titleLarge?.copyWith(
              color: Oficina.mute,
            ),
          ),
        ),
        const SizedBox(height: 10),
        Text(
          'Só os números do painel. O app usa para avisar troca de óleo e '
          'corrente, e você corrige depois quando quiser.',
          style: tema.textTheme.bodyMedium,
        ),
      ],
    );
  }

  Widget _passoCombustivel() {
    final tema = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: _Opcao(
                icone: Icons.local_gas_station_outlined,
                titulo: 'Gasolina',
                detalhe: 'Só gasolina',
                marcada: !widget.flex,
                aoTocar: () => _escolherFlex(false),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _Opcao(
                icone: Icons.swap_horiz,
                titulo: 'Flex',
                detalhe: 'Gasolina ou álcool',
                marcada: widget.flex,
                aoTocar: () => _escolherFlex(true),
              ),
            ),
          ],
        ),
        const SizedBox(height: 18),
        DuplaCampos(
          esquerda: CampoOficina(
            widget.kmLitro,
            'Km com 1 L de gasolina',
            teclado: const TextInputType.numberWithOptions(decimal: true),
            max: 5,
            filtros: [FilteringTextInputFormatter.allow(RegExp(r'[0-9,.]'))],
          ),
          direita: widget.flex
              ? CampoOficina(
                  widget.kmLitroAlcool,
                  'Km com 1 L de álcool',
                  teclado: const TextInputType.numberWithOptions(decimal: true),
                  max: 5,
                  filtros: [
                    FilteringTextInputFormatter.allow(RegExp(r'[0-9,.]')),
                  ],
                )
              : const SizedBox.shrink(),
        ),
        Text(
          _vaiEstimar
              ? 'Sem o número do álcool, o app usa 70% da gasolina '
                    '($_alcoolEstimado km) até você ajustar.'
              : 'Quantos km a moto faz com um litro. Pode ser aproximado, '
                    'dá para ajustar depois com a sua média.',
          style: tema.textTheme.bodyMedium,
        ),
      ],
    );
  }
}

/// Três traços; o do passo atual e os anteriores em latão.
class _Progresso extends StatelessWidget {
  const _Progresso({required this.passo, required this.total});

  final int passo;
  final int total;

  @override
  Widget build(BuildContext context) {
    final apagado = Theme.of(context).colorScheme.onSurface
        .withValues(alpha: 0.12);
    return Row(
      children: [
        for (var i = 0; i < total; i++) ...[
          Expanded(
            child: AnimatedContainer(
              duration: Movimento.medio,
              curve: Movimento.curva,
              height: 3,
              decoration: BoxDecoration(
                color: i <= passo ? Oficina.latao : apagado,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          if (i < total - 1) const SizedBox(width: 6),
        ],
        const SizedBox(width: 12),
        Text(
          '${passo + 1} de $total',
          style: Theme.of(context).textTheme.labelLarge
              ?.copyWith(fontSize: 11, letterSpacing: 1.2, color: Oficina.mute),
        ),
      ],
    );
  }
}

class _Opcao extends StatelessWidget {
  const _Opcao({
    required this.icone,
    required this.titulo,
    required this.detalhe,
    required this.marcada,
    required this.aoTocar,
  });

  final IconData icone;
  final String titulo;
  final String detalhe;
  final bool marcada;
  final VoidCallback aoTocar;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final cor = marcada ? Oficina.latao : Oficina.mute;
    return Material(
      color: tema.colorScheme.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: aoTocar,
        child: AnimatedContainer(
          duration: Movimento.curto,
          padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: marcada ? Oficina.latao : Colors.transparent,
              width: 2,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icone, color: cor),
              const SizedBox(height: 10),
              Text(
                titulo,
                style: tema.textTheme.titleMedium?.copyWith(fontSize: 18),
              ),
              const SizedBox(height: 2),
              Text(detalhe, style: tema.textTheme.bodyMedium),
            ],
          ),
        ),
      ),
    );
  }
}
