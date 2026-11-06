import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:life_and_roads/core/atualizacao/atualizacao_controller.dart';
import 'package:life_and_roads/core/atualizacao/cartao_atualizacao.dart';
import 'package:life_and_roads/core/atualizacao/servico_atualizacao.dart';
import 'package:life_and_roads/core/atualizacao/versao_app.dart';
import 'package:life_and_roads/tema.dart';

Map<String, Object?> _release({
  String tag = 'v1.6.0',
  bool apk = true,
  String? url,
  bool previa = false,
  bool rascunho = false,
}) => {
  'tag_name': tag,
  'prerelease': previa,
  'draft': rascunho,
  'assets': [
    if (apk)
      {
        'name': 'life-and-roads-beta-aberto.apk',
        'state': 'uploaded',
        'size': 60000000,
        'browser_download_url':
            url ??
            'https://github.com/RaulnikRoyce/life-and-roads/releases/download/$tag/life-and-roads-beta-aberto.apk',
      },
  ],
};

class _Fonte extends FonteAtualizacao {
  VersaoInstalada versao = const VersaoInstalada('1.5.2', '78');
  VersaoPublicada release = VersaoPublicada.deJson(_release());
  Object? falha;
  Completer<VersaoPublicada>? espera;
  bool abre = true;
  int leituras = 0, consultas = 0, aberturas = 0;
  Uri? aberto;
  @override
  Future<VersaoInstalada> instalada() async {
    leituras++;
    return versao;
  }

  @override
  Future<VersaoPublicada> publicada() async {
    consultas++;
    if (falha != null) throw falha!;
    return espera == null ? release : espera!.future;
  }

  @override
  Future<bool> abrir(Uri apk) async {
    aberturas++;
    aberto = apk;
    return abre;
  }
}

class _Cliente extends MockClient {
  _Cliente(super.fn);
  bool fechado = false;
  @override
  void close() {
    fechado = true;
    super.close();
  }
}

void main() {
  GoogleFonts.config.allowRuntimeFetching = false;
  late _Fonte fonte;
  late ProviderContainer app;
  late AtualizacaoController ctrl;
  setUp(() {
    fonte = _Fonte();
    app = ProviderContainer(
      overrides: [
        atualizacaoSuportadaProvider.overrideWithValue(true),
        fonteAtualizacaoProvider.overrideWithValue(fonte),
      ],
    );
    ctrl = app.read(atualizacaoControllerProvider.notifier);
  });
  tearDown(() => app.dispose());

  test(
    'compara componentes numéricos e aceita estável após prévia instalada',
    () {
      expect(
        NumeroVersao.ler('1.10.0')!.maisNovaQue(NumeroVersao.ler('1.9.9')!),
        isTrue,
      );
      expect(
        NumeroVersao.ler('1.5.2')!.maisNovaQue(NumeroVersao.ler('1.10.0')!),
        isFalse,
      );
      expect(
        NumeroVersao.ler('v1.6.0')!
            .maisNovaQue(NumeroVersao.ler('1.6.0-beta.1+70')!),
        isTrue,
      );
      expect(
        NumeroVersao.ler('1.6.0+79')!
            .maisNovaQue(NumeroVersao.ler('1.6.0+78')!),
        isFalse,
      );
      for (final v in ['dev', '1.6', '1.06.0', '1.6.0-..', 'vnext']) {
        expect(NumeroVersao.ler(v), isNull);
      }
    },
  );
  test('ignora releases preliminares, rascunhos e tags desconhecidas', () {
    for (final json in [
      _release(previa: true),
      _release(rascunho: true),
      _release(tag: 'v1.6.0-beta.1'),
      _release(tag: 'ultima'),
    ]) {
      expect(() => VersaoPublicada.deJson(json), throwsFormatException);
    }
  });
  test('download exige arquivo pronto da mesma tag no repositório oficial', () {
    expect(VersaoPublicada.deJson(_release(apk: false)).apk, isNull);
    for (final url in [
      'https://example.com/life-and-roads-beta-aberto.apk',
      'https://github.com/Outro/projeto/releases/download/v1.6.0/life-and-roads-beta-aberto.apk',
      'https://github.com/RaulnikRoyce/life-and-roads/releases/download/v1.5.2/life-and-roads-beta-aberto.apk',
    ]) {
      expect(VersaoPublicada.deJson(_release(url: url)).apk, isNull);
    }
    final preparando = _release();
    ((preparando['assets'] as List).single as Map)['state'] = 'starter';
    expect(VersaoPublicada.deJson(preparando).apk, isNull);
    expect(VersaoPublicada.deJson(_release()).apk!.host, 'github.com');
  });
  test(
    'consulta pública usa cliente separado, sem credenciais, e o fecha',
    () async {
      final client = _Cliente((req) async {
        expect(req.url, ServicoAtualizacao.endpoint);
        expect(req.headers['authorization'], isNull);
        expect(req.headers['cookie'], isNull);
        expect(
          req.headers['User-Agent'] ?? req.headers['user-agent'],
          'life-and-roads',
        );
        return http.Response(jsonEncode(_release()), 200);
      });
      final resultado = await ServicoAtualizacao(criarCliente: () => client)
          .publicada();
      expect(resultado.versao, '1.6.0');
      expect(client.fechado, isTrue);
    },
  );
  test(
    'timeout e limite do GitHub liberam o cliente para nova tentativa',
    () async {
      final lento = _Cliente((_) => Completer<http.Response>().future);
      await expectLater(
        ServicoAtualizacao(
          criarCliente: () => lento,
          tempoLimite: const Duration(milliseconds: 1),
        ).publicada(),
        throwsA(isA<TimeoutException>()),
      );
      expect(lento.fechado, isTrue);
      final limitado = _Cliente((_) async => http.Response('', 429));
      await expectLater(
        ServicoAtualizacao(criarCliente: () => limitado).publicada(),
        throwsStateError,
      );
      expect(limitado.fechado, isTrue);
    },
  );
  test(
    'lê versão real instalada sem usar APP_VERSION de diagnóstico',
    () async {
      PackageInfo.setMockInitialValues(
        appName: 'life.and.roads',
        packageName: 'test.app',
        version: '1.5.2',
        buildNumber: '78',
        buildSignature: '',
      );
      final versao = await ServicoAtualizacao().instalada();
      expect(versao.versao, '1.5.2');
      expect(versao.build, '78');
    },
  );
  test('consulta automática ocorre uma vez e consulta manual permite tentar novamente', () async {
    await ctrl.verificar(automatico: true);
    await ctrl.verificar(automatico: true);
    expect(fonte.consultas, 1);
    expect(app.read(atualizacaoControllerProvider).disponivel, isTrue);
    await ctrl.verificar();
    expect(fonte.consultas, 2);
  });
  test(
    'versão igual ou anterior não oferece atualização nem downgrade',
    () async {
      for (final versao in ['1.6.0', '1.7.0']) {
        fonte.versao = VersaoInstalada(versao, '99');
        await ctrl.verificar();
        expect(
          app.read(atualizacaoControllerProvider).situacao,
          SituacaoAtualizacao.atualizado,
        );
        await ctrl.baixar();
      }
      expect(fonte.aberturas, 0);
    },
  );
  test(
    'release sem APK fica preparando e só libera quando arquivo estiver pronto',
    () async {
      fonte.release = VersaoPublicada.deJson(_release(apk: false));
      await ctrl.verificar();
      expect(
        app.read(atualizacaoControllerProvider).situacao,
        SituacaoAtualizacao.preparando,
      );
      await ctrl.baixar();
      expect(fonte.aberturas, 0);
      fonte.release = VersaoPublicada.deJson(_release());
      await ctrl.verificar();
      expect(app.read(atualizacaoControllerProvider).disponivel, isTrue);
    },
  );
  test('falha automática é silenciosa e manual informa falha sem fingir atualizado', () async {
    fonte.falha = StateError('offline');
    await ctrl.verificar(automatico: true);
    expect(app.read(atualizacaoControllerProvider).erro, isNull);
    expect(
      app.read(atualizacaoControllerProvider).situacao,
      SituacaoAtualizacao.indisponivel,
    );
    await ctrl.verificar();
    expect(app.read(atualizacaoControllerProvider).erro, isNotNull);
    fonte.falha = null;
    await ctrl.verificar();
    expect(app.read(atualizacaoControllerProvider).disponivel, isTrue);
    expect(app.read(atualizacaoControllerProvider).erro, isNull);
  });
  test(
    'bloqueia consultas simultâneas e abertura duplicada do download',
    () async {
      fonte.espera = Completer<VersaoPublicada>();
      final primeira = ctrl.verificar();
      await Future<void>.delayed(Duration.zero);
      await ctrl.verificar();
      expect(fonte.consultas, 1);
      fonte.espera!.complete(fonte.release);
      await primeira;
      await Future.wait([ctrl.baixar(), ctrl.baixar()]);
      expect(fonte.aberturas, 1);
      expect(fonte.aberto, fonte.release.apk);
      expect(app.read(atualizacaoControllerProvider).disponivel, isTrue);
    },
  );
  test('falha ao abrir mantém aviso e permite repetir', () async {
    await ctrl.verificar();
    fonte.abre = false;
    await ctrl.baixar();
    expect(app.read(atualizacaoControllerProvider).erro, isNotNull);
    expect(app.read(atualizacaoControllerProvider).disponivel, isTrue);
    fonte.abre = true;
    await ctrl.baixar();
    expect(app.read(atualizacaoControllerProvider).erro, isNull);
  });
  test('resposta atrasada não atualiza controller descartado', () async {
    final isolado = ProviderContainer(
      overrides: [
        atualizacaoSuportadaProvider.overrideWithValue(true),
        fonteAtualizacaoProvider.overrideWithValue(fonte),
      ],
    );
    fonte.espera = Completer<VersaoPublicada>();
    final pendente = isolado
        .read(atualizacaoControllerProvider.notifier)
        .verificar();
    await Future<void>.delayed(Duration.zero);
    isolado.dispose();
    fonte.espera!.complete(fonte.release);
    await pendente;
  });
  test('plataforma sem suporte não consulta nem abre links', () async {
    final isolado = ProviderContainer(
      overrides: [
        atualizacaoSuportadaProvider.overrideWithValue(false),
        fonteAtualizacaoProvider.overrideWithValue(fonte),
      ],
    );
    addTearDown(isolado.dispose);
    final c = isolado.read(atualizacaoControllerProvider.notifier);
    await c.verificar(automatico: true);
    await c.verificar();
    await c.baixar();
    expect(fonte.leituras, 0);
    expect(fonte.consultas, 0);
    expect(fonte.aberturas, 0);
  });
  testWidgets('consulta e botão abrem APK da tag em tela de celular', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: app,
        child: MaterialApp(
          theme: temaOficina(),
          home: const Scaffold(
            body: SingleChildScrollView(child: CartaoAtualizacao()),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Verificar atualização'));
    await tester.pumpAndSettle();
    expect(find.text('Nova versão 1.6.0'), findsOneWidget);
    expect(find.textContaining('1.5.2 (build 78)'), findsOneWidget);
    await tester.tap(find.text('Baixar APK'));
    await tester.pumpAndSettle();
    expect(fonte.aberto, fonte.release.apk);
    expect(find.text('Nova versão 1.6.0'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });
  testWidgets('widget oculto em plataformas sem suporte', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [atualizacaoSuportadaProvider.overrideWithValue(false)],
        child: const MaterialApp(home: Scaffold(body: CartaoAtualizacao())),
      ),
    );
    expect(find.text('Verificar atualização'), findsNothing);
    expect(fonte.consultas, 0);
  });
}
