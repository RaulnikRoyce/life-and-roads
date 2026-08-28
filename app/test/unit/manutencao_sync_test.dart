import 'package:flutter_test/flutter_test.dart';
import 'package:life_and_roads/api.dart';
import 'package:life_and_roads/core/sync/status_sync.dart';
import 'package:life_and_roads/features/auth/data/auth_local_datasource.dart';
import 'package:life_and_roads/features/auth/data/auth_remote_datasource.dart';
import 'package:life_and_roads/features/auth/data/auth_repository_impl.dart';
import 'package:life_and_roads/features/ficha/data/ficha_local_datasource.dart';
import 'package:life_and_roads/features/manutencao/data/manutencao_local_datasource.dart';
import 'package:life_and_roads/features/manutencao/data/manutencao_remote_datasource.dart';
import 'package:life_and_roads/features/manutencao/data/manutencao_repository_impl.dart';
import 'package:life_and_roads/features/manutencao/data/manutencao_sync_store.dart';
import 'package:life_and_roads/features/manutencao/domain/agenda_manutencao.dart';
import 'package:life_and_roads/manutencao/extra.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../helpers/banco_teste.dart';

class _RemotoFake implements ManutencaoRemoteDatasource {
  AgendaManutencao? remota;
  bool falhar = false;
  int salvamentos = 0;

  @override
  Future<AgendaManutencao?> buscar(String token) async {
    if (falhar) {
      throw FalhaApi('API fora do ar. Ficou só neste aparelho.');
    }
    return remota;
  }

  @override
  Future<void> salvar(String token, AgendaManutencao agenda) async {
    if (falhar) {
      throw FalhaApi('API fora do ar. Ficou só neste aparelho.');
    }
    salvamentos++;
    remota = agenda;
  }
}

void main() {
  late _RemotoFake remoto;
  late ManutencaoRepositoryImpl repo;

  final agenda = AgendaManutencao(
    oleoUltima: DateTime(2026, 1, 10),
    oleoProxima: DateTime(2026, 7, 10),
  );

  setUp(() async {
    SharedPreferences.setMockInitialValues({
      'token_life_and_roads': 'abc',
      'email_life_and_roads': 'a@b.c',
    });
    await abrirBancoTeste();
    remoto = _RemotoFake();
    repo = ManutencaoRepositoryImpl(
      local: ManutencaoLocalDatasource(),
      remoto: remoto,
      auth: AuthRepositoryImpl(
        local: AuthLocalDatasource(),
        remoto: AuthRemoteDatasource(),
      ),
      fichaLocal: FichaLocalDatasource(),
      sync: ManutencaoSyncStore(),
    );
  });

  tearDown(() async {
    await fecharBancoTeste();
  });

  test('falha de rede deixa a agenda failed e o retry envia', () async {
    remoto.falhar = true;
    final salva = await repo.salvar(agenda, const ManutencaoExtra());
    expect(salva.offline, isTrue);
    expect(salva.sync.status, StatusSync.failed);
    expect(remoto.salvamentos, 0);

    remoto.falhar = false;
    final carregada = await repo.carregar();
    expect(carregada.offline, isFalse);
    expect(carregada.sync.status, StatusSync.synced);
    expect(remoto.salvamentos, 1);
    expect(carregada.agenda.oleoUltima, DateTime(2026, 1, 10));
  });

  test('pending em conflito se o GET remoto divergir', () async {
    remoto.falhar = true;
    await repo.salvar(agenda, const ManutencaoExtra());
    remoto.falhar = false;
    remoto.remota = AgendaManutencao(
      oleoUltima: DateTime(2025, 1, 1),
      oleoProxima: DateTime(2025, 7, 1),
    );

    final carregada = await repo.carregar();
    expect(carregada.agenda.oleoUltima, DateTime(2026, 1, 10));
    expect(remoto.salvamentos, 0);
    expect(carregada.sync.status, StatusSync.conflict);
    expect(carregada.remoto?.oleoUltima, DateTime(2025, 1, 1));
  });

  test('km e CNH ficam no extra local', () async {
    remoto.falhar = false;
    const extra = ManutencaoExtra(
      oleoKmUltima: 10000,
      cnhProxima: '2030-03-15',
    );
    await repo.salvar(agenda, extra);
    final carregada = await repo.carregar();
    expect(carregada.extra.oleoKmUltima, 10000);
    expect(carregada.extra.cnhProxima, '2030-03-15');
    expect(remoto.remota?.oleoUltima, DateTime(2026, 1, 10));
  });
}
