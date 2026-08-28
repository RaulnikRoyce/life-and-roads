import 'dart:convert';

import 'package:life_and_roads/core/database/armazem_kv.dart';
import 'package:life_and_roads/core/database/chaves_kv.dart';

/// IDs de aviso já lidos neste aparelho.
class AvisosLidosDatasource {
  Future<Set<String>> ler() async {
    final bruto = await ArmazemKv.lerTexto(ChavesKv.avisosLidos);
    if (bruto == null || bruto.isEmpty) return {};
    try {
      final lista = jsonDecode(bruto);
      if (lista is! List) return {};
      return {for (final e in lista) '$e'};
    } on FormatException {
      return {};
    }
  }

  Future<void> gravar(Set<String> ids) {
    final ordenados = ids.toList()..sort();
    return ArmazemKv.gravarTexto(ChavesKv.avisosLidos, jsonEncode(ordenados));
  }
}
