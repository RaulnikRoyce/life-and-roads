import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:life_and_roads/features/manutencao/domain/usecases/montar_linha_do_tempo.dart';
import 'package:life_and_roads/features/manutencao/presentation/widgets/linha_do_tempo.dart';
import 'package:life_and_roads/features/manutencao/presentation/widgets/painel_saude.dart';
import 'package:life_and_roads/tema.dart';

Widget _app(Widget filho) => MaterialApp(
  theme: temaOficina(),
  home: Scaffold(
    body: Padding(padding: const EdgeInsets.all(20), child: filho),
  ),
);

const _atrasado = ItemLinhaDoTempo(
  id: 'ipva',
  titulo: 'IPVA',
  detalhe: '15/09/2026, atrasado há 3 dias',
  fracao: 1,
  estado: EstadoItem.atrasado,
  ordem: -3,
);

const _oleoKm = ItemLinhaDoTempo(
  id: 'oleo-km',
  titulo: 'Óleo por km',
  detalhe: 'troca aos 34.000 km, em 350 km',
  fracao: 0.9,
  estado: EstadoItem.emDia,
  ordem: 7,
  porKm: true,
);

const _atencao = ItemLinhaDoTempo(
  id: 'pneus',
  titulo: 'Pneus',
  detalhe: '30/09/2026, em 9 dias',
  fracao: 0.6,
  estado: EstadoItem.atencao,
  ordem: 9,
);

/// Razão de contraste WCAG entre duas cores opacas.
double _contraste(Color a, Color b) {
  final la = a.computeLuminance();
  final lb = b.computeLuminance();
  final claro = la > lb ? la : lb;
  final escuro = la > lb ? lb : la;
  return (claro + 0.05) / (escuro + 0.05);
}

/// [cor] com [alpha] por cima de [fundo], já achatada.
Color _sobre(Color cor, double alpha, Color fundo) =>
    Color.lerp(fundo, cor, alpha)!;

void main() {
  GoogleFonts.config.allowRuntimeFetching = false;

  test('falta desfaz a régua de km e mantém os dias', () {
    expect(PainelSaude.falta(_oleoKm), 350);
    expect(PainelSaude.falta(_atrasado), -3);
    expect(PainelSaude.unidade(_oleoKm), 'km');
    expect(PainelSaude.unidade(_atrasado), 'dias atrás');
  });

  testWidgets('sem itens mostra Sem vencimentos', (tester) async {
    await tester.pumpWidget(_app(const PainelSaude(itens: [])));
    await tester.pumpAndSettle();

    expect(find.text('Sem vencimentos'), findsOneWidget);
    expect(find.text('Toque num grupo abaixo para começar.'), findsOneWidget);
    expect(find.byIcon(Icons.build_outlined), findsOneWidget);
    expect(
      find.text('Informe o km na Ficha para o aviso por km.'),
      findsOneWidget,
    );
    expect(find.text('PRÓXIMO'), findsNothing);
  });

  testWidgets('item atrasado mostra dias atrás, o estado e a ficha', (
    tester,
  ) async {
    await tester.pumpWidget(_app(const PainelSaude(itens: [_atrasado])));
    await tester.pumpAndSettle();

    expect(find.text('PRÓXIMO'), findsOneWidget);
    expect(find.text('IPVA'), findsOneWidget);
    expect(find.text('3'), findsOneWidget);
    expect(find.text('dias atrás'), findsOneWidget);
    expect(find.text('atrasado'), findsOneWidget);
    expect(find.text('1 atrasado'), findsOneWidget);
    expect(find.text('1 em dia'), findsNothing);
  });

  testWidgets('item por km em dia mostra o km que falta', (tester) async {
    await tester.pumpWidget(_app(const PainelSaude(itens: [_oleoKm])));
    await tester.pumpAndSettle();

    expect(find.text('350'), findsOneWidget);
    expect(find.text('km'), findsOneWidget);
    expect(find.text('em dia'), findsOneWidget);
    expect(find.text('1 em dia'), findsOneWidget);
  });

  testWidgets('com kmAtual mostra o painel', (tester) async {
    await tester.pumpWidget(
      _app(const PainelSaude(itens: [_oleoKm, _atrasado], kmAtual: 12500)),
    );
    await tester.pumpAndSettle();

    expect(find.text('Painel 12.500 km'), findsOneWidget);
    expect(find.text('1 atrasado'), findsOneWidget);
    expect(find.text('1 em dia'), findsOneWidget);
  });

  test('corTexto escurece só no tema claro', () {
    final escuro = temaOficina();
    final claro = temaOficinaClaro();
    for (final estado in EstadoItem.values) {
      final cor = LinhaDoTempo.corDe(estado);
      expect(PainelSaude.corTexto(escuro, cor), cor);
      expect(PainelSaude.corTexto(claro, cor), isNot(cor));
    }
  });

  testWidgets('texto de estado e ficha legíveis no tema claro', (tester) async {
    final tema = temaOficinaClaro();
    await tester.pumpWidget(
      MaterialApp(
        theme: tema,
        home: const Scaffold(
          body: PainelSaude(itens: [_atencao, _oleoKm, _atrasado]),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final fundo = tema.scaffoldBackgroundColor;
    Color corDoTexto(String texto) =>
        tester.widget<Text>(find.text(texto)).style!.color!;

    // Linha de estado, sobre o fundo da tela.
    expect(_contraste(corDoTexto('atenção'), fundo), greaterThanOrEqualTo(4.5));

    // Fichas, sobre o fundo da ficha (cor do estado a 14 % sobre a tela).
    final fichas = {
      '1 atenção': EstadoItem.atencao,
      '1 em dia': EstadoItem.emDia,
      '1 atrasado': EstadoItem.atrasado,
    };
    for (final MapEntry(key: texto, value: estado) in fichas.entries) {
      final fundoFicha = _sobre(LinhaDoTempo.corDe(estado), 0.14, fundo);
      expect(
        _contraste(corDoTexto(texto), fundoFicha),
        greaterThanOrEqualTo(4.5),
        reason: texto,
      );
    }
  });
}
