import 'dart:convert';

import 'package:life_and_roads/core/database/armazem_kv.dart';
import 'package:life_and_roads/core/database/chaves_kv.dart';
import 'package:life_and_roads/features/ficha/data/ficha_moto_model.dart';
import 'package:life_and_roads/features/ficha/domain/ficha_moto.dart';

class FichaLocalDatasource {
  Future<FichaMoto?> ler({bool recarregar = false}) async {
    final bruto = await ArmazemKv.lerTexto(ChavesKv.ficha);
    if (bruto == null) return null;
    try {
      final mapa = jsonDecode(bruto);
      if (mapa is! Map) return null;
      return FichaMotoModel.fromJson(Map<String, dynamic>.from(mapa));
    } on FormatException {
      return null;
    }
  }

  Future<void> gravar(FichaMoto ficha) {
    return ArmazemKv.gravarTexto(
      ChavesKv.ficha,
      jsonEncode(FichaMotoModel.toJson(ficha)),
    );
  }
}
