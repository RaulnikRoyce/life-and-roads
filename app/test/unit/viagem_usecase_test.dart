import 'package:flutter_test/flutter_test.dart';
import 'package:life_and_roads/features/ficha/domain/ficha_moto.dart';
import 'package:life_and_roads/features/viagem/domain/usecases/calcular_custo_viagem.dart';
import 'package:life_and_roads/features/viagem/domain/usecases/montar_abastecimento.dart';
import 'package:life_and_roads/viagem/calculo.dart';

void main() {
  const calcular = CalcularCustoViagem();
  const montar = MontarAbastecimento();

  test('calcular recusa sem km ou preço', () {
    final r = calcular.executar(
      km: null,
      kmPorLitro: 25,
      preco: 6,
      combustivel: Combustivel.gasolina,
    );
    expect(r.resultado, isNull);
    expect(r.erro, contains('preço da gasolina'));
  });

  test('calcular 100 km a 25 km/l a R\$ 6', () {
    final r = calcular.executar(
      km: 100,
      kmPorLitro: 25,
      preco: 6,
      combustivel: Combustivel.gasolina,
    );
    expect(r.erro, isNull);
    expect(r.resultado!.litros, 4);
    expect(r.resultado!.reais, 24);
  });

  test('montar recusa sem ficha', () {
    final r = montar.executar(
      ficha: null,
      historico: const [],
      kmPainel: 1100,
      litros: 5,
      preco: 6,
      combustivel: Combustivel.gasolina,
    );
    expect(r.registro, isNull);
    expect(r.erro, contains('Ficha'));
  });

  const ficha = FichaMoto(
    marca: 'Honda',
    modelo: 'Bros',
    kmLitro: 30,
    kmAtual: 1000,
  );

  test('primeiro abastecimento guarda km e litros, sem consumo', () {
    final r = montar.executar(
      ficha: ficha,
      historico: const [],
      kmPainel: 1200,
      litros: 5,
      preco: 6,
      combustivel: Combustivel.gasolina,
    );
    expect(r.erro, isNull);
    expect(r.registro!.temConsumo, isFalse);
    expect(r.registro!.kmPainel, 1200);
    expect(r.registro!.litros, 5);
    expect(r.registro!.reais, 30);
    // A ficha só recebe o km do painel; o consumo dela fica como estava.
    expect(r.ficha!.kmAtual, 1200);
    expect(r.ficha!.kmLitro, 30);
    expect(r.aviso, contains('Primeiro abastecimento'));
    expect(r.aviso, contains('A partir do próximo'));
  });

  test('primeiro abastecimento recusa km menor que o da ficha', () {
    final r = montar.executar(
      ficha: ficha,
      historico: const [],
      kmPainel: 900,
      litros: 5,
      preco: 6,
      combustivel: Combustivel.gasolina,
    );
    expect(r.registro, isNull);
    expect(r.erro, contains('menor que o da Ficha'));
  });

  test('segundo abastecimento calcula pelo intervalo desde o anterior', () {
    final primeiro = primeiroRegistroDoPosto(
      litros: 5,
      precoLitro: 6,
      kmPainel: 1200,
      combustivel: Combustivel.gasolina,
    )!;
    final r = montar.executar(
      ficha: ficha.copiarCom(kmAtual: 1200),
      historico: [primeiro],
      kmPainel: 1400,
      litros: 5,
      preco: 6,
      combustivel: Combustivel.gasolina,
    );
    expect(r.erro, isNull);
    expect(r.registro!.temConsumo, isTrue);
    expect(r.registro!.kmRodados, 200);
    expect(r.registro!.kmPorLitro, 40);
    expect(r.ficha!.kmAtual, 1400);
    expect(r.ficha!.kmLitro, 40);
    expect(r.aviso, contains('200 km desde o último'));
    expect(r.aviso, contains('40 km com 1 L'));
    expect(r.aviso, isNot(contains('km/l')));
  });

  test('a média se refina a cada abastecimento (ponderada por litros)', () {
    final primeiro = primeiroRegistroDoPosto(
      litros: 5,
      precoLitro: 6,
      kmPainel: 1000,
      combustivel: Combustivel.gasolina,
    )!;
    // 200 km com 5 L = 40; depois 300 km com 10 L = 30. Média: 500/15.
    final segundo = registroDoPosto(
      consumo: consumoDoPainel(kmAnterior: 1000, kmPainel: 1200, litros: 5)!,
      litros: 5,
      precoLitro: 6,
      kmPainel: 1200,
      combustivel: Combustivel.gasolina,
    )!;
    final r = montar.executar(
      ficha: ficha.copiarCom(kmAtual: 1200, kmLitro: 40),
      historico: [segundo, primeiro],
      kmPainel: 1500,
      litros: 10,
      preco: 6,
      combustivel: Combustivel.gasolina,
    );
    expect(r.erro, isNull);
    expect(r.registro!.kmPorLitro, 30);
    expect(r.ficha!.kmLitro, closeTo(500 / 15, 0.001));
  });

  test('montar recusa painel menor ou igual ao do último abastecimento', () {
    final anterior = primeiroRegistroDoPosto(
      litros: 5,
      precoLitro: 6,
      kmPainel: 32000,
      combustivel: Combustivel.gasolina,
    )!;
    final r = montar.executar(
      ficha: ficha.copiarCom(kmAtual: 32000),
      historico: [anterior],
      kmPainel: 32000,
      litros: 12,
      preco: 6,
      combustivel: Combustivel.gasolina,
    );
    expect(r.registro, isNull);
    expect(r.erro, contains('maior que o do último abastecimento'));
    expect(r.erro, isNot(contains('km/l')));
  });

  test('montar recusa painel que quase não andou para tanto combustível', () {
    final anterior = primeiroRegistroDoPosto(
      litros: 5,
      precoLitro: 6,
      kmPainel: 32000,
      combustivel: Combustivel.gasolina,
    )!;
    final r = montar.executar(
      ficha: ficha.copiarCom(kmAtual: 32000),
      historico: [anterior],
      kmPainel: 32020,
      litros: 12,
      preco: 6,
      combustivel: Combustivel.gasolina,
    );
    expect(r.registro, isNull);
    expect(r.erro, contains('muito baixo'));
  });

  test('flex: o intervalo conta para o combustível que estava no tanque', () {
    const flex = FichaMoto(
      marca: 'Honda',
      modelo: 'CG 160',
      kmLitro: 35,
      kmLitroAlcool: 28,
      kmAtual: 1000,
    );
    // Anterior foi álcool; agora entra gasolina. Os 100 km foram com álcool.
    final anterior = primeiroRegistroDoPosto(
      litros: 4,
      precoLitro: 4,
      kmPainel: 1000,
      combustivel: Combustivel.alcool,
    )!;
    final r = montar.executar(
      ficha: flex,
      historico: [anterior],
      kmPainel: 1100,
      litros: 4,
      preco: 6,
      combustivel: Combustivel.gasolina,
    );
    expect(r.erro, isNull);
    expect(r.ficha!.kmLitroAlcool, 25);
    expect(r.ficha!.kmLitro, 35);
    expect(r.ficha!.combustivel, Combustivel.gasolina);
    expect(r.aviso, contains('Rodados com álcool'));
  });
}
