import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:life_and_roads/core/marca/logo_dados.dart';
import 'package:life_and_roads/core/marca/logo_pintor.dart';

void main() {
  test('leitor de caminho entende M, L, C e Z', () {
    final p = lerCaminho(
      'M10.0 10.0 L20.0 10.0 C20.0 20.0 10.0 20.0 10.0 10.0 Z',
    );
    final b = p.getBounds();
    expect(b.left, 10);
    expect(b.top, 10);
    expect(b.right, 20);
    // getBounds inclui os pontos de controle da curva.
    expect(b.bottom, 20);
  });

  test('todos os traços da logo são legíveis e ficam perto da caixa', () {
    // Pontos de controle e contornos passam um pouco da caixa do desenho.
    final grupos = [
      LogoDados.disco,
      LogoDados.borda,
      LogoDados.capaceteEsquerdo,
      LogoDados.capaceteDireito,
      LogoDados.cabelo,
      LogoDados.fitaCima,
      LogoDados.fitaBaixo,
      LogoDados.fitaEsquerda,
      LogoDados.fitaDireita,
      LogoDados.textoCima,
      LogoDados.textoBaixo,
      LogoDados.instagram,
      LogoDados.handle,
      LogoDados.cidade,
    ];
    var total = 0;
    for (final g in grupos) {
      for (final t in g) {
        final b = lerCaminho(t.d).getBounds();
        expect(b.left, greaterThanOrEqualTo(-150));
        expect(b.top, greaterThanOrEqualTo(-150));
        expect(b.right, lessThanOrEqualTo(LogoDados.largura + 150));
        expect(b.bottom, lessThanOrEqualTo(LogoDados.altura + 150));
        total++;
      }
    }
    expect(total, 31);
  });

  testWidgets('a logo pinta em qualquer progresso, nos dois temas', (
    tester,
  ) async {
    for (final escuro in [false, true]) {
      for (final t in [0.0, 0.25, 0.5, 0.75, 1.0]) {
        await tester.pumpWidget(
          MaterialApp(
            theme: ThemeData(
              brightness: escuro ? Brightness.dark : Brightness.light,
            ),
            home: Center(
              child: CustomPaint(
                size: const Size(200, 216),
                painter: LogoPintor(t: t, escuro: escuro),
              ),
            ),
          ),
        );
        await tester.pump();
        expect(tester.takeException(), isNull);
      }
    }
    await tester.pumpWidget(const MaterialApp(home: LogoMarca(tamanho: 36)));
    expect(tester.takeException(), isNull);
  });
}
