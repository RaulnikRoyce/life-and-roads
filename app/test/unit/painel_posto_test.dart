import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:life_and_roads/features/viagem/domain/usecases/resumo_consumo.dart';
import 'package:life_and_roads/features/viagem/presentation/widgets/grafico_consumo.dart';
import 'package:life_and_roads/features/viagem/presentation/widgets/painel_posto.dart';
import 'package:life_and_roads/tema.dart';
import 'package:life_and_roads/viagem/calculo.dart';

Widget _app(Widget filho) => MaterialApp(
  theme: temaOficina(),
  home: Scaffold(
    body: Padding(padding: const EdgeInsets.all(20), child: filho),
  ),
);

RegistroAbastecimento _posto(String em, double reaisPorKm) =>
    RegistroAbastecimento(
      em: em,
      combustivel: Combustivel.gasolina,
      kmPainel: 1000,
      kmRodados: 300,
      litros: 8,
      precoLitro: 6,
      reais: 48,
      kmPorLitro: 37.5,
      reaisPorKm: reaisPorKm,
    );

/// Três postos como o histórico entrega, do mais novo ao mais antigo.
final _tres = [
  _posto('2026-09-20T10:00:00', 0.15),
  _posto('2026-09-10T10:00:00', 0.18),
  _posto('2026-09-01T10:00:00', 0.12),
];

void main() {
  GoogleFonts.config.allowRuntimeFetching = false;

  test('formata reais, km e milhar', () {
    expect(PainelPosto.reais(0.42), '0,42');
    expect(PainelPosto.km(35), '35');
    expect(PainelPosto.km(38.2), '38,2');
    expect(PainelPosto.milhar(32130), '32.130');
  });

  testWidgets('vazio mostra a frase de partida e traços', (tester) async {
    await tester.pumpWidget(
      _app(const PainelPosto(origem: 'informe os preços', postos: 0)),
    );
    await tester.pumpAndSettle();

    expect(find.text('POR KM'), findsOneWidget);
    expect(find.text('informe os preços'), findsOneWidget);
    expect(
      find.textContaining('Registre o primeiro abastecimento'),
      findsOneWidget,
    );
    // Custo, consumo e tanque sem valor.
    expect(find.text('-'), findsNWidgets(3));
    expect(find.text('0'), findsOneWidget);
  });

  testWidgets('com números mostra custo, postos, consumo e tanque', (
    tester,
  ) async {
    await tester.pumpWidget(
      _app(
        const PainelPosto(
          custoPorKm: 0.42,
          origem: 'média de 5 postos',
          fraseVencedor: 'Hoje o álcool custa menos.',
          postos: 5,
          kmComUmLitro: 38,
          autonomiaKm: 660,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('R\$ 0,42'), findsOneWidget);
    expect(find.text('média de 5 postos'), findsOneWidget);
    expect(find.text('5'), findsOneWidget);
    expect(find.text('38 km'), findsOneWidget);
    expect(find.text('660 km'), findsOneWidget);
    expect(find.text('TANQUE CHEIO'), findsOneWidget);
    expect(find.text('Hoje o álcool custa menos.'), findsOneWidget);
    expect(find.text('-'), findsNothing);
  });

  testWidgets('tanque cheio arredonda e usa ponto de milhar', (tester) async {
    await tester.pumpWidget(
      _app(
        const PainelPosto(
          origem: 'pela ficha e os preços de hoje',
          postos: 0,
          kmComUmLitro: 35.3,
          autonomiaKm: 12 * 35.3,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('35,3 km'), findsOneWidget);
    expect(find.text('424 km'), findsOneWidget);
    expect(find.text('423,6 km'), findsNothing);

    await tester.pumpWidget(
      _app(
        const PainelPosto(
          origem: 'pela ficha e os preços de hoje',
          postos: 0,
          kmComUmLitro: 40,
          autonomiaKm: 40 * 40,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('1.600 km'), findsOneWidget);
  });

  test('pontos inverte para a ordem cronológica e corta nos 10 últimos', () {
    final serie = GraficoConsumo.pontos(
      const ResumoConsumo().executar(_tres).barras,
    );
    expect(serie.map((b) => b.registro.em).toList(), [
      '2026-09-01T10:00:00',
      '2026-09-10T10:00:00',
      '2026-09-20T10:00:00',
    ]);

    final doze = [
      for (var i = 0; i < 12; i++)
        _posto('2026-09-${(12 - i).toString().padLeft(2, '0')}T10:00:00', 0.1),
    ];
    final dez = GraficoConsumo.pontos(
      const ResumoConsumo().executar(doze).barras,
    );
    expect(dez.length, 10);
    expect(dez.first.registro.em, startsWith('2026-09-03'));
    expect(dez.last.registro.em, startsWith('2026-09-12'));
  });

  testWidgets('gráfico com 3 postos mostra as datas das pontas', (
    tester,
  ) async {
    await tester.pumpWidget(
      _app(
        GraficoConsumo(
          barras: const ResumoConsumo().executar(_tres).barras,
          fundo: Oficina.couro,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('01/09'), findsOneWidget);
    expect(find.text('20/09'), findsOneWidget);
    expect(find.text('10/09'), findsNothing);
    expect(find.textContaining('Registre o primeiro'), findsNothing);
  });

  testWidgets('em tela estreita cabe sem estourar', (tester) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      _app(
        PainelPosto(
          custoPorKm: 0.42,
          origem: 'média de 3 postos',
          fraseVencedor: 'Hoje a gasolina custa menos.',
          postos: 3,
          kmComUmLitro: 38.2,
          autonomiaKm: 660,
          barras: const ResumoConsumo().executar(_tres).barras,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('R\$ 0,42'), findsOneWidget);
    expect(find.text('38,2 km'), findsOneWidget);
    expect(find.text('01/09'), findsOneWidget);
  });
}
