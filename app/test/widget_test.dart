import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:life_and_roads/core/widgets/barra_abas.dart';
import 'package:life_and_roads/main.dart';
import 'package:life_and_roads/tela_abertura.dart';

import 'helpers/banco_teste.dart';

Finder _aba(String nome) =>
    find.descendant(of: find.byType(BarraAbas), matching: find.text(nome));

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

  testWidgets('ficha vazia conduz em três passos e salva', (tester) async {
    await _app(tester);

    // Passo 1: a moto. Continuar só libera com marca e modelo.
    expect(find.text('Qual é a sua moto?'), findsOneWidget);
    expect(find.text('1 de 3'), findsOneWidget);
    expect(find.text('Esportiva'), findsOneWidget);
    expect(find.text('Escolher no catálogo'), findsOneWidget);
    expect(find.text('Adicionar foto'), findsNothing);
    expect(find.text('Tanque (litros)'), findsNothing);
    expect(
      tester
          .widget<FilledButton>(find.widgetWithText(FilledButton, 'Continuar'))
          .enabled,
      isFalse,
    );
    await tester.enterText(find.widgetWithText(TextField, 'Marca'), 'Honda');
    await tester.enterText(find.widgetWithText(TextField, 'Modelo'), 'Bros');
    await tester.pump();
    await tester.tap(find.text('Continuar'));
    await tester.pumpAndSettle();

    // Passo 2: o painel. Voltar aparece.
    expect(find.text('Quanto marca o painel?'), findsOneWidget);
    expect(find.text('2 de 3'), findsOneWidget);
    expect(find.text('Voltar'), findsOneWidget);
    await tester.enterText(
      find.widgetWithText(TextField, 'Km no painel agora'),
      '1000',
    );
    await tester.pump();
    await tester.tap(find.text('Continuar'));
    await tester.pumpAndSettle();

    // Passo 3: combustível. Flex sem álcool avisa que vai estimar 70%.
    expect(find.text('Gasolina ou flex?'), findsOneWidget);
    expect(find.text('Começar'), findsOneWidget);
    await tester.enterText(
      find.widgetWithText(TextField, 'Km com 1 L de gasolina'),
      '30',
    );
    await tester.pump();
    expect(find.textContaining('70% da gasolina (21 km)'), findsOneWidget);
    await tester.tap(find.text('Gasolina'));
    await tester.pumpAndSettle();
    expect(find.text('Km com 1 L de álcool'), findsNothing);

    // Backup e conta continuam ao alcance de quem trocou de aparelho.
    await tester.scrollUntilVisible(
      find.text('Backup neste aparelho'),
      200,
      scrollable: _scroll(),
    );
    expect(find.text('Backup neste aparelho'), findsOneWidget);

    // Começar salva e a Ficha vira painel.
    await tester.scrollUntilVisible(
      find.text('Começar'),
      -200,
      scrollable: _scroll(),
    );
    await tester.tap(find.text('Começar'));
    await tester.pumpAndSettle();
    expect(find.text('Honda Bros'), findsOneWidget);
    expect(find.text('Ajustar números'), findsOneWidget);
    expect(find.text('Qual é a sua moto?'), findsNothing);
  });

  testWidgets('ficha salva mostra o card e esconde o form em Ajustar números', (
    tester,
  ) async {
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
      'ficha_moto_v1': '{"marca":"Honda","modelo":"CG 160","kmLitro":"41","kmLitroAlcool":"35","kmAtual":"1000"}',
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

    expect(find.text('Data da última troca'), findsOneWidget);
    expect(
      find.text('Próxima troca (o app sugere seis meses depois)'),
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
    expect(find.text('Litros abastecidos'), findsOneWidget);
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

    expect(find.textContaining('Consumo com gasolina'), findsOneWidget);
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
