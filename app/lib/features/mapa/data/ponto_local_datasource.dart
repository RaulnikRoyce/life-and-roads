import 'package:latlong2/latlong.dart';
import 'package:life_and_roads/mapa/ponto.dart';

class PontoLocalDatasource {
  Future<LatLng?> ler() => carregarUltimoPonto();

  Future<void> gravar(LatLng ponto) => salvarUltimoPonto(ponto);
}
