import 'package:flutter_test/flutter_test.dart';
import 'package:life_and_roads/features/manutencao/domain/agenda_manutencao.dart';
import 'package:life_and_roads/features/manutencao/domain/usecases/montar_linha_do_tempo.dart';
import 'package:life_and_roads/manutencao/extra.dart';

void main() {
  const montar = MontarLinhaDoTempo();
  final hoje = DateTime(2026, 9, 18);

  test('sem nada agendado, lista vazia', () {
    final itens = montar.executar(
      agenda: const AgendaManutencao(),
      extra: const ManutencaoExtra(),
      kmAtual: 1000,
      agora: hoje,
    );
    expect(itens, isEmpty);
  });

  test('óleo com última e próxima: fração do intervalo e estado', () {
    final itens = montar.executar(
      agenda: AgendaManutencao(
        oleoUltima: DateTime(2026, 8, 19),
        oleoProxima: DateTime(2026, 10, 18),
      ),
      extra: const ManutencaoExtra(),
      kmAtual: null,
      agora: hoje,
    );
    final oleo = itens.single;
    expect(oleo.titulo, 'Óleo');
    expect(oleo.fracao, closeTo(0.5, 0.02));
    expect(oleo.estado, EstadoItem.emDia);
    expect(oleo.detalhe, '18/10/2026, em 30 dias');
  });

  test('atrasado vem primeiro, depois atenção, depois em dia', () {
    final itens = montar.executar(
      agenda: AgendaManutencao(
        ipvaProxima: DateTime(2026, 9, 10), // atrasado 8 dias
        seguroProxima: DateTime(2026, 9, 25), // em 7 dias
        licenciamentoProxima: DateTime(2027, 3, 1), // folgado
      ),
      extra: const ManutencaoExtra(oleoKmUltima: 30000, oleoKmIntervalo: 4000),
      kmAtual: 33900, // faltam 100 km
      agora: hoje,
    );
    expect(itens.map((i) => i.id).toList(), [
      'ipva',
      'oleo-km',
      'seguro',
      'licenciamento',
    ]);
    expect(itens[0].estado, EstadoItem.atrasado);
    expect(itens[0].fracao, 1);
    expect(itens[0].detalhe, contains('atrasado há 8 dias'));
    expect(itens[1].estado, EstadoItem.atencao);
    expect(itens[1].porKm, isTrue);
    expect(itens[1].detalhe, 'troca aos 34.000 km, em 100 km');
    expect(itens[1].fracao, closeTo(0.975, 0.001));
    expect(itens[2].estado, EstadoItem.atencao);
    expect(itens[3].estado, EstadoItem.emDia);
  });

  test('papelada sem última assume um ano de intervalo', () {
    final itens = montar.executar(
      agenda: AgendaManutencao(ipvaProxima: DateTime(2027, 3, 18)),
      extra: const ManutencaoExtra(),
      kmAtual: null,
      agora: hoje,
    );
    // 182 dias para o vencimento em um intervalo de 365: metade passou.
    expect(itens.single.fracao, closeTo(0.5, 0.01));
  });

  test('vence hoje é atenção com fração cheia', () {
    final itens = montar.executar(
      agenda: AgendaManutencao(pneusProxima: hoje),
      extra: const ManutencaoExtra(),
      kmAtual: null,
      agora: hoje,
    );
    expect(itens.single.estado, EstadoItem.atencao);
    expect(itens.single.fracao, 1);
    expect(itens.single.detalhe, endsWith('vence hoje'));
  });
}
