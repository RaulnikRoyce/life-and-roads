import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:life_and_roads/mapa/rota.dart';

void main() {
  test('OSRM Ok vira km de estrada e o traçado', () {
    final rota = rotaDeOsrm({
      'code': 'Ok',
      'routes': [
        {
          'distance': 12340,
          'geometry': {
            'type': 'LineString',
            'coordinates': [
              [-46.63, -23.55],
              [-46.50, -23.50],
              [-43.17, -22.91],
            ],
          },
        },
      ],
    });
    expect(rota, isNotNull);
    expect(rota!.km, closeTo(12.34, 0.001));
    expect(rota.pontos, hasLength(3));
    expect(rota.pontos.first.latitude, closeTo(-23.55, 0.001));
    expect(rota.pontos.first.longitude, closeTo(-46.63, 0.001));
  });

  test('sem rota ou km fora da faixa não conta', () {
    expect(rotaDeOsrm({'code': 'NoRoute', 'routes': []}), isNull);
    expect(
      rotaDeOsrm({
        'code': 'Ok',
        'routes': [
          {
            'distance': 50,
            'geometry': {
              'coordinates': [
                [0, 0],
                [0.001, 0],
              ],
            },
          },
        ],
      }),
      isNull,
    );
  });

  test('URL do OSRM usa lng,lat', () {
    final uri = urlRotaOsrm(
      origem: const LatLng(-23.55, -46.63),
      destino: const LatLng(-22.91, -43.17),
    );
    expect(uri.path, contains('-46.63,-23.55;-43.17,-22.91'));
    expect(uri.queryParameters['geometries'], 'geojson');
  });
}
