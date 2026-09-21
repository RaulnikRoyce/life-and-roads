import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:life_and_roads/features/ficha/presentation/widgets/primeiros_passos.dart';
import 'package:life_and_roads/ficha/catalogo.dart';
import 'package:life_and_roads/tema.dart';

/// Monta o widget sozinho, com os controllers na mão, para testar a
/// condução sem banco nem controller de ficha.
class _Cenario {
  final marca = TextEditingController();
  final modelo = TextEditingController();
  final kmLitro = TextEditingController();
  final kmLitroAlcool = TextEditingController();
  final kmAtual = TextEditingController();
  bool flex = true;
  ModeloCatalogo? catalogo;
  int concluiu = 0;

  Widget montar() {
    return MaterialApp(
      theme: temaOficina(),
      home: Scaffold(
        body: StatefulBuilder(
          builder: (context, setState) => ListView(
            padding: const EdgeInsets.all(20),
            children: [
              PrimeirosPassos(
                marca: marca,
                modelo: modelo,
                kmLitro: kmLitro,
                kmLitroAlcool: kmLitroAlcool,
                kmAtual: kmAtual,
                flex: flex,
                aoFlex: (v) => setState(() => flex = v),
                aoCatalogo: (m) => catalogo = m,
                aoConcluir: () => concluiu++,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void descartar() {
    for (final c in [marca, modelo, kmLitro, kmLitroAlcool, kmAtual]) {
      c.dispose();
    }
  }
}

Future<void> _ate3(WidgetTester tester, _Cenario c) async {
  c.marca.text = 'Honda';
  c.modelo.text = 'Bros';
  c.kmAtual.text = '1000';
  c.kmLitro.text = '30';
  await tester.pump();
  await tester.tap(find.text('Continuar'));
  await tester.pumpAndSettle();
  await tester.tap(find.text('Continuar'));
  await tester.pumpAndSettle();
  expect(find.text('Gasolina ou flex?'), findsOneWidget);
}

void main() {
  GoogleFonts.config.allowRuntimeFetching = false;

  testWidgets('Continuar espera marca e modelo; Voltar volta', (tester) async {
    final c = _Cenario();
    addTearDown(c.descartar);
    await tester.pumpWidget(c.montar());
    await tester.pumpAndSettle();

    FilledButton botao() =>
        tester.widget(find.widgetWithText(FilledButton, 'Continuar'));
    expect(botao().enabled, isFalse);
    c.marca.text = 'Honda';
    await tester.pump();
    expect(botao().enabled, isFalse);
    c.modelo.text = 'Bros';
    await tester.pump();
    expect(botao().enabled, isTrue);

    await tester.tap(find.text('Continuar'));
    await tester.pumpAndSettle();
    expect(find.text('Quanto marca o painel?'), findsOneWidget);
    expect(find.text('2 de 3'), findsOneWidget);
    await tester.tap(find.text('Voltar'));
    await tester.pumpAndSettle();
    expect(find.text('Qual é a sua moto?'), findsOneWidget);
    expect(find.text('Voltar'), findsNothing);
  });

  testWidgets('Gasolina guarda o álcool e Flex devolve', (tester) async {
    final c = _Cenario();
    addTearDown(c.descartar);
    c.kmLitroAlcool.text = '35'; // veio do catálogo
    await tester.pumpWidget(c.montar());
    await tester.pumpAndSettle();
    await _ate3(tester, c);

    await tester.tap(find.text('Gasolina'));
    await tester.pumpAndSettle();
    expect(c.flex, isFalse);
    expect(c.kmLitroAlcool.text, '');
    expect(find.text('Km com 1 L de álcool'), findsNothing);

    await tester.tap(find.text('Flex'));
    await tester.pumpAndSettle();
    expect(c.flex, isTrue);
    expect(c.kmLitroAlcool.text, '35');
    expect(find.textContaining('70% da gasolina'), findsNothing);
  });

  testWidgets('Flex sem álcool avisa a estimativa e preenche no Começar', (
    tester,
  ) async {
    final c = _Cenario();
    addTearDown(c.descartar);
    await tester.pumpWidget(c.montar());
    await tester.pumpAndSettle();
    await _ate3(tester, c);

    expect(find.textContaining('70% da gasolina (21 km)'), findsOneWidget);
    expect(c.kmLitroAlcool.text, '');

    await tester.tap(find.text('Começar'));
    await tester.pump();
    expect(c.concluiu, 1);
    expect(c.kmLitroAlcool.text, '21');
  });

  testWidgets('álcool digitado tira o aviso e vale como está', (tester) async {
    final c = _Cenario();
    addTearDown(c.descartar);
    await tester.pumpWidget(c.montar());
    await tester.pumpAndSettle();
    await _ate3(tester, c);

    await tester.enterText(
      find.widgetWithText(TextField, 'Km com 1 L de álcool'),
      '24',
    );
    await tester.pump();
    expect(find.textContaining('70% da gasolina'), findsNothing);
    await tester.tap(find.text('Começar'));
    await tester.pump();
    expect(c.kmLitroAlcool.text, '24');
  });

  testWidgets('Começar só libera com gasolina válida', (tester) async {
    final c = _Cenario();
    addTearDown(c.descartar);
    await tester.pumpWidget(c.montar());
    await tester.pumpAndSettle();
    await _ate3(tester, c);

    final comecar = find.widgetWithText(FilledButton, 'Começar');
    c.kmLitro.clear();
    await tester.pump();
    expect(tester.widget<FilledButton>(comecar).enabled, isFalse);
    c.kmLitro.text = '30';
    c.kmLitroAlcool.text = 'x';
    await tester.pump();
    expect(tester.widget<FilledButton>(comecar).enabled, isFalse);
    c.kmLitroAlcool.text = '22';
    await tester.pump();
    expect(tester.widget<FilledButton>(comecar).enabled, isTrue);
  });
}
