import 'package:life_and_roads/features/ficha/domain/ficha_moto.dart';
import 'package:life_and_roads/features/viagem/domain/usecases/editar_abastecimento.dart';
import 'package:life_and_roads/viagem/calculo.dart';

class ExcluirAbastecimento {
  const ExcluirAbastecimento();

  ({FichaMoto? ficha, List<RegistroAbastecimento>? historico, String? erro})
  executar({
    required FichaMoto ficha,
    required List<RegistroAbastecimento> historico,
    required int indice,
  }) {
    if (indice < 0 || indice >= historico.length) {
      return (
        ficha: null,
        historico: null,
        erro: 'O abastecimento não está mais no histórico. Abra novamente.',
      );
    }
    final base = ficha.copiarCom(
      kmLitro: referenciaConsumo(historico, Combustivel.gasolina),
      kmLitroAlcool: referenciaConsumo(historico, Combustivel.alcool),
    );
    var restantes = [...historico]..removeAt(indice);
    var atual = base;
    // Só o trecho posterior perde sua referência de distância ou de compra.
    if (indice > 0) {
      final proximo = restantes[indice - 1];
      final refeito = const EditarAbastecimento().executar(
        ficha: base,
        historico: restantes,
        indice: indice - 1,
        kmPainel: proximo.kmPainel,
        litros: proximo.litros,
        valorPago: proximo.reais,
        combustivel: proximo.combustivel,
        tanqueCheio: proximo.tanqueCheio,
        totalBarras: proximo.totalBarras,
        barrasAntes: proximo.barrasAntes,
        barrasDepois: proximo.barrasDepois,
      );
      if (refeito.erro != null) return refeito;
      restantes = refeito.historico!;
      atual = refeito.ficha!;
    }
    final novoKm =
        indice == 0 &&
            restantes.isNotEmpty &&
            ficha.kmAtual == historico.first.kmPainel
        ? restantes.first.kmPainel
        : ficha.kmAtual;
    atual = atual.copiarCom(
      kmAtual: novoKm,
      combustivel: restantes.isEmpty
          ? ficha.combustivel
          : restantes.first.combustivel,
      kmLitro: mediaKmPorLitro(restantes, Combustivel.gasolina),
      kmLitroAlcool: mediaKmPorLitro(restantes, Combustivel.alcool),
    );
    return (ficha: atual, historico: restantes, erro: null);
  }
}
