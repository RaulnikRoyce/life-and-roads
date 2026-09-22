import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:life_and_roads/features/mapa/presentation/widgets/bilhete_viagem.dart';
import 'package:life_and_roads/tema.dart';
import 'package:life_and_roads/viagem/calculo.dart';

Widget _app(Widget filho, {double largura = 400}) => MaterialApp(
  theme: temaOficina(),
  home: Scaffold(
    body: Center(
      child: SizedBox(
        width: largura,
        child: Padding(padding: const EdgeInsets.all(20), child: filho),
      ),
    ),
  ),
);

void main() {
  GoogleFonts.config.allowRuntimeFetching = false;

  test('formata km, litros e reais', () {
    expect(BilheteViagem.kmTexto(300), '300');
    expect(BilheteViagem.kmTexto(7.5), '7,5');
    expect(BilheteViagem.litrosTexto(12.4), '12,4');
    expect(BilheteViagem.reaisTexto(78.1), '78,10');
  });

  testWidgets('mostra a viagem, o combustível, litros, valor e o tanque', (
    tester,
  ) async {
    await tester.pumpWidget(
      _app(
        const BilheteViagem(
          km: 300,
          combustivel: Combustivel.gasolina,
          litros: 12.4,
          reais: 78.1,
          avisoTanque: 'Cabe no tanque de 16,1 L.',
        ),
      ),
    );
    // O número anima até o valor final.
    await tester.pumpAndSettle();

    expect(find.text('VIAGEM DE 300 KM'), findsOneWidget);
    expect(find.text('GASOLINA'), findsOneWidget);
    expect(find.text('12,4 L'), findsOneWidget);
    expect(find.text('R\$ 78,10'), findsOneWidget);
    expect(find.text('Cabe no tanque de 16,1 L.'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('sem tanque na ficha, sem a linha do tanque', (tester) async {
    await tester.pumpWidget(
      _app(
        const BilheteViagem(
          km: 120,
          combustivel: Combustivel.alcool,
          litros: 4.3,
          reais: 17.2,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('VIAGEM DE 120 KM'), findsOneWidget);
    expect(find.text('ÁLCOOL'), findsOneWidget);
    expect(find.textContaining('tanque'), findsNothing);
  });

  testWidgets('cabe em 320 px de largura sem estourar', (tester) async {
    await tester.pumpWidget(
      _app(
        const BilheteViagem(
          km: 1500,
          combustivel: Combustivel.gasolina,
          litros: 62.5,
          reais: 368.13,
          avisoTanque:
              'Ultrapassa o tanque de 16,1 L. A viagem precisa de 62,5 L.',
        ),
        largura: 320,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('62,5 L'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
