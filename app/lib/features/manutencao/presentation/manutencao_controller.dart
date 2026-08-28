import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:life_and_roads/features/ficha/presentation/ficha_controller.dart';
import 'package:life_and_roads/features/manutencao/data/manutencao_local_datasource.dart';
import 'package:life_and_roads/features/manutencao/data/manutencao_remote_datasource.dart';
import 'package:life_and_roads/features/manutencao/data/manutencao_repository_impl.dart';
import 'package:life_and_roads/features/manutencao/data/manutencao_sync_store.dart';
import 'package:life_and_roads/features/manutencao/domain/agenda_manutencao.dart';
import 'package:life_and_roads/features/manutencao/domain/manutencao_repository.dart';
import 'package:life_and_roads/features/manutencao/presentation/manutencao_estado.dart';
import 'package:life_and_roads/manutencao/extra.dart';
import 'package:life_and_roads/manutencao/servicos.dart';

final manutencaoLocalDatasourceProvider = Provider<ManutencaoLocalDatasource>(
  (_) => ManutencaoLocalDatasource(),
);

final manutencaoRemoteDatasourceProvider = Provider<ManutencaoRemoteDatasource>(
  (_) => ManutencaoRemoteDatasource(),
);

final manutencaoSyncStoreProvider = Provider<ManutencaoSyncStore>(
  (_) => ManutencaoSyncStore(),
);

final manutencaoRepositoryProvider = Provider<ManutencaoRepository>(
  (ref) => ManutencaoRepositoryImpl(
    local: ref.watch(manutencaoLocalDatasourceProvider),
    remoto: ref.watch(manutencaoRemoteDatasourceProvider),
    auth: ref.watch(authRepositoryProvider),
    fichaLocal: ref.watch(fichaLocalDatasourceProvider),
    sync: ref.watch(manutencaoSyncStoreProvider),
  ),
);

class ManutencaoController extends Notifier<ManutencaoEstado> {
  ManutencaoRepository get _repo => ref.read(manutencaoRepositoryProvider);

  @override
  ManutencaoEstado build() => const ManutencaoEstado();

  Future<void> carregar() async {
    state = state.copiarCom(
      carregando: true,
      limparErro: true,
      limparAviso: true,
    );
    final c = await _repo.carregar();
    state = ManutencaoEstado(
      carregando: false,
      agenda: c.agenda,
      remoto: c.remoto,
      extra: c.extra,
      servicos: c.servicos,
      kmAtual: c.kmAtual,
      offline: c.offline,
      sync: c.sync,
    );
  }

  Future<void> relerKm() async {
    final km = await _repo.lerKmDaFicha();
    state = state.copiarCom(kmAtual: km, limparKm: km == null);
  }

  Future<void> salvar(AgendaManutencao agenda, ManutencaoExtra extra) async {
    final erro = agenda.tentar();
    if (erro != null) {
      state = state.copiarCom(erro: erro, limparAviso: true);
      return;
    }
    final resultado = await _repo.salvar(agenda, extra);
    state = state.copiarCom(
      agenda: resultado.agenda,
      extra: resultado.extra,
      aviso: resultado.mensagem,
      offline: resultado.offline,
      sync: resultado.sync,
      limparErro: true,
    );
  }

  Future<void> acrescentarServico(RegistroServico registro) async {
    final lista = await _repo.acrescentarServico(registro);
    state = state.copiarCom(
      servicos: lista,
      aviso: 'Serviço neste aparelho.',
      limparErro: true,
    );
  }

  Future<void> manterLocal() async {
    final r = await _repo.manterLocal();
    state = state.copiarCom(
      agenda: r.agenda,
      extra: r.extra,
      servicos: r.servicos,
      limparRemoto: true,
      offline: r.offline,
      sync: r.sync,
      aviso: r.offline
          ? 'Datas neste aparelho. Reenvia quando a API voltar.'
          : 'Datas desta tela foram para o servidor.',
      limparErro: true,
    );
  }

  Future<void> usarRemoto() async {
    final r = await _repo.usarRemoto();
    state = state.copiarCom(
      agenda: r.agenda,
      extra: r.extra,
      servicos: r.servicos,
      limparRemoto: true,
      offline: r.offline,
      sync: r.sync,
      aviso: 'Datas do servidor neste aparelho. Km e CNH ficaram.',
      limparErro: true,
    );
  }
}

final manutencaoControllerProvider =
    NotifierProvider<ManutencaoController, ManutencaoEstado>(
  ManutencaoController.new,
);
