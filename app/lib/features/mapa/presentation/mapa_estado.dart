import 'package:latlong2/latlong.dart';
import 'package:life_and_roads/mapa/pins.dart';

class MapaEstado {
  const MapaEstado({
    this.carregando = true,
    this.ponto,
    this.pins = const [],
    this.rastreando = false,
    this.aviso,
    this.autonomiaKm,
  });

  final bool carregando;
  final LatLng? ponto;
  final List<PinoMapa> pins;
  final bool rastreando;
  final String? aviso;

  /// Tanque cheio × km/l da ficha. Raio do círculo de alcance.
  final double? autonomiaKm;

  MapaEstado copiarCom({
    bool? carregando,
    LatLng? ponto,
    bool limparPonto = false,
    List<PinoMapa>? pins,
    bool? rastreando,
    String? aviso,
    bool limparAviso = false,
    double? autonomiaKm,
  }) {
    return MapaEstado(
      carregando: carregando ?? this.carregando,
      ponto: limparPonto ? null : (ponto ?? this.ponto),
      pins: pins ?? this.pins,
      rastreando: rastreando ?? this.rastreando,
      aviso: limparAviso ? null : (aviso ?? this.aviso),
      autonomiaKm: autonomiaKm ?? this.autonomiaKm,
    );
  }
}
