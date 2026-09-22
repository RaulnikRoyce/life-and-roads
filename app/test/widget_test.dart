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
    expect(_aba('Posto'), findsOneWidget);
    expect(_aba('Viagem'), findsOneWidget);
    expect(_aba('Mapa'), findsNothing);
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

  testWidgets('aba manutenção mostra o painel e os grupos', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(child: LifeAndRoadsApp(pularAbertura: true)),
    );
    await tester.pumpAndSettle();

    await tester.tap(_aba('Manutenção'));
    await tester.pumpAndSettle();

    // Agenda vazia: o anel fica só com o trilho e o formulário não aparece.
    expect(find.text('Sem vencimentos'), findsOneWidget);
    expect(find.byIcon(Icons.notifications_outlined), findsOneWidget);
    expect(find.text('Data da última troca'), findsNothing);
    expect(find.text('Salvar manutenção'), findsNothing);

    // O grupo abre a folha com os campos de sempre.
    await tester.scrollUntilVisible(
      find.text('ÓLEO E CORRENTE'),
      200,
      scrollable: _scroll(),
    );
    await tester.tap(find.text('ÓLEO E CORRENTE'));
    await tester.pumpAndSettle();
    expect(find.text('Data da última troca'), findsOneWidget);
    expect(
      find.text('Próxima troca (o app sugere seis meses depois)'),
      findsOneWidget,
    );
    expect(find.text('Km do painel na troca'), findsOneWidget);
    // O botão fica no fim da folha; com a folha aberta, o primeiro
    // Scrollable tocável é o dela.
    await tester.scrollUntilVisible(
      find.text('Salvar'),
      200,
      scrollable: _scroll(),
    );
    expect(find.widgetWithText(FilledButton, 'Salvar'), findsOneWidget);

    // Fechar pela barreira, sem salvar.
    await tester.tapAt(const Offset(10, 10));
    await tester.pumpAndSettle();
    expect(find.text('Data da última troca'), findsNothing);

    for (final grupo in ['PNEUS', 'DOCUMENTOS', 'CNH']) {
      await tester.scrollUntilVisible(
        find.text(grupo),
        200,
        scrollable: _scroll(),
      );
      expect(find.text(grupo), findsOneWidget);
    }
    await tester.tap(find.text('CNH'));
    await tester.pumpAndSettle();
    expect(find.text('CNH, vencimento'), findsOneWidget);
    expect(find.text('CNH 10 anos'), findsOneWidget);
    await tester.tapAt(const Offset(10, 10));
    await tester.pumpAndSettle();
    expect(find.text('CNH, vencimento'), findsNothing);

    await tester.scrollUntilVisible(
      find.text('Registrar serviço'),
      200,
      scrollable: _scroll(),
    );
    expect(find.text('Registrar serviço'), findsOneWidget);
    expect(find.text('Nenhum serviço ainda'), findsOneWidget);
  });

  testWidgets('aba posto mostra o painel e o abastecimento', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(child: LifeAndRoadsApp(pularAbertura: true)),
    );
    await tester.pumpAndSettle();

    await tester.tap(_aba('Posto'));
    await tester.pumpAndSettle();

    // A calculadora saiu desta aba.
    expect(find.text('Calcular'), findsNothing);
    expect(find.text('Marcar no mapa'), findsNothing);

    expect(find.text('POR KM'), findsOneWidget);
    expect(find.text('Preço gasolina (R\$)'), findsOneWidget);
    expect(find.text('Registrar abastecimento'), findsOneWidget);
    expect(find.text('Nenhum abastecimento ainda'), findsOneWidget);
    // Km e litros ficam na folha, não na tela.
    expect(find.text('Litros abastecidos'), findsNothing);

    await tester.scrollUntilVisible(
      find.text('Registrar abastecimento'),
      200,
      scrollable: _scroll(),
    );
    await tester.tap(find.text('Registrar abastecimento'));
    await tester.pumpAndSettle();
    expect(find.text('Litros abastecidos'), findsOneWidget);
    expect(find.text('Km no painel agora'), findsOneWidget);
    expect(find.widgetWithText(FilledButton, 'Registrar'), findsOneWidget);

    // Fechar pela barreira, sem registrar.
    await tester.tapAt(const Offset(10, 10));
    await tester.pumpAndSettle();
    expect(find.text('Litros abastecidos'), findsNothing);
  });

  testWidgets('aba posto relê a ficha ao abrir', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(child: LifeAndRoadsApp(pularAbertura: true)),
    );
    await tester.pumpAndSettle();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      'ficha_moto_v1',
      '{"marca":"Honda","modelo":"NXR 160 Bros","kmLitro":"35","kmLitroAlcool":"28","kmAtual":"32130","tanqueLitros":"12"}',
    );

    await tester.tap(_aba('Posto'));
    await tester.pumpAndSettle();

    // Pastilha COM 1 L com o kmLitro da ficha e o km gravado.
    expect(find.text('35 km'), findsOneWidget);
    expect(find.text('Último km gravado: 32.130.'), findsOneWidget);
  });

  testWidgets('aba viagem mostra Rastrear', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(child: LifeAndRoadsApp(pularAbertura: true)),
    );
    await tester.pumpAndSettle();

    await tester.tap(_aba('Viagem'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.text('Rastrear'), findsOneWidget);
    expect(find.textContaining('Toque longo'), findsOneWidget);
  });

  testWidgets('aba viagem abre o cálculo', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(child: LifeAndRoadsApp(pularAbertura: true)),
    );
    await tester.pumpAndSettle();

    await tester.tap(_aba('Viagem'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    // Recolhido: só as ações e a ajuda.
    expect(find.text('Km da viagem'), findsNothing);

    await tester.tap(find.text('Calcular viagem'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.text('Km da viagem'), findsOneWidget);
    expect(find.widgetWithText(FilledButton, 'Calcular'), findsOneWidget);
    expect(find.text('Gasolina'), findsOneWidget);
    expect(find.text('Álcool'), findsOneWidget);
    expect(find.text('Informe os preços na aba Posto.'), findsOneWidget);

    // O mapa não termina animações em teste; sem pumpAndSettle. O cartão
    // cresce durante Movimento.medio com o cabeçalho ainda fora da caixa;
    // o pump com duração avança o relógio até ele caber e receber o toque.
    await tester.pump(const Duration(milliseconds: 400));
    await tester.tap(find.byIcon(Icons.expand_more));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text('Km da viagem'), findsNothing);
    expect(find.text('Calcular viagem'), findsOneWidget);
  });

  testWidgets('preço digitado no Posto chega à Viagem', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(child: LifeAndRoadsApp(pularAbertura: true)),
    );
    await tester.pumpAndSettle();

    await tester.tap(_aba('Posto'));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.widgetWithText(TextField, 'Preço gasolina (R\$)'),
      '5,89',
    );
    await tester.enterText(
      find.widgetWithText(TextField, 'Preço álcool (R\$)'),
      '3,99',
    );
    await tester.pumpAndSettle();

    await tester.tap(_aba('Viagem'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    await tester.tap(find.text('Calcular viagem'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(
      find.text(
        'Preços de hoje: gasolina R\$ 5,89, álcool R\$ 3,99. '
        'Ajuste na aba Posto.',
      ),
      findsOneWidget,
    );
    expect(find.text('Informe os preços na aba Posto.'), findsNothing);
  });
}
