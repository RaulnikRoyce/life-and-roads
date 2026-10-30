import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:life_and_roads/core/database/caderneta_banco.dart';
import 'package:life_and_roads/core/database/caderneta_database.dart';
import 'package:life_and_roads/viagem/calculo.dart';

/// Postos neste aparelho. Sem placa. Não vai na ficha da API.
class HistoricoAbastecimento {
  static const chave = 'abastecimentos_v1';
  static const max = 5000;

  static Future<List<RegistroAbastecimento>> carregar() async {
    final linhas = await CadernetaBanco.instancia.listarAbastecimentos();
    return [for (final l in linhas) _deLinha(l)];
  }

  static Future<List<RegistroAbastecimento>> acrescentar(
    RegistroAbastecimento registro,
  ) async {
    await inserirLinha(registro);
    await CadernetaBanco.instancia.podarMaisAntigos('abastecimentos', max);

    return carregar();
  }

  static Future<void> inserirLinha(RegistroAbastecimento r) {
    return CadernetaBanco.instancia.inserirAbastecimento(
      AbastecimentosCompanion.insert(
        detalhes: Value(jsonEncode(r.paraJson())),
        em: r.em,
        combustivel: r.combustivel.name,
        kmPainel: r.kmPainel,
        kmRodados: r.kmRodados,
        litros: r.litros,
        precoLitro: r.precoLitro,
        reais: r.reais,
        kmPorLitro: r.kmPorLitro,
        reaisPorKm: r.reaisPorKm,
      ),
    );
  }

  static RegistroAbastecimento _deLinha(LinhaAbastecimento l) {
    if (l.detalhes != null) {
      try {
        final registro = RegistroAbastecimento.deJson(jsonDecode(l.detalhes!));
        if (registro != null) {
          return registro;
        }
      } on FormatException {
        /* Preserva as colunas do registro antigo. */
      }
    }
    return RegistroAbastecimento(
      em: l.em,
      combustivel: combustivelDe(l.combustivel),
      kmPainel: l.kmPainel,
      kmRodados: l.kmRodados,
      litros: l.litros,
      precoLitro: l.precoLitro,
      reais: l.reais,
      kmPorLitro: l.kmPorLitro,
      reaisPorKm: l.reaisPorKm,
    );
  }
}
