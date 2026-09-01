import 'package:life_and_roads/api.dart';
import 'package:life_and_roads/core/sync/ficha_sync_store.dart';
import 'package:life_and_roads/features/auth/domain/auth_repository.dart';
import 'package:life_and_roads/features/ficha/data/ficha_conflito_store.dart';
import 'package:life_and_roads/features/ficha/data/ficha_local_datasource.dart';
import 'package:life_and_roads/features/ficha/data/ficha_remote_datasource.dart';
import 'package:life_and_roads/features/ficha/domain/ficha_moto.dart';
import 'package:life_and_roads/features/ficha/domain/ficha_repository.dart';
import 'package:life_and_roads/features/ficha/domain/usecases/detectar_conflito_ficha.dart';

class FichaRepositoryImpl implements FichaRepository {
  FichaRepositoryImpl({
    required FichaLocalDatasource local,
    required FichaRemoteDatasource remoto,
    required AuthRepository auth,
    required FichaSyncStore sync,
    FichaConflitoStore? conflito,
    DetectarConflitoFicha? detectar,
  })  : _local = local,
        _remoto = remoto,
        _auth = auth,
        _sync = sync,
        _conflito = conflito ?? FichaConflitoStore(),
        _detectar = detectar ?? DetectarConflitoFicha();

  final FichaLocalDatasource _local;
  final FichaRemoteDatasource _remoto;
  final AuthRepository _auth;
  final FichaSyncStore _sync;
  final FichaConflitoStore _conflito;
  final DetectarConflitoFicha _detectar;

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

    FichaMoto? remota;
    try {
      remota = await _remoto.buscar(sessao.token!);
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

    if (ficha == null) {
      if (remota != null) {
        await _local.gravar(remota);
        ficha = remota;
        await _sync.marcarSincronizado();
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

    await _conflito.limpar();
    if (meta.deveReenviar) {
      final envio = await _enviar(sessao.token!, ficha);
      offline = envio.offline;
      meta = await _sync.ler();
    } else {
      await _sync.marcarSincronizado();
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
    await _local.gravar(ficha);
    final sessao = await _auth.carregar();
    if (!sessao.logado) {
      return FichaSalva(
        ficha: ficha,
        mensagem:
            'Salvo neste aparelho. Use a conta para manter na troca de celular.',
        sync: await _sync.ler(),
      );
    }

    await _sync.marcarPendente();
    final envio = await _enviar(sessao.token!, ficha);
    final meta = await _sync.ler();
    if (envio.ok) {
      await _conflito.limpar();
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
      offline: true,
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
    final envio = await _enviar(sessao.token!, ficha);
    if (envio.ok) await _conflito.limpar();
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
    if (remota == null && sessao.logado) {
      try {
        remota = await _remoto.buscar(sessao.token!);
      } catch (_) {}
    }
    if (remota == null) return carregar();
    final mesclada = remota.copiarCom(
      psiDianteiro: remota.psiDianteiro ?? local?.psiDianteiro,
      psiTraseiro: remota.psiTraseiro ?? local?.psiTraseiro,
    );
    await _local.gravar(mesclada);
    await _sync.marcarSincronizado();
    await _conflito.limpar();
    return FichaCarregada(
      sessao: sessao,
      ficha: mesclada,
      sync: await _sync.ler(),
    );
  }

  Future<({bool ok, bool offline, String mensagem})> _enviar(
    String token,
    FichaMoto ficha,
  ) async {
    try {
      await _remoto.salvar(token, ficha);
      await _sync.marcarSincronizado();
      return (
        ok: true,
        offline: false,
        mensagem: '',
      );
    } on FalhaApi catch (e) {
      await _sync.marcarFalhou(e.mensagem);
      return (ok: false, offline: true, mensagem: e.mensagem);
    } catch (_) {
      const msg = 'API fora do ar. A ficha ficou só neste aparelho.';
      await _sync.marcarFalhou(msg);
      return (ok: false, offline: true, mensagem: msg);
    }
  }
}
