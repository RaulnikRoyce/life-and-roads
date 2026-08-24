import 'dart:convert';

import 'package:latlong2/latlong.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Último GPS deste aparelho. A aba Mapa e o destino da viagem leem daqui.
const chaveUltimoPonto = 'ultimo_ponto_v1';

const brasilCentro = LatLng(-14.235, -51.9253);

LatLng? pontoDeJson(String? bruto) {
  if (bruto == null) return null;
  try {
    final mapa = jsonDecode(bruto);
    if (mapa is! Map<String, dynamic>) return null;
    final lat = (mapa['latitude'] as num?)?.toDouble();
    final lng = (mapa['longitude'] as num?)?.toDouble();
    if (lat == null || lng == null) return null;
    if (lat < -90 || lat > 90 || lng < -180 || lng > 180) return null;
    return LatLng(lat, lng);
  } on FormatException {
    return null;
  }
}

Future<LatLng?> carregarUltimoPonto() async {
  final prefs = await SharedPreferences.getInstance();
  return pontoDeJson(prefs.getString(chaveUltimoPonto));
}

Future<void> salvarUltimoPonto(LatLng ponto) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString(
    chaveUltimoPonto,
    jsonEncode({
      'latitude': ponto.latitude,
      'longitude': ponto.longitude,
    }),
  );
}
