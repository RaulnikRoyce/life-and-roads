import 'package:flutter_test/flutter_test.dart';
import 'package:life_and_roads/api.dart';
import 'package:life_and_roads/core/sync/ficha_sync_store.dart';
import 'package:life_and_roads/core/sync/status_sync.dart';
import 'package:life_and_roads/features/auth/data/auth_local_datasource.dart';
import 'package:life_and_roads/features/auth/data/auth_remote_datasource.dart';
import 'package:life_and_roads/features/auth/data/auth_repository_impl.dart';
import 'package:life_and_roads/features/ficha/data/ficha_local_datasource.dart';
import 'package:life_and_roads/features/ficha/data/ficha_remote_datasource.dart';
import 'package:life_and_roads/features/ficha/data/ficha_repository_impl.dart';
import 'package:life_and_roads/features/ficha/domain/ficha_moto.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../helpers/banco_teste.dart';

class _RemotoFake implements FichaRemoteDatasource {
  FichaMoto? remota;
  bool falhar = false;
  int salvamentos = 0;

  @override
  Future<FichaMoto?> buscar(String token) async {
    if (falhar) throw FalhaApi('API fora do ar. A ficha ficou só neste aparelho.');
    return remota;
  }

  @override
  Future<void> salvar(String token, FichaMoto ficha) async {
    if (falhar) {
      throw FalhaApi('API fora do ar. A ficha ficou só neste aparelho.');
    }
    salvamentos++;
    remota = ficha;
  }
}

void main() {
  late _RemotoFake remoto;
  late FichaRepositoryImpl repo;

  const ficha = FichaMoto(
    marca: 'Honda',
    modelo: 'Bros',
    kmLitro: 35,
    kmAtual: 1000,
  );

  setUp(() async {
    SharedPreferences.setMockInitialValues({
      'token_life_and_roads': 'abc',
      'email_life_and_roads': 'a@b.c',
    });
    await abrirBancoTeste();
    remoto = _RemotoFake();
    repo = FichaRepositoryImpl(
      local: FichaLocalDatasource(),
      remoto: remoto,
      auth: AuthRepositoryImpl(
        local: AuthLocalDatasource(),
        remoto: AuthRemoteDatasource(),
      ),
      sync: FichaSyncStore(),
    );
  });

  tearDown(() async {
    await fecharBancoTeste();
  });

  test('falha de rede deixa a ficha pending e o retry envia', () async {
    remoto.falhar = true;
    final salva = await repo.salvar(ficha);
    expect(salva.offline, isTrue);
    expect(salva.sync.status, StatusSync.failed);
    expect(remoto.salvamentos, 0);

    remoto.falhar = false;
    final carregada = await repo.carregar();
    expect(carregada.offline, isFalse);
    expect(carregada.sync.status, StatusSync.synced);
    expect(remoto.salvamentos, 1);
    expect(remoto.remota?.modelo, 'Bros');
  });

  test('pending em conflito se o GET remoto divergir', () async {
    remoto.falhar = true;
    await repo.salvar(ficha);
    remoto.falhar = false;
    remoto.remota = const FichaMoto(
      marca: 'Yamaha',
      modelo: 'Fazer',
      kmLitro: 40,
      kmAtual: 2000,
    );

    final carregada = await repo.carregar();
    expect(carregada.ficha?.modelo, 'Bros');
    expect(carregada.remoto?.modelo, 'Fazer');
    expect(remoto.salvamentos, 0);
    expect(carregada.sync.status, StatusSync.conflict);
  });

  test('manter neste aparelho envia o local', () async {
    remoto.falhar = true;
    await repo.salvar(ficha);
    remoto.falhar = false;
    remoto.remota = const FichaMoto(
      marca: 'Yamaha',
      modelo: 'Fazer',
      kmLitro: 40,
      kmAtual: 2000,
    );
    await repo.carregar();
    final ok = await repo.manterLocal();
    expect(ok.ficha?.modelo, 'Bros');
    expect(ok.sync.status, StatusSync.synced);
    expect(remoto.salvamentos, 1);
    expect(remoto.remota?.modelo, 'Bros');
  });

  test('usar o servidor traz a remota e preserva PSI', () async {
    const local = FichaMoto(
      marca: 'Honda',
      modelo: 'Bros',
      kmLitro: 35,
      kmAtual: 1000,
      psiDianteiro: 32,
    );
    remoto.falhar = true;
    await repo.salvar(local);
    remoto.falhar = false;
    remoto.remota = const FichaMoto(
      marca: 'Yamaha',
      modelo: 'Fazer',
      kmLitro: 40,
      kmAtual: 2000,
    );
    await repo.carregar();
    final ok = await repo.usarRemoto();
    expect(ok.ficha?.modelo, 'Fazer');
    expect(ok.ficha?.psiDianteiro, 32);
    expect(ok.sync.status, StatusSync.synced);
  });

  test('sem ficha local o GET preenche', () async {
    remoto.remota = ficha;
    final carregada = await repo.carregar();
    expect(carregada.ficha?.modelo, 'Bros');
    expect(carregada.sync.status, StatusSync.synced);
  });
}
