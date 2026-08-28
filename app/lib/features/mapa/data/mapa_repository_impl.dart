import 'package:latlong2/latlong.dart';
import 'package:life_and_roads/features/auth/domain/auth_repository.dart';
import 'package:life_and_roads/features/mapa/data/localizacao_remote_datasource.dart';
import 'package:life_and_roads/features/mapa/data/pins_local_datasource.dart';
import 'package:life_and_roads/features/mapa/data/ponto_local_datasource.dart';
import 'package:life_and_roads/features/mapa/domain/mapa_repository.dart';
import 'package:life_and_roads/mapa/pins.dart';

class MapaRepositoryImpl implements MapaRepository {
  MapaRepositoryImpl({
    required PontoLocalDatasource ponto,
    required PinsLocalDatasource pins,
    required LocalizacaoRemoteDatasource remoto,
    required AuthRepository auth,
  })  : _ponto = ponto,
        _pins = pins,
        _remoto = remoto,
        _auth = auth;

  final PontoLocalDatasource _ponto;
  final PinsLocalDatasource _pins;
  final LocalizacaoRemoteDatasource _remoto;
  final AuthRepository _auth;

  DateTime? _ultimoEnvio;

  @override
  Future<LatLng?> carregarPonto() async {
    var ponto = await _ponto.ler();
    final sessao = await _auth.carregar();
    if (!sessao.logado) return ponto;
    try {
      final remota = await _remoto.buscar(sessao.token!);
      if (remota != null) {
        await _ponto.gravar(remota);
        return remota;
      }
    } catch (_) {
      // fica o local
    }
    return ponto;
  }

  @override
  Future<void> guardarPonto(LatLng ponto, {bool forcarRede = false}) async {
    await _ponto.gravar(ponto);
    final agora = DateTime.now();
    final cedo = _ultimoEnvio != null &&
        agora.difference(_ultimoEnvio!) < const Duration(seconds: 15);
    if (cedo && !forcarRede) return;

    final sessao = await _auth.carregar();
    if (!sessao.logado) return;
    _ultimoEnvio = agora;
    try {
      await _remoto.salvar(sessao.token!, ponto);
    } catch (_) {
      // o ponto já está neste aparelho
    }
  }

  @override
  Future<List<PinoMapa>> carregarPins() => _pins.listar();

  @override
  Future<List<PinoMapa>> salvarPins(List<PinoMapa> pins) => _pins.gravar(pins);
}
