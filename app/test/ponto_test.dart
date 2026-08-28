import 'package:flutter_test/flutter_test.dart';
import 'package:life_and_roads/mapa/ponto.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'helpers/banco_teste.dart';

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await abrirBancoTeste();
  });

  tearDown(() async {
    await fecharBancoTeste();
  });

  test('JSON inválido não vira ponto', () {
    expect(pontoDeJson(null), isNull);
    expect(pontoDeJson('{'), isNull);
    expect(pontoDeJson('{"latitude": 91, "longitude": 0}'), isNull);
  });

  test('salva e lê o último ponto', () async {
    await salvarUltimoPonto(brasilCentro);
    final lido = await carregarUltimoPonto();
    expect(lido, isNotNull);
    expect(lido!.latitude, closeTo(brasilCentro.latitude, 0.0001));
    expect(lido.longitude, closeTo(brasilCentro.longitude, 0.0001));
  });
}
