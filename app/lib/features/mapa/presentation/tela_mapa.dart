import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:life_and_roads/features/mapa/presentation/camada_osm.dart';
import 'package:life_and_roads/features/mapa/presentation/mapa_controller.dart';
import 'package:life_and_roads/mapa/pins.dart';
import 'package:life_and_roads/mapa/ponto.dart';
import 'package:life_and_roads/tema.dart';

/// O celular é o rastreador. OSM isolado. Só o último ponto.
class TelaMapa extends ConsumerStatefulWidget {
  const TelaMapa({super.key});

  @override
  ConsumerState<TelaMapa> createState() => _TelaMapaState();
}

class _TelaMapaState extends ConsumerState<TelaMapa> {
  final _mapa = MapController();
  StreamSubscription<Position>? _fluxo;

  MapaController get _ctrl => ref.read(mapaControllerProvider.notifier);

  @override
  void initState() {
    super.initState();
    Future<void>.microtask(() {
      if (mounted) _ctrl.carregar();
    });
  }

  @override
  void dispose() {
    _fluxo?.cancel();
    super.dispose();
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

  Future<bool> _pedirPermissao() async {
    final motivo = await ref.read(permissaoGpsProvider).recusar(web: kIsWeb);
    if (motivo != null) {
      _aviso(motivo);
      return false;
    }
    return true;
  }

  Future<void> _rastrear() async {
    if (!await _pedirPermissao()) return;

    await _fluxo?.cancel();
    _ctrl.marcarRastreando(true);
    _fluxo = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 8,
      ),
    ).listen((pos) {
      final ponto = LatLng(pos.latitude, pos.longitude);
      _ctrl.aoGps(ponto);
      _irPara(ponto, 16);
    }, onError: (_) {
      _aviso('Não deu para ler o GPS.');
      _parar();
    });
  }

  Future<void> _parar() async {
    await _fluxo?.cancel();
    _fluxo = null;
    await _ctrl.parar(enviarUltimo: true);
  }

  void _aviso(String texto) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(texto)));
  }

  Future<void> _aoSegurar(TapPosition _, LatLng ponto) async {
    final tipo = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Oficina.couro,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.local_gas_station, color: Oficina.latao),
              title: const Text('Posto'),
              onTap: () => Navigator.pop(ctx, 'posto'),
            ),
            ListTile(
              leading: const Icon(Icons.build, color: Oficina.latao),
              title: const Text('Oficina'),
              onTap: () => Navigator.pop(ctx, 'oficina'),
            ),
          ],
        ),
      ),
    );
    if (tipo == null) return;
    await _ctrl.acrescentarPin(tipo: tipo, ponto: ponto);
  }

  Future<void> _apagarPin(PinoMapa pin) async {
    final nome = pin.tipo == 'posto' ? 'este posto' : 'esta oficina';
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Oficina.couro,
        title: Text('Apagar $nome?'),
        content: const Text('Só some neste aparelho.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Apagar'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    await _ctrl.removerPin(pin);
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(mapaControllerProvider, (anterior, atual) {
      if (anterior?.carregando == true &&
          !atual.carregando &&
          atual.ponto != null) {
        _irPara(atual.ponto!, 15);
      }
    });

    final estado = ref.watch(mapaControllerProvider);
    final ponto = estado.ponto;
    final pins = estado.pins;
    final rastreando = estado.rastreando;

    return Column(
      children: [
        Expanded(
          child: FlutterMap(
            mapController: _mapa,
            options: MapOptions(
              initialCenter: ponto ?? brasilCentro,
              initialZoom: ponto == null ? 4 : 15,
              onLongPress: _aoSegurar,
            ),
            children: [
              const CamadaOsm(),
              MarkerLayer(
                markers: [
                  if (ponto != null)
                    Marker(
                      point: ponto,
                      width: 44,
                      height: 44,
                      child: const Icon(
                        Icons.two_wheeler,
                        color: Oficina.latao,
                        size: 38,
                      ),
                    ),
                  for (final pin in pins)
                    Marker(
                      point: pin.ponto,
                      width: 44,
                      height: 44,
                      child: GestureDetector(
                        onTap: () => _apagarPin(pin),
                        child: Icon(
                          pin.tipo == 'posto'
                              ? Icons.local_gas_station
                              : Icons.build,
                          color: Oficina.creme,
                          size: 34,
                        ),
                      ),
                    ),
                ],
              ),
              const CreditoOsm(),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
          child: CartaoOficina(
            child: Column(
              children: [
                Text(
                  ponto == null
                      ? 'Nenhum ponto ainda. Rastrear usa o GPS deste aparelho. '
                          'Toque longo: posto ou oficina.'
                      : 'Último ponto: ${ponto.latitude.toStringAsFixed(5)}, '
                          '${ponto.longitude.toStringAsFixed(5)}. '
                          'Toque longo: posto ou oficina. Toque no pino para apagar.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: rastreando ? _parar : _rastrear,
                    child: Text(rastreando ? 'Parar' : 'Rastrear'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
