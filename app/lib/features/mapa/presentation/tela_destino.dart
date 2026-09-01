import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:life_and_roads/features/mapa/presentation/camada_osm.dart';
import 'package:life_and_roads/features/mapa/presentation/mapa_controller.dart';
import 'package:life_and_roads/mapa/ponto.dart';
import 'package:life_and_roads/mapa/rota.dart';
import 'package:life_and_roads/tema.dart';

/// Toque no destino. Origem = GPS agora ou último ponto. Km de estrada.
class TelaDestino extends ConsumerStatefulWidget {
  const TelaDestino({super.key});

  @override
  ConsumerState<TelaDestino> createState() => _TelaDestinoState();
}

class _TelaDestinoState extends ConsumerState<TelaDestino> {
  final _mapa = MapController();
  LatLng? _origem;
  LatLng? _destino;
  RotaEstrada? _rota;
  bool _buscandoGps = true;
  bool _buscandoRota = false;
  int _pedido = 0;

  @override
  void initState() {
    super.initState();
    _prepararOrigem();
  }

  Future<void> _prepararOrigem() async {
    final salvo = await ref.read(mapaRepositoryProvider).carregarPonto();
    if (mounted && salvo != null) {
      setState(() {
        _origem = salvo;
        _buscandoGps = true;
      });
      _irPara(salvo, 15);
    }

    final gps = await _gpsAgora();
    if (!mounted) return;
    setState(() {
      if (gps != null) _origem = gps;
      _buscandoGps = false;
    });
    if (gps != null) {
      await ref.read(mapaRepositoryProvider).guardarPonto(gps);
      if (_destino == null) _irPara(gps, 15);
    }
  }

  Future<LatLng?> _gpsAgora() async {
    if (!await _pedirPermissao()) return null;
    try {
      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
          timeLimit: Duration(seconds: 6),
        ),
      );
      return LatLng(pos.latitude, pos.longitude);
    } on TimeoutException {
      return null;
    } catch (_) {
      return null;
    }
  }

  Future<bool> _pedirPermissao() async {
    final ligado = await Geolocator.isLocationServiceEnabled();
    if (!ligado) return false;

    var perm = await Geolocator.checkPermission();
    if (perm == LocationPermission.denied) {
      perm = await Geolocator.requestPermission();
    }
    return perm != LocationPermission.denied &&
        perm != LocationPermission.deniedForever;
  }

  void _irPara(LatLng ponto, double zoom) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      try {
        _mapa.move(ponto, zoom);
      } catch (_) {
        // mapa ainda não montou
      }
    });
  }

  Future<void> _aoToque(TapPosition _, LatLng ponto) async {
    final origem = _origem;
    if (origem == null) {
      _aviso(
        kIsWeb
            ? 'Sem origem. Permita a localização no Chrome ou rastreie no Mapa.'
            : 'Sem origem. Ligue o GPS ou rastreie no Mapa primeiro.',
      );
      return;
    }

    final id = ++_pedido;
    setState(() {
      _destino = ponto;
      _rota = null;
      _buscandoRota = true;
    });

    final rota = await buscarRotaEstrada(origem: origem, destino: ponto);
    if (!mounted || id != _pedido) return;
    if (rota == null) {
      setState(() => _buscandoRota = false);
      _aviso('Sem km de estrada agora. Digite os km na Viagem.');
      return;
    }

    setState(() {
      _rota = rota;
      _buscandoRota = false;
    });
    _encaixar(rota.pontos);
  }

  void _encaixar(List<LatLng> pontos) {
    if (pontos.length < 2) return;
    try {
      _mapa.fitCamera(
        CameraFit.coordinates(
          coordinates: pontos,
          padding: const EdgeInsets.fromLTRB(48, 48, 48, 140),
        ),
      );
    } catch (_) {
      // mapa ainda não montou
    }
  }

  void _usar() {
    final km = _rota?.km;
    if (km == null) return;
    Navigator.pop(context, km);
  }

  void _aviso(String texto) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(texto)));
  }

  String _textoKm(double km) {
    if (km < 10) return '${km.toStringAsFixed(1).replaceAll('.', ',')} km';
    return '${km.toStringAsFixed(0)} km';
  }

  String get _legenda {
    if (_origem == null) {
      return _buscandoGps
          ? 'Procurando o GPS…'
          : 'Sem origem. Rastreie no Mapa ou permita a localização.';
    }
    if (_buscandoRota) return 'Buscando a estrada…';
    if (_destino == null) {
      return 'Selecione o destino no mapa. Usa km de estrada.';
    }
    final km = _rota?.km;
    if (km == null) {
      return 'Rota indisponível. Toque novamente ou volte e digite os km.';
    }
    return 'Estrada ${_textoKm(km)}. Sem navegação, só o número da viagem.';
  }

  @override
  Widget build(BuildContext context) {
    final origem = _origem;
    final destino = _destino;
    final rota = _rota;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Destino'),
      ),
      body: Column(
        children: [
          Expanded(
            child: FlutterMap(
              mapController: _mapa,
              options: MapOptions(
                initialCenter: origem ?? brasilCentro,
                initialZoom: origem == null ? 4 : 15,
                onTap: _aoToque,
              ),
              children: [
                const CamadaOsm(),
                if (rota != null)
                  PolylineLayer(
                    polylines: [
                      Polyline(
                        points: rota.pontos,
                        color: Oficina.latao,
                        strokeWidth: 4,
                      ),
                    ],
                  ),
                MarkerLayer(
                  markers: [
                    if (origem != null)
                      Marker(
                        point: origem,
                        width: 44,
                        height: 44,
                        child: const Icon(
                          Icons.two_wheeler,
                          color: Oficina.latao,
                          size: 38,
                        ),
                      ),
                    if (destino != null)
                      Marker(
                        point: destino,
                        width: 44,
                        height: 44,
                        child: const Icon(
                          Icons.place,
                          color: Oficina.creme,
                          size: 38,
                        ),
                      ),
                  ],
                ),
                const CreditoOsm(texto: 'OSM · CARTO · OSRM'),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
            child: Column(
              children: [
                if (_buscandoRota)
                  const Padding(
                    padding: EdgeInsets.only(bottom: 10),
                    child: LinearProgressIndicator(),
                  ),
                Text(
                  _legenda,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Oficina.tinta),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: rota == null ? null : _usar,
                    child: const Text('Usar estes km'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
