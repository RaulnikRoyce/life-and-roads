import 'package:flutter_test/flutter_test.dart';
import 'package:life_and_roads/features/ficha/domain/ficha_moto.dart';
import 'package:life_and_roads/features/ficha/domain/usecases/detectar_conflito_ficha.dart';
import 'package:life_and_roads/features/manutencao/domain/agenda_manutencao.dart';
import 'package:life_and_roads/features/manutencao/domain/usecases/detectar_conflito_agenda.dart';

void main() {
  test('ficha igual na API não conflita; PSI diferente não conta', () {
    const local = FichaMoto(
      marca: 'Honda',
      modelo: 'Bros',
      kmLitro: 35,
      kmAtual: 1000,
      psiDianteiro: 32,
    );
    const remota = FichaMoto(
      marca: 'Honda',
      modelo: 'Bros',
      kmLitro: 35,
      kmAtual: 1000,
    );
    expect(DetectarConflitoFicha().executar(local, remota), isFalse);
  });

  test('km diferente no servidor é conflito', () {
    const local = FichaMoto(
      marca: 'Honda',
      modelo: 'Bros',
      kmLitro: 35,
      kmAtual: 1000,
    );
    const remota = FichaMoto(
      marca: 'Honda',
      modelo: 'Bros',
      kmLitro: 35,
      kmAtual: 2000,
    );
    expect(DetectarConflitoFicha().executar(local, remota), isTrue);
  });

  test('agenda compara só o dia', () {
    final local = AgendaManutencao(
      oleoUltima: DateTime(2026, 1, 10, 15),
      oleoProxima: DateTime(2026, 7, 10),
    );
    final remota = AgendaManutencao(
      oleoUltima: DateTime(2026, 1, 10),
      oleoProxima: DateTime(2026, 7, 10),
    );
    expect(DetectarConflitoAgenda().executar(local, remota), isFalse);
    expect(
      DetectarConflitoAgenda().executar(
        local,
        AgendaManutencao(oleoUltima: DateTime(2025, 1, 10)),
      ),
      isTrue,
    );
  });
}
