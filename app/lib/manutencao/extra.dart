import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// Óleo e corrente por km + CNH (só a data). Local, sem placa.
class ManutencaoExtra {
  const ManutencaoExtra({
    this.oleoKmUltima,
    this.oleoKmIntervalo = 4000,
    this.correnteKmUltima,
    this.correnteKmIntervalo = 1000,
    this.cnhProxima,
  });

  final double? oleoKmUltima;
  final double oleoKmIntervalo;
  final double? correnteKmUltima;
  final double correnteKmIntervalo;
  final String? cnhProxima;

  static const chave = 'manutencao_km_v1';

  Map<String, dynamic> paraJson() => {
        'oleoKmUltima': oleoKmUltima,
        'oleoKmIntervalo': oleoKmIntervalo,
        'correnteKmUltima': correnteKmUltima,
        'correnteKmIntervalo': correnteKmIntervalo,
        'cnhProxima': cnhProxima,
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
    );
  }

  static double? _num(Object? valor) {
    if (valor == null) return null;
    if (valor is num) return valor.toDouble();
    return double.tryParse('$valor'.trim().replaceAll(',', '.'));
  }

  static Future<ManutencaoExtra> carregar() async {
    final prefs = await SharedPreferences.getInstance();
    final bruto = prefs.getString(chave);
    if (bruto == null) return const ManutencaoExtra();
    try {
      return deJson(jsonDecode(bruto));
    } on FormatException {
      return const ManutencaoExtra();
    }
  }

  static Future<void> salvar(ManutencaoExtra extra) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(chave, jsonEncode(extra.paraJson()));
  }
}
