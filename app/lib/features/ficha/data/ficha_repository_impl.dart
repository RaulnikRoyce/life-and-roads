import 'package:life_and_roads/core/database/caderneta_banco.dart';
import 'package:life_and_roads/api.dart';
import 'package:life_and_roads/core/sync/ficha_sync_store.dart';
import 'package:life_and_roads/core/sync/lido_do_servidor.dart';
import 'package:life_and_roads/features/auth/domain/auth_repository.dart';
import 'package:life_and_roads/features/ficha/data/ficha_conflito_store.dart';
import 'package:life_and_roads/features/ficha/data/ficha_local_datasource.dart';
import 'package:life_and_roads/features/ficha/data/ficha_remote_datasource.dart';
import 'package:life_and_roads/features/ficha/domain/ficha_moto.dart';
import 'package:life_and_roads/features/ficha/domain/ficha_repository.dart';
import 'package:life_and_roads/features/ficha/domain/usecases/detectar_conflito_ficha.dart';

class FichaRepositoryImpl implements FichaRepository {
  FichaRepositoryImpl({
    required this._local,
    required this._remoto,
    required this._auth,
    required this._sync,
    FichaConflitoStore? conflito,
    DetectarConflitoFicha? detectar,
  }) : _conflito = conflito ?? FichaConflitoStore(),
       _detectar = detectar ?? DetectarConflitoFicha();

  final FichaLocalDatasource _local;
  final FichaRemoteDatasource _remoto;
  final AuthRepository _auth;
  final FichaSyncStore _sync;
  final FichaConflitoStore _conflito;
  final DetectarConflitoFicha _detectar;

  @override
  Future<FichaCarregada> carregarLocal() async {
    final sessao = await _auth.carregar();
    return FichaCarregada(
      sessao: sessao,
      ficha: await _local.ler(),
      remoto: await _conflito.ler(),
      sync: await _sync.ler(),
    );
  }

  @override
  Future<FichaCarregada> carregar() async {
    final sessao = await _auth.carregar();
    var ficha = await _local.ler();
    var offline = false;
    var meta = await _sync.ler();
    FichaMoto? snapshot = await _conflito.ler();

    if (!sessao.logado) {
      return FichaCarregada(
        sessao: sessao,
        ficha: ficha,
        remoto: snapshot,
        sync: meta,
      );
    }

    LidoDoServidor<FichaMoto>? lida;
    try {
      lida = await _remoto.buscar(sessao.token!);
    } on FalhaApi {
      offline = true;
    } catch (_) {
      offline = true;
    }

    if (offline) {
      return FichaCarregada(
        sessao: sessao,
        ficha: ficha,
        remoto: snapshot,
        offline: true,
        sync: meta,
      );
    }

    final remota = lida?.dado;
    if (ficha == null) {
      if (remota != null) {
        await _local.gravar(remota);
        ficha = remota;
        await _sync.marcarSincronizado(carimbo: lida?.atualizadoEm);
        await _conflito.limpar();
        meta = await _sync.ler();
      }
      return FichaCarregada(sessao: sessao, ficha: ficha, sync: meta);
    }

    if (remota == null) {
      if (meta.deveReenviar) {
        final envio = await _enviar(sessao.token!, ficha);
        offline = envio.offline;
        meta = await _sync.ler();
      }
      return FichaCarregada(
        sessao: sessao,
        ficha: ficha,
        offline: offline,
        sync: meta,
      );
    }

    if (_detectar.executar(ficha, remota)) {
      // Diverge. Se há alteração local pendente e o servidor ainda está no
      // carimbo que guardamos, ninguém mexeu lá: é só o pending deste
      // aparelho. Sobe sem perguntar (ADR 0018). Fora disso, pergunta.
      final soLocalMudou =
          meta.deveReenviar &&
          mesmoCarimbo(lida?.atualizadoEm, meta.remoteUpdatedAt);
      if (!soLocalMudou) {
        await _sync.marcarConflito();
        await _conflito.gravar(remota);
        meta = await _sync.ler();
        return FichaCarregada(
          sessao: sessao,
          ficha: ficha,
          remoto: remota,
          sync: meta,
        );
      }
    }

    await _conflito.limpar();
    if (meta.deveReenviar) {
      final envio = await _enviar(sessao.token!, ficha);
      offline = envio.offline;
      meta = await _sync.ler();
    } else {
      await _sync.marcarSincronizado(carimbo: lida?.atualizadoEm);
      meta = await _sync.ler();
    }
    return FichaCarregada(
      sessao: sessao,
      ficha: ficha,
      offline: offline,
      sync: meta,
    );
  }

  @override
  Future<FichaSalva> salvar(FichaMoto ficha) async {
    final sessao = await _auth.carregar();
    final versao = await CadernetaBanco.instancia.transaction(() async {
      await _local.gravar(ficha);
      if (sessao.logado) await _sync.marcarPendente();
      return (await _sync.ler()).localUpdatedAt;
    });
    if (!sessao.logado) {
      return FichaSalva(
        ficha: ficha,
        mensagem: 'Salvo neste aparelho. Use a conta para manter na troca de celular.',
        sync: await _sync.ler(),
      );
    }

    final envio = await _enviar(sessao.token!, ficha, localEm: versao);
    final meta = await _sync.ler();
    if (envio.ok) {
      return FichaSalva(
        ficha: ficha,
        sincronizada: true,
        mensagem:
            'Ficha no servidor. Trocar de celular: entre com o mesmo e-mail.',
        sync: meta,
      );
    }
    return FichaSalva(
      ficha: ficha,
      offline: envio.offline,
      mensagem: envio.mensagem,
      sync: meta,
    );
  }

  @override
  Future<FichaCarregada> manterLocal() async {
    final sessao = await _auth.carregar();
    final ficha = await _local.ler();
    if (ficha == null) return carregar();
    if (!sessao.logado) {
      await _conflito.limpar();
      await _sync.marcarSincronizado();
      return carregar();
    }
    final envio = await _enviar(sessao.token!, ficha, substituir: true);
    return FichaCarregada(
      sessao: sessao,
      ficha: ficha,
      offline: envio.offline,
      sync: await _sync.ler(),
    );
  }

  @override
  Future<FichaCarregada> usarRemoto() async {
    final sessao = await _auth.carregar();
    final local = await _local.ler();
    var remota = await _conflito.ler();
    DateTime? carimbo;
    if (remota == null && sessao.logado) {
      try {
        final lida = await _remoto.buscar(sessao.token!);
        remota = lida?.dado;
        carimbo = lida?.atualizadoEm;
      } catch (_) {}
    }
    if (remota == null) return carregar();
    final mesclada = remota.copiarCom(
      psiDianteiro: remota.psiDianteiro ?? local?.psiDianteiro,
      psiTraseiro: remota.psiTraseiro ?? local?.psiTraseiro,
    );
    await _local.gravar(mesclada);
    // Vindo do snapshot de conflito não há carimbo; o próximo carregar()
    // (local == remoto) grava o carimbo certo.
    await _sync.marcarSincronizado(carimbo: carimbo);
    await _conflito.limpar();
    return FichaCarregada(
      sessao: sessao,
      ficha: mesclada,
      sync: await _sync.ler(),
    );
  }

  Future<({bool ok, bool offline, String mensagem})> _enviar(
    String token,
    FichaMoto ficha, {
    DateTime? localEm,
    bool substituir = false,
  }) async {
    final versao = localEm ?? (await _sync.ler()).localUpdatedAt;
    try {
      final base = substituir
          ? (await _remoto.buscar(token))?.atualizadoEm
          : (await _sync.ler()).remoteUpdatedAt;
      final carimbo = await _remoto.salvar(
        token,
        ficha,
        baseAtualizadoEm: base?.toUtc().toIso8601String() ?? 'null',
      );
      final confirmou = await CadernetaBanco.instancia.transaction(() async {
        if ((await _sync.ler()).localUpdatedAt != versao) return false;
        await _sync.marcarSincronizado(carimbo: carimbo, seLocalEm: versao);
        await _conflito.limpar();
        return true;
      });
      return (ok: confirmou, offline: false, mensagem: '');
    } on ConflitoSync catch (e) {
      LidoDoServidor<FichaMoto>? remoto;
      try {
        remoto = await _remoto.buscar(token);
      } catch (_) {}
      await CadernetaBanco.instancia.transaction(() async {
        if ((await _sync.ler()).localUpdatedAt != versao) return;
        if (remoto != null) await _conflito.gravar(remoto.dado);
        await _sync.marcarConflito(seLocalEm: versao);
      });
      return (ok: false, offline: false, mensagem: e.mensagem);
    } on FalhaApi catch (e) {
      await _sync.marcarFalhou(e.mensagem, seLocalEm: versao);
      return (ok: false, offline: true, mensagem: e.mensagem);
    } catch (_) {
      const msg = 'API fora do ar. A ficha ficou só neste aparelho.';
      await _sync.marcarFalhou(msg, seLocalEm: versao);
      return (ok: false, offline: true, mensagem: msg);
    }
  }
}
