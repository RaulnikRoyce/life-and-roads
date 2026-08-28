import 'dart:convert';

import 'package:latlong2/latlong.dart';
import 'package:life_and_roads/core/database/armazem_kv.dart';
import 'package:life_and_roads/core/database/chaves_kv.dart';

/// Último GPS deste aparelho. A aba Mapa e o destino da viagem leem daqui.
const chaveUltimoPonto = ChavesKv.ponto;

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
  return pontoDeJson(await ArmazemKv.lerTexto(chaveUltimoPonto));
}

Future<void> salvarUltimoPonto(LatLng ponto) {
  return ArmazemKv.gravarTexto(
    chaveUltimoPonto,
    jsonEncode({
      'latitude': ponto.latitude,
      'longitude': ponto.longitude,
    }),
  );
}
