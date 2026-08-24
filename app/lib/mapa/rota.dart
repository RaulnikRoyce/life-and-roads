import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

/// Rota de moto/carro em estrada. Sem seta, sem voz: só km e o traçado.
class RotaEstrada {
  const RotaEstrada({required this.km, required this.pontos});

  final double km;
  final List<LatLng> pontos;
}

/// Lê a resposta JSON do OSRM (`geometries=geojson`).
RotaEstrada? rotaDeOsrm(Object? bruto) {
  if (bruto is! Map) return null;
  if ('${bruto['code']}' != 'Ok') return null;
  final rotas = bruto['routes'];
  if (rotas is! List || rotas.isEmpty) return null;
  final primeira = rotas.first;
  if (primeira is! Map) return null;
  final metros = (primeira['distance'] as num?)?.toDouble();
  if (metros == null) return null;
  final km = metros / 1000;
  if (km < 0.1 || km > 5000) return null;

  final geo = primeira['geometry'];
  final coords = geo is Map ? geo['coordinates'] : null;
  if (coords is! List) return null;
  final pontos = <LatLng>[];
  for (final c in coords) {
    if (c is! List || c.length < 2) continue;
    final lng = (c[0] as num?)?.toDouble();
    final lat = (c[1] as num?)?.toDouble();
    if (lat == null || lng == null) continue;
    if (lat < -90 || lat > 90 || lng < -180 || lng > 180) continue;
    pontos.add(LatLng(lat, lng));
  }
  if (pontos.length < 2) return null;
  return RotaEstrada(km: km, pontos: pontos);
}

Uri urlRotaOsrm({required LatLng origem, required LatLng destino}) {
  final de = '${origem.longitude},${origem.latitude}';
  final para = '${destino.longitude},${destino.latitude}';
  return Uri.parse(
    'https://router.project-osrm.org/route/v1/driving/$de;$para'
    '?overview=simplified&geometries=geojson',
  );
}

/// Pedido à rede. Null se offline, timeout ou rota inexistente.
Future<RotaEstrada?> buscarRotaEstrada({
  required LatLng origem,
  required LatLng destino,
  http.Client? cliente,
}) async {
  final httpCliente = cliente ?? http.Client();
  final fechar = cliente == null;
  try {
    final resp = await httpCliente
        .get(
          urlRotaOsrm(origem: origem, destino: destino),
          headers: const {
            'User-Agent': 'life.and.roads/1.0',
            'Accept': 'application/json',
          },
        )
        .timeout(const Duration(seconds: 10));
    if (resp.statusCode < 200 || resp.statusCode >= 300) return null;
    return rotaDeOsrm(jsonDecode(resp.body));
  } catch (_) {
    return null;
  } finally {
    if (fechar) httpCliente.close();
  }
}
