import 'package:flutter_test/flutter_test.dart';
import 'package:life_and_roads/features/manutencao/domain/agenda_manutencao.dart';
import 'package:life_and_roads/features/manutencao/domain/usecases/montar_avisos_caderneta.dart';
import 'package:life_and_roads/features/manutencao/domain/usecases/montar_horarios_lembrete.dart';
import 'package:life_and_roads/manutencao/extra.dart';

void main() {
  const avisos = MontarAvisosCaderneta();
  const horarios = MontarHorariosLembrete();
  final agora = DateTime(2026, 8, 26, 10, 0);

  test('óleo atrasado por data entra no aviso', () {
    final lista = avisos.executar(
      agenda: AgendaManutencao(oleoProxima: DateTime(2026, 8, 20)),
      extra: const ManutencaoExtra(),
      kmAtual: 1000,
      agora: agora,
    );
    expect(lista.single.texto, contains('atrasado há 6 dia'));
    expect(lista.single.atrasado, isTrue);
  });

  test('óleo atrasado por km entra no aviso', () {
    final lista = avisos.executar(
      agenda: const AgendaManutencao(),
      extra: const ManutencaoExtra(oleoKmUltima: 1000, oleoKmIntervalo: 4000),
      kmAtual: 5200,
      agora: agora,
    );
    expect(lista.single.texto, contains('atrasado 200 km'));
    expect(lista.single.porKm, isTrue);
    expect(lista.single.atrasado, isTrue);
  });

  test('data passada ainda agenda amanhã 9h', () {
    final lista = horarios.executar(
      agora: agora,
      oleo: DateTime(2026, 8, 1),
    );
    expect(lista, hasLength(1));
    expect(lista.single.id, MontarHorariosLembrete.idOleo);
    expect(lista.single.quando, DateTime(2026, 8, 27, 9));
    expect(lista.single.corpo, contains('Já passou'));
  });

  test('falta mais de 7 dias agenda o dia e a semana', () {
    final lista = horarios.executar(
      agora: agora,
      oleo: DateTime(2026, 9, 10),
    );
    expect(lista.map((d) => d.id), [
      MontarHorariosLembrete.idOleo,
      MontarHorariosLembrete.idOleoSemana,
    ]);
    expect(lista[1].quando, DateTime(2026, 9, 3, 9));
  });

  test('faltam 5 dias agenda só o dia', () {
    final lista = horarios.executar(
      agora: agora,
      oleo: DateTime(2026, 8, 31),
    );
    expect(lista, hasLength(1));
    expect(lista.single.quando, DateTime(2026, 8, 31, 9));
  });
}
