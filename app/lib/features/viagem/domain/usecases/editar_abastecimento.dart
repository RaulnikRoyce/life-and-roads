import 'package:life_and_roads/features/ficha/domain/ficha_moto.dart';
import 'package:life_and_roads/features/viagem/domain/usecases/montar_abastecimento.dart';
import 'package:life_and_roads/viagem/calculo.dart';

/// Mantém a ordem e as datas. Refaz os resultados a partir da compra corrigida.
class EditarAbastecimento {
  const EditarAbastecimento();

  ({FichaMoto? ficha, List<RegistroAbastecimento>? historico, String? erro})
  executar({
    required FichaMoto ficha,
    required List<RegistroAbastecimento> historico,
    required int indice,
    required double? kmPainel,
    required double? litros,
    required double? valorPago,
    required Combustivel combustivel,
    required bool tanqueCheio,
    int? totalBarras,
    int? barrasAntes,
    int? barrasDepois,
  }) {
    ({FichaMoto? ficha, List<RegistroAbastecimento>? historico, String? erro})
    erro(String texto) => (ficha: null, historico: null, erro: texto);
    if (valorPago == null || !valorPago.isFinite || valorPago <= 0) {
      return erro('Informe um valor pago maior que zero.');
    }
    if (indice < 0 || indice >= historico.length) {
      return erro(
        'O abastecimento não está mais no histórico. Abra novamente.',
      );
    }
    if (kmPainel != null &&
        indice > 0 &&
        kmPainel >= historico[indice - 1].kmPainel) {
      return erro('O km deve ser menor que o do abastecimento seguinte.');
    }
    final refeitos = historico.skip(indice + 1).toList();
    // Usa estimativas anteriores à primeira medição quando disponíveis.
    double? base(Combustivel c) {
      for (var i = historico.length - 1; i >= 0; i--) {
        final r = historico[i];
        if (r.tipoConsumo == 'estimado' &&
            r.kmPorLitro > 0 &&
            combustivelDoIntervalo(historico, i) == c) {
          return r.kmPorLitro;
        }
      }
      return null;
    }

    var atual = ficha.copiarCom(
      kmAtual: refeitos.isEmpty ? 0 : refeitos.first.kmPainel,
      kmLitro:
          mediaKmPorLitro(refeitos, Combustivel.gasolina) ??
          base(Combustivel.gasolina),
      kmLitroAlcool:
          mediaKmPorLitro(refeitos, Combustivel.alcool) ??
          base(Combustivel.alcool),
    );
    for (var i = indice; i >= 0; i--) {
      final antigo = historico[i];
      final editado = i == indice;
      final r = const MontarAbastecimento().executar(
        ficha: atual,
        historico: refeitos,
        em: antigo.em,
        kmPainel: editado ? kmPainel : antigo.kmPainel,
        litros: editado ? litros : antigo.litros,
        preco: antigo.precoLitro,
        valorPago: editado ? valorPago : antigo.reais,
        combustivel: editado ? combustivel : antigo.combustivel,
        tanqueCheio: editado ? tanqueCheio : antigo.tanqueCheio,
        totalBarras: editado ? totalBarras : antigo.totalBarras,
        barrasAntes: editado ? barrasAntes : antigo.barrasAntes,
        barrasDepois: editado ? barrasDepois : antigo.barrasDepois,
      );
      if (r.erro != null) return erro(r.erro!);
      atual = r.ficha!;
      refeitos.insert(0, r.registro!);
    }
    // Uma ficha com km posterior, vindo de dados antigos, não deve retroceder.
    if (ficha.kmAtual > historico.first.kmPainel) {
      atual = atual.copiarCom(kmAtual: ficha.kmAtual);
    }
    atual = atual.copiarCom(
      kmLitro: mediaKmPorLitro(refeitos, Combustivel.gasolina),
      kmLitroAlcool: mediaKmPorLitro(refeitos, Combustivel.alcool),
    );
    return (ficha: atual, historico: refeitos, erro: null);
  }
}
