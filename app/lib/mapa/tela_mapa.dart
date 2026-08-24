import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:life_and_roads/api.dart';
import 'package:life_and_roads/mapa/pins.dart';
import 'package:life_and_roads/mapa/ponto.dart';
import 'package:life_and_roads/tema.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// O celular é o rastreador. OSM, sem chave do Google. Só o último ponto.
class TelaMapa extends StatefulWidget {
  const TelaMapa({super.key});

  @override
  State<TelaMapa> createState() => _TelaMapaState();
}

class _TelaMapaState extends State<TelaMapa> {
  final _mapa = MapController();
  StreamSubscription<Position>? _fluxo;
  LatLng? _ponto;
  List<PinoMapa> _pins = [];
  bool _rastreando = false;
  DateTime? _ultimoEnvio;

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  @override
  void dispose() {
    _fluxo?.cancel();
    super.dispose();
  }

  Future<void> _carregar() async {
    _ponto = await carregarUltimoPonto();
    _pins = await PinsMapa.carregar();
    final prefs = await SharedPreferences.getInstance();

    final token = prefs.getString(ApiCaderneta.chaveToken);
    if (token != null && token.isNotEmpty) {
      try {
        final remota = await ApiCaderneta.buscarLocalizacao(token);
        if (remota != null) {
          _ponto = LatLng(
            (remota['latitude'] as num).toDouble(),
            (remota['longitude'] as num).toDouble(),
          );
        }
      } catch (_) {
        // fica o local
      }
    }

    if (mounted) {
      setState(() {});
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        final p = _ponto;
        if (p == null) return;
        try {
          _mapa.move(p, 15);
        } catch (_) {
          // mapa ainda não montou: o initialCenter cobre
        }
      });
    }
  }

  Future<void> _guardar(LatLng ponto, {bool forcarRede = false}) async {
    await salvarUltimoPonto(ponto);
    final prefs = await SharedPreferences.getInstance();

    final agora = DateTime.now();
    final cedo = _ultimoEnvio != null &&
        agora.difference(_ultimoEnvio!) < const Duration(seconds: 15);
    if (cedo && !forcarRede) return;

    _ultimoEnvio = agora;
    final token = prefs.getString(ApiCaderneta.chaveToken);
    if (token == null || token.isEmpty) return;
    try {
      await ApiCaderneta.salvarLocalizacao(
        token,
        latitude: ponto.latitude,
        longitude: ponto.longitude,
      );
    } catch (_) {
      // o ponto já está neste aparelho
    }
  }

  Future<bool> _pedirPermissao() async {
    final ligado = await Geolocator.isLocationServiceEnabled();
    if (!ligado) {
      _aviso(
        kIsWeb
            ? 'Ligue a localização do aparelho (ou permita no Chrome).'
            : 'Ligue o GPS deste celular.',
      );
      return false;
    }

    var perm = await Geolocator.checkPermission();
    if (perm == LocationPermission.denied) {
      perm = await Geolocator.requestPermission();
    }
    if (perm == LocationPermission.denied ||
        perm == LocationPermission.deniedForever) {
      _aviso(
        kIsWeb
            ? 'Sem permissão de localização. No Chrome, aceite o pedido do site.'
            : 'Sem permissão de localização. Autorize o GPS para o app.',
      );
      return false;
    }
    return true;
  }

  Future<void> _rastrear() async {
    if (!await _pedirPermissao()) return;

    await _fluxo?.cancel();
    _fluxo = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 8,
      ),
    ).listen((pos) {
      final ponto = LatLng(pos.latitude, pos.longitude);
      setState(() => _ponto = ponto);
      _mapa.move(ponto, 16);
      _guardar(ponto);
    }, onError: (_) {
      _aviso('Não deu para ler o GPS.');
      _parar();
    });

    setState(() => _rastreando = true);
  }

  Future<void> _parar() async {
    await _fluxo?.cancel();
    _fluxo = null;
    setState(() => _rastreando = false);
    final p = _ponto;
    if (p != null) await _guardar(p, forcarRede: true);
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
    final lista = [..._pins, PinoMapa(tipo: tipo, latitude: ponto.latitude, longitude: ponto.longitude)];
    final salvos = await PinsMapa.salvar(lista);
    if (!mounted) return;
    setState(() => _pins = salvos);
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
    final filtrado = _pins
        .where(
          (p) =>
              p.tipo != pin.tipo ||
              p.latitude != pin.latitude ||
              p.longitude != pin.longitude,
        )
        .toList();
    final salvos = await PinsMapa.salvar(filtrado);
    if (!mounted) return;
    setState(() => _pins = salvos);
  }

  @override
  Widget build(BuildContext context) {
    final ponto = _ponto;

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
              TileLayer(
                urlTemplate:
                    'https://basemaps.cartocdn.com/dark_all/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.raulnik.life_and_roads',
              ),
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
                    for (final pin in _pins)
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
              const SimpleAttributionWidget(
                source: Text('OSM · CARTO'),
              ),
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
                    onPressed: _rastreando ? _parar : _rastrear,
                    child: Text(_rastreando ? 'Parar' : 'Rastrear'),
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
