import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:life_and_roads/core/backup/backup_automatico.dart';
import 'package:life_and_roads/core/backup/backup_nuvem.dart';
import 'package:life_and_roads/core/database/caderneta_banco.dart';
import 'package:life_and_roads/features/ficha/data/ficha_local_datasource.dart';
import 'package:life_and_roads/features/ficha/domain/ficha_moto.dart';
import 'package:life_and_roads/features/ficha/presentation/ficha_controller.dart';
import 'package:life_and_roads/features/viagem/domain/precos_litro.dart';
import 'package:life_and_roads/features/viagem/domain/usecases/calibrar_marcador.dart';
import 'package:life_and_roads/features/viagem/presentation/tela_posto.dart';
import 'package:life_and_roads/features/viagem/presentation/viagem_controller.dart';
import 'package:life_and_roads/tema.dart';
import 'package:life_and_roads/viagem/historico.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../helpers/banco_teste.dart';

void main() {
  GoogleFonts.config.allowRuntimeFetching = false;
  late ProviderContainer app;
  late BackupAutomatico download;
  late BackupNuvem nuvem;
  var descartado = false;
  void descartar() {
    if (descartado) return;
    app.dispose();
    download.descartar();
    nuvem.descartar();
    descartado = true;
  }

  setUp(() async {
    descartado = false;
    SharedPreferences.setMockInitialValues({});
    await abrirBancoTeste();
    download = BackupAutomatico(
      exportar: () async => '{}',
      espera: const Duration(hours: 1),
    );
    nuvem = BackupNuvem(espera: const Duration(hours: 1));
    app = ProviderContainer(
      overrides: [
        backupAutomaticoProvider.overrideWithValue(download),
        backupNuvemProvider.overrideWithValue(nuvem),
      ],
    );
  });
  tearDown(() async {
    descartar();
    await fecharBancoTeste();
  });
  Future<ViagemController> preparar({int quantidade = 3}) async {
    await FichaLocalDatasource().gravar(
      const FichaMoto(
        marca: 'Honda',
        modelo: 'Bros',
        kmLitro: 35,
        kmAtual: 1000,
        tanqueLitros: 12,
      ),
    );
    final ctrl = app.read(viagemControllerProvider.notifier);
    for (final km in [1000.0, 1300.0, 1600.0].take(quantidade)) {
      await ctrl.registrarAbastecimento(
        kmPainel: km,
        litros: 9,
        valorPago: 54,
        precos: const PrecosLitro(),
        tanqueCheio: true,
        totalBarras: 6,
        barrasAntes: 1,
        barrasDepois: 6,
      );
    }
    return ctrl;
  }

  test(
    'exclusão persiste, atualiza ficha e retira referência da calibração',
    () async {
      final ctrl = await preparar();
      final original = app.read(viagemControllerProvider).historico.first;
      expect(
        await ctrl.excluirAbastecimento(indice: 0, original: original),
        isTrue,
      );
      final restantes = await HistoricoAbastecimento.carregar();
      final ficha = (await FichaLocalDatasource().ler())!;
      expect(restantes, hasLength(2));
      expect(restantes.first.kmPainel, 1300);
      expect(ficha.kmAtual, 1300);
      expect(app.read(fichaControllerProvider).ficha!.kmAtual, 1300);
      expect(
        const CalibrarMarcador()
            .executar(ficha: ficha, historico: restantes, totalBarras: 6)
            .consultar(1),
        isNull,
      );
      expect(download.pendente, isTrue);
      await ctrl.carregar();
      expect(app.read(viagemControllerProvider).historico, hasLength(2));
    },
  );
  test('bloqueia duas exclusões simultâneas e confirmação antiga', () async {
    final ctrl = await preparar();
    final original = app.read(viagemControllerProvider).historico.first;
    final resultados = await Future.wait([
      ctrl.excluirAbastecimento(indice: 0, original: original),
      ctrl.excluirAbastecimento(indice: 0, original: original),
    ]);
    expect(resultados, [true, false]);
    expect(
      await ctrl.excluirAbastecimento(indice: 0, original: original),
      isFalse,
    );
    expect(await HistoricoAbastecimento.carregar(), hasLength(2));
    expect((await FichaLocalDatasource().ler())!.kmAtual, 1300);
  });
  test('falha no banco reverte remoção inteira e mantém ficha', () async {
    final ctrl = await preparar();
    final antes = await HistoricoAbastecimento.carregar();
    await CadernetaBanco.instancia.customStatement(
      "CREATE TRIGGER recusar_regravacao BEFORE INSERT ON abastecimentos BEGIN SELECT RAISE(ABORT, 'falha de teste'); END",
    );
    expect(
      await ctrl.excluirAbastecimento(indice: 1, original: antes[1]),
      isFalse,
    );
    expect(
      (await HistoricoAbastecimento.carregar()).map((r) => r.paraJson()),
      antes.map((r) => r.paraJson()),
    );
    expect((await FichaLocalDatasource().ler())!.kmAtual, 1600);
  });
  test('excluir único registro deixa histórico vazio preservando km', () async {
    final ctrl = await preparar(quantidade: 1);
    final original = app.read(viagemControllerProvider).historico.single;
    expect(
      await ctrl.excluirAbastecimento(indice: 0, original: original),
      isTrue,
    );
    expect(await HistoricoAbastecimento.carregar(), isEmpty);
    expect(app.read(viagemControllerProvider).historico, isEmpty);
    expect((await FichaLocalDatasource().ler())!.kmAtual, 1000);
  });
  testWidgets(
    'cancelar preserva registro e confirmar exclui em tela estreita',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await preparar();
      try {
        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: app,
            child: MaterialApp(
              theme: temaOficina(),
              home: const Scaffold(body: TelaPosto()),
            ),
          ),
        );
        await tester.pumpAndSettle();
        await tester.scrollUntilVisible(
          find.text('Excluir').first,
          250,
          scrollable: find.byType(Scrollable).first,
        );
        await tester.pumpAndSettle();
        await tester.ensureVisible(find.text('Excluir').first);
        await tester.pumpAndSettle();
        await tester.tap(find.text('Excluir').first);
        await tester.pumpAndSettle();
        expect(find.text('Excluir abastecimento?'), findsOneWidget);
        expect(
          find.textContaining('voltará ao último abastecimento'),
          findsOneWidget,
        );
        await tester.tap(find.text('Cancelar'));
        await tester.pumpAndSettle();
        expect(await HistoricoAbastecimento.carregar(), hasLength(3));
        await tester.tap(find.text('Excluir').first);
        await tester.pumpAndSettle();
        await tester.tap(
          find.descendant(
            of: find.byType(AlertDialog),
            matching: find.widgetWithText(FilledButton, 'Excluir'),
          ),
        );
        await tester.pumpAndSettle();
        expect(find.byType(AlertDialog), findsNothing);
        expect(await HistoricoAbastecimento.carregar(), hasLength(2));
        expect(tester.takeException(), isNull);
      } finally {
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pumpAndSettle();
        descartar();
      }
    },
  );
}
