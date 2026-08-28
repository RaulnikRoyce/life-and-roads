import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import 'package:life_and_roads/features/ficha/presentation/ficha_controller.dart';
import 'package:life_and_roads/features/mapa/data/localizacao_remote_datasource.dart';
import 'package:life_and_roads/features/mapa/data/mapa_repository_impl.dart';
import 'package:life_and_roads/features/mapa/data/pins_local_datasource.dart';
import 'package:life_and_roads/features/mapa/data/ponto_local_datasource.dart';
import 'package:life_and_roads/features/mapa/data/servico_permissao_gps.dart';
import 'package:life_and_roads/features/mapa/domain/mapa_repository.dart';
import 'package:life_and_roads/features/mapa/domain/usecases/acrescentar_pino.dart';
import 'package:life_and_roads/features/mapa/domain/usecases/remover_pino.dart';
import 'package:life_and_roads/features/mapa/presentation/mapa_estado.dart';
import 'package:life_and_roads/mapa/pins.dart';

final pontoLocalDatasourceProvider = Provider<PontoLocalDatasource>(
  (_) => PontoLocalDatasource(),
);

final pinsLocalDatasourceProvider = Provider<PinsLocalDatasource>(
  (_) => PinsLocalDatasource(),
);

final localizacaoRemoteDatasourceProvider =
    Provider<LocalizacaoRemoteDatasource>(
  (_) => LocalizacaoRemoteDatasource(),
);

final permissaoGpsProvider = Provider<ConsultaPermissaoGps>(
  (_) => ServicoPermissaoGps(),
);

final mapaRepositoryProvider = Provider<MapaRepository>(
  (ref) => MapaRepositoryImpl(
    ponto: ref.watch(pontoLocalDatasourceProvider),
    pins: ref.watch(pinsLocalDatasourceProvider),
    remoto: ref.watch(localizacaoRemoteDatasourceProvider),
    auth: ref.watch(authRepositoryProvider),
  ),
);

class MapaController extends Notifier<MapaEstado> {
  MapaRepository get _repo => ref.read(mapaRepositoryProvider);

  @override
  MapaEstado build() => const MapaEstado();

  Future<void> carregar() async {
    state = state.copiarCom(carregando: true, limparAviso: true);
    final ponto = await _repo.carregarPonto();
    final pins = await _repo.carregarPins();
    state = MapaEstado(
      carregando: false,
      ponto: ponto,
      pins: pins,
    );
  }

  Future<void> aoGps(LatLng ponto) async {
    state = state.copiarCom(ponto: ponto, rastreando: true);
    await _repo.guardarPonto(ponto);
  }

  void marcarRastreando(bool ligado) {
    state = state.copiarCom(rastreando: ligado);
  }

  Future<void> parar({required bool enviarUltimo}) async {
    state = state.copiarCom(rastreando: false);
    final ponto = state.ponto;
    if (enviarUltimo && ponto != null) {
      await _repo.guardarPonto(ponto, forcarRede: true);
    }
  }

  Future<void> acrescentarPin({
    required String tipo,
    required LatLng ponto,
  }) async {
    const use = AcrescentarPino();
    final lista = use.executar(
      atuais: state.pins,
      tipo: tipo,
      latitude: ponto.latitude,
      longitude: ponto.longitude,
    );
    if (lista == null) return;
    final salvos = await _repo.salvarPins(lista);
    state = state.copiarCom(pins: salvos);
  }

  Future<void> removerPin(PinoMapa pin) async {
    const use = RemoverPino();
    final lista = use.executar(atuais: state.pins, alvo: pin);
    final salvos = await _repo.salvarPins(lista);
    state = state.copiarCom(pins: salvos);
  }
}

final mapaControllerProvider =
    NotifierProvider<MapaController, MapaEstado>(MapaController.new);
