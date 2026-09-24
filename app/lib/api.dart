import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart' show visibleForTesting;
import 'package:http/http.dart' as http;
import 'package:life_and_roads/core/config/ambiente.dart';
import 'package:life_and_roads/core/security/sessao_segura.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FalhaApi implements Exception {
  FalhaApi(this.mensagem);
  final String mensagem;

  @override
  String toString() => mensagem;
}

/// A caderneta na nuvem mudou em outro aparelho desde o último envio deste
/// (409). Nada foi gravado; quem chamou precisa perguntar qual fica.
class ConflitoNuvem extends FalhaApi {
  ConflitoNuvem(super.mensagem, {this.atualizadoEm});

  /// O carimbo que está no servidor agora, quando a API mandou.
  final String? atualizadoEm;
}

/// Cliente HTTP da API life.and.roads (porta 3001).
class ApiCaderneta {
  static String get padrao => Ambiente.apiPadrao;
  static const chaveBase = 'api_base_v1';
  static const _timeoutNormal = Duration(seconds: 8);

  /// Render no plano grátis hiberna após 15 min; acordar leva ~20 s.
  static const _timeoutPrimeiraResposta = Duration(seconds: 25);

  /// Vira true na primeira resposta HTTP desta sessão do app.
  static bool _apiRespondeu = false;

  /// Enquanto a API não deu sinal de vida, espera mais. Depois, 8 s.
  static Duration get _timeout =>
      _apiRespondeu ? _timeoutNormal : _timeoutPrimeiraResposta;

  static final SessaoSegura _sessaoSegura = SessaoSegura();
  static http.Client _cliente = http.Client();

  /// Um refresh por vez. Abas que caem no 401 juntas esperam o mesmo pedido
  /// em vez de mandar cada uma o seu com o mesmo refresh (a API trata reuso
  /// fora da janela como roubo e derruba a conta).
  static Future<String?>? _renovacaoEmVoo;

  /// Troca o transporte HTTP. Só para testes.
  @visibleForTesting
  static void usarCliente(http.Client cliente) {
    _cliente = cliente;
    _renovacaoEmVoo = null;
    _apiRespondeu = false;
  }

  @visibleForTesting
  static bool get apiRespondeu => _apiRespondeu;

  /// Acorda a API antes de o piloto precisar dela. Só com conta: sem conta
  /// nada sai do aparelho. Não espera a resposta e ignora falha.
  static Future<void> aquecer() async {
    final token = await _sessaoSegura.lerToken();
    if (token == null || token.isEmpty) return;
    unawaited(
      _cliente
          .get(Uri.parse('$base/health'))
          .timeout(_timeoutPrimeiraResposta)
          .then<void>((_) {
            _apiRespondeu = true;
          })
          .catchError((_) {}),
    );
  }

  static String _base = Ambiente.apiPadrao;
  static String get base => _base;

  static String _semBarra(String url) {
    final t = url.trim();
    if (t.endsWith('/')) return t.substring(0, t.length - 1);
    return t;
  }

  static Future<void> carregarBase() async {
    if (!Ambiente.exibeCampoServidor) {
      _base = padrao;
      return;
    }
    final prefs = await SharedPreferences.getInstance();
    final salvo = prefs.getString(chaveBase);
    if (salvo == null || salvo.trim().isEmpty) {
      _base = padrao;
      return;
    }
    _base = _semBarra(salvo);
  }

  static Future<void> definirBase(String url) async {
    if (!Ambiente.exibeCampoServidor) {
      _base = padrao;
      return;
    }
    final limpo = _semBarra(url);
    _base = limpo.isEmpty ? padrao : limpo;
    final prefs = await SharedPreferences.getInstance();
    if (limpo.isEmpty || limpo == padrao) {
      await prefs.remove(chaveBase);
    } else {
      await prefs.setString(chaveBase, _base);
    }
  }

  static double? numero(Object? valor) {
    if (valor == null) return null;
    if (valor is num) return valor.toDouble();
    return double.tryParse('$valor'.trim().replaceAll(',', '.'));
  }

  /// Qualquer resposta HTTP prova que a API está de pé.
  static http.Response _viva(http.Response r) {
    _apiRespondeu = true;
    return r;
  }

  static Map<String, String> _cabecalhos({String? token}) {
    return {
      'Content-Type': 'application/json',
      if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
    };
  }

  static Map<String, dynamic> _corpo(http.Response r) {
    if (r.body.isEmpty) return {};
    final decoded = jsonDecode(r.body);
    if (decoded is Map<String, dynamic>) return decoded;
    return {};
  }

  static FalhaApi _erro(http.Response r) {
    final corpo = _corpo(r);
    final msg = corpo['erro'] as String? ?? 'Falha na API (${r.statusCode}).';
    return FalhaApi(msg);
  }

  static Future<void> registrar(Map<String, dynamic> credenciais) async {
    final r = await _cliente
        .post(
          Uri.parse('$base/auth/registrar'),
          headers: _cabecalhos(),
          body: jsonEncode(credenciais),
        )
        .timeout(_timeout)
        .then(_viva);
    if (r.statusCode != 201) throw _erro(r);
  }

  static Future<Map<String, dynamic>> login(
    Map<String, dynamic> credenciais,
  ) async {
    final r = await _cliente
        .post(
          Uri.parse('$base/auth/login'),
          headers: _cabecalhos(),
          body: jsonEncode(credenciais),
        )
        .timeout(_timeout)
        .then(_viva);
    if (r.statusCode != 200) throw _erro(r);
    return _corpo(r);
  }

  static Future<http.Response> _comAuth(
    String token,
    Future<http.Response> Function(String token) enviar,
  ) async {
    final r = await enviar(token).timeout(_timeout).then(_viva);
    if (r.statusCode != 401) return r;

    // Outra aba pode ter renovado um instante antes. Usa o access mais novo
    // do storage antes de gastar mais um refresh.
    final guardado = await _sessaoSegura.lerToken();
    if (guardado != null && guardado.isNotEmpty && guardado != token) {
      final r2 = await enviar(guardado).timeout(_timeout).then(_viva);
      if (r2.statusCode != 401) return r2;
    }

    final novo = await renovarAccess();
    if (novo == null) return r;
    return enviar(novo).timeout(_timeout).then(_viva);
  }

  static Future<String?> renovarAccess() {
    final emVoo = _renovacaoEmVoo;
    if (emVoo != null) return emVoo;
    final pedido = _renovar().whenComplete(() => _renovacaoEmVoo = null);
    _renovacaoEmVoo = pedido;
    return pedido;
  }

  static Future<String?> _renovar() async {
    final refresh = await _sessaoSegura.lerRefresh();
    if (refresh == null || refresh.isEmpty) return null;
    try {
      final r = await _cliente
          .post(
            Uri.parse('$base/auth/refresh'),
            headers: _cabecalhos(),
            body: jsonEncode({'refreshToken': refresh}),
          )
          .timeout(_timeout)
          .then(_viva);
      if (r.statusCode != 200) {
        await _sessaoSegura.apagar();
        return null;
      }
      final corpo = _corpo(r);
      final token = '${corpo['token'] ?? ''}';
      final novoRefresh = '${corpo['refreshToken'] ?? refresh}';
      if (token.isEmpty) return null;
      await _sessaoSegura.gravar(token: token, refresh: novoRefresh);
      return token;
    } catch (_) {
      return null;
    }
  }

  static Future<void> encerrarSessaoRemota() async {
    final refresh = await _sessaoSegura.lerRefresh();
    if (refresh == null || refresh.isEmpty) return;
    try {
      await _cliente
          .post(
            Uri.parse('$base/auth/sair'),
            headers: _cabecalhos(),
            body: jsonEncode({'refreshToken': refresh}),
          )
          .timeout(_timeout)
          .then(_viva);
    } catch (_) {
      // local já apaga a sessão
    }
  }

  static Future<Map<String, dynamic>?> buscarFicha(String token) async {
    final r = await _comAuth(
      token,
      (t) => _cliente.get(
        Uri.parse('$base/ficha'),
        headers: _cabecalhos(token: t),
      ),
    );
    if (r.statusCode == 404) return null;
    if (r.statusCode != 200) throw _erro(r);
    return _corpo(r);
  }

  /// Devolve o corpo da resposta (ficha + `atualizadoEm` do servidor).
  static Future<Map<String, dynamic>> salvarFicha(
    String token,
    Map<String, dynamic> ficha,
  ) async {
    final r = await _comAuth(
      token,
      (t) => _cliente.put(
        Uri.parse('$base/ficha'),
        headers: _cabecalhos(token: t),
        body: jsonEncode(ficha),
      ),
    );
    if (r.statusCode != 200) throw _erro(r);
    return _corpo(r);
  }

  static Future<Map<String, dynamic>?> buscarManutencao(String token) async {
    final r = await _comAuth(
      token,
      (t) => _cliente.get(
        Uri.parse('$base/manutencao'),
        headers: _cabecalhos(token: t),
      ),
    );
    if (r.statusCode == 404) return null;
    if (r.statusCode != 200) throw _erro(r);
    return _corpo(r);
  }

  /// Devolve o corpo da resposta (datas + `atualizadoEm` do servidor).
  static Future<Map<String, dynamic>> salvarManutencao(
    String token,
    Map<String, dynamic> manutencao,
  ) async {
    final r = await _comAuth(
      token,
      (t) => _cliente.put(
        Uri.parse('$base/manutencao'),
        headers: _cabecalhos(token: t),
        body: jsonEncode(manutencao),
      ),
    );
    if (r.statusCode != 200) throw _erro(r);
    return _corpo(r);
  }

  static Future<Map<String, dynamic>?> buscarLocalizacao(String token) async {
    final r = await _comAuth(
      token,
      (t) => _cliente.get(
        Uri.parse('$base/localizacao'),
        headers: _cabecalhos(token: t),
      ),
    );
    if (r.statusCode == 404) return null;
    if (r.statusCode != 200) throw _erro(r);
    return _corpo(r);
  }

  static Future<void> salvarLocalizacao(
    String token, {
    required double latitude,
    required double longitude,
  }) async {
    final r = await _comAuth(
      token,
      (t) => _cliente.put(
        Uri.parse('$base/localizacao'),
        headers: _cabecalhos(token: t),
        body: jsonEncode({'latitude': latitude, 'longitude': longitude}),
      ),
    );
    if (r.statusCode != 200) throw _erro(r);
  }

  /// Caderneta guardada na conta, já aberta pelo servidor: `conteudo` e
  /// `atualizadoEm`. Null quando a conta ainda não tem (ADR 0038).
  static Future<Map<String, dynamic>?> buscarCaderneta(String token) async {
    final r = await _comAuth(
      token,
      (t) => _cliente.get(
        Uri.parse('$base/caderneta'),
        headers: _cabecalhos(token: t),
      ),
    );
    if (r.statusCode == 404) return null;
    if (r.statusCode != 200) throw _erro(r);
    return _corpo(r);
  }

  /// Grava se ninguém mexeu desde [carimboBase], o carimbo que este aparelho
  /// conhece (null na primeira vez). Devolve o carimbo novo. Se outro
  /// aparelho gravou antes, lança [ConflitoNuvem] e nada muda no servidor.
  static Future<String> salvarCaderneta(
    String token,
    Map<String, dynamic> conteudo, {
    required String? carimboBase,
  }) async {
    final r = await _comAuth(
      token,
      (t) => _cliente.put(
        Uri.parse('$base/caderneta'),
        headers: _cabecalhos(token: t),
        body: jsonEncode({
          'conteudo': conteudo,
          'baseAtualizadoEm': carimboBase,
        }),
      ),
    );
    if (r.statusCode == 409) {
      final corpo = _corpo(r);
      final detalhes = corpo['detalhes'];
      throw ConflitoNuvem(
        corpo['erro'] as String? ?? 'A caderneta na nuvem mudou em outro aparelho.',
        atualizadoEm: detalhes is Map ? detalhes['atualizadoEm'] as String? : null,
      );
    }
    if (r.statusCode != 200) throw _erro(r);
    final carimbo = _corpo(r)['atualizadoEm'];
    if (carimbo is! String) throw FalhaApi('Resposta da API sem carimbo.');
    return carimbo;
  }

  /// Apaga a caderneta da conta. Já não existir também é sucesso.
  static Future<void> apagarCaderneta(String token) async {
    final r = await _comAuth(
      token,
      (t) => _cliente.delete(
        Uri.parse('$base/caderneta'),
        headers: _cabecalhos(token: t),
      ),
    );
    if (r.statusCode != 204) throw _erro(r);
  }

  /// Registra o aceite dos termos por quem já tem conta.
  static Future<void> aceitarTermos(
    String token,
    Map<String, dynamic> termos,
  ) async {
    final r = await _comAuth(
      token,
      (t) => _cliente.post(
        Uri.parse('$base/auth/termos'),
        headers: _cabecalhos(token: t),
        body: jsonEncode(termos),
      ),
    );
    if (r.statusCode != 200) throw _erro(r);
  }

  static Future<void> excluirConta(String token) async {
    final r = await _comAuth(
      token,
      (t) => _cliente.delete(
        Uri.parse('$base/auth/conta'),
        headers: _cabecalhos(token: t),
      ),
    );
    if (r.statusCode != 200) throw _erro(r);
  }

  static Future<Map<String, dynamic>> trocarSenha(
    String token,
    Map<String, dynamic> troca,
  ) async {
    final r = await _comAuth(
      token,
      (t) => _cliente.post(
        Uri.parse('$base/auth/senha'),
        headers: _cabecalhos(token: t),
        body: jsonEncode(troca),
      ),
    );
    if (r.statusCode != 200) throw _erro(r);
    return _corpo(r);
  }

  /// Pede o código de recuperação por e-mail. A API responde 200 com ou
  /// sem conta para o e-mail; 429 e 503 chegam como [FalhaApi].
  static Future<void> recuperarSenha(Map<String, dynamic> pedido) async {
    final r = await _cliente
        .post(
          Uri.parse('$base/auth/recuperar'),
          headers: _cabecalhos(),
          body: jsonEncode(pedido),
        )
        .timeout(_timeout)
        .then(_viva);
    if (r.statusCode != 200) throw _erro(r);
  }

  /// Troca a senha com o código. Devolve o mesmo corpo do login.
  static Future<Map<String, dynamic>> redefinirSenha(
    Map<String, dynamic> pedido,
  ) async {
    final r = await _cliente
        .post(
          Uri.parse('$base/auth/redefinir'),
          headers: _cabecalhos(),
          body: jsonEncode(pedido),
        )
        .timeout(_timeout)
        .then(_viva);
    if (r.statusCode != 200) throw _erro(r);
    return _corpo(r);
  }

  /// Crash do aparelho. Sem ficha nem e-mail. Falha de rede é ignorada.
  static Future<void> relatarCrash({
    required String tipo,
    required String mensagem,
    required String ambiente,
    String? versaoApp,
    String? plataforma,
    String? pilha,
  }) async {
    try {
      await _cliente
          .post(
            Uri.parse('$base/monitor/evento'),
            headers: _cabecalhos(),
            body: jsonEncode({
              'tipo': tipo,
              'mensagem': mensagem,
              'ambiente': ambiente,
              'versaoApp': ?versaoApp,
              'plataforma': ?plataforma,
              'pilha': ?pilha,
            }),
          )
          .timeout(_timeout)
          .then(_viva);
    } catch (_) {}
  }
}
