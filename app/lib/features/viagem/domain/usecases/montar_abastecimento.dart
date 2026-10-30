import 'package:life_and_roads/features/ficha/domain/ficha_moto.dart';
import 'package:life_and_roads/viagem/calculo.dart';

/// Compra e consumo têm referências distintas. Parciais não medem litros gastos.
class MontarAbastecimento {
  const MontarAbastecimento();
  ({
    FichaMoto? ficha,
    RegistroAbastecimento? registro,
    String? erro,
    String? aviso,
  })
  executar({
    required FichaMoto? ficha,
    required List<RegistroAbastecimento> historico,
    required double? kmPainel,
    required double? litros,
    required double? preco,
    required Combustivel combustivel,
    double? valorPago,
    bool tanqueCheio = false,
    int? totalBarras,
    int? barrasAntes,
    int? barrasDepois,
  }) {
    ({
      FichaMoto? ficha,
      RegistroAbastecimento? registro,
      String? erro,
      String? aviso,
    })
    erro(String msg) => (ficha: null, registro: null, erro: msg, aviso: null);
    if (ficha == null) {
      return erro('Preencha a Ficha antes de registrar o abastecimento.');
    }
    if (valorPago != null) {
      if (!valorPago.isFinite || valorPago <= 0) {
        return erro('Informe um valor pago maior que zero.');
      }
      if (litros != null && litros.isFinite && litros > 0) {
        preco = valorPago / litros;
      }
    }
    if (kmPainel == null ||
        !kmPainel.isFinite ||
        kmPainel < 0 ||
        kmPainel > 999999 ||
        litros == null ||
        !litros.isFinite ||
        litros <= 0 ||
        preco == null ||
        !preco.isFinite ||
        preco <= 0 ||
        !(litros * preco).isFinite) {
      return erro('Informe km válido, litros e preço maiores que zero.');
    }
    if (kmPainel < ficha.kmAtual) {
      return erro('O km no painel não pode ser menor que o da Ficha.');
    }
    final anterior = historico.isEmpty ? null : historico.first;
    if (anterior != null && kmPainel <= anterior.kmPainel) {
      return erro(
        'O km no painel tem que ser maior que o do último abastecimento.',
      );
    }
    if (totalBarras != null || barrasAntes != null || barrasDepois != null) {
      if (totalBarras == null ||
          totalBarras < 1 ||
          totalBarras > 30 ||
          barrasAntes == null ||
          barrasDepois == null ||
          barrasAntes < 0 ||
          barrasDepois < barrasAntes ||
          barrasDepois > totalBarras) {
        return erro('Confira o total de barras e os níveis antes e depois.');
      }
    }
    // Sem medição do combustível restante, uma troca não confirma tanque puro.
    var misturaAnterior = false;
    Combustivel? ultimoCombustivel;
    for (final r in historico.reversed) {
      misturaAnterior =
          misturaAnterior ||
          r.misturaNoTanque == true ||
          (ultimoCombustivel != null && ultimoCombustivel != r.combustivel);
      ultimoCombustivel = r.combustivel;
    }
    final misturaDepois =
        misturaAnterior ||
        (anterior != null && anterior.combustivel != combustivel);
    final distancia = anterior == null ? 0.0 : kmPainel - anterior.kmPainel;
    final noTanque = anterior?.combustivel ?? combustivel;
    double? media = anterior == null
        ? null
        : noTanque == Combustivel.alcool
        ? ficha.kmLitroAlcool
        : ficha.kmLitro;
    var tipo = media == null ? 'referencia' : 'estimado';
    double? kmMedidos, litrosMedidos, reaisMedidos;
    Combustivel? combustivelMedido;
    var custo = media == null ? 0.0 : preco / media;
    if (tanqueCheio) {
      var volume = litros;
      var gasto = litros * preco;
      final intermediarios = <RegistroAbastecimento>[];
      for (final r in historico) {
        if (r.tipoConsumo == 'legado') {
          break;
        }
        if (r.tanqueCheio) {
          kmMedidos = kmPainel - r.kmPainel;
          litrosMedidos = volume;
          reaisMedidos = gasto;
          final mesmo =
              !misturaAnterior &&
              intermediarios.every((p) => p.combustivel == r.combustivel);
          combustivelMedido = mesmo ? r.combustivel : null;
          tipo = mesmo ? 'medido' : 'medidoMisto';
          media = kmMedidos / volume;
          custo = gasto / kmMedidos;
          break;
        }
        intermediarios.add(r);
        volume += r.litros;
        gasto += r.reais;
      }
    }
    if ((media != null && (!media.isFinite || media <= 0)) || !custo.isFinite) {
      return erro(
        'Confira os números do abastecimento. O resultado precisa ser finito e positivo.',
      );
    }
    final registro = RegistroAbastecimento(
      em: DateTime.now().toIso8601String(),
      combustivel: combustivel,
      kmPainel: kmPainel,
      kmRodados: distancia,
      litros: litros,
      precoLitro: preco,
      reais: litros * preco,
      kmPorLitro: media ?? 0,
      reaisPorKm: custo,
      tipoConsumo: tipo,
      misturaNoTanque: misturaDepois,
      tanqueCheio: tanqueCheio,
      kmMedidos: kmMedidos,
      litrosMedidos: litrosMedidos,
      reaisMedidos: reaisMedidos,
      combustivelMedido: combustivelMedido,
      totalBarras: totalBarras,
      barrasAntes: barrasAntes,
      barrasDepois: barrasDepois,
    );
    var atualizada = ficha.copiarCom(
      kmAtual: kmPainel,
      combustivel: combustivel,
    );
    if (tipo == 'medido') {
      final medidos = [registro, ...historico.where((r) => r.medido)];
      final ponderada = mediaKmPorLitro(medidos, combustivelMedido!)!;
      atualizada = combustivelMedido == Combustivel.alcool
          ? atualizada.copiarCom(kmLitroAlcool: ponderada)
          : atualizada.copiarCom(kmLitro: ponderada);
    }
    return (
      ficha: atualizada,
      registro: registro,
      erro: null,
      aviso: anterior == null
          ? 'Primeiro abastecimento registrado. A referência foi salva.'
          : registro.medido
          ? 'Abastecimento registrado. Consumo medido entre tanques cheios.'
          : 'Abastecimento registrado. Consumo estimado pela média da Ficha.',
    );
  }
}
