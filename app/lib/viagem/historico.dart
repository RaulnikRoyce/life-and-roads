import 'package:life_and_roads/core/database/caderneta_banco.dart';
import 'package:life_and_roads/core/database/caderneta_database.dart';
import 'package:life_and_roads/viagem/calculo.dart';

/// Postos neste aparelho. Sem placa. Não vai na ficha da API.
class HistoricoAbastecimento {
  static const chave = 'abastecimentos_v1';
  static const max = 20;

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
