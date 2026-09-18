import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:life_and_roads/api.dart';
import 'package:life_and_roads/core/security/sessao_segura.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// API de mentira: aceita só o access atual; refresh troca o par.
class _ApiFalsa {
  _ApiFalsa({required this.accessValido});

  String accessValido;
  int refreshChamado = 0;
  int fichaChamada = 0;
  bool refreshFalha = false;
  int healthChamado = 0;

  http.Client cliente() => MockClient((req) async {
        if (req.url.path == '/health') {
          healthChamado++;
          return http.Response('{"status":"ok"}', 200);
        }
        if (req.url.path == '/auth/refresh') {
          refreshChamado++;
          if (refreshFalha) {
            return http.Response(jsonEncode({'erro': 'Token inválido'}), 401);
          }
          accessValido = 'access-$refreshChamado';
          return http.Response(
            jsonEncode({
              'token': accessValido,
              'refreshToken': 'refresh-$refreshChamado',
            }),
            200,
          );
        }
        if (req.url.path == '/ficha') {
          fichaChamada++;
          final auth = req.headers['Authorization'] ?? '';
          if (auth != 'Bearer $accessValido') {
            return http.Response(jsonEncode({'erro': 'Token inválido'}), 401);
          }
          return http.Response(jsonEncode({'marca': 'Honda'}), 200);
        }
        return http.Response('', 404);
      });
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('três abas com access vencido disparam um único refresh', () async {
    final api = _ApiFalsa(accessValido: 'access-novo');
    ApiCaderneta.usarCliente(api.cliente());
    await SessaoSegura().gravar(token: 'access-velho', refresh: 'refresh-0');

    final respostas = await Future.wait([
      ApiCaderneta.buscarFicha('access-velho'),
      ApiCaderneta.buscarFicha('access-velho'),
      ApiCaderneta.buscarFicha('access-velho'),
    ]);

    expect(api.refreshChamado, 1);
    for (final r in respostas) {
      expect(r?['marca'], 'Honda');
    }
    expect(await SessaoSegura().lerToken(), 'access-1');
    expect(await SessaoSegura().lerRefresh(), 'refresh-1');
  });

  test('access mais novo no storage é usado antes de pedir refresh', () async {
    final api = _ApiFalsa(accessValido: 'access-atual');
    ApiCaderneta.usarCliente(api.cliente());
    await SessaoSegura().gravar(token: 'access-atual', refresh: 'refresh-0');

    final r = await ApiCaderneta.buscarFicha('access-velho');

    expect(r?['marca'], 'Honda');
    expect(api.refreshChamado, 0);
    expect(api.fichaChamada, 2);
  });

  test('depois de um refresh, o próximo 401 pede outro normalmente', () async {
    final api = _ApiFalsa(accessValido: 'x');
    ApiCaderneta.usarCliente(api.cliente());
    await SessaoSegura().gravar(token: 'a0', refresh: 'r0');

    await ApiCaderneta.buscarFicha('a0');
    expect(api.refreshChamado, 1);

    // Access vence de novo no servidor.
    api.accessValido = 'outro';
    await ApiCaderneta.buscarFicha('access-1');
    expect(api.refreshChamado, 2);
  });

  test('refresh recusado apaga a sessão e devolve o erro original', () async {
    final api = _ApiFalsa(accessValido: 'x')..refreshFalha = true;
    ApiCaderneta.usarCliente(api.cliente());
    await SessaoSegura().gravar(token: 'a0', refresh: 'r0');

    await expectLater(
      ApiCaderneta.buscarFicha('a0'),
      throwsA(isA<FalhaApi>()),
    );
    expect(api.refreshChamado, 1);
    expect(await SessaoSegura().lerToken(), isNull);
    expect(await SessaoSegura().lerRefresh(), isNull);
  });

  test('aquecer só chama /health quando há conta', () async {
    final api = _ApiFalsa(accessValido: 'a0');
    ApiCaderneta.usarCliente(api.cliente());

    await ApiCaderneta.aquecer();
    await Future<void>.delayed(Duration.zero);
    expect(api.healthChamado, 0);
    expect(ApiCaderneta.apiRespondeu, isFalse);

    await SessaoSegura().gravar(token: 'a0', refresh: 'r0');
    await ApiCaderneta.aquecer();
    await Future<void>.delayed(Duration.zero);
    expect(api.healthChamado, 1);
    expect(ApiCaderneta.apiRespondeu, isTrue);
  });

  test('qualquer resposta marca a API como viva', () async {
    final api = _ApiFalsa(accessValido: 'a0');
    ApiCaderneta.usarCliente(api.cliente());
    expect(ApiCaderneta.apiRespondeu, isFalse);

    await ApiCaderneta.buscarFicha('a0');
    expect(ApiCaderneta.apiRespondeu, isTrue);
  });
}
