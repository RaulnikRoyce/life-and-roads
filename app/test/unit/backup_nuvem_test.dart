import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:life_and_roads/api.dart';
import 'package:life_and_roads/core/backup/backup_nuvem.dart';
import 'package:life_and_roads/core/legal/textos.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../helpers/banco_teste.dart';

/// A API de mentira: guarda o que chegou e devolve um carimbo novo por envio.
class _NuvemFalsa {
  final envios = <({Map<String, dynamic> conteudo, String? base})>[];
  Object? falha;
  Completer<void>? segurar;

  Future<String> enviar(
    String token,
    Map<String, dynamic> conteudo, {
    required String? carimboBase,
  }) async {
    envios.add((conteudo: conteudo, base: carimboBase));
    final espera = segurar;
    if (espera != null) await espera.future;
    final erro = falha;
    if (erro != null) throw erro;
    return '2026-09-24T12:00:0${envios.length}.000Z';
  }
}

void main() {
  late _NuvemFalsa nuvem;
  late Map<String, dynamic> pacote;
  late String? token;
  const estado = EstadoNuvem();

  BackupNuvem criar({Duration espera = const Duration(minutes: 2)}) {
    final b = BackupNuvem(
      exportar: () async => Map<String, dynamic>.from(pacote),
      lerToken: () async => token,
      enviar: nuvem.enviar,
      espera: espera,
    );
    addTearDown(b.descartar);
    return b;
  }

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await abrirBancoTeste();
    nuvem = _NuvemFalsa();
    pacote = {'v': 1, 'abastecimentos': <Object>[], 'extra': null};
    token = 'access';
    await estado.gravarTermosAceitos(versaoTermos);
  });

  tearDown(fecharBancoTeste);

  group('nada sobe', () {
    test('sem conta', () async {
      token = null;
      expect(await criar().enviarAgora(), ResultadoNuvem.parada);
      expect(nuvem.envios, isEmpty);
    });

    test('com o interruptor desligado', () async {
      await estado.ligar(false);
      expect(await criar().enviarAgora(), ResultadoNuvem.parada);
      expect(nuvem.envios, isEmpty);
    });

    test('sem aceite dos termos', () async {
      await estado.gravarTermosAceitos(null);
      expect(await criar().enviarAgora(), ResultadoNuvem.parada);
      expect(nuvem.envios, isEmpty);
    });

    test('com aceite de uma versão antiga dos termos', () async {
      await estado.gravarTermosAceitos('2026-08-26');
      expect(await criar().enviarAgora(), ResultadoNuvem.parada);
      expect(nuvem.envios, isEmpty);
    });
  });

  test('primeiro envio vai sem carimbo e guarda o que voltou', () async {
    final b = criar();

    expect(await b.enviarAgora(), ResultadoNuvem.enviada);

    expect(nuvem.envios.single.base, isNull);
    expect(await estado.carimbo(), '2026-09-24T12:00:01.000Z');
    expect(await estado.assinatura(), BackupNuvem.assinar(pacote));
    expect(b.ultimo.value, '2026-09-24T12:00:01.000Z');
  });

  test('mesma caderneta não sobe de novo; caderneta mudada sobe com o carimbo', () async {
    final b = criar();
    await b.enviarAgora();

    expect(await b.enviarAgora(), ResultadoNuvem.semMudanca);
    expect(nuvem.envios, hasLength(1));

    pacote['extra'] = '{"kmOleo":"12000"}';
    expect(await b.enviarAgora(), ResultadoNuvem.enviada);
    expect(nuvem.envios, hasLength(2));
    expect(nuvem.envios.last.base, '2026-09-24T12:00:01.000Z');
    expect(await estado.carimbo(), '2026-09-24T12:00:02.000Z');
  });

  test('conflito para os envios até o piloto escolher', () async {
    final b = criar();
    nuvem.falha = ConflitoNuvem('mudou', atualizadoEm: '2026-09-24T13:00:00.000Z');

    expect(await b.enviarAgora(), ResultadoNuvem.conflito);
    expect(await estado.emConflito(), isTrue);
    expect(await estado.carimbo(), isNull, reason: 'nada foi gravado');

    nuvem.falha = null;
    pacote['extra'] = 'outra coisa';
    expect(await b.enviarAgora(), ResultadoNuvem.parada);
    expect(nuvem.envios, hasLength(1), reason: 'não insiste por cima');
  });

  test('falha de rede não guarda nada e a próxima tentativa manda de novo', () async {
    final b = criar();
    nuvem.falha = FalhaApi('API fora do ar.');

    expect(await b.enviarAgora(), ResultadoNuvem.falhou);
    expect(await estado.carimbo(), isNull);
    expect(await estado.emConflito(), isFalse);

    nuvem.falha = null;
    expect(await b.enviarAgora(), ResultadoNuvem.enviada);
    expect(nuvem.envios, hasLength(2));
  });

  test('várias mudanças seguidas viram um envio só, depois da espera', () async {
    final b = criar(espera: const Duration(milliseconds: 40));

    b.agendar();
    b.agendar();
    b.agendar();
    expect(b.pendente, isTrue);
    expect(nuvem.envios, isEmpty, reason: 'espera antes de mandar');

    await Future<void>.delayed(const Duration(milliseconds: 150));
    expect(nuvem.envios, hasLength(1));
    expect(b.pendente, isFalse);
  });

  test('indo para segundo plano, manda na hora o que estava esperando', () async {
    final b = criar(espera: const Duration(hours: 1));

    await b.enviarSePendente();
    expect(nuvem.envios, isEmpty, reason: 'nada esperando, nada a fazer');

    b.agendar();
    await b.enviarSePendente();
    expect(nuvem.envios, hasLength(1));
    expect(b.pendente, isFalse);
  });

  test('mudança durante um envio sobe logo depois dele', () async {
    final b = criar();
    nuvem.segurar = Completer<void>();

    final primeiro = b.enviarAgora();
    // O primeiro passa pelo banco antes de chegar na API. Só mexe depois
    // que ele já levou o pacote.
    for (var i = 0; i < 200 && nuvem.envios.isEmpty; i++) {
      await Future<void>.delayed(const Duration(milliseconds: 5));
    }
    expect(nuvem.envios, hasLength(1));
    pacote['extra'] = 'mudou no meio';
    expect(await b.enviarAgora(), ResultadoNuvem.emAndamento);

    nuvem.segurar!.complete();
    nuvem.segurar = null;
    expect(await primeiro, ResultadoNuvem.enviada);
    expect(nuvem.envios, hasLength(2));
    expect(nuvem.envios.last.conteudo['extra'], 'mudou no meio');
    expect(nuvem.envios.last.base, '2026-09-24T12:00:01.000Z');
  });

  test('depois de restaurar, a mesma caderneta não volta a subir', () async {
    final b = criar();

    await b.registrarRestaurada('2026-09-23T10:00:00.000Z');

    expect(await estado.carimbo(), '2026-09-23T10:00:00.000Z');
    expect(await b.enviarAgora(), ResultadoNuvem.semMudanca);
    expect(nuvem.envios, isEmpty);
  });

  test('sair da conta esquece carimbo, conflito e aceite, e mantém o interruptor', () async {
    final b = criar(espera: const Duration(hours: 1));
    await b.enviarAgora();
    await estado.marcarConflito();
    await estado.ligar(false);
    b.agendar();

    await b.esquecerConta();

    expect(b.pendente, isFalse);
    expect(await estado.carimbo(), isNull);
    expect(await estado.assinatura(), isNull);
    expect(await estado.emConflito(), isFalse);
    expect(await estado.termosAceitos(), isNull);
    expect(await estado.ligada(), isFalse, reason: 'escolha da pessoa');
    expect(b.ultimo.value, isNull);
  });
}
