import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:life_and_roads/core/backup/backup_automatico.dart';
import 'package:life_and_roads/core/backup/pasta_download.dart';

/// Guarda o que seria gravado, no lugar do canal nativo.
class _PastaFalsa implements PastaDownload {
  final gravados = <({String nome, String conteudo})>[];
  String? devolve = 'Download/life.and.roads/caderneta.json';

  @override
  Future<String?> salvar({
    required String nome,
    required String conteudo,
  }) async {
    gravados.add((nome: nome, conteudo: conteudo));
    return devolve;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('agendar grava uma vez depois da espera', (tester) async {
    final pasta = _PastaFalsa();
    final auto = BackupAutomatico(
      pasta: pasta,
      exportar: () async => '{"v":2}',
      espera: const Duration(milliseconds: 50),
    );
    addTearDown(auto.descartar);

    auto.agendar();
    auto.agendar();
    auto.agendar();
    expect(pasta.gravados, isEmpty, reason: 'espera antes de gravar');

    await tester.pump(const Duration(milliseconds: 60));
    await tester.pumpAndSettle();
    expect(pasta.gravados.length, 1);
    expect(pasta.gravados.single.nome, 'caderneta.json');
    expect(pasta.gravados.single.conteudo, '{"v":2}');
  });

  test('avisa quem escuta quando grava, para a Ficha trocar o texto', () async {
    final pasta = _PastaFalsa();
    final auto = BackupAutomatico(pasta: pasta, exportar: () async => '{}');
    final vistos = <DateTime?>[];
    auto.ultimo.addListener(() => vistos.add(auto.ultimo.value));

    expect(auto.ultimo.value, isNull, reason: 'começa sem carimbo');
    await auto.gravarAgora();
    expect(vistos.length, 1);
    expect(vistos.single, isNotNull);
  });

  test('backup que não gravou não avisa ninguém', () async {
    final pasta = _PastaFalsa()..devolve = null;
    final auto = BackupAutomatico(pasta: pasta, exportar: () async => '{}');
    var avisos = 0;
    auto.ultimo.addListener(() => avisos++);

    await auto.gravarAgora();
    expect(avisos, 0);
    expect(auto.ultimo.value, isNull);
  });

  test('gravarAgora devolve o caminho mesmo sem o banco do carimbo', () async {
    final pasta = _PastaFalsa();
    final auto = BackupAutomatico(pasta: pasta, exportar: () async => '{}');

    // Sem banco aberto, o carimbo falha; o backup já foi e vale.
    expect(await auto.gravarAgora(), 'Download/life.and.roads/caderneta.json');
    expect(pasta.gravados.single.conteudo, '{}');
  });

  test('sem pasta disponível não grava carimbo e não quebra', () async {
    final pasta = _PastaFalsa()..devolve = null;
    final auto = BackupAutomatico(pasta: pasta, exportar: () async => '{}');

    expect(await auto.gravarAgora(), isNull);
    expect(pasta.gravados.length, 1, reason: 'tentou');
  });

  test('erro ao exportar não derruba o app', () async {
    final auto = BackupAutomatico(
      pasta: _PastaFalsa(),
      exportar: () async => throw StateError('banco fechado'),
    );
    expect(await auto.gravarAgora(), isNull);
  });

  test('descartar cancela o que estava agendado', () async {
    final pasta = _PastaFalsa();
    final auto = BackupAutomatico(
      pasta: pasta,
      exportar: () async => '{}',
      espera: const Duration(milliseconds: 20),
    );
    auto.agendar();
    auto.descartar();
    await Future<void>.delayed(const Duration(milliseconds: 60));
    expect(pasta.gravados, isEmpty);
  });

  /// O override de plataforma precisa sair antes do fim do corpo do teste;
  /// o Flutter confere as variáveis de depuração ali, antes do tearDown.
  Future<void> comoPlataforma(
    TargetPlatform plataforma,
    Future<void> Function() corpo,
  ) async {
    debugDefaultTargetPlatformOverride = plataforma;
    try {
      await corpo();
    } finally {
      debugDefaultTargetPlatformOverride = null;
    }
  }

  /// Instala um atendente falso no canal e devolve o que ele recebeu.
  void ouvirCanal(
    WidgetTester tester,
    Future<Object?> Function(MethodCall) atender,
  ) {
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      PastaDownload.canal,
      atender,
    );
    addTearDown(
      () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        PastaDownload.canal,
        null,
      ),
    );
  }

  testWidgets('fora do Android o canal nem é chamado', (tester) async {
    final chamadas = <String>[];
    ouvirCanal(tester, (chamada) async {
      chamadas.add(chamada.method);
      return 'nunca';
    });

    await comoPlataforma(TargetPlatform.iOS, () async {
      final r = await const PastaDownload().salvar(
        nome: 'caderneta.json',
        conteudo: '{}',
      );
      expect(r, isNull);
      expect(chamadas, isEmpty);
    });
  });

  testWidgets('no Android o canal recebe nome e conteúdo', (tester) async {
    MethodCall? recebida;
    ouvirCanal(tester, (chamada) async {
      recebida = chamada;
      return 'Download/life.and.roads/caderneta.json';
    });

    await comoPlataforma(TargetPlatform.android, () async {
      final r = await const PastaDownload().salvar(
        nome: 'caderneta.json',
        conteudo: '{"v":2}',
      );
      expect(r, 'Download/life.and.roads/caderneta.json');
      expect(recebida?.method, 'salvar');
      expect(recebida?.arguments, {
        'nome': 'caderneta.json',
        'conteudo': '{"v":2}',
      });
    });
  });

  testWidgets('erro do lado nativo vira null, sem exceção', (tester) async {
    ouvirCanal(tester, (chamada) async => throw PlatformException(code: 'x'));

    await comoPlataforma(TargetPlatform.android, () async {
      expect(
        await const PastaDownload().salvar(nome: 'a.json', conteudo: '{}'),
        isNull,
      );
    });
  });
}
