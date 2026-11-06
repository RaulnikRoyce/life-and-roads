import 'package:flutter_test/flutter_test.dart';
import 'package:life_and_roads/features/ficha/domain/ficha_moto.dart';
import 'package:life_and_roads/features/viagem/domain/usecases/excluir_abastecimento.dart';
import 'package:life_and_roads/features/viagem/domain/usecases/montar_abastecimento.dart';
import 'package:life_and_roads/viagem/calculo.dart';

void main() {
  late FichaMoto ficha;
  late List<RegistroAbastecimento> registros;
  void adicionar(
    double km,
    double litros,
    bool cheio, [
    Combustivel combustivel = Combustivel.gasolina,
  ]) {
    final r = const MontarAbastecimento().executar(
      ficha: ficha,
      historico: registros,
      kmPainel: km,
      litros: litros,
      preco: 6,
      combustivel: combustivel,
      tanqueCheio: cheio,
      em: '2026-11-04T10:00:00.${registros.length}',
      referenciaMarcador: 'referencia-da-moto',
    );
    ficha = r.ficha!;
    registros.insert(0, r.registro!);
  }

  setUp(() {
    ficha = const FichaMoto(
      marca: 'Honda',
      modelo: 'Bros',
      kmLitro: 35,
      kmAtual: 1000,
    );
    registros = [];
    adicionar(1000, 8, true);
    adicionar(1100, 2, false);
    adicionar(1200, 3, true);
  });
  test('excluir parcial recalcula litros, custo e média do período', () {
    final r = const ExcluirAbastecimento().executar(
      ficha: ficha,
      historico: registros,
      indice: 1,
    );
    expect(r.erro, isNull);
    expect(r.historico, hasLength(2));
    expect(r.historico!.first.kmMedidos, 200);
    expect(r.historico!.first.litrosMedidos, 3);
    expect(r.historico!.first.reaisMedidos, 18);
    expect(r.ficha!.kmLitro, closeTo(200 / 3, .000001));
    expect(r.ficha!.kmAtual, 1200);
    expect(r.historico!.last, same(registros.last));
    expect(r.historico!.first.em, registros.first.em);
    expect(r.historico!.first.referenciaMarcador, 'referencia-da-moto');
    expect(registros, hasLength(3));
  });
  test('dois tanques cheios sem parcial preservam a referência ao excluir', () {
    registros = [];
    ficha = ficha.copiarCom(kmAtual: 1000, kmLitro: 35);
    adicionar(1000, 8, true);
    adicionar(1200, 5, true);
    expect(ficha.kmLitro, 40);
    // Simula a ida e volta pelo arquivo de backup ou armazenamento local.
    registros = registros
        .map((r) => RegistroAbastecimento.deJson(r.paraJson())!)
        .toList();
    final r = const ExcluirAbastecimento().executar(
      ficha: ficha,
      historico: registros,
      indice: 0,
    );
    expect(r.ficha!.kmLitro, 35);
    expect(r.ficha!.kmAtual, 1000);
    expect(r.historico!.where((r) => r.medido), isEmpty);
  });
  test('excluir primeira referência invalida medição que dependia dela', () {
    final r = const ExcluirAbastecimento().executar(
      ficha: ficha,
      historico: registros,
      indice: 2,
    );
    expect(r.historico!.last.tipoConsumo, 'referencia');
    expect(r.historico!.last.kmRodados, 0);
    expect(r.historico!.where((r) => r.medido), isEmpty);
    expect(r.ficha!.kmLitro, 35);
    expect(r.ficha!.kmAtual, 1200);
  });
  test('excluir último abastecimento restaura km e referência de consumo', () {
    final r = const ExcluirAbastecimento().executar(
      ficha: ficha,
      historico: registros,
      indice: 0,
    );
    expect(r.ficha!.kmAtual, 1100);
    expect(r.ficha!.kmLitro, 35);
    expect(r.historico!.first, same(registros[1]));
  });
  test('km posterior da ficha é preservado', () {
    final r = const ExcluirAbastecimento().executar(
      ficha: ficha.copiarCom(kmAtual: 1250),
      historico: registros,
      indice: 0,
    );
    expect(r.ficha!.kmAtual, 1250);
  });
  test('excluir único registro mantém km sem inventar referência anterior', () {
    final r = const ExcluirAbastecimento().executar(
      ficha: ficha,
      historico: [registros.first],
      indice: 0,
    );
    expect(r.erro, isNull);
    expect(r.historico, isEmpty);
    expect(r.ficha!.kmAtual, ficha.kmAtual);
  });
  test('índice inválido não muda dados', () {
    for (final i in [-1, 3]) {
      expect(
        const ExcluirAbastecimento()
            .executar(ficha: ficha, historico: registros, indice: i)
            .erro,
        isNotNull,
      );
    }
    expect(registros, hasLength(3));
    expect(
      const ExcluirAbastecimento()
          .executar(ficha: ficha, historico: [], indice: 0)
          .erro,
      isNotNull,
    );
  });
  test('excluir troca de combustível refaz classificação da mistura', () {
    registros = [];
    ficha = ficha.copiarCom(kmAtual: 1000, kmLitro: 35, kmLitroAlcool: 25);
    adicionar(1000, 8, true);
    adicionar(1100, 2, false, Combustivel.alcool);
    adicionar(1200, 3, true);
    expect(registros.first.tipoConsumo, 'medidoMisto');
    final r = const ExcluirAbastecimento().executar(
      ficha: ficha,
      historico: registros,
      indice: 1,
    );
    expect(r.historico!.first.tipoConsumo, 'medido');
    expect(r.historico!.first.misturaNoTanque, isFalse);
  });
  test('remover fechamento recalcula média com os ciclos restantes', () {
    adicionar(1500, 10, true);
    final r = const ExcluirAbastecimento().executar(
      ficha: ficha,
      historico: registros,
      indice: 0,
    );
    expect(r.ficha!.kmLitro, 40);
    expect(r.ficha!.kmAtual, 1200);
  });
  test('remover tanque cheio intermediário refaz ciclo mais longo', () {
    adicionar(1500, 10, true);
    final r = const ExcluirAbastecimento().executar(
      ficha: ficha,
      historico: registros,
      indice: 1,
    );
    expect(r.historico!.first.kmMedidos, 500);
    expect(r.historico!.first.litrosMedidos, 12);
    expect(r.historico!.first.reaisMedidos, 72);
    expect(r.ficha!.kmLitro, closeTo(500 / 12, .000001));
  });
}
