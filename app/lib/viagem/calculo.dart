import 'dart:math' as math;

/// Flex: gasolina e álcool têm km/l distintos. Fórmulas da aba Viagem.
///
/// Consumo no posto: `(km painel − km ficha) / litros`.
/// Custo da rota: `km / km/l * preço`. R$/km: `litros * preço / km rodados`.
enum Combustivel { gasolina, alcool }

String rotuloCombustivel(Combustivel c) =>
    c == Combustivel.alcool ? 'Álcool' : 'Gasolina';

Combustivel combustivelDe(Object? valor) =>
    '${valor ?? ''}' == 'alcool' ? Combustivel.alcool : Combustivel.gasolina;

/// km ÷ km/l = litros; litros × preço = reais.
class ResultadoViagem {
  const ResultadoViagem({required this.litros, required this.reais});

  final double litros;
  final double reais;
}

/// km rodados no painel (agora − último) ÷ litros deste abastecimento.
class ConsumoAbastecimento {
  const ConsumoAbastecimento({
    required this.kmRodados,
    required this.kmPorLitro,
  });

  final double kmRodados;
  final double kmPorLitro;
}

/// Um posto: data, litros, preço, km. Serve o histórico e o R$/km.
class RegistroAbastecimento {
  const RegistroAbastecimento({
    required this.em,
    required this.combustivel,
    required this.kmPainel,
    required this.kmRodados,
    required this.litros,
    required this.precoLitro,
    required this.reais,
    required this.kmPorLitro,
    required this.reaisPorKm,
  });

  final String em;
  final Combustivel combustivel;
  final double kmPainel;
  final double kmRodados;
  final double litros;
  final double precoLitro;
  final double reais;
  final double kmPorLitro;
  final double reaisPorKm;

  /// O primeiro abastecimento não tem intervalo anterior: km rodados e
  /// consumo ficam em zero (as colunas do banco são obrigatórias). Só os
  /// registros com intervalo entram nas médias e no gráfico.
  bool get temConsumo => kmRodados > 0 && kmPorLitro > 0;

  Map<String, dynamic> paraJson() => {
    'em': em,
    'combustivel': combustivel.name,
    'kmPainel': kmPainel,
    'kmRodados': kmRodados,
    'litros': litros,
    'precoLitro': precoLitro,
    'reais': reais,
    'kmPorLitro': kmPorLitro,
    'reaisPorKm': reaisPorKm,
  };

  static RegistroAbastecimento? deJson(Object? bruto) {
    if (bruto is! Map) return null;
    final mapa = Map<String, dynamic>.from(bruto);
    final litros = _num(mapa['litros']);
    final preco = _num(mapa['precoLitro']);
    final kmRodados = _num(mapa['kmRodados']);
    final kmPainel = _num(mapa['kmPainel']);
    final kmL = _num(mapa['kmPorLitro']);
    if (litros == null ||
        preco == null ||
        kmRodados == null ||
        kmPainel == null ||
        kmL == null) {
      return null;
    }
    final reais = _num(mapa['reais']) ?? litros * preco;
    final rpk =
        _num(mapa['reaisPorKm']) ?? (kmRodados <= 0 ? 0.0 : reais / kmRodados);
    final em = '${mapa['em'] ?? ''}'.trim();
    return RegistroAbastecimento(
      em: em.isEmpty ? DateTime.now().toIso8601String() : em,
      combustivel: combustivelDe(mapa['combustivel']),
      kmPainel: kmPainel,
      kmRodados: kmRodados,
      litros: litros,
      precoLitro: preco,
      reais: reais,
      kmPorLitro: kmL,
      reaisPorKm: rpk,
    );
  }

  static double? _num(Object? valor) {
    if (valor == null) return null;
    if (valor is num) return valor.toDouble();
    return double.tryParse('$valor'.trim().replaceAll(',', '.'));
  }
}

ResultadoViagem? calcularViagem({
  required double km,
  required double kmPorLitro,
  required double precoLitro,
}) {
  if (km <= 0 || km > 5000) return null;
  if (kmPorLitro < 5 || kmPorLitro > 80) return null;
  if (precoLitro < 2 || precoLitro > 20) return null;

  final litros = km / kmPorLitro;
  return ResultadoViagem(litros: litros, reais: litros * precoLitro);
}

/// Tanque cheio × km/l. Litros entre 2 e 40 (Pop até big trail).
double? autonomiaKm({
  required double tanqueLitros,
  required double kmPorLitro,
}) {
  if (tanqueLitros < 2 || tanqueLitros > 40) return null;
  if (kmPorLitro < 5 || kmPorLitro > 80) return null;
  return tanqueLitros * kmPorLitro;
}

bool? cabeNoTanque({
  required double litrosViagem,
  required double tanqueLitros,
}) {
  if (tanqueLitros < 2 || tanqueLitros > 40) return null;
  if (litrosViagem <= 0) return null;
  return litrosViagem <= tanqueLitros;
}

/// km do painel no posto − km da ficha = km rodados; ÷ litros = km/l.
ConsumoAbastecimento? consumoDoPainel({
  required double kmAnterior,
  required double kmPainel,
  required double litros,
}) {
  final kmRodados = kmPainel - kmAnterior;
  if (kmRodados <= 0 || kmRodados > 2000) return null;
  if (litros < 0.5 || litros > 40) return null;

  final consumo = kmRodados / litros;
  if (consumo < 5 || consumo > 80) return null;
  return ConsumoAbastecimento(kmRodados: kmRodados, kmPorLitro: consumo);
}

/// Compatível com testes antigos: só o km/l.
double? kmPorLitroReal({
  required double kmAnterior,
  required double kmPainel,
  required double litros,
}) {
  return consumoDoPainel(
    kmAnterior: kmAnterior,
    kmPainel: kmPainel,
    litros: litros,
  )?.kmPorLitro;
}

/// Litros × preço do litro neste posto. Mesma faixa da viagem (R$ 2–20).
double? reaisDoAbastecimento({
  required double litros,
  required double precoLitro,
}) {
  if (litros < 0.5 || litros > 40) return null;
  if (precoLitro < 2 || precoLitro > 20) return null;
  return litros * precoLitro;
}

double? reaisPorKm({required double reais, required double kmRodados}) {
  if (reais <= 0 || kmRodados <= 0) return null;
  return reais / kmRodados;
}

/// Preço do litro ÷ km/l = R$/km daquele combustível.
double? custoPorKmCombustivel({
  required double precoLitro,
  required double kmPorLitro,
}) {
  if (precoLitro < 2 || precoLitro > 20) return null;
  if (kmPorLitro < 5 || kmPorLitro > 80) return null;
  return precoLitro / kmPorLitro;
}

/// Qual bomba está mais barata por km. Null = falta dado; empate = os dois.
Combustivel? combustivelMaisBarato({
  required double precoGasolina,
  required double precoAlcool,
  required double kmLitroGasolina,
  required double kmLitroAlcool,
}) {
  final gas = custoPorKmCombustivel(
    precoLitro: precoGasolina,
    kmPorLitro: kmLitroGasolina,
  );
  final alcool = custoPorKmCombustivel(
    precoLitro: precoAlcool,
    kmPorLitro: kmLitroAlcool,
  );
  if (gas == null || alcool == null) return null;
  if ((gas - alcool).abs() < 0.005) return null;
  return alcool < gas ? Combustivel.alcool : Combustivel.gasolina;
}

String? textoDicaFlex({
  required double precoGasolina,
  required double precoAlcool,
  required double kmLitroGasolina,
  required double kmLitroAlcool,
}) {
  final gas = custoPorKmCombustivel(
    precoLitro: precoGasolina,
    kmPorLitro: kmLitroGasolina,
  );
  final alcool = custoPorKmCombustivel(
    precoLitro: precoAlcool,
    kmPorLitro: kmLitroAlcool,
  );
  if (gas == null || alcool == null) return null;
  final g = gas.toStringAsFixed(2).replaceAll('.', ',');
  final a = alcool.toStringAsFixed(2).replaceAll('.', ',');
  if ((gas - alcool).abs() < 0.005) {
    return 'Ambos custam R\$ $g/km.';
  }
  if (alcool < gas) {
    return 'Álcool custa menos hoje, R\$ $a/km, gasolina R\$ $g/km.';
  }
  return 'Gasolina custa menos hoje, R\$ $g/km, álcool R\$ $a/km.';
}

/// Próxima troca = km da última + intervalo (óleo ~3–6 mil, corrente ~1 mil).
double? kmDaProximaTroca({
  required double kmUltima,
  required double intervaloKm,
}) {
  if (kmUltima < 0 || kmUltima > 999999) return null;
  if (intervaloKm < 100 || intervaloKm > 20000) return null;
  return kmUltima + intervaloKm;
}

/// Positivo = km que faltam; negativo = km atrasados.
int? kmAteATroca({required double kmAtual, required double kmProxima}) {
  if (kmAtual < 0 || kmProxima <= 0) return null;
  return (kmProxima - kmAtual).round();
}

/// Soma dos reais ÷ soma dos km dos registros com intervalo. Um número,
/// não planilha. O primeiro abastecimento fica de fora.
double? custoMedioPorKm(Iterable<RegistroAbastecimento> lista) {
  var km = 0.0;
  var reais = 0.0;
  for (final r in lista) {
    if (!r.temConsumo) continue;
    km += r.kmRodados;
    reais += r.reais;
  }
  return reaisPorKm(reais: reais, kmRodados: km);
}

/// O combustível que rodou o intervalo do registro [indice] é o que estava
/// no tanque, ou seja, o do abastecimento anterior. O histórico vem do mais
/// novo para o mais antigo. Null para o mais antigo (sem anterior).
Combustivel? combustivelDoIntervalo(
  List<RegistroAbastecimento> historico,
  int indice,
) {
  if (indice < 0 || indice + 1 >= historico.length) return null;
  return historico[indice + 1].combustivel;
}

/// Média ponderada do consumo com [noTanque]: soma dos km dividida pela
/// soma dos litros de todos os intervalos rodados com esse combustível.
/// Cada abastecimento novo refina o número. Null sem intervalo.
double? mediaKmPorLitro(
  List<RegistroAbastecimento> historico,
  Combustivel noTanque,
) {
  var km = 0.0;
  var litros = 0.0;
  for (var i = 0; i < historico.length; i++) {
    final r = historico[i];
    if (!r.temConsumo) continue;
    if (combustivelDoIntervalo(historico, i) != noTanque) continue;
    km += r.kmRodados;
    litros += r.litros;
  }
  if (km <= 0 || litros <= 0) return null;
  return km / litros;
}

/// Distância em linha reta (Haversine). Null se coordenadas inválidas,
/// pontos quase iguais ou acima de 5000 km (teto da viagem).
double? kmLinhaReta({
  required double latA,
  required double lngA,
  required double latB,
  required double lngB,
}) {
  if (!_coordOk(latA, lngA) || !_coordOk(latB, lngB)) return null;
  const raioKm = 6371.0;
  final dLat = _rad(latB - latA);
  final dLng = _rad(lngB - lngA);
  final a =
      math.sin(dLat / 2) * math.sin(dLat / 2) +
      math.cos(_rad(latA)) *
          math.cos(_rad(latB)) *
          math.sin(dLng / 2) *
          math.sin(dLng / 2);
  final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
  final km = raioKm * c;
  if (km < 0.1 || km > 5000) return null;
  return km;
}

bool _coordOk(double lat, double lng) =>
    lat >= -90 && lat <= 90 && lng >= -180 && lng <= 180;

double _rad(double graus) => graus * math.pi / 180;

/// Primeiro abastecimento: sem anterior não há intervalo. Guarda o km do
/// painel, os litros e o valor; consumo e custo por km ficam em zero.
RegistroAbastecimento? primeiroRegistroDoPosto({
  required double litros,
  required double precoLitro,
  required double kmPainel,
  required Combustivel combustivel,
  DateTime? agora,
}) {
  final reais = reaisDoAbastecimento(litros: litros, precoLitro: precoLitro);
  if (reais == null) return null;
  return RegistroAbastecimento(
    em: (agora ?? DateTime.now()).toIso8601String(),
    combustivel: combustivel,
    kmPainel: kmPainel,
    kmRodados: 0,
    litros: litros,
    precoLitro: precoLitro,
    reais: reais,
    kmPorLitro: 0,
    reaisPorKm: 0,
  );
}

RegistroAbastecimento? registroDoPosto({
  required ConsumoAbastecimento consumo,
  required double litros,
  required double precoLitro,
  required double kmPainel,
  required Combustivel combustivel,
  DateTime? agora,
}) {
  final reais = reaisDoAbastecimento(litros: litros, precoLitro: precoLitro);
  if (reais == null) return null;
  final rpk = reaisPorKm(reais: reais, kmRodados: consumo.kmRodados);
  if (rpk == null) return null;
  return RegistroAbastecimento(
    em: (agora ?? DateTime.now()).toIso8601String(),
    combustivel: combustivel,
    kmPainel: kmPainel,
    kmRodados: consumo.kmRodados,
    litros: litros,
    precoLitro: precoLitro,
    reais: reais,
    kmPorLitro: consumo.kmPorLitro,
    reaisPorKm: rpk,
  );
}
