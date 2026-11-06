import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:life_and_roads/features/ficha/domain/ficha_moto.dart';
import 'package:life_and_roads/features/viagem/domain/usecases/identificar_consumo.dart';
import 'package:life_and_roads/features/viagem/presentation/tela_posto.dart';
import 'package:life_and_roads/features/viagem/presentation/viagem_controller.dart';
import 'package:life_and_roads/features/viagem/presentation/viagem_estado.dart';
import 'package:life_and_roads/tema.dart';
import 'package:life_and_roads/viagem/calculo.dart';

RegistroAbastecimento _registro(
  String tipo, {
  Combustivel? medidoCom,
  bool cheio = true,
  double? litrosMedidos = 10,
}) => RegistroAbastecimento(
  em: '2026-11-04T12:00:00',
  combustivel: Combustivel.gasolina,
  kmPainel: 1200,
  kmRodados: 100,
  litros: 1,
  precoLitro: 6,
  reais: 6,
  kmPorLitro: 20,
  reaisPorKm: .3,
  tipoConsumo: tipo,
  tanqueCheio: cheio,
  kmMedidos: tipo.startsWith('medido') ? 200 : null,
  litrosMedidos: tipo.startsWith('medido') ? litrosMedidos : null,
  reaisMedidos: tipo.startsWith('medido') ? 60 : null,
  combustivelMedido: medidoCom,
);

class _ControllerFixo extends ViagemController {
  @override
  ViagemEstado build() => ViagemEstado(
    carregando: false,
    ficha: const FichaMoto(
      marca: 'Honda',
      modelo: 'Bros',
      kmAtual: 1200,
      kmLitro: 35,
    ),
    historico: [_registro('medidoMisto')],
  );
  @override
  Future<void> carregar() async {}
}

void main() {
  const identificar = IdentificarConsumo();
  GoogleFonts.config.allowRuntimeFetching = false;
  test(
    'marcar tanque cheio não transforma estimativa ou legado em medição',
    () {
      final registros = [
        _registro('referencia'),
        _registro('estimado'),
        _registro('legado'),
      ];
      expect(registros.map((r) => identificar.registro(r).tipo), [
        TipoOrigemConsumo.referencia,
        TipoOrigemConsumo.estimado,
        TipoOrigemConsumo.legado,
      ]);
      expect(identificar.custoHistorico(registros), isNull);
      expect(identificar.gasolina(registros), contains('referência da Ficha'));
    },
  );
  test('custo misto medido não cria média medida de gasolina', () {
    final registros = [
      _registro('medidoMisto'),
      _registro('medido', medidoCom: Combustivel.alcool),
    ];
    expect(
      identificar.custoHistorico(registros)!.tipo,
      TipoOrigemConsumo.mistura,
    );
    expect(
      identificar.custoHistorico(registros)!.titulo,
      contains('2 períodos'),
    );
    expect(
      identificar.custoHistorico(registros)!.explicacao,
      contains('1 período com mistura'),
    );
    expect(identificar.gasolina(registros), contains('referência da Ficha'));
    expect(
      identificar.registro(registros.first).tipo,
      TipoOrigemConsumo.mistura,
    );
  });
  test('origem da gasolina conta apenas ciclos válidos sem mistura desse combustível', () {
    final registros = [
      _registro('medido', medidoCom: Combustivel.gasolina),
      _registro('medidoMisto'),
      _registro('legado'),
      _registro('estimado'),
      _registro('medido', medidoCom: Combustivel.alcool),
    ];
    expect(
      identificar.gasolina(registros),
      contains('1 ciclo completo sem mistura'),
    );
    expect(
      identificar.custoHistorico(registros)!.titulo,
      contains('3 períodos'),
    );
    expect(
      identificar.registro(registros.first).tipo,
      TipoOrigemConsumo.medido,
    );
  });
  test('totais ausentes não são apresentados como medição válida', () {
    final invalido = _registro(
      'medido',
      medidoCom: Combustivel.gasolina,
      litrosMedidos: null,
    );
    expect(identificar.registro(invalido).tipo, TipoOrigemConsumo.indisponivel);
    expect(identificar.custoHistorico([invalido]), isNull);
  });
  testWidgets(
    'painel distingue custo misto de gasolina estimada e compra do ciclo',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            viagemControllerProvider.overrideWith(_ControllerFixo.new),
          ],
          child: MaterialApp(
            theme: temaOficina(),
            home: const Scaffold(body: TelaPosto()),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(
        find.textContaining('Inclui 1 período com mistura'),
        findsOneWidget,
      );
      expect(
        find.text('Gasolina estimada pela referência da Ficha.'),
        findsOneWidget,
      );
      await tester.scrollUntilVisible(
        find.text('Compra de 1,0 L · R\$ 6,00'),
        250,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();
      expect(find.text('Medido com mistura no período'), findsOneWidget);
      expect(find.text('200 km · 10,0 L no período'), findsOneWidget);
      expect(find.textContaining('Custo do período R\$ 60,00'), findsOneWidget);
      expect(find.textContaining('rodou com gasolina'), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );
}
