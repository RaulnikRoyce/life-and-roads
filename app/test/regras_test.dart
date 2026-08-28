import 'package:flutter_test/flutter_test.dart';
import 'package:life_and_roads/manutencao/regras.dart';

void main() {
  test('óleo última preenche próxima em 6 meses', () {
    expect(
      acrescentarMeses(DateTime(2026, 1, 31), 6),
      DateTime(2026, 7, 31),
    );
    expect(
      acrescentarMeses(DateTime(2026, 1, 15), -1),
      DateTime(2025, 12, 15),
    );
  });

  test('seguro vencido pula para o mesmo dia no ano que vem', () {
    expect(
      proximaAnual(DateTime(2024, 1, 30), hoje: DateTime(2026, 8, 25)),
      DateTime(2027, 1, 30),
    );
    expect(
      proximaAnual(DateTime(2027, 1, 30), hoje: DateTime(2026, 8, 25)),
      DateTime(2027, 1, 30),
    );
  });

  test('CNH vencida soma 10 anos ou 5', () {
    expect(
      proximaCnh(
        DateTime(2015, 1, 30),
        cincoAnos: false,
        hoje: DateTime(2026, 8, 25),
      ),
      DateTime(2035, 1, 30),
    );
    expect(
      proximaCnh(
        DateTime(2022, 1, 30),
        cincoAnos: true,
        hoje: DateTime(2026, 8, 25),
      ),
      DateTime(2027, 1, 30),
    );
  });

  test('data digitada 13/08/26', () {
    expect(parseDataBr('13/08/26'), DateTime(2026, 8, 13));
    expect(parseDataBr('13/08/2026'), DateTime(2026, 8, 13));
    expect(parseDataBr('31/02/26'), isNull);
    expect(parseDataBr('abc'), isNull);
  });
}
