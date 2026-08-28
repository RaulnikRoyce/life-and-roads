import 'dart:convert';

import 'package:life_and_roads/core/database/armazem_kv.dart';
import 'package:life_and_roads/core/database/chaves_kv.dart';
import 'package:life_and_roads/features/manutencao/data/agenda_manutencao_model.dart';
import 'package:life_and_roads/features/manutencao/domain/agenda_manutencao.dart';

/// Snapshot da agenda remota enquanto o piloto decide o conflito.
class AgendaConflitoStore {
  Future<void> gravar(AgendaManutencao remota) {
    return ArmazemKv.gravarTexto(
      ChavesKv.agendaConflito,
      jsonEncode(AgendaManutencaoModel.toApiJson(remota)),
    );
  }

  Future<AgendaManutencao?> ler() async {
    final bruto = await ArmazemKv.lerTexto(ChavesKv.agendaConflito);
    if (bruto == null) return null;
    try {
      final mapa = jsonDecode(bruto);
      if (mapa is! Map) return null;
      return AgendaManutencaoModel.fromJson(Map<String, dynamic>.from(mapa));
    } on FormatException {
      return null;
    }
  }

  Future<void> limpar() =>
      ArmazemKv.gravarTexto(ChavesKv.agendaConflito, null);
}
