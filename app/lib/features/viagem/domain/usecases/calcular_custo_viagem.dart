import 'package:life_and_roads/viagem/calculo.dart';

/// Estima litros e reais da rota. Sem persistência.
class CalcularCustoViagem {
  const CalcularCustoViagem();
  ({ResultadoViagem? resultado, String? erro}) executar({
    required double? km,
    required double? kmPorLitro,
    required double? preco,
    required Combustivel combustivel,
  }) {
    if (km == null || preco == null) {
      return (
        resultado: null,
        erro: combustivel == Combustivel.alcool
            ? 'Informe os km da viagem e o preço do álcool.'
            : 'Informe os km da viagem e o preço da gasolina.',
      );
    }
    if (kmPorLitro == null) {
      return (
        resultado: null,
        erro: combustivel == Combustivel.alcool
            ? 'Informe o consumo com álcool na Ficha ou registre um abastecimento com álcool.'
            : 'Informe o consumo com gasolina na Ficha.',
      );
    }
    final r = calcularViagem(
      km: km,
      kmPorLitro: kmPorLitro,
      precoLitro: preco,
    );
    if (r == null) {
      return (
        resultado: null,
        erro: 'Confira os km (até 5000) e o preço do litro (entre 2 e 20).',
      );
    }
    return (resultado: r, erro: null);
  }
}
