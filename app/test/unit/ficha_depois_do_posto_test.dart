import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:life_and_roads/core/backup/backup_automatico.dart';
import 'package:life_and_roads/core/backup/backup_nuvem.dart';
import 'package:life_and_roads/features/ficha/data/ficha_local_datasource.dart';
import 'package:life_and_roads/features/ficha/domain/ficha_moto.dart';
import 'package:life_and_roads/features/ficha/presentation/ficha_controller.dart';
import 'package:life_and_roads/features/viagem/domain/precos_litro.dart';
import 'package:life_and_roads/features/viagem/presentation/viagem_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../helpers/banco_teste.dart';

void main() {
  late ProviderContainer app;
  late BackupAutomatico download;
  late BackupNuvem nuvem;

  setUp(() async {
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
    download.descartar();
    nuvem.descartar();
    await fecharBancoTeste();
  });

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
}
