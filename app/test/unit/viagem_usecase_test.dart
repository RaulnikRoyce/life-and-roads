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
      kmPainel: 1100,
      litros: 5,
      preco: 6,
      combustivel: Combustivel.gasolina,
    );
    expect(r.registro, isNull);
    expect(r.erro, contains('Ficha'));
  });

  test('montar atualiza km e km/l da ficha e não leva placa', () {
    const ficha = FichaMoto(
      marca: 'Honda',
      modelo: 'Bros',
      kmLitro: 30,
      kmAtual: 1000,
    );
    final r = montar.executar(
      ficha: ficha,
      kmPainel: 1200,
      litros: 5,
      preco: 6,
      combustivel: Combustivel.gasolina,
    );
    expect(r.erro, isNull);
    expect(r.ficha!.kmAtual, 1200);
    expect(r.ficha!.kmLitro, 40);
    expect(r.ficha!.combustivel, Combustivel.gasolina);
    expect(r.registro!.kmPorLitro, 40);
    expect(r.aviso, contains('Abastecimento registrado'));
    expect(r.aviso, isNot(contains('km/l')));
  });

  test('montar recusa painel menor ou igual ao da ficha', () {
    const ficha = FichaMoto(
      marca: 'Honda',
      modelo: 'Bros',
      kmLitro: 30,
      kmAtual: 32000,
    );
    final r = montar.executar(
      ficha: ficha,
      kmPainel: 32000,
      litros: 12,
      preco: 6,
      combustivel: Combustivel.gasolina,
    );
    expect(r.registro, isNull);
    expect(r.erro, contains('maior que o da Ficha'));
    expect(r.erro, isNot(contains('km/l')));
  });

  test('montar recusa painel que quase não andou para tanto combustível', () {
    const ficha = FichaMoto(
      marca: 'Honda',
      modelo: 'Bros',
      kmLitro: 30,
      kmAtual: 32000,
    );
    final r = montar.executar(
      ficha: ficha,
      kmPainel: 32020,
      litros: 12,
      preco: 6,
      combustivel: Combustivel.gasolina,
    );
    expect(r.registro, isNull);
    expect(r.erro, contains('muito baixo'));
    expect(r.erro, isNot(contains('km/l')));
  });

  test('montar com álcool grava kmLitroAlcool e deixa a gasolina', () {
    const ficha = FichaMoto(
      marca: 'Honda',
      modelo: 'Bros',
      kmLitro: 35,
      kmLitroAlcool: 28,
      kmAtual: 1000,
    );
    final r = montar.executar(
      ficha: ficha,
      kmPainel: 1100,
      litros: 4,
      preco: 4,
      combustivel: Combustivel.alcool,
    );
    expect(r.ficha!.kmLitro, 35);
    expect(r.ficha!.kmLitroAlcool, 25);
    expect(r.ficha!.combustivel, Combustivel.alcool);
  });
}
