import 'dart:convert';

import 'package:life_and_roads/viagem/calculo.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Postos neste aparelho. Sem placa. Não vai na ficha da API.
class HistoricoAbastecimento {
  static const chave = 'abastecimentos_v1';
  static const max = 20;

  static Future<List<RegistroAbastecimento>> carregar() async {
    final prefs = await SharedPreferences.getInstance();
    final bruto = prefs.getString(chave);
    if (bruto == null || bruto.isEmpty) return [];
    try {
      final lista = jsonDecode(bruto);
      if (lista is! List) return [];
      return lista
          .map(RegistroAbastecimento.deJson)
          .whereType<RegistroAbastecimento>()
          .toList();
    } on FormatException {
      return [];
    }
  }

  static Future<List<RegistroAbastecimento>> acrescentar(
    RegistroAbastecimento registro,
  ) async {
    final atual = await carregar();
    final juntos = [registro, ...atual].take(max).toList();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      chave,
      jsonEncode([for (final r in juntos) r.paraJson()]),
    );
    return juntos;
  }
}
