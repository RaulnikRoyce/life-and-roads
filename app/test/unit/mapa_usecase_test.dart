import 'package:flutter_test/flutter_test.dart';
import 'package:life_and_roads/features/mapa/domain/usecases/acrescentar_pino.dart';
import 'package:life_and_roads/features/mapa/domain/usecases/remover_pino.dart';
import 'package:life_and_roads/features/mapa/presentation/camada_osm.dart';
import 'package:life_and_roads/mapa/pins.dart';

void main() {
  const acrescentar = AcrescentarPino();
  const remover = RemoverPino();

  test('pino posto entra na lista; tipo estranho não', () {
    final ok = acrescentar.executar(
      atuais: const [],
      tipo: 'posto',
      latitude: -23.5,
      longitude: -46.6,
    );
    expect(ok, isNotNull);
    expect(ok, hasLength(1));
    expect(ok!.first.tipo, 'posto');

    expect(
      acrescentar.executar(
        atuais: const [],
        tipo: 'casa',
        latitude: -23.5,
        longitude: -46.6,
      ),
      isNull,
    );
  });

  test('remover pino compara tipo e coordenada', () {
    const alvo = PinoMapa(tipo: 'oficina', latitude: -23.5, longitude: -46.6);
    const outro = PinoMapa(tipo: 'posto', latitude: -23.5, longitude: -46.6);
    final lista = remover.executar(atuais: [alvo, outro], alvo: alvo);
    expect(lista, hasLength(1));
    expect(lista.first.tipo, 'posto');
  });

  test('OSM isolado usa CARTO e o pacote do app', () {
    expect(CamadaOsm.urlTemplate, contains('cartocdn.com'));
    expect(CamadaOsm.userAgent, 'com.raulnik.life_and_roads');
    expect(CamadaOsm.urlTemplate.contains('google'), isFalse);
  });
}
