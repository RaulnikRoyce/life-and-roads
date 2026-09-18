import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:life_and_roads/backup.dart';
import 'package:life_and_roads/core/security/sessao_segura.dart';
import 'package:life_and_roads/core/sync/ficha_sync_store.dart';
import 'package:life_and_roads/core/sync/status_sync.dart';
import 'package:life_and_roads/features/manutencao/data/manutencao_sync_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../helpers/banco_teste.dart';

final _backup = jsonEncode({
  'v': 2,
  'ficha': jsonEncode({'marca': 'Honda', 'modelo': 'Bros', 'kmLitro': '35'}),
  'manutencao': jsonEncode({'oleoUltima': '2026-01-10'}),
  'servicos': [],
  'abastecimentos': [],
  'pins': [],
});

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await abrirBancoTeste();
  });

  tearDown(fecharBancoTeste);

  test('restaurar com conta marca ficha e agenda como pendentes', () async {
    await SessaoSegura().gravar(token: 'access', refresh: 'refresh');

    expect(await BackupCaderneta.restaurar(_backup), isNull);

    expect((await FichaSyncStore().ler()).status, StatusSync.pending);
    expect((await ManutencaoSyncStore().ler()).status, StatusSync.pending);
  });

  test('restaurar sem conta não cria fila de sync', () async {
    expect(await BackupCaderneta.restaurar(_backup), isNull);

    expect((await FichaSyncStore().ler()).status, StatusSync.synced);
    expect((await ManutencaoSyncStore().ler()).status, StatusSync.synced);
  });
}
