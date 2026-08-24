import 'package:flutter_test/flutter_test.dart';
import 'package:life_and_roads/viagem/calculo.dart';
import 'package:life_and_roads/viagem/historico.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('grava o posto neste aparelho e calcula o R\$/km médio', () async {
    final consumo = consumoDoPainel(kmAnterior: 1000, kmPainel: 1200, litros: 5)!;
    final registro = registroDoPosto(
      consumo: consumo,
      litros: 5,
      precoLitro: 6,
      kmPainel: 1200,
      combustivel: Combustivel.gasolina,
      agora: DateTime(2026, 8, 24),
    )!;
    final lista = await HistoricoAbastecimento.acrescentar(registro);
    expect(lista, hasLength(1));
    expect(lista.first.reaisPorKm, 0.15);
    expect(custoMedioPorKm(await HistoricoAbastecimento.carregar()), 0.15);
  });
}
