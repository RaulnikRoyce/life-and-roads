import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:life_and_roads/api.dart';
import 'package:life_and_roads/features/auth/data/auth_remote_datasource.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  late List<http.Request> pedidos;

  void responder(int status, [Object? corpo]) {
    ApiCaderneta.usarCliente(MockClient((req) async {
      pedidos.add(req);
      return http.Response(
        corpo == null ? '' : jsonEncode(corpo),
        status,
        headers: {'content-type': 'application/json; charset=utf-8'},
      );
    }));
  }

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    pedidos = [];
  });

  const conteudo = {'v': 1, 'pins': <Object>[]};

  test('buscar sem caderneta na conta devolve nulo', () async {
    responder(404, {'erro': 'Nenhuma caderneta na nuvem ainda'});
    expect(await ApiCaderneta.buscarCaderneta('access'), isNull);
    expect(pedidos.single.method, 'GET');
    expect(pedidos.single.headers['Authorization'], 'Bearer access');
  });

  test('buscar devolve conteúdo e carimbo', () async {
    responder(200, {'conteudo': conteudo, 'atualizadoEm': '2026-09-24T12:00:00.000Z'});
    final lida = await ApiCaderneta.buscarCaderneta('access');
    expect(lida!['conteudo'], conteudo);
    expect(lida['atualizadoEm'], '2026-09-24T12:00:00.000Z');
  });

  test('salvar vai para o servidor, com o carimbo base, e devolve o novo', () async {
    responder(200, {'atualizadoEm': '2026-09-24T12:00:05.000Z'});

    final carimbo = await ApiCaderneta.salvarCaderneta(
      'access',
      conteudo,
      carimboBase: '2026-09-24T12:00:00.000Z',
    );

    expect(carimbo, '2026-09-24T12:00:05.000Z');
    final pedido = pedidos.single;
    expect(pedido.method, 'PUT');
    expect(pedido.url.toString(), '${ApiCaderneta.base}/caderneta');
    expect(jsonDecode(pedido.body), {
      'conteudo': conteudo,
      'baseAtualizadoEm': '2026-09-24T12:00:00.000Z',
    });
  });

  test('primeiro envio manda o carimbo base nulo', () async {
    responder(200, {'atualizadoEm': '2026-09-24T12:00:05.000Z'});
    await ApiCaderneta.salvarCaderneta('access', conteudo, carimboBase: null);
    final corpo = jsonDecode(pedidos.single.body) as Map;
    expect(corpo.containsKey('baseAtualizadoEm'), isTrue);
    expect(corpo['baseAtualizadoEm'], isNull);
  });

  test('409 vira ConflitoNuvem com o carimbo que está no servidor', () async {
    responder(409, {
      'erro': 'A caderneta na nuvem mudou em outro aparelho.',
      'detalhes': {'atualizadoEm': '2026-09-24T13:00:00.000Z'},
    });

    await expectLater(
      ApiCaderneta.salvarCaderneta('access', conteudo, carimboBase: null),
      throwsA(
        isA<ConflitoNuvem>().having(
          (e) => e.atualizadoEm,
          'atualizadoEm',
          '2026-09-24T13:00:00.000Z',
        ),
      ),
    );
  });

  test('503 sem a chave no servidor é falha comum, não conflito', () async {
    responder(503, {'erro': 'A caderneta na nuvem está indisponível agora.'});
    await expectLater(
      ApiCaderneta.salvarCaderneta('access', conteudo, carimboBase: null),
      throwsA(
        isA<FalhaApi>()
            .having((e) => e is ConflitoNuvem, 'conflito', isFalse)
            .having((e) => e.mensagem, 'mensagem', contains('indisponível')),
      ),
    );
  });

  test('aceite dos termos vai com token e só a versão', () async {
    responder(200, {'termosVersao': '2026-09-24'});
    await AuthRemoteDatasource().aceitarTermos('access', '2026-09-24');
    final pedido = pedidos.single;
    expect(pedido.url.toString(), '${ApiCaderneta.base}/auth/termos');
    expect(pedido.headers['Authorization'], 'Bearer access');
    expect(jsonDecode(pedido.body), {'versao': '2026-09-24'});
  });

  test('cadastro manda a versão dos termos aceita', () async {
    responder(201, {'id': 1, 'email': 'a@b.c'});
    await AuthRemoteDatasource().registrar(
      'a@b.c',
      'senha1234',
      termosVersao: '2026-09-24',
    );
    expect(jsonDecode(pedidos.single.body), {
      'email': 'a@b.c',
      'senha': 'senha1234',
      'termosVersao': '2026-09-24',
    });
  });

  test('login traz a versão aceita, e conta sem aceite traz nulo', () async {
    responder(200, {
      'token': 'access',
      'refreshToken': 'refresh',
      'email': 'a@b.c',
      'termosVersao': '2026-09-24',
    });
    final comAceite = await AuthRemoteDatasource().login('a@b.c', 'senha1234');
    expect(comAceite.termosVersao, '2026-09-24');

    responder(200, {
      'token': 'access',
      'refreshToken': 'refresh',
      'email': 'a@b.c',
      'termosVersao': null,
    });
    final semAceite = await AuthRemoteDatasource().login('a@b.c', 'senha1234');
    expect(semAceite.termosVersao, isNull);
  });

  test('apagar aceita 204 e recusa o resto', () async {
    responder(204);
    await ApiCaderneta.apagarCaderneta('access');
    expect(pedidos.single.method, 'DELETE');

    responder(500, {'erro': 'Erro interno do servidor'});
    await expectLater(
      ApiCaderneta.apagarCaderneta('access'),
      throwsA(isA<FalhaApi>()),
    );
  });
}
