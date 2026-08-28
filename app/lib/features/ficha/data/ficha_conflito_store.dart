import 'dart:convert';

import 'package:life_and_roads/core/database/armazem_kv.dart';
import 'package:life_and_roads/core/database/chaves_kv.dart';
import 'package:life_and_roads/features/ficha/data/ficha_moto_model.dart';
import 'package:life_and_roads/features/ficha/domain/ficha_moto.dart';

/// Snapshot da ficha remota enquanto o piloto decide o conflito.
class FichaConflitoStore {
  Future<void> gravar(FichaMoto remota) {
    return ArmazemKv.gravarTexto(
      ChavesKv.fichaConflito,
      jsonEncode(FichaMotoModel.toApiJson(remota)),
    );
  }

  Future<FichaMoto?> ler() async {
    final bruto = await ArmazemKv.lerTexto(ChavesKv.fichaConflito);
    if (bruto == null) return null;
    try {
      final mapa = jsonDecode(bruto);
      if (mapa is! Map) return null;
      return FichaMotoModel.fromJson(Map<String, dynamic>.from(mapa));
    } on FormatException {
      return null;
    }
  }

  Future<void> limpar() => ArmazemKv.gravarTexto(ChavesKv.fichaConflito, null);
}
