import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:life_and_roads/features/ficha/domain/ficha_moto.dart';
import 'package:life_and_roads/features/viagem/domain/usecases/calibrar_marcador.dart';
import 'package:life_and_roads/features/viagem/presentation/widgets/painel_marcador.dart';
import 'package:life_and_roads/tema.dart';
import 'package:life_and_roads/viagem/calculo.dart';

const _ficha = FichaMoto(
  marca: 'Honda',
  modelo: 'Bros',
  ano: 2023,
  cilindrada: 160,
  kmLitro: 35,
  kmAtual: 1000,
  tanqueLitros: 12,
);
RegistroAbastecimento _leitura(
  int id, {
  int antes = 1,
  int total = 6,
  int depois = 6,
  double litros = 9,
  bool cheio = true,
  FichaMoto ficha = _ficha,
  bool identificada = true,
}) => RegistroAbastecimento(
  em: '2026-11-04T10:00:00.$id',
  combustivel: Combustivel.gasolina,
  kmPainel: 1000 + id * 100,
  kmRodados: 0,
  litros: litros,
  precoLitro: 6,
  reais: litros * 6,
  kmPorLitro: 0,
  reaisPorKm: 0,
  tipoConsumo: 'referencia',
  tanqueCheio: cheio,
  totalBarras: total,
  barrasAntes: antes,
  barrasDepois: depois,
  referenciaMarcador: identificada ? referenciaMarcadorDaFicha(ficha) : null,
);
CalibracaoMarcador _calibrar(
  List<RegistroAbastecimento> registros, {
  FichaMoto? ficha = _ficha,
  int total = 6,
}) => const CalibrarMarcador().executar(
  ficha: ficha,
  historico: registros,
  totalBarras: total,
);

void main() {
  GoogleFonts.config.allowRuntimeFetching = false;
  test('aprende faixa de um nível a partir de três tanques completos', () {
    final r = _calibrar([
      _leitura(1),
      _leitura(2, litros: 8.8),
      _leitura(3, litros: 9.2),
    ]);
    expect(r.consultar(1)!.minimo, closeTo(2.8, .000001));
    expect(r.consultar(1)!.maximo, closeTo(3.2, .000001));
    expect(r.consultar(1)!.referencias, 3);
    expect(r.consultar(2), isNull);
  });
  test('uma ou duas referências não liberam estimativa', () {
    final r = _calibrar([_leitura(1), _leitura(2)]);
    expect(r.niveis[1]!.referencias, 2);
    expect(r.consultar(1), isNull);
  });
  test('não transforma parciais ou marcador incompleto em referência', () {
    expect(
      _calibrar([_leitura(1, cheio: false), _leitura(2, depois: 4)]).niveis,
      isEmpty,
    );
  });
  test(
    'não supõe zero litros na reserva nem tanque cheio com todas as barras',
    () {
      final r = _calibrar([
        for (var i = 1; i <= 3; i++) _leitura(i, antes: 0, litros: 10.5),
        for (var i = 4; i <= 6; i++) _leitura(i, antes: 6, litros: 1),
      ]);
      expect(r.consultar(0)!.minimo, 1.5);
      expect(r.consultar(6)!.maximo, 11);
    },
  );
  test('não interpola níveis nem divide tanque igualmente', () {
    final r = _calibrar([
      for (var i = 1; i <= 3; i++) _leitura(i, antes: 1, litros: 9),
      for (var i = 4; i <= 6; i++) _leitura(i, antes: 4, litros: 7),
    ]);
    expect(r.consultar(1)!.minimo, 3);
    expect(r.consultar(4)!.minimo, 5);
    expect(r.consultar(3), isNull);
  });
  test('separa motos, capacidades e marcadores diferentes', () {
    final registros = [_leitura(1), _leitura(2), _leitura(3)];
    expect(
      _calibrar(registros, ficha: _ficha.copiarCom(modelo: 'Outra')).niveis,
      isEmpty,
    );
    expect(
      _calibrar(registros, ficha: _ficha.copiarCom(tanqueLitros: 13)).niveis,
      isEmpty,
    );
    expect(_calibrar(registros, total: 5).niveis, isEmpty);
    expect(
      _calibrar(
        registros,
        ficha: _ficha.copiarCom(marca: ' HONDA '),
      ).consultar(1),
      isNotNull,
    );
  });
  test('não atribui leituras antigas sem identificação à moto atual', () {
    expect(
      _calibrar([for (var i = 0; i < 3; i++) _leitura(i, identificada: false)])
          .niveis,
      isEmpty,
    );
  });
  test('registros duplicados não contam como novas referências', () {
    final r = _leitura(1);
    expect(_calibrar([r, r, r]).niveis[1]!.referencias, 1);
  });
  test('leituras fisicamente contraditórias suspendem consulta', () {
    final r = _calibrar([
      for (var i = 1; i <= 3; i++) _leitura(i, antes: 1, litros: 3),
      for (var i = 4; i <= 6; i++) _leitura(i, antes: 4, litros: 8),
    ]);
    expect(r.contraditoria, isTrue);
    expect(r.consultar(1), isNull);
  });
  test('ignora compras impossíveis sem bloquear o histórico', () {
    expect(
      _calibrar([
        _leitura(1, litros: 13),
        _leitura(2, litros: double.nan),
        _leitura(3, litros: -2),
      ]).niveis,
      isEmpty,
    );
    expect(_calibrar([_leitura(1)], ficha: null).niveis, isEmpty);
    expect(
      _calibrar([
        _leitura(1),
      ], ficha: _ficha.copiarCom(limparTanque: true)).niveis,
      isEmpty,
    );
  });
  test('referência acompanha JSON e dados antigos continuam válidos', () {
    final r = _leitura(1);
    expect(
      RegistroAbastecimento.deJson(r.paraJson())!.referenciaMarcador,
      r.referenciaMarcador,
    );
    final antigo = r.paraJson()..remove('referenciaMarcador');
    expect(RegistroAbastecimento.deJson(antigo)!.referenciaMarcador, isNull);
    expect(
      RegistroAbastecimento.deJson({...antigo, 'referenciaMarcador': 123}),
      isNull,
    );
  });
  testWidgets(
    'consulta apresenta faixa observada e aprendizado para outro nível',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        MaterialApp(
          theme: temaOficina(),
          home: Scaffold(
            body: SingleChildScrollView(
              child: PainelMarcador(
                ficha: _ficha,
                historico: [
                  _leitura(1),
                  _leitura(2, litros: 8),
                  _leitura(3, litros: 9.5),
                ],
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Combustível pelas barrinhas'));
      await tester.pumpAndSettle();
      await tester.tap(find.byType(DropdownButtonFormField<int>).last);
      await tester.pumpAndSettle();
      await tester.tap(find.text('1 de 6 barras').last);
      await tester.pumpAndSettle();
      expect(
        find.text('Faixa observada de 2,5 a 4,0 L no tanque'),
        findsOneWidget,
      );
      expect(find.textContaining('3 abastecimentos completos'), findsOneWidget);
      await tester.tap(find.byType(DropdownButtonFormField<int>).last);
      await tester.pumpAndSettle();
      await tester.tap(find.text('2 de 6 barras').last);
      await tester.pumpAndSettle();
      expect(find.textContaining('0 de 3 referências'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets('sem capacidade orienta preencher ficha', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: PainelMarcador(
            ficha: _ficha.copiarCom(limparTanque: true),
            historico: const [],
          ),
        ),
      ),
    );
    await tester.tap(find.text('Combustível pelas barrinhas'));
    await tester.pumpAndSettle();
    expect(
      find.textContaining('capacidade do tanque na Ficha'),
      findsOneWidget,
    );
    expect(find.byType(DropdownButtonFormField<int>), findsNothing);
  });
}
