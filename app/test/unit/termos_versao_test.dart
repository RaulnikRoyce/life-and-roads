import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:life_and_roads/core/legal/textos.dart';

/// O aceite registra `versaoTermos` (ADR 0038). Se o texto dos Termos mudar
/// e a data não subir junto, a pessoa aceita uma versão que não leu.
void main() {
  String ler(String nome) {
    final candidatos = [File('../docs/$nome'), File('docs/$nome')];
    return candidatos.firstWhere((f) => f.existsSync()).readAsStringSync();
  }

  String? dataDe(String texto) =>
      RegExp(r'Última atualização, (\d{4}-\d{2}-\d{2})').firstMatch(texto)?.group(1);

  test('a versão aceita no app é a data dos Termos de uso', () {
    expect(dataDe(ler('termos.md')), versaoTermos);
  });

  test('a Privacidade tem a mesma data, porque o aceite vale para as duas', () {
    expect(dataDe(ler('privacidade.md')), versaoTermos);
  });
}
