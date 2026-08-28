import 'package:life_and_roads/features/ficha/domain/ficha_moto.dart';
import 'package:life_and_roads/viagem/calculo.dart';

/// Monta o registro do posto e a ficha atualizada. Sem persistência.
class MontarAbastecimento {
  const MontarAbastecimento();
  ({
    FichaMoto? ficha,
    RegistroAbastecimento? registro,
    String? erro,
    String? aviso,
  }) executar({
    required FichaMoto? ficha,
    required double? kmPainel,
    required double? litros,
    required double? preco,
    required Combustivel combustivel,
  }) {
    if (kmPainel == null || litros == null) {
      return (
        ficha: null,
        registro: null,
        erro: 'Informe o km no painel agora e os litros que entrou.',
        aviso: null,
      );
    }
    if (preco == null) {
      return (
        ficha: null,
        registro: null,
        erro: combustivel == Combustivel.alcool
            ? 'Informe o preço do litro de álcool.'
            : 'Informe o preço do litro de gasolina.',
        aviso: null,
      );
    }
    if (ficha == null) {
      return (
        ficha: null,
        registro: null,
        erro: 'Preencha o km do painel na Ficha antes de anotar o posto.',
        aviso: null,
      );
    }

    final erroConsumo = _erroDoPainel(
      kmAnterior: ficha.kmAtual,
      kmPainel: kmPainel,
      litros: litros,
    );
    if (erroConsumo != null) {
      return (
        ficha: null,
        registro: null,
        erro: erroConsumo,
        aviso: null,
      );
    }

    final consumo = consumoDoPainel(
      kmAnterior: ficha.kmAtual,
      kmPainel: kmPainel,
      litros: litros,
    )!;

    final registro = registroDoPosto(
      consumo: consumo,
      litros: litros,
      precoLitro: preco,
      kmPainel: kmPainel,
      combustivel: combustivel,
    );
    if (registro == null) {
      return (
        ficha: null,
        registro: null,
        erro: 'Preço do litro fica entre 2 e 20 reais.',
        aviso: null,
      );
    }

    final atualizada = combustivel == Combustivel.alcool
        ? ficha.copiarCom(
            kmAtual: kmPainel,
            kmLitroAlcool: consumo.kmPorLitro,
            combustivel: combustivel,
          )
        : ficha.copiarCom(
            kmAtual: kmPainel,
            kmLitro: consumo.kmPorLitro,
            combustivel: combustivel,
          );

    final kmTxt = consumo.kmRodados.toStringAsFixed(0).replaceAll('.', ',');
    final lTxt = litros.toStringAsFixed(1).replaceAll('.', ',');

    return (
      ficha: atualizada,
      registro: registro,
      erro: null,
      aviso: 'Posto anotado. $kmTxt km com $lTxt L.',
    );
  }

  String? _erroDoPainel({
    required double kmAnterior,
    required double kmPainel,
    required double litros,
  }) {
    final kmRodados = kmPainel - kmAnterior;
    final kmBr = kmAnterior.toStringAsFixed(0).replaceAll('.', ',');
    if (kmRodados <= 0) {
      return 'O km no painel tem que ser maior que o da Ficha ($kmBr).';
    }
    if (kmRodados > 2000) {
      return 'Muita diferença de km desde a Ficha. Confira o painel.';
    }
    if (litros < 0.5 || litros > 40) {
      return 'Os litros deste tanque ficam entre 0,5 e 40.';
    }
    final media = kmRodados / litros;
    if (media < 5) {
      return 'O painel quase não andou para tanto combustível. Confira o km e os litros.';
    }
    if (media > 80) {
      return 'Andou demais para tão pouco combustível. Confira o km e os litros.';
    }
    return null;
  }
}
