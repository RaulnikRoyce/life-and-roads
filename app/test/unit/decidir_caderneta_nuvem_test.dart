import 'package:flutter_test/flutter_test.dart';
import 'package:life_and_roads/features/ficha/domain/resumo_caderneta.dart';
import 'package:life_and_roads/features/ficha/domain/usecases/decidir_caderneta_nuvem.dart';

const _vazia = ResumoCaderneta();
const _cheia = ResumoCaderneta(abastecimentos: 3, pins: 1);

DecisaoNuvem _decidir({
  required ResumoCaderneta aparelho,
  required ResumoCaderneta? nuvem,
  bool mesmoCarimbo = false,
  bool mesmoConteudo = false,
}) {
  return const DecidirCadernetaNuvem().executar(
    aparelho: aparelho,
    nuvem: nuvem,
    mesmoCarimbo: mesmoCarimbo,
    mesmoConteudo: mesmoConteudo,
  );
}

void main() {
  group('a tabela do plano', () {
    test('aparelho com dados e conta sem caderneta: manda', () {
      expect(_decidir(aparelho: _cheia, nuvem: null), DecisaoNuvem.enviar);
    });

    test('aparelho vazio e conta com caderneta: traz sem perguntar', () {
      expect(_decidir(aparelho: _vazia, nuvem: _cheia), DecisaoNuvem.restaurar);
    });

    test('mesmo carimbo: é a mesma, manda só se mudou aqui', () {
      expect(
        _decidir(aparelho: _cheia, nuvem: _cheia, mesmoCarimbo: true),
        DecisaoNuvem.enviar,
      );
    });

    test('carimbo diferente e os dois com histórico: pergunta', () {
      expect(_decidir(aparelho: _cheia, nuvem: _cheia), DecisaoNuvem.perguntar);
    });
  });

  test('nada nos dois lados: nada a fazer', () {
    expect(_decidir(aparelho: _vazia, nuvem: null), DecisaoNuvem.nada);
  });

  test('mesmo conteúdo sem carimbo guardado: só adota, sem perguntar', () {
    expect(
      _decidir(aparelho: _cheia, nuvem: _cheia, mesmoConteudo: true),
      DecisaoNuvem.adotar,
    );
  });

  test('conta com caderneta vazia não vale pergunta: o aparelho manda', () {
    expect(_decidir(aparelho: _cheia, nuvem: _vazia), DecisaoNuvem.enviar);
  });

  test('aparelho vazio com carimbo igual continua mandando, sem restaurar', () {
    // Apagar tudo aqui de propósito é mudança deste aparelho.
    expect(
      _decidir(aparelho: _vazia, nuvem: _cheia, mesmoCarimbo: true),
      DecisaoNuvem.enviar,
    );
  });

  group('resumo', () {
    test('lê o pacote e escreve no singular e no plural', () {
      final r = ResumoCaderneta.de({
        'abastecimentos': [{}, {}, {}],
        'servicos': [{}],
        'pins': <Object>[],
        'extra': null,
      });
      expect(r.texto, '3 abastecimentos, 1 serviço e 0 pinos');
      expect(r.vazia, isFalse);
    });

    test('só preço e PSI contam como vazia; km ou CNH não', () {
      expect(
        ResumoCaderneta.de({
          'precoGasolina': '6,29',
          'psi': {'dianteiro': 25},
        }).vazia,
        isTrue,
      );
      expect(ResumoCaderneta.de({'extra': '{"kmOleo":"1"}'}).vazia, isFalse);
    });
  });
}
