import 'dart:convert';
import 'dart:io';

import 'package:drift/native.dart';
import 'package:drift/drift.dart' show DatabaseConnection;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:life_and_roads/api.dart';
import 'package:life_and_roads/core/database/caderneta_banco.dart';
import 'package:life_and_roads/core/database/caderneta_database.dart';
import 'package:life_and_roads/features/ficha/domain/ficha_repository.dart';
import 'package:life_and_roads/features/ficha/presentation/ficha_controller.dart';
import 'package:life_and_roads/features/manutencao/data/manutencao_sync_store.dart';

import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:life_and_roads/core/backup/backup_automatico.dart';
import 'package:life_and_roads/core/backup/pasta_download.dart';
import 'package:life_and_roads/core/sync/ficha_sync_store.dart';
import 'package:life_and_roads/core/sync/lido_do_servidor.dart';
import 'package:life_and_roads/features/auth/domain/auth_repository.dart';
import 'package:life_and_roads/features/auth/domain/sessao.dart';
import 'package:life_and_roads/features/ficha/data/ficha_repository_impl.dart';
import 'package:life_and_roads/features/ficha/data/ficha_local_datasource.dart';
import 'package:life_and_roads/features/ficha/data/ficha_remote_datasource.dart';
import 'package:life_and_roads/features/ficha/domain/ficha_moto.dart';

import '../helpers/banco_teste.dart';

class Pasta implements PastaDownload {
  final entrou = Completer<void>(), liberar = Completer<String?>();
  final escritos = <String>[];
  @override
  Future<String?> salvar({
    required String nome,
    required String conteudo,
  }) async {
    escritos.add(conteudo);
    if (escritos.length == 1) {
      entrou.complete();
      return liberar.future;
    }
    return 'backup';
  }
}

class Conta implements AuthRepository {
  @override
  Future<Sessao> carregar() async =>
      Sessao(token: 'teste', servidor: 'http://local');
  @override
  dynamic noSuchMethod(Invocation i) => super.noSuchMethod(i);
}

class Remoto implements FichaRemoteDatasource {
  final entrou = Completer<void>(), liberar = Completer<DateTime?>();
  int chamadas = 0;
  FichaMoto? ficha;
  @override
  Future<LidoDoServidor<FichaMoto>?> buscar(String t) async => null;
  @override
  Future<DateTime?> salvar(
    String t,
    FichaMoto f, {
    String? baseAtualizadoEm,
  }) async {
    chamadas++;
    if (chamadas == 1) {
      ficha = f;
      entrou.complete();
      return liberar.future;
    }
    throw Exception('rede indisponivel');
  }
}

class RepoControlado implements FichaRepository {
  final respostas = <Completer<FichaSalva>>[];
  @override
  Future<FichaSalva> salvar(FichaMoto ficha) {
    final c = Completer<FichaSalva>();
    respostas.add(c);
    return c.future;
  }

  @override
  dynamic noSuchMethod(Invocation i) => super.noSuchMethod(i);
}

class RemotoConflito extends Remoto {
  @override
  Future<LidoDoServidor<FichaMoto>?> buscar(String token) async =>
      LidoDoServidor(
        const FichaMoto(
          marca: 'Yamaha',
          modelo: 'Fazer',
          kmLitro: 40,
          kmAtual: 2000,
        ),
        atualizadoEm: DateTime.utc(2026, 11, 6),
      );
  @override
  Future<DateTime?> salvar(
    String token,
    FichaMoto ficha, {
    String? baseAtualizadoEm,
  }) async {
    throw ConflitoSync('Outro aparelho mudou.');
  }
}

class ConflitoDepoisDoPrimeiro extends Remoto {
  @override
  Future<DateTime?> salvar(String t, FichaMoto f, {String? baseAtualizadoEm}) {
    if (chamadas > 0) throw ConflitoSync('mudou');
    return super.salvar(t, f, baseAtualizadoEm: baseAtualizadoEm);
  }

  @override
  Future<LidoDoServidor<FichaMoto>?> buscar(String t) async => LidoDoServidor(
    const FichaMoto(
      marca: 'Yamaha',
      modelo: 'Fazer',
      kmLitro: 40,
      kmAtual: 2000,
    ),
  );
}

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await abrirBancoTeste();
  });
  tearDown(fecharBancoTeste);
  testWidgets('backup deve guardar mudanca ocorrida durante gravacao lenta', (
    tester,
  ) async {
    final pasta = Pasta();
    var local = 'v1';
    final auto = BackupAutomatico(
      pasta: pasta,
      exportar: () async => local,
      espera: const Duration(seconds: 3),
    );
    addTearDown(auto.descartar);
    final primeira = auto.gravarAgora();
    await tester.pump();
    expect(pasta.entrou.isCompleted, true);
    local = 'v2';
    auto.agendar();
    await tester.pump(const Duration(seconds: 4));
    pasta.liberar.complete('backup');
    await tester.pump();
    await primeira;
    await tester.pump(const Duration(seconds: 5));
    expect(
      pasta.escritos.last,
      'v2',
      reason:
          'a mudanca nao pode sumir ao disparar o timer durante uma gravacao',
    );
  });
  test(
    'resposta antiga nao pode limpar falha de envio da ficha mais nova',
    () async {
      final remoto = Remoto(), sync = FichaSyncStore();
      final local = FichaLocalDatasource();
      final repo = FichaRepositoryImpl(
        local: local,
        remoto: remoto,
        auth: Conta(),
        sync: sync,
      );
      const original = FichaMoto(
        marca: 'Honda',
        modelo: 'Bros',
        kmLitro: 35,
        kmAtual: 1000,
      );
      final primeira = repo.salvar(original);
      await remoto.entrou.future;
      await repo.salvar(original.copiarCom(kmAtual: 1100));
      expect((await sync.ler()).deveReenviar, true);
      remoto.liberar.complete(DateTime.utc(2026, 11, 6));
      await primeira;
      expect((await local.ler())!.kmAtual, 1100);
      expect(remoto.ficha!.kmAtual, 1000);
      expect(
        (await sync.ler()).deveReenviar,
        true,
        reason: '1100 ainda nao foi confirmado no servidor',
      );
    },
  );
  testWidgets(
    'backup repete a ultima versao mesmo se a primeira gravacao falhar',
    (tester) async {
      final pasta = Pasta();
      var local = 'v1';
      final auto = BackupAutomatico(pasta: pasta, exportar: () async => local);
      addTearDown(auto.descartar);
      final first = auto.gravarAgora();
      await tester.pump();
      local = 'v2';
      auto.agendar();
      auto.agendar();
      pasta.liberar.completeError(Exception('armazenamento ocupado'));
      await tester.pump();
      await first;
      await tester.pump();
      expect(pasta.escritos, ['v1', 'v2']);
    },
  );
  testWidgets(
    'descarte durante gravacao nao escreve novamente nem notifica objeto descartado',
    (tester) async {
      final pasta = Pasta();
      final auto = BackupAutomatico(pasta: pasta, exportar: () async => 'v1');
      final first = auto.gravarAgora();
      await tester.pump();
      auto.agendar();
      auto.descartar();
      pasta.liberar.complete('backup');
      await tester.pump();
      await first;
      expect(pasta.escritos.length, 1);
      expect(tester.takeException(), isNull);
    },
  );
  test(
    'confirmacao ou falha antiga nao altera metadados da versao nova',
    () async {
      final sync = FichaSyncStore();
      await sync.marcarPendente();
      final old = (await sync.ler()).localUpdatedAt!;
      await sync.marcarPendente();
      final latest = (await sync.ler()).localUpdatedAt!;
      expect(latest.isAfter(old), true);
      await sync.marcarSincronizado(
        carimbo: DateTime.utc(2026, 11, 6),
        seLocalEm: latest,
      );
      await sync.marcarFalhou('erro antigo', seLocalEm: old);
      expect((await sync.ler()).deveReenviar, false);
      final manutencao = ManutencaoSyncStore();
      await manutencao.marcarPendente();
      final mOld = (await manutencao.ler()).localUpdatedAt!;
      await manutencao.marcarPendente();
      final mLatest = (await manutencao.ler()).localUpdatedAt!;
      await manutencao.marcarFalhou('sem rede', seLocalEm: mLatest);
      await manutencao.marcarSincronizado(seLocalEm: mOld);
      expect((await manutencao.ler()).deveReenviar, true);
    },
  );
  test(
    'carimbo remoto completo e pendencia sobrevivem a reabrir o SQLite',
    () async {
      await fecharBancoTeste();
      final temp = await Directory.systemTemp.createTemp('lr-sync-test-');
      addTearDown(() async {
        await fecharBancoTeste();
        await temp.delete(recursive: true);
      });
      final file = File('${temp.path}/caderneta.sqlite');
      CadernetaBanco.usar(
        CadernetaDatabase(DatabaseConnection(NativeDatabase(file))),
      );
      final carimbo = DateTime.utc(2026, 11, 6, 12, 0, 0, 123);
      final sync = FichaSyncStore();
      await sync.marcarPendente();
      await sync.marcarSincronizado(carimbo: carimbo);
      await sync.marcarPendente();
      final before = await sync.ler();
      await fecharBancoTeste();
      CadernetaBanco.usar(
        CadernetaDatabase(DatabaseConnection(NativeDatabase(file))),
      );
      final after = await FichaSyncStore().ler();
      expect(after.remoteUpdatedAt, carimbo);
      expect(after.localUpdatedAt, before.localUpdatedAt);
      expect(after.deveReenviar, true);
    },
  );
  test('controller mantem a edicao mais nova quando a resposta antiga chega por ultimo', () async {
    final repo = RepoControlado();
    final container = ProviderContainer(
      overrides: [fichaRepositoryProvider.overrideWithValue(repo)],
    );
    addTearDown(container.dispose);
    final controller = container.read(fichaControllerProvider.notifier);
    const ficha = FichaMoto(
      marca: 'Honda',
      modelo: 'Bros',
      kmLitro: 35,
      kmAtual: 1000,
    );
    final old = controller.salvar(ficha);
    final latest = controller.salvar(ficha.copiarCom(kmAtual: 1100));
    repo.respostas[1].complete(
      FichaSalva(ficha: ficha.copiarCom(kmAtual: 1100), mensagem: 'nova'),
    );
    await latest;
    repo.respostas[0].complete(
      const FichaSalva(ficha: ficha, mensagem: 'antiga'),
    );
    await old;
    expect(container.read(fichaControllerProvider).ficha!.kmAtual, 1100);
  });
  test(
    'conflito de versao preserva o aparelho e guarda a escolha remota',
    () async {
      final sync = FichaSyncStore();
      final local = FichaLocalDatasource();
      final repo = FichaRepositoryImpl(
        local: local,
        remoto: RemotoConflito(),
        auth: Conta(),
        sync: sync,
      );
      const ficha = FichaMoto(
        marca: 'Honda',
        modelo: 'Bros',
        kmLitro: 35,
        kmAtual: 1100,
      );
      final result = await repo.salvar(ficha);
      expect(result.sync.emConflito, true);
      expect(result.offline, false);
      final loaded = await repo.carregarLocal();
      expect(loaded.ficha!.kmAtual, 1100);
      expect(loaded.remoto!.kmAtual, 2000);
    },
  );
  test(
    'transporte envia versao base e reconhece 409 da ficha e manutencao',
    () async {
      final bases = <String?>[];
      ApiCaderneta.usarCliente(
        MockClient((request) async {
          bases.add(request.headers['X-Base-Atualizado-Em']);
          return http.Response(jsonEncode({'erro': 'mudou'}), 409);
        }),
      );
      await expectLater(
        ApiCaderneta.salvarFicha('t', {}, baseAtualizadoEm: 'null'),
        throwsA(isA<ConflitoSync>()),
      );
      await expectLater(
        ApiCaderneta.salvarManutencao(
          't',
          {},
          baseAtualizadoEm: '2026-11-06T12:00:00.123Z',
        ),
        throwsA(isA<ConflitoSync>()),
      );
      expect(bases, ['null', '2026-11-06T12:00:00.123Z']);
    },
  );
  test(
    'sucesso antigo nao remove o conflito nem o snapshot da edicao mais nova',
    () async {
      final remoto = ConflitoDepoisDoPrimeiro();
      final repo = FichaRepositoryImpl(
        local: FichaLocalDatasource(),
        remoto: remoto,
        auth: Conta(),
        sync: FichaSyncStore(),
      );
      const ficha = FichaMoto(
        marca: 'Honda',
        modelo: 'Bros',
        kmLitro: 35,
        kmAtual: 1000,
      );
      final first = repo.salvar(ficha);
      await remoto.entrou.future;
      final latest = await repo.salvar(ficha.copiarCom(kmAtual: 1100));
      expect(latest.sync.emConflito, true);
      remoto.liberar.complete(DateTime.utc(2026, 11, 6));
      await first;
      final loaded = await repo.carregarLocal();
      expect(loaded.sync.emConflito, true);
      expect(loaded.remoto!.kmAtual, 2000);
      expect(loaded.ficha!.kmAtual, 1100);
    },
  );
}
