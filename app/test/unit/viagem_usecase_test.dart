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

  const ficha = FichaMoto(
    marca: 'Honda',
    modelo: 'Bros',
    kmLitro: 35,
    kmLitroAlcool: 28,
    kmAtual: 1000,
  );
  RegistroAbastecimento posto(
    double km,
    double litros, {
    bool cheio = false,
    List<RegistroAbastecimento> anteriores = const [],
    Combustivel combustivel = Combustivel.gasolina,
  }) {
    final r = montar.executar(
      ficha: ficha,
      kmPainel: km,
      litros: litros,
      preco: 6,
      combustivel: combustivel,
      tanqueCheio: cheio,
      historico: anteriores,
    );
    expect(r.erro, isNull);
    return r.registro!;
  }

  test('primeiro estabelece referencia e parcial nao inventa consumo', () {
    final a = posto(1000, 12);
    expect(a.tipoConsumo, 'referencia');
    expect(a.kmPorLitro, 0);
    final b = posto(1350, 3, anteriores: [a]);
    expect(b.tipoConsumo, 'estimado');
    expect(b.kmPorLitro, 35);
  });
  test('dois cheios incluem parciais, excluem a compra inicial e usam todo o periodo', () {
    final a = posto(1000, 12, cheio: true);
    final b = posto(1100, 2, anteriores: [a]);
    final c = posto(1350, 8, cheio: true, anteriores: [b, a]);
    expect(c.tipoConsumo, 'medido');
    expect(c.kmPorLitro, 35);
    expect(c.kmMedidos, 350);
    expect(c.litrosMedidos, 10);
    expect(c.reaisMedidos, 60);
    expect(custoMedioPorKm([c, b, a]), closeTo(60 / 350, 1e-9));
  });
  test('media dos ciclos e ponderada sem contar parciais duas vezes', () {
    final a = posto(1000, 12, cheio: true);
    final b = posto(1200, 5, cheio: true, anteriores: [a]);
    final c = posto(1500, 10, cheio: true, anteriores: [b, a]);
    expect(
      mediaKmPorLitro([c, b, a], Combustivel.gasolina),
      closeTo(500 / 15, 1e-9),
    );
  });
  test('aceita resultados medidos acima e abaixo de limites antigos', () {
    for (final comb in Combustivel.values) {
      for (final distancia in [10.0, 500.0, 3000.0]) {
        final a = posto(1000, 12, cheio: true, combustivel: comb);
        final b = posto(
          1000 + distancia,
          5,
          cheio: true,
          anteriores: [a],
          combustivel: comb,
        );
        expect(b.kmPorLitro, distancia / 5);
        expect(b.medido, isTrue);
      }
    }
  });
  test(
    'combustivel da compra de fechamento nao muda o que rodou o periodo',
    () {
      final a = posto(1000, 12, cheio: true, combustivel: Combustivel.alcool);
      final r = montar.executar(
        ficha: ficha,
        historico: [a],
        kmPainel: 1100,
        litros: 4,
        preco: 6,
        combustivel: Combustivel.gasolina,
        tanqueCheio: true,
      );
      expect(r.ficha!.kmLitroAlcool, 25);
      expect(r.ficha!.kmLitro, 35);
      expect(r.registro!.combustivelMedido, Combustivel.alcool);
    },
  );
  test('mistura em parcial nao substitui a media de um combustivel', () {
    final a = posto(1000, 12, cheio: true);
    final b = posto(1100, 2, anteriores: [a], combustivel: Combustivel.alcool);
    final r = montar.executar(
      ficha: ficha,
      historico: [b, a],
      kmPainel: 1350,
      litros: 8,
      preco: 6,
      combustivel: Combustivel.gasolina,
      tanqueCheio: true,
    );
    expect(r.registro!.tipoConsumo, 'medidoMisto');
    expect(r.ficha!.kmLitro, 35);
  });
  test('legado nao e tratado como tanque cheio confirmado', () {
    final antigo = primeiroRegistroDoPosto(
      kmPainel: 1000,
      litros: 12,
      precoLitro: 6,
      combustivel: Combustivel.gasolina,
    )!;
    expect(posto(1350, 10, cheio: true, anteriores: [antigo]).medido, isFalse);
  });
  test('valor pago determina preco real da compra', () {
    final r = montar.executar(
      ficha: ficha,
      historico: [],
      kmPainel: 1000,
      litros: 3,
      preco: null,
      valorPago: 19.5,
      combustivel: Combustivel.gasolina,
    );
    expect(r.erro, isNull);
    expect(r.registro!.reais, 19.5);
    expect(r.registro!.precoLitro, 6.5);
  });
  test('barras opcionais sao preservadas no JSON', () {
    final r = montar.executar(
      ficha: ficha,
      historico: [],
      kmPainel: 1000,
      litros: 3,
      preco: 6,
      combustivel: Combustivel.gasolina,
      totalBarras: 6,
      barrasAntes: 1,
      barrasDepois: 3,
    );
    final copia = RegistroAbastecimento.deJson(r.registro!.paraJson())!;
    expect(copia.totalBarras, 6);
    expect(copia.barrasAntes, 1);
    expect(copia.barrasDepois, 3);
  });
  test('rejeita numeros invalidos, duplicado e barras incoerentes', () {
    final a = posto(1000, 3);
    for (final km in [double.nan, double.infinity, 999.0, 1000.0]) {
      expect(
        montar
            .executar(
              ficha: ficha,
              historico: [a],
              kmPainel: km,
              litros: 3,
              preco: 6,
              combustivel: Combustivel.gasolina,
            )
            .erro,
        isNotNull,
      );
    }
    expect(
      montar
          .executar(
            ficha: ficha,
            historico: [],
            kmPainel: 1000,
            litros: 3,
            preco: 6,
            combustivel: Combustivel.gasolina,
            totalBarras: 6,
            barrasAntes: 5,
            barrasDepois: 2,
          )
          .erro,
      isNotNull,
    );
  });
}
