import 'package:life_and_roads/api.dart';
import 'package:life_and_roads/features/auth/domain/auth_repository.dart';
import 'package:life_and_roads/features/ficha/data/ficha_local_datasource.dart';
import 'package:life_and_roads/features/manutencao/data/agenda_conflito_store.dart';
import 'package:life_and_roads/features/manutencao/data/manutencao_local_datasource.dart';
import 'package:life_and_roads/features/manutencao/data/manutencao_remote_datasource.dart';
import 'package:life_and_roads/features/manutencao/data/manutencao_sync_store.dart';
import 'package:life_and_roads/features/manutencao/domain/agenda_manutencao.dart';
import 'package:life_and_roads/features/manutencao/domain/manutencao_repository.dart';
import 'package:life_and_roads/features/manutencao/domain/usecases/detectar_conflito_agenda.dart';
import 'package:life_and_roads/manutencao/extra.dart';
import 'package:life_and_roads/manutencao/regras.dart';
import 'package:life_and_roads/manutencao/servicos.dart';

class ManutencaoRepositoryImpl implements ManutencaoRepository {
  ManutencaoRepositoryImpl({
    required ManutencaoLocalDatasource local,
    required ManutencaoRemoteDatasource remoto,
    required AuthRepository auth,
    required FichaLocalDatasource fichaLocal,
    required ManutencaoSyncStore sync,
    AgendaConflitoStore? conflito,
    DetectarConflitoAgenda? detectar,
  })  : _local = local,
        _remoto = remoto,
        _auth = auth,
        _fichaLocal = fichaLocal,
        _sync = sync,
        _conflito = conflito ?? AgendaConflitoStore(),
        _detectar = detectar ?? DetectarConflitoAgenda();

  final ManutencaoLocalDatasource _local;
  final ManutencaoRemoteDatasource _remoto;
  final AuthRepository _auth;
  final FichaLocalDatasource _fichaLocal;
  final ManutencaoSyncStore _sync;
  final AgendaConflitoStore _conflito;
  final DetectarConflitoAgenda _detectar;

  Future<ManutencaoCarregada> _base({
    required AgendaManutencao agenda,
    required ManutencaoExtra extra,
    AgendaManutencao? remoto,
    bool offline = false,
  }) async {
    return ManutencaoCarregada(
      agenda: agenda,
      extra: extra,
      remoto: remoto,
      servicos: await HistoricoServico.carregar(),
      kmAtual: (await _fichaLocal.ler())?.kmAtual,
      offline: offline,
      sync: await _sync.ler(),
    );
  }

  @override
  Future<ManutencaoCarregada> carregar() async {
    final sessao = await _auth.carregar();
    var agenda = (await _local.lerAgenda()).normalizarAnuais();
    final extra = _normalizarCnh(await _local.lerExtra());
    var snapshot = await _conflito.ler();

    if (!sessao.logado) {
      return _base(agenda: agenda, extra: extra, remoto: snapshot);
    }

    AgendaManutencao? remota;
    var offline = false;
    try {
      remota = await _remoto.buscar(sessao.token!);
      if (remota != null) remota = remota.normalizarAnuais();
    } on FalhaApi {
      offline = true;
    } catch (_) {
      offline = true;
    }

    if (offline) {
      return _base(
        agenda: agenda,
        extra: extra,
        remoto: snapshot,
        offline: true,
      );
    }

    var meta = await _sync.ler();

    if (remota == null) {
      if (meta.deveReenviar) {
        final envio = await _enviar(sessao.token!, agenda);
        return _base(
          agenda: agenda,
          extra: extra,
          offline: envio.offline,
        );
      }
      return _base(agenda: agenda, extra: extra);
    }

    if (agenda.vazia) {
      agenda = remota;
      await _local.gravarAgenda(agenda);
      await _sync.marcarSincronizado();
      await _conflito.limpar();
      return _base(agenda: agenda, extra: extra);
    }

    if (_detectar.executar(agenda, remota)) {
      await _sync.marcarConflito();
      await _conflito.gravar(remota);
      return _base(agenda: agenda, extra: extra, remoto: remota);
    }

    await _conflito.limpar();
    if (meta.deveReenviar) {
      final envio = await _enviar(sessao.token!, agenda);
      return _base(
        agenda: agenda,
        extra: extra,
        offline: envio.offline,
      );
    }
    await _sync.marcarSincronizado();
    return _base(agenda: agenda, extra: extra);
  }

  @override
  Future<double?> lerKmDaFicha() async {
    return (await _fichaLocal.ler(recarregar: true))?.kmAtual;
  }

  @override
  Future<ManutencaoSalva> salvar(
    AgendaManutencao agenda,
    ManutencaoExtra extra,
  ) async {
    final normal = agenda.normalizarAnuais();
    final extraNorm = _normalizarCnh(extra);
    await _local.gravarAgenda(normal);
    await _local.gravarExtra(extraNorm);

    final sessao = await _auth.carregar();
    if (!sessao.logado) {
      return ManutencaoSalva(
        agenda: normal,
        extra: extraNorm,
        mensagem: 'Salva neste aparelho. Entre na Ficha para ir ao servidor.',
        sync: await _sync.ler(),
      );
    }

    await _sync.marcarPendente();
    final envio = await _enviar(sessao.token!, normal);
    final meta = await _sync.ler();
    if (envio.ok) {
      await _conflito.limpar();
      return ManutencaoSalva(
        agenda: normal,
        extra: extraNorm,
        sincronizada: true,
        mensagem:
            'Manutenção no servidor. Km, serviço e CNH ficam neste aparelho.',
        sync: meta,
      );
    }
    return ManutencaoSalva(
      agenda: normal,
      extra: extraNorm,
      offline: true,
      mensagem: envio.mensagem,
      sync: meta,
    );
  }

  @override
  Future<List<RegistroServico>> acrescentarServico(RegistroServico registro) {
    return HistoricoServico.acrescentar(registro);
  }

  @override
  Future<ManutencaoCarregada> manterLocal() async {
    final sessao = await _auth.carregar();
    final agenda = (await _local.lerAgenda()).normalizarAnuais();
    final extra = _normalizarCnh(await _local.lerExtra());
    if (!sessao.logado) {
      await _conflito.limpar();
      await _sync.marcarSincronizado();
      return _base(agenda: agenda, extra: extra);
    }
    final envio = await _enviar(sessao.token!, agenda);
    if (envio.ok) await _conflito.limpar();
    return _base(
      agenda: agenda,
      extra: extra,
      offline: envio.offline,
    );
  }

  @override
  Future<ManutencaoCarregada> usarRemoto() async {
    final sessao = await _auth.carregar();
    final extra = _normalizarCnh(await _local.lerExtra());
    var remota = await _conflito.ler();
    if (remota == null && sessao.logado) {
      try {
        remota = await _remoto.buscar(sessao.token!);
      } catch (_) {}
    }
    if (remota == null) return carregar();
    final normal = remota.normalizarAnuais();
    await _local.gravarAgenda(normal);
    await _sync.marcarSincronizado();
    await _conflito.limpar();
    return _base(agenda: normal, extra: extra);
  }

  ManutencaoExtra _normalizarCnh(ManutencaoExtra extra) {
    final iso = extra.cnhProxima;
    if (iso == null || iso.length < 10) return extra;
    final d = DateTime.tryParse(iso.substring(0, 10));
    if (d == null) return extra;
    final n = proximaCnh(d, cincoAnos: extra.cnhCincoAnos);
    final m = n.month.toString().padLeft(2, '0');
    final dia = n.day.toString().padLeft(2, '0');
    return extra.copiarCom(cnhProxima: '${n.year}-$m-$dia');
  }

  Future<({bool ok, bool offline, String mensagem})> _enviar(
    String token,
    AgendaManutencao agenda,
  ) async {
    try {
      await _remoto.salvar(token, agenda);
      await _sync.marcarSincronizado();
      return (ok: true, offline: false, mensagem: '');
    } on FalhaApi catch (e) {
      await _sync.marcarFalhou(e.mensagem);
      return (ok: false, offline: true, mensagem: e.mensagem);
    } catch (_) {
      const msg = 'API fora do ar. Ficou só neste aparelho.';
      await _sync.marcarFalhou(msg);
      return (ok: false, offline: true, mensagem: msg);
    }
  }
}
