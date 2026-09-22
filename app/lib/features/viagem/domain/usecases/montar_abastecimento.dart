import 'package:life_and_roads/features/ficha/domain/ficha_moto.dart';
import 'package:life_and_roads/viagem/calculo.dart';

/// Monta o registro do posto e a ficha atualizada. Sem persistência.
///
/// A referência de km é o abastecimento anterior, não a Ficha. O primeiro
/// registro só guarda km, litros e valor; do segundo em diante, o intervalo
/// entre um posto e o próximo dividido pelos litros que entraram agora dá o
/// consumo (tanque cheio nos dois). O intervalo foi rodado com o combustível
/// do abastecimento anterior, e é para ele que a média conta. A Ficha
/// recebe a média ponderada de todos os intervalos daquele combustível.
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
  }) {
    if (kmPainel == null || litros == null) {
      return _erro('Informe o km do painel e os litros abastecidos.');
    }
    if (preco == null) {
      return _erro(
        combustivel == Combustivel.alcool
            ? 'Informe o preço do litro de álcool.'
            : 'Informe o preço do litro de gasolina.',
      );
    }
    if (ficha == null) {
      return _erro(
        'Preencha o km do painel na Ficha antes de registrar o abastecimento.',
      );
    }
    if (litros < 0.5 || litros > 40) {
      return _erro('Litros abastecidos entre 0,5 e 40.');
    }

    final anterior = historico.isEmpty ? null : historico.first;
    if (anterior == null) {
      return _primeiro(ficha, kmPainel, litros, preco, combustivel);
    }

    final erroIntervalo = _erroDoIntervalo(
      kmAnterior: anterior.kmPainel,
      kmPainel: kmPainel,
      litros: litros,
    );
    if (erroIntervalo != null) return _erro(erroIntervalo);

    final consumo = consumoDoPainel(
      kmAnterior: anterior.kmPainel,
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
      return _erro('Preço do litro fica entre 2 e 20 reais.');
    }

    // O que rodou o intervalo é o que estava no tanque: o combustível do
    // abastecimento anterior. A média junta todos os intervalos dele.
    final noTanque = anterior.combustivel;
    final media =
        mediaKmPorLitro([registro, ...historico], noTanque) ??
        consumo.kmPorLitro;
    final atualizada = noTanque == Combustivel.alcool
        ? ficha.copiarCom(
            kmAtual: kmPainel,
            kmLitroAlcool: media,
            combustivel: combustivel,
          )
        : ficha.copiarCom(
            kmAtual: kmPainel,
            kmLitro: media,
            combustivel: combustivel,
          );

    final kmTxt = _br(consumo.kmRodados, 0);
    final lTxt = _br(litros, 1);
    final consumoTxt = _br(consumo.kmPorLitro, 0);
    final rodou = noTanque == combustivel
        ? ''
        : ' Rodados com ${rotuloCombustivel(noTanque).toLowerCase()}.';
    return (
      ficha: atualizada,
      registro: registro,
      erro: null,
      aviso:
          'Abastecimento registrado. $kmTxt km desde o último com $lTxt L, '
          '$consumoTxt km com 1 L.$rodou',
    );
  }

  ({
    FichaMoto? ficha,
    RegistroAbastecimento? registro,
    String? erro,
    String? aviso,
  })
  _primeiro(
    FichaMoto ficha,
    double kmPainel,
    double litros,
    double preco,
    Combustivel combustivel,
  ) {
    if (kmPainel < ficha.kmAtual) {
      final kmBr = _br(ficha.kmAtual, 0);
      return _erro('O km no painel não pode ser menor que o da Ficha ($kmBr).');
    }
    final registro = primeiroRegistroDoPosto(
      litros: litros,
      precoLitro: preco,
      kmPainel: kmPainel,
      combustivel: combustivel,
    );
    if (registro == null) {
      return _erro('Preço do litro fica entre 2 e 20 reais.');
    }
    return (
      ficha: ficha.copiarCom(kmAtual: kmPainel, combustivel: combustivel),
      registro: registro,
      erro: null,
      aviso:
          'Primeiro abastecimento registrado. A partir do próximo o app '
          'calcula o consumo.',
    );
  }

  String? _erroDoIntervalo({
    required double kmAnterior,
    required double kmPainel,
    required double litros,
  }) {
    final kmRodados = kmPainel - kmAnterior;
    final kmBr = _br(kmAnterior, 0);
    if (kmRodados <= 0) {
      return 'O km no painel tem que ser maior que o do último abastecimento ($kmBr).';
    }
    if (kmRodados > 2000) {
      return 'Muita diferença de km desde o último abastecimento. Confira o painel.';
    }
    final media = kmRodados / litros;
    if (media < 5) {
      return 'Km rodados muito baixo para o volume abastecido. Confira o km e os litros.';
    }
    if (media > 80) {
      return 'Andou demais para tão pouco combustível. Confira o km e os litros.';
    }
    return null;
  }

  ({
    FichaMoto? ficha,
    RegistroAbastecimento? registro,
    String? erro,
    String? aviso,
  })
  _erro(String mensagem) =>
      (ficha: null, registro: null, erro: mensagem, aviso: null);

  static String _br(double n, int casas) =>
      n.toStringAsFixed(casas).replaceAll('.', ',');
}
