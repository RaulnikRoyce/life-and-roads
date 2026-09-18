import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:life_and_roads/core/database/armazem_kv.dart';
import 'package:life_and_roads/core/database/chaves_kv.dart';
import 'package:life_and_roads/features/ficha/domain/usecases/enviar_caderneta_arquivo.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../helpers/banco_teste.dart';

void main() {
  late Directory pasta;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await abrirBancoTeste();
    pasta = await Directory.systemTemp.createTemp('lr-enviar');
    await ArmazemKv.gravarTexto(
      ChavesKv.ficha,
      jsonEncode({'marca': 'Honda', 'modelo': 'Bros', 'kmLitro': '35'}),
    );
  });

  tearDown(() async {
    await fecharBancoTeste();
    await pasta.delete(recursive: true);
  });

  test('grava o JSON v2 e entrega o caminho ao compartilhar', () async {
    String? recebido;
    final caso = EnviarCadernetaArquivo(
      pasta: pasta.path,
      enviar: ({String? caminho, String? json}) async {
        recebido = caminho;
        return true;
      },
    );

    final r = await caso.executar();

    expect(r.enviado, isTrue);
    expect(r.erro, isNull);
    expect(recebido, isNotNull);
    final conteudo = jsonDecode(await File(recebido!).readAsString()) as Map;
    expect(conteudo['v'], 2);
    expect(conteudo['ficha'], contains('Bros'));
  });

  test('compartilhar indisponível vira mensagem, não exceção', () async {
    final caso = EnviarCadernetaArquivo(
      pasta: pasta.path,
      enviar: ({String? caminho, String? json}) async => false,
    );

    final r = await caso.executar();

    expect(r.enviado, isFalse);
    expect(r.erro, contains('Copiar backup'));
  });
}
