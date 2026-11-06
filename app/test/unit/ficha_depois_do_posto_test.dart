import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:life_and_roads/tema.dart';
import 'package:life_and_roads/features/viagem/presentation/tela_posto.dart';
import 'package:life_and_roads/features/viagem/domain/usecases/calibrar_marcador.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:life_and_roads/core/backup/backup_automatico.dart';
import 'package:life_and_roads/core/backup/backup_nuvem.dart';
import 'package:life_and_roads/features/ficha/data/ficha_local_datasource.dart';
import 'package:life_and_roads/features/ficha/domain/ficha_moto.dart';
import 'package:life_and_roads/features/ficha/presentation/ficha_controller.dart';
import 'package:life_and_roads/features/viagem/domain/precos_litro.dart';
import 'package:life_and_roads/features/viagem/presentation/viagem_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:life_and_roads/viagem/calculo.dart';
import 'package:life_and_roads/viagem/historico.dart';

import '../helpers/banco_teste.dart';

void main() {
  GoogleFonts.config.allowRuntimeFetching = false;
  late ProviderContainer app;
  late BackupAutomatico download;
  late BackupNuvem nuvem;
  var backupsDescartados = false;

  setUp(() async {
    backupsDescartados = false;
    SharedPreferences.setMockInitialValues({});
    await abrirBancoTeste();
    // Sem conta: nada vai à rede. Backups com espera longa, só marcados.
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
    app.dispose();
    if (!backupsDescartados) {
      download.descartar();
      nuvem.descartar();
    }
    await fecharBancoTeste();
  });

  testWidgets(
    'Posto abre edição preenchida e salva correção em tela estreita',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await FichaLocalDatasource().gravar(
        const FichaMoto(
          marca: 'Honda',
          modelo: 'Bros',
          kmLitro: 35,
          kmAtual: 1000,
        ),
      );
      final ctrl = app.read(viagemControllerProvider.notifier);
      await ctrl.registrarAbastecimento(
        kmPainel: 1000,
        litros: 5,
        valorPago: 30,
        precos: const PrecosLitro(),
        tanqueCheio: true,
      );
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
        find.text('Editar'),
        250,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Editar'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Editar'));
      await tester.pumpAndSettle();
      expect(find.text('Editar abastecimento'), findsOneWidget);
      final campo = find.widgetWithText(TextField, 'Litros abastecidos');
      expect(tester.widget<TextField>(campo).controller!.text, '5.0');
      await tester.enterText(campo, '4');
      await tester.scrollUntilVisible(
        find.text('Salvar correção'),
        200,
        scrollable: find
            .descendant(
              of: find.byType(ListView).last,
              matching: find.byType(Scrollable),
            )
            .first,
      );
      await tester.tap(find.text('Salvar correção'));
      await tester.pumpAndSettle(const Duration(milliseconds: 500));
      expect(find.text('Editar abastecimento'), findsNothing);
      expect((await HistoricoAbastecimento.carregar()).single.litros, 4);
      expect((await HistoricoAbastecimento.carregar()).single.precoLitro, 7.5);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();
      download.descartar();
      nuvem.descartar();
      backupsDescartados = true;
    },
  );

  test(
    'registro parcial guarda compra e bloqueia confirmacoes simultaneas',
    () async {
      await FichaLocalDatasource().gravar(
        const FichaMoto(
          marca: 'Honda',
          modelo: 'Bros',
          kmLitro: 35,
          kmAtual: 1000,
        ),
      );
      await app.read(fichaControllerProvider.notifier).carregar();
      final ctrl = app.read(viagemControllerProvider.notifier);
      await Future.wait([
        ctrl.registrarAbastecimento(
          kmPainel: 1000,
          litros: 3,
          valorPago: 19.5,
          precos: const PrecosLitro(),
          totalBarras: 6,
          barrasAntes: 1,
          barrasDepois: 3,
        ),
        ctrl.registrarAbastecimento(
          kmPainel: 1000,
          litros: 3,
          valorPago: 19.5,
          precos: const PrecosLitro(),
        ),
      ]);
      expect(app.read(viagemControllerProvider).historico, hasLength(1));
      expect(
        app.read(viagemControllerProvider).historico.single.totalBarras,
        6,
      );
      await ctrl.registrarAbastecimento(
        kmPainel: 1350,
        litros: 3,
        valorPago: 18,
        precos: const PrecosLitro(),
      );
      final r = app.read(viagemControllerProvider).historico.first;
      expect(r.tipoConsumo, 'estimado');
      expect(r.kmPorLitro, 35);
      expect(app.read(fichaControllerProvider).ficha!.kmAtual, 1350);
      expect(app.read(fichaControllerProvider).ficha!.kmLitro, 35);
    },
  );

  test(
    'abastecimento no Posto troca o km da Ficha sem reabrir o app',
    () async {
      await FichaLocalDatasource().gravar(
        const FichaMoto(
          marca: 'Yamaha',
          modelo: 'Fazer 250',
          kmLitro: 30,
          kmAtual: 30000,
        ),
      );
      await app.read(fichaControllerProvider.notifier).carregar();
      expect(app.read(fichaControllerProvider).ficha!.kmAtual, 30000);

      await app
          .read(viagemControllerProvider.notifier)
          .registrarAbastecimento(
            kmPainel: 30780,
            litros: 12,
            precos: const PrecosLitro(gasolina: '6,59'),
          );

      expect(app.read(viagemControllerProvider).erro, isNull);
      expect(app.read(fichaControllerProvider).ficha!.kmAtual, 30780);
    },
  );

  test(
    'edição persiste correção, atualiza ficha e rejeita formulário antigo',
    () async {
      await FichaLocalDatasource().gravar(
        const FichaMoto(
          marca: 'Honda',
          modelo: 'Bros',
          kmLitro: 35,
          kmAtual: 1000,
        ),
      );
      await app.read(fichaControllerProvider.notifier).carregar();
      final ctrl = app.read(viagemControllerProvider.notifier);
      for (final km in [1000.0, 1200.0]) {
        await ctrl.registrarAbastecimento(
          kmPainel: km,
          litros: 5,
          valorPago: 30,
          tanqueCheio: true,
          precos: const PrecosLitro(),
        );
      }
      final original = app.read(viagemControllerProvider).historico.first;
      expect(
        await ctrl.editarAbastecimento(
          indice: 0,
          original: original,
          kmPainel: 1190,
          litros: 4,
          valorPago: 24,
          combustivel: Combustivel.gasolina,
          tanqueCheio: true,
        ),
        isTrue,
      );
      final salvo = (await HistoricoAbastecimento.carregar()).first;
      expect(salvo.em, original.em);
      expect(salvo.kmPorLitro, 47.5);
      expect((await FichaLocalDatasource().ler())!.kmAtual, 1190);
      expect(app.read(fichaControllerProvider).ficha!.kmLitro, 47.5);
      expect(download.pendente, isTrue);
      expect(
        await ctrl.editarAbastecimento(
          indice: 0,
          original: original,
          kmPainel: 1180,
          litros: 4,
          valorPago: 24,
          combustivel: Combustivel.gasolina,
          tanqueCheio: true,
        ),
        isFalse,
      );
      expect((await HistoricoAbastecimento.carregar()).first.kmPainel, 1190);
    },
  );

  test(
    'leituras novas aprendem a moto e edição recalibra preservando referência',
    () async {
      const ficha = FichaMoto(
        marca: 'Honda',
        modelo: 'Bros',
        ano: 2023,
        kmLitro: 35,
        kmAtual: 1000,
        tanqueLitros: 12,
      );
      await FichaLocalDatasource().gravar(ficha);
      final ctrl = app.read(viagemControllerProvider.notifier);
      for (final km in [1000.0, 1300.0, 1600.0]) {
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
      final registros = await HistoricoAbastecimento.carregar();
      expect(
        registros.every(
          (r) => r.referenciaMarcador == referenciaMarcadorDaFicha(ficha),
        ),
        isTrue,
      );
      expect(
        const CalibrarMarcador()
            .executar(ficha: ficha, historico: registros, totalBarras: 6)
            .consultar(1)!
            .minimo,
        3,
      );
      expect(
        await ctrl.editarAbastecimento(
          indice: 1,
          original: registros[1],
          kmPainel: 1300,
          litros: 8,
          valorPago: 48,
          combustivel: Combustivel.gasolina,
          tanqueCheio: true,
          totalBarras: 6,
          barrasAntes: 1,
          barrasDepois: 6,
        ),
        isTrue,
      );
      final corrigidos = await HistoricoAbastecimento.carregar();
      final faixa = const CalibrarMarcador()
          .executar(ficha: ficha, historico: corrigidos, totalBarras: 6)
          .consultar(1)!;
      expect(faixa.minimo, 3);
      expect(faixa.maximo, 4);
      expect(
        corrigidos.map((r) => r.referenciaMarcador),
        registros.map((r) => r.referenciaMarcador),
      );
      expect(
        const CalibrarMarcador()
            .executar(
              ficha: ficha.copiarCom(modelo: 'Outra'),
              historico: corrigidos,
              totalBarras: 6,
            )
            .consultar(1),
        isNull,
      );
    },
  );
}
