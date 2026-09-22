import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:life_and_roads/features/ficha/presentation/widgets/busca_modelo.dart';
import 'package:life_and_roads/ficha/catalogo.dart';
import 'package:life_and_roads/tema.dart';

void main() {
  GoogleFonts.config.allowRuntimeFetching = false;

  test('busca ignora acento e caixa', () {
    final tenere = BuscaModelo.filtrar(catalogoMotos, 'tenere');
    expect(tenere, isNotEmpty);
    expect(tenere.every((m) => m.rotulo.contains('Ténéré')), isTrue);

    expect(BuscaModelo.filtrar(catalogoMotos, 'HONDA'), isNotEmpty);
    expect(BuscaModelo.semAcento('Ténéré'), 'tenere');
  });

  test('cada pedaço digitado conta, em qualquer ordem', () {
    final r = BuscaModelo.filtrar(catalogoMotos, 'hon 160');
    expect(r.any((m) => m.modelo == 'CG 160'), isTrue);
    expect(r.every((m) => m.marca == 'Honda'), isTrue);

    // Invertido dá o mesmo.
    expect(BuscaModelo.filtrar(catalogoMotos, '160 hon').length, r.length);
  });

  test('busca vazia devolve a lista inteira; sem acerto devolve vazia', () {
    expect(BuscaModelo.filtrar(catalogoMotos, '   '), catalogoMotos);
    expect(BuscaModelo.filtrar(catalogoMotos, 'lambreta'), isEmpty);
  });

  testWidgets('folha filtra pelo texto e devolve o modelo escolhido', (
    tester,
  ) async {
    ModeloCatalogo? escolhido;
    await tester.pumpWidget(
      MaterialApp(
        theme: temaOficina(),
        home: Scaffold(
          body: Builder(
            builder: (context) => Center(
              child: FilledButton(
                onPressed: () async {
                  escolhido = await BuscaModelo.abrir(context);
                },
                child: const Text('abrir'),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('abrir'));
    await tester.pumpAndSettle();
    expect(find.text('Busque a marca ou o modelo'), findsOneWidget);
    expect(find.text('Trail'), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'fat boy');
    await tester.pumpAndSettle();
    expect(find.text('Harley-Davidson Fat Boy'), findsOneWidget);
    // A linha mostra o que ajuda a escolher.
    expect(find.textContaining('1868 cc'), findsOneWidget);
    expect(find.textContaining('km com 1 L'), findsOneWidget);

    await tester.tap(find.text('Harley-Davidson Fat Boy'));
    await tester.pumpAndSettle();
    expect(escolhido?.modelo, 'Fat Boy');
  });

  testWidgets('sem acerto, a folha explica o que fazer', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: temaOficina(),
        home: Scaffold(
          body: Builder(
            builder: (context) => Center(
              child: FilledButton(
                onPressed: () => BuscaModelo.abrir(context),
                child: const Text('abrir'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('abrir'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'zzz');
    await tester.pumpAndSettle();
    expect(find.text('Nenhuma moto com esse nome'), findsOneWidget);
    expect(find.textContaining('marca e modelo à mão'), findsOneWidget);
  });

  testWidgets('campo mostra o convite e depois o modelo escolhido', (
    tester,
  ) async {
    Widget montar(ModeloCatalogo? m) => MaterialApp(
      theme: temaOficina(),
      home: Scaffold(
        body: CampoBuscaModelo(escolhido: m, aoTocar: () {}),
      ),
    );

    await tester.pumpWidget(montar(null));
    await tester.pumpAndSettle();
    expect(find.text('Buscar a moto no catálogo'), findsOneWidget);

    final cg = catalogoMotos.firstWhere((m) => m.modelo == 'CG 160');
    await tester.pumpWidget(montar(cg));
    await tester.pumpAndSettle();
    expect(find.text(cg.rotulo), findsOneWidget);
  });
}
