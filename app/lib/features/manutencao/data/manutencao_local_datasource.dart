import 'dart:convert';

import 'package:life_and_roads/core/database/armazem_kv.dart';
import 'package:life_and_roads/core/database/chaves_kv.dart';
import 'package:life_and_roads/features/manutencao/data/agenda_manutencao_model.dart';
import 'package:life_and_roads/features/manutencao/domain/agenda_manutencao.dart';
import 'package:life_and_roads/manutencao/extra.dart';

class ManutencaoLocalDatasource {
  static const chave = ChavesKv.agenda;

  Future<AgendaManutencao> lerAgenda() async {
    final bruto = await ArmazemKv.lerTexto(chave);
    if (bruto == null) return const AgendaManutencao();
    try {
      final mapa = jsonDecode(bruto);
      if (mapa is! Map) return const AgendaManutencao();
      return AgendaManutencaoModel.fromJson(Map<String, dynamic>.from(mapa));
    } on FormatException {
      return const AgendaManutencao();
    }
  }

  Future<void> gravarAgenda(AgendaManutencao agenda) {
    return ArmazemKv.gravarTexto(
      chave,
      jsonEncode(AgendaManutencaoModel.toJson(agenda)),
    );
  }

  Future<ManutencaoExtra> lerExtra() => ManutencaoExtra.carregar();

  Future<void> gravarExtra(ManutencaoExtra extra) =>
      ManutencaoExtra.salvar(extra);
}
