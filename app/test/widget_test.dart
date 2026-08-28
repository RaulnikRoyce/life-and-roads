import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:life_and_roads/main.dart';
import 'package:life_and_roads/tela_abertura.dart';

import 'helpers/banco_teste.dart';

Finder _aba(String nome) => find.descendant(
      of: find.byType(NavigationBar),
      matching: find.text(nome),
    );

Finder _scroll() => find.byType(Scrollable).hitTestable().first;

Future<void> _app(WidgetTester tester) async {
  await tester.pumpWidget(
    const ProviderScope(child: LifeAndRoadsApp(pularAbertura: true)),
  );
  await tester.pumpAndSettle();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  GoogleFonts.config.allowRuntimeFetching = false;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await abrirBancoTeste();
  });

  tearDown(() async {
    await fecharBancoTeste();
  });

  testWidgets('abre com as 4 abas', (tester) async {
    await _app(tester);

    expect(_aba('Ficha'), findsOneWidget);
    expect(_aba('Manutenção'), findsOneWidget);
    expect(_aba('Viagem'), findsOneWidget);
    expect(_aba('Mapa'), findsOneWidget);
  });

  testWidgets('abertura mostra a logo e o crédito', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: LifeAndRoadsApp()));
    await tester.pump();

    expect(find.text('developed by Raulnik Royce'), findsOneWidget);
    expect(find.byType(TelaPrincipal), findsNothing);

    await tester.pump(TelaAbertura.duracao);
    await tester.pumpAndSettle();
    expect(find.byType(TelaPrincipal), findsOneWidget);
  });

  testWidgets('ficha mostra o formulário', (tester) async {
    await _app(tester);

    expect(find.text('Sua moto'), findsWidgets);
    expect(find.textContaining('Sem placa'), findsOneWidget);
    expect(find.text('Toque para a foto'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Esportiva'),
      200,
      scrollable: _scroll(),
    );
    expect(find.text('Esportiva'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Marca'),
      200,
      scrollable: _scroll(),
    );
    expect(find.text('Marca'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Tanque (litros)'),
      200,
      scrollable: _scroll(),
    );
    expect(find.text('Tanque (litros)'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Mais números'),
      200,
      scrollable: _scroll(),
    );
    expect(find.text('Mais números'), findsOneWidget);
    await tester.tap(find.text('Mais números'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('PSI dianteiro'),
      200,
      scrollable: _scroll(),
    );
    expect(find.text('PSI dianteiro'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Backup neste aparelho'),
      200,
      scrollable: _scroll(),
    );
    expect(find.text('Backup neste aparelho'), findsOneWidget);
  });

  testWidgets('ficha salva mostra o card e esconde o form em Ajustar números',
      (tester) async {
    SharedPreferences.setMockInitialValues({
      'ficha_moto_v1':
          '{"marca":"Honda","modelo":"Bros","kmLitro":"35","kmAtual":"1000"}',
    });
    await tester.pumpWidget(
      const ProviderScope(child: LifeAndRoadsApp(pularAbertura: true)),
    );
    await tester.pumpAndSettle();

    expect(find.text('Honda Bros'), findsOneWidget);
    expect(find.text('ÁLCOOL'), findsNothing);
    expect(find.text('GASOLINA'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Ajustar números'),
      200,
      scrollable: _scroll(),
    );
    expect(find.text('Ajustar números'), findsOneWidget);
    expect(find.text('Marca'), findsNothing);

    await tester.tap(find.text('Ajustar números'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('Marca'),
      200,
      scrollable: _scroll(),
    );
    expect(find.text('Marca'), findsOneWidget);
  });

  testWidgets('ficha flex mostra o card ÁLCOOL', (tester) async {
    SharedPreferences.setMockInitialValues({
      'ficha_moto_v1':
          '{"marca":"Honda","modelo":"CG 160","kmLitro":"41","kmLitroAlcool":"35","kmAtual":"1000"}',
    });
    await tester.pumpWidget(
      const ProviderScope(child: LifeAndRoadsApp(pularAbertura: true)),
    );
    await tester.pumpAndSettle();

    expect(find.text('Honda CG 160'), findsOneWidget);
    expect(find.text('ÁLCOOL'), findsOneWidget);
    expect(find.text('GASOLINA'), findsOneWidget);
  });

  testWidgets('aba manutenção mostra óleo e pneus', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(child: LifeAndRoadsApp(pularAbertura: true)),
    );
    await tester.pumpAndSettle();

    await tester.tap(_aba('Manutenção'));
    await tester.pumpAndSettle();

    expect(find.text('Quando você trocou'), findsOneWidget);
    expect(
      find.text('Próxima troca (o app completa uns seis meses)'),
      findsOneWidget,
    );
    expect(find.text('Km do painel na troca'), findsOneWidget);
    expect(find.byIcon(Icons.notifications_outlined), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('CNH, vencimento'),
      200,
      scrollable: _scroll(),
    );
    expect(find.text('CNH, vencimento'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Registrar serviço'),
      200,
      scrollable: _scroll(),
    );
    expect(find.text('Registrar serviço'), findsOneWidget);
  });

  testWidgets('aba viagem mostra o cálculo', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(child: LifeAndRoadsApp(pularAbertura: true)),
    );
    await tester.pumpAndSettle();

    await tester.tap(_aba('Viagem'));
    await tester.pumpAndSettle();

    expect(find.text('Calcular'), findsOneWidget);
    expect(find.text('Marcar no mapa'), findsOneWidget);
    expect(find.text('Gasolina'), findsWidgets);
    expect(find.text('Álcool'), findsWidgets);
    expect(find.text('Preço gasolina (R\$)'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Registrar abastecimento'),
      200,
      scrollable: _scroll(),
    );
    expect(find.text('Registrar abastecimento'), findsOneWidget);
    expect(find.text('Litros que entrou'), findsOneWidget);
    expect(find.text('Km no painel agora'), findsOneWidget);
  });

  testWidgets('aba viagem relê o km/l da ficha ao abrir', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(child: LifeAndRoadsApp(pularAbertura: true)),
    );
    await tester.pumpAndSettle();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      'ficha_moto_v1',
      '{"marca":"Honda","modelo":"NXR 160 Bros","kmLitro":"35","kmLitroAlcool":"28","kmAtual":"32130","tanqueLitros":"12"}',
    );

    await tester.tap(_aba('Viagem'));
    await tester.pumpAndSettle();

    expect(
      find.textContaining('uns 35'),
      findsOneWidget,
    );
  });

  testWidgets('aba mapa mostra Rastrear', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(child: LifeAndRoadsApp(pularAbertura: true)),
    );
    await tester.pumpAndSettle();

    await tester.tap(_aba('Mapa'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.text('Rastrear'), findsOneWidget);
    expect(find.textContaining('Toque longo'), findsOneWidget);
  });
}
