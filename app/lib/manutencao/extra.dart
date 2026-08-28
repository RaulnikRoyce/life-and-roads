import 'dart:convert';

import 'package:life_and_roads/core/database/armazem_kv.dart';
import 'package:life_and_roads/core/database/chaves_kv.dart';

/// Óleo e corrente por km + CNH (só a data). Local, sem placa.
class ManutencaoExtra {
  const ManutencaoExtra({
    this.oleoKmUltima,
    this.oleoKmIntervalo = 4000,
    this.correnteKmUltima,
    this.correnteKmIntervalo = 1000,
    this.cnhProxima,
    this.cnhCincoAnos = false,
  });

  final double? oleoKmUltima;
  final double oleoKmIntervalo;
  final double? correnteKmUltima;
  final double correnteKmIntervalo;
  final String? cnhProxima;

  /// true = renova em 5 anos; false = 10.
  final bool cnhCincoAnos;

  static const chave = ChavesKv.extra;

  ManutencaoExtra copiarCom({
    double? oleoKmUltima,
    bool limparOleoKm = false,
    double? oleoKmIntervalo,
    double? correnteKmUltima,
    bool limparCorrenteKm = false,
    double? correnteKmIntervalo,
    String? cnhProxima,
    bool limparCnh = false,
    bool? cnhCincoAnos,
  }) {
    return ManutencaoExtra(
      oleoKmUltima: limparOleoKm ? null : (oleoKmUltima ?? this.oleoKmUltima),
      oleoKmIntervalo: oleoKmIntervalo ?? this.oleoKmIntervalo,
      correnteKmUltima:
          limparCorrenteKm ? null : (correnteKmUltima ?? this.correnteKmUltima),
      correnteKmIntervalo: correnteKmIntervalo ?? this.correnteKmIntervalo,
      cnhProxima: limparCnh ? null : (cnhProxima ?? this.cnhProxima),
      cnhCincoAnos: cnhCincoAnos ?? this.cnhCincoAnos,
    );
  }

  Map<String, dynamic> paraJson() => {
        'oleoKmUltima': oleoKmUltima,
        'oleoKmIntervalo': oleoKmIntervalo,
        'correnteKmUltima': correnteKmUltima,
        'correnteKmIntervalo': correnteKmIntervalo,
        'cnhProxima': cnhProxima,
        'cnhCincoAnos': cnhCincoAnos,
      };

  static ManutencaoExtra deJson(Object? bruto) {
    if (bruto is! Map) return const ManutencaoExtra();
    final mapa = Map<String, dynamic>.from(bruto);
    return ManutencaoExtra(
      oleoKmUltima: _num(mapa['oleoKmUltima']),
      oleoKmIntervalo: _num(mapa['oleoKmIntervalo']) ?? 4000,
      correnteKmUltima: _num(mapa['correnteKmUltima']),
      correnteKmIntervalo: _num(mapa['correnteKmIntervalo']) ?? 1000,
      cnhProxima: '${mapa['cnhProxima'] ?? ''}'.trim().isEmpty
          ? null
          : '${mapa['cnhProxima']}'.trim(),
      cnhCincoAnos: mapa['cnhCincoAnos'] == true,
    );
  }

  static double? _num(Object? valor) {
    if (valor == null) return null;
    if (valor is num) return valor.toDouble();
    return double.tryParse('$valor'.trim().replaceAll(',', '.'));
  }

  static Future<ManutencaoExtra> carregar() async {
    final bruto = await ArmazemKv.lerTexto(chave);
    if (bruto == null) return const ManutencaoExtra();
    try {
      return deJson(jsonDecode(bruto));
    } on FormatException {
      return const ManutencaoExtra();
    }
  }

  static Future<void> salvar(ManutencaoExtra extra) {
    return ArmazemKv.gravarTexto(chave, jsonEncode(extra.paraJson()));
  }
}
