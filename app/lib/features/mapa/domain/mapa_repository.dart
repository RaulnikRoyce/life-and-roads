import 'package:latlong2/latlong.dart';
import 'package:life_and_roads/mapa/pins.dart';

abstract class MapaRepository {
  Future<LatLng?> carregarPonto();
  Future<void> guardarPonto(LatLng ponto, {bool forcarRede = false});
  Future<List<PinoMapa>> carregarPins();
  Future<List<PinoMapa>> salvarPins(List<PinoMapa> pins);
}
