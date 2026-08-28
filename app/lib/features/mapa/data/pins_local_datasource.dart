import 'package:life_and_roads/mapa/pins.dart';

class PinsLocalDatasource {
  Future<List<PinoMapa>> listar() => PinsMapa.carregar();

  Future<List<PinoMapa>> gravar(List<PinoMapa> pins) => PinsMapa.salvar(pins);
}
