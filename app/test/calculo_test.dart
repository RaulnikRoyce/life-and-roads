import 'package:flutter_test/flutter_test.dart';
import 'package:life_and_roads/viagem/calculo.dart';

void main() {
  test('100 km a 25 km/l a R\$ 6 = 4 litros e R\$ 24', () {
    final r = calcularViagem(km: 100, kmPorLitro: 25, precoLitro: 6);
    expect(r, isNotNull);
    expect(r!.litros, 4);
    expect(r.reais, 24);
  });

  test('abastecimento: 200 km com 5 L = 40 km/l', () {
    final r = consumoDoPainel(kmAnterior: 1000, kmPainel: 1200, litros: 5);
    expect(r, isNotNull);
    expect(r!.kmRodados, 200);
    expect(r.kmPorLitro, 40);
  });

  test('painel menor que o km anterior não conta', () {
    expect(
      consumoDoPainel(kmAnterior: 1000, kmPainel: 900, litros: 5),
      isNull,
    );
  });

  test('tanque 16 L a 42 km/l = 672 km de autonomia', () {
    expect(autonomiaKm(tanqueLitros: 16, kmPorLitro: 42), 672);
  });

  test('200 km com 5 L a R\$ 6 = R\$ 30 e R\$ 0,15/km', () {
    final consumo = consumoDoPainel(kmAnterior: 1000, kmPainel: 1200, litros: 5);
    final r = registroDoPosto(
      consumo: consumo!,
      litros: 5,
      precoLitro: 6,
      kmPainel: 1200,
      combustivel: Combustivel.gasolina,
      agora: DateTime(2026, 8, 24),
    );
    expect(r, isNotNull);
    expect(r!.reais, 30);
    expect(r.reaisPorKm, 0.15);
  });

  test('preço fora da faixa não vira registro', () {
    final consumo = consumoDoPainel(kmAnterior: 1000, kmPainel: 1200, litros: 5);
    expect(
      registroDoPosto(
        consumo: consumo!,
        litros: 5,
        precoLitro: 1,
        kmPainel: 1200,
        combustivel: Combustivel.gasolina,
      ),
      isNull,
    );
  });

  test('dois postos: R\$ 50 em 300 km = R\$ 0,166.../km', () {
    final a = registroDoPosto(
      consumo: consumoDoPainel(kmAnterior: 1000, kmPainel: 1200, litros: 5)!,
      litros: 5,
      precoLitro: 6,
      kmPainel: 1200,
      combustivel: Combustivel.gasolina,
    )!;
    final b = registroDoPosto(
      consumo: consumoDoPainel(kmAnterior: 1200, kmPainel: 1300, litros: 4)!,
      litros: 4,
      precoLitro: 5,
      kmPainel: 1300,
      combustivel: Combustivel.alcool,
    )!;
    expect(custoMedioPorKm([a, b]), closeTo(50 / 300, 0.0001));
  });

  test('álcool mais barato no litro ainda perde se o km/l cair demais', () {
    expect(
      combustivelMaisBarato(
        precoGasolina: 6,
        precoAlcool: 4.2,
        kmLitroGasolina: 40,
        kmLitroAlcool: 25,
      ),
      Combustivel.gasolina,
    );
    expect(
      combustivelMaisBarato(
        precoGasolina: 6,
        precoAlcool: 3.5,
        kmLitroGasolina: 40,
        kmLitroAlcool: 32,
      ),
      Combustivel.alcool,
    );
  });

  test('óleo aos 10.000 a cada 4.000 = próxima aos 14.000; atrasado se o painel passou', () {
    expect(kmDaProximaTroca(kmUltima: 10000, intervaloKm: 4000), 14000);
    expect(kmAteATroca(kmAtual: 14200, kmProxima: 14000), -200);
    expect(kmAteATroca(kmAtual: 13800, kmProxima: 14000), 200);
  });

  test('dica flex fala o R\$/km de cada bomba', () {
    expect(
      textoDicaFlex(
        precoGasolina: 6,
        precoAlcool: 3.5,
        kmLitroGasolina: 40,
        kmLitroAlcool: 32,
      ),
      contains('custa menos'),
    );
  });

  test('1° no equador ≈ 111 km em linha reta', () {
    final km = kmLinhaReta(latA: 0, lngA: 0, latB: 0, lngB: 1);
    expect(km, closeTo(111.2, 0.3));
  });

  test('mesmo ponto ou coordenadas inválidas não viram km', () {
    expect(kmLinhaReta(latA: -23.55, lngA: -46.63, latB: -23.55, lngB: -46.63), isNull);
    expect(kmLinhaReta(latA: 91, lngA: 0, latB: 0, lngB: 0), isNull);
  });

  test('100 km a 25 km/l cabe em 16 L; 500 km não', () {
    final r = calcularViagem(km: 100, kmPorLitro: 25, precoLitro: 6);
    expect(cabeNoTanque(litrosViagem: r!.litros, tanqueLitros: 16), isTrue);
    final longa = calcularViagem(km: 500, kmPorLitro: 25, precoLitro: 6);
    expect(cabeNoTanque(litrosViagem: longa!.litros, tanqueLitros: 16), isFalse);
  });
}
