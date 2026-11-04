import 'package:flutter_test/flutter_test.dart';
import 'package:life_and_roads/features/ficha/domain/ficha_moto.dart';
import 'package:life_and_roads/features/viagem/domain/usecases/editar_abastecimento.dart';
import 'package:life_and_roads/features/viagem/domain/usecases/montar_abastecimento.dart';
import 'package:life_and_roads/viagem/calculo.dart';

void main() {
  late FichaMoto ficha;
  late List<RegistroAbastecimento> registros;
  setUp(() {
    ficha = const FichaMoto(
      marca: 'Honda',
      modelo: 'Bros',
      kmLitro: 35,
      kmAtual: 1000,
    );
    registros = [];
    for (final (km, litros, cheio) in [
      (1000.0, 8.0, true),
      (1100.0, 2.0, false),
      (1200.0, 3.0, true),
    ]) {
      final r = const MontarAbastecimento().executar(
        ficha: ficha,
        historico: registros,
        kmPainel: km,
        litros: litros,
        preco: 6,
        combustivel: Combustivel.gasolina,
        tanqueCheio: cheio,
        em: '2026-10-${registros.length + 10}T12:00:00',
      );
      ficha = r.ficha!;
      registros.insert(0, r.registro!);
    }
  });
  ({FichaMoto? ficha, List<RegistroAbastecimento>? historico, String? erro})
  editar({
    int indice = 1,
    double? km = 1100,
    double? litros = 4,
    double? pago = 24,
    bool cheio = false,
    Combustivel combustivel = Combustivel.gasolina,
  }) => const EditarAbastecimento().executar(
    ficha: ficha,
    historico: registros,
    indice: indice,
    kmPainel: km,
    litros: litros,
    valorPago: pago,
    combustivel: combustivel,
    tanqueCheio: cheio,
  );

  test(
    'corrige parcial e recalcula ciclo, custo e média preservando datas',
    () {
      final r = editar();
      expect(r.erro, isNull);
      expect(r.historico!.first.litrosMedidos, 7);
      expect(r.historico!.first.kmPorLitro, closeTo(200 / 7, .000001));
      expect(r.historico!.first.reaisMedidos, 42);
      expect(r.ficha!.kmLitro, closeTo(200 / 7, .000001));
      expect(r.historico!.map((r) => r.em), registros.map((r) => r.em));
      expect(r.historico!.last, same(registros.last));
    },
  );
  test('impede ultrapassar ou igualar vizinhos sem alterar histórico', () {
    for (final km in [999.0, 1000.0, 1200.0, 1300.0, double.nan]) {
      expect(editar(km: km).erro, isNotNull);
    }
    expect(registros.first.kmPorLitro, 40);
  });
  test('corrigir último km pode reduzir a ficha e refazer distância', () {
    final r = editar(indice: 0, km: 1190, litros: 3, pago: 18, cheio: true);
    expect(r.ficha!.kmAtual, 1190);
    expect(r.historico!.first.kmMedidos, 190);
  });
  test('corrigir primeiro km refaz medição sem contar litros iniciais', () {
    final r = editar(indice: 2, km: 990, litros: 10, pago: 60, cheio: true);
    expect(r.historico!.first.kmMedidos, 210);
    expect(r.historico!.first.litrosMedidos, 5);
    expect(r.ficha!.kmAtual, 1200);
  });
  test('desmarcar tanque cheio invalida ciclo medido', () {
    final r = editar(indice: 2, km: 1000, litros: 8, pago: 48);
    expect(r.historico!.where((r) => r.medido), isEmpty);
    expect(r.ficha!.kmLitro, 35);
  });
  test('corrigir combustível recalcula mistura e não mantém média pura', () {
    final r = editar(combustivel: Combustivel.alcool);
    expect(r.historico!.first.tipoConsumo, 'medidoMisto');
    expect(r.historico!.first.combustivelMedido, isNull);
    expect(r.ficha!.kmLitro, 35);
  });
  test('rejeita dados inválidos e aceita eficiência alta', () {
    expect(editar(pago: 0).erro, isNotNull);
    expect(editar(litros: 0).erro, isNotNull);
    expect(editar(km: null).erro, isNotNull);
    final r = editar(indice: 0, km: 1800, litros: 3, pago: 18, cheio: true);
    expect(r.erro, isNull);
    expect(r.historico!.first.kmPorLitro, 160);
  });
}
