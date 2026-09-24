import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:life_and_roads/core/backup/backup_automatico.dart';
import 'package:life_and_roads/core/backup/backup_nuvem.dart';
import 'package:life_and_roads/core/backup/caderneta_mudou.dart';
import 'package:life_and_roads/core/backup/pasta_download.dart';
import 'package:life_and_roads/core/legal/textos.dart';
import 'package:life_and_roads/features/manutencao/presentation/manutencao_controller.dart';
import 'package:life_and_roads/features/mapa/presentation/mapa_controller.dart';
import 'package:life_and_roads/manutencao/servicos.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../helpers/banco_teste.dart';

class _PastaFalsa implements PastaDownload {
  int gravados = 0;

  @override
  Future<String?> salvar({
    required String nome,
    required String conteudo,
  }) async {
    gravados++;
    return 'Download/life.and.roads/$nome';
  }
}

void main() {
  late _PastaFalsa pasta;
  late BackupAutomatico download;
  late BackupNuvem nuvem;
  late int envios;
  late ProviderContainer app;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await abrirBancoTeste();
    await const EstadoNuvem().gravarTermosAceitos(versaoTermos);
    pasta = _PastaFalsa();
    envios = 0;
    // Espera longa: os testes olham o que ficou marcado para gravar.
    download = BackupAutomatico(
      pasta: pasta,
      exportar: () async => '{}',
      espera: const Duration(hours: 1),
    );
    nuvem = BackupNuvem(
      lerToken: () async => 'access',
      enviar: (token, conteudo, {required carimboBase}) async {
        envios++;
        return '2026-09-24T12:00:00.000Z';
      },
      espera: const Duration(hours: 1),
    );
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

  test('um aviso só marca os dois backups', () {
    app.read(cadernetaMudouProvider).avisar();
    expect(download.pendente, isTrue);
    expect(nuvem.pendente, isTrue);
  });

  test('saindo do app, os dois gravam o que estava esperando', () async {
    app.read(cadernetaMudouProvider).avisar();

    await app.read(cadernetaMudouProvider).aoSairDoApp();

    expect(pasta.gravados, 1);
    expect(envios, 1);
    expect(download.pendente, isFalse);
    expect(nuvem.pendente, isFalse);
  });

  test('saindo do app sem nada esperando, nada acontece', () async {
    await app.read(cadernetaMudouProvider).aoSairDoApp();
    expect(pasta.gravados, 0);
    expect(envios, 0);
  });

  test('marcar e apagar pino avisa os backups', () async {
    final mapa = app.read(mapaControllerProvider.notifier);

    await mapa.acrescentarPin(tipo: 'posto', ponto: const LatLng(-20.75, -42.88));
    expect(download.pendente, isTrue);
    expect(nuvem.pendente, isTrue);

    await app.read(cadernetaMudouProvider).aoSairDoApp();
    final pino = app.read(mapaControllerProvider).pins.single;
    await mapa.removerPin(pino);
    expect(download.pendente, isTrue, reason: 'apagar também é mudança');
  });

  test('serviço novo no histórico avisa os backups', () async {
    await app.read(manutencaoControllerProvider.notifier).acrescentarServico(
      const RegistroServico(
        em: '2026-09-24',
        tipo: 'oleo',
        kmPainel: 12000,
        reais: 80,
      ),
    );
    expect(download.pendente, isTrue);
    expect(nuvem.pendente, isTrue);
  });
}
