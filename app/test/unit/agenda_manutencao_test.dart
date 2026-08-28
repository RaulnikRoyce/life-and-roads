import 'package:flutter_test/flutter_test.dart';
import 'package:life_and_roads/features/manutencao/data/agenda_manutencao_model.dart';
import 'package:life_and_roads/features/manutencao/domain/agenda_manutencao.dart';

void main() {
  test('JSON legado vira AgendaManutencao', () {
    final agenda = AgendaManutencaoModel.fromJson({
      'oleoUltima': '2026-01-10',
      'oleoProxima': '2026-07-10',
      'revisaoUltima': '',
      'pneusUltima': '2025-08-01',
      'pneusProxima': '2026-08-01',
      'ipvaProxima': '2027-01-15',
      'seguroProxima': null,
      'licenciamentoProxima': '2026-12-01',
    });
    expect(agenda.oleoUltima, DateTime(2026, 1, 10));
    expect(agenda.oleoProxima, DateTime(2026, 7, 10));
    expect(agenda.revisaoUltima, isNull);
    expect(agenda.seguroProxima, isNull);
  });

  test('toJson local preserva as chaves da caderneta', () {
    const agenda = AgendaManutencao(
      oleoUltima: null,
      oleoProxima: null,
    );
    final json = AgendaManutencaoModel.toJson(agenda);
    expect(json.keys, containsAll([
      'oleoUltima',
      'oleoProxima',
      'revisaoUltima',
      'pneusUltima',
      'pneusProxima',
      'ipvaProxima',
      'seguroProxima',
      'licenciamentoProxima',
    ]));
    expect(json.containsKey('cnhProxima'), isFalse);
  });

  test('toApiJson não leva km nem CNH', () {
    final json = AgendaManutencaoModel.toApiJson(
      const AgendaManutencao(oleoUltima: null),
    );
    expect(json.containsKey('oleoKmUltima'), isFalse);
    expect(json.containsKey('cnhProxima'), isFalse);
    expect(json.containsKey('placa'), isFalse);
  });

  test('tentar recusa próximo óleo antes da última', () {
    final agenda = AgendaManutencao(
      oleoUltima: DateTime(2026, 7, 1),
      oleoProxima: DateTime(2026, 1, 1),
    );
    expect(agenda.tentar(), contains('óleo'));
  });

  test('tentar aceita agenda vazia', () {
    expect(const AgendaManutencao().tentar(), isNull);
  });
}
