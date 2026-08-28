import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:life_and_roads/core/config/ambiente.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FalhaApi implements Exception {
  FalhaApi(this.mensagem);
  final String mensagem;

  @override
  String toString() => mensagem;
}

/// Cliente HTTP da API life.and.roads (porta 3001).
class ApiCaderneta {
  static String get padrao => Ambiente.apiPadrao;
  static const chaveToken = 'token_life_and_roads';
  static const chaveRefresh = 'refresh_life_and_roads';
  static const chaveBase = 'api_base_v1';
  static const _timeout = Duration(seconds: 8);

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

  static Map<String, dynamic> fichaParaApi(Map<String, dynamic> mapa) {
    final ano = '${mapa['ano'] ?? ''}'.trim();
    final cc = '${mapa['cilindrada'] ?? ''}'.trim();
    final comb = '${mapa['combustivel'] ?? 'gasolina'}';
    return {
      'marca': mapa['marca'],
      'modelo': mapa['modelo'],
      'ano': ano.isEmpty ? null : int.tryParse(ano),
      'cilindrada': cc.isEmpty ? null : int.tryParse(cc),
      'kmLitro': numero(mapa['kmLitro']),
      'kmLitroAlcool': numero(mapa['kmLitroAlcool']),
      'combustivel': comb == 'alcool' ? 'alcool' : 'gasolina',
      'kmAtual': numero(mapa['kmAtual']),
      'tanqueLitros': numero(mapa['tanqueLitros']),
      'personalizacoes': mapa['personalizacoes'] ?? '',
    };
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

  static Future<void> registrar(String email, String senha) async {
    final r = await http
        .post(
          Uri.parse('$base/auth/registrar'),
          headers: _cabecalhos(),
          body: jsonEncode({'email': email, 'senha': senha}),
        )
        .timeout(_timeout);
    if (r.statusCode != 201) throw _erro(r);
  }

  static Future<Map<String, dynamic>> login(String email, String senha) async {
    final r = await http
        .post(
          Uri.parse('$base/auth/login'),
          headers: _cabecalhos(),
          body: jsonEncode({'email': email, 'senha': senha}),
        )
        .timeout(_timeout);
    if (r.statusCode != 200) throw _erro(r);
    return _corpo(r);
  }

  static Future<http.Response> _comAuth(
    String token,
    Future<http.Response> Function(String token) enviar,
  ) async {
    final r = await enviar(token).timeout(_timeout);
    if (r.statusCode != 401) return r;
    final novo = await renovarAccess();
    if (novo == null) return r;
    return enviar(novo).timeout(_timeout);
  }

  static Future<String?> renovarAccess() async {
    final prefs = await SharedPreferences.getInstance();
    final refresh = prefs.getString(chaveRefresh);
    if (refresh == null || refresh.isEmpty) return null;
    try {
      final r = await http
          .post(
            Uri.parse('$base/auth/refresh'),
            headers: _cabecalhos(),
            body: jsonEncode({'refreshToken': refresh}),
          )
          .timeout(_timeout);
      if (r.statusCode != 200) {
        await prefs.remove(chaveToken);
        await prefs.remove(chaveRefresh);
        return null;
      }
      final corpo = _corpo(r);
      final token = '${corpo['token'] ?? ''}';
      final novoRefresh = '${corpo['refreshToken'] ?? refresh}';
      if (token.isEmpty) return null;
      await prefs.setString(chaveToken, token);
      await prefs.setString(chaveRefresh, novoRefresh);
      return token;
    } catch (_) {
      return null;
    }
  }

  static Future<void> encerrarSessaoRemota() async {
    final prefs = await SharedPreferences.getInstance();
    final refresh = prefs.getString(chaveRefresh);
    if (refresh == null || refresh.isEmpty) return;
    try {
      await http
          .post(
            Uri.parse('$base/auth/sair'),
            headers: _cabecalhos(),
            body: jsonEncode({'refreshToken': refresh}),
          )
          .timeout(_timeout);
    } catch (_) {
      // local já apaga a sessão
    }
  }

  static Future<Map<String, dynamic>?> buscarFicha(String token) async {
    final r = await _comAuth(
      token,
      (t) => http.get(Uri.parse('$base/ficha'), headers: _cabecalhos(token: t)),
    );
    if (r.statusCode == 404) return null;
    if (r.statusCode != 200) throw _erro(r);
    return _corpo(r);
  }

  static Future<void> salvarFicha(String token, Map<String, dynamic> ficha) async {
    final r = await _comAuth(
      token,
      (t) => http.put(
        Uri.parse('$base/ficha'),
        headers: _cabecalhos(token: t),
        body: jsonEncode(ficha),
      ),
    );
    if (r.statusCode != 200) throw _erro(r);
  }

  static Future<Map<String, dynamic>?> buscarManutencao(String token) async {
    final r = await _comAuth(
      token,
      (t) => http.get(
        Uri.parse('$base/manutencao'),
        headers: _cabecalhos(token: t),
      ),
    );
    if (r.statusCode == 404) return null;
    if (r.statusCode != 200) throw _erro(r);
    return _corpo(r);
  }

  static Future<void> salvarManutencao(
    String token,
    Map<String, dynamic> manutencao,
  ) async {
    final r = await _comAuth(
      token,
      (t) => http.put(
        Uri.parse('$base/manutencao'),
        headers: _cabecalhos(token: t),
        body: jsonEncode(manutencao),
      ),
    );
    if (r.statusCode != 200) throw _erro(r);
  }

  static Future<Map<String, dynamic>?> buscarLocalizacao(String token) async {
    final r = await _comAuth(
      token,
      (t) => http.get(
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
      (t) => http.put(
        Uri.parse('$base/localizacao'),
        headers: _cabecalhos(token: t),
        body: jsonEncode({
          'latitude': latitude,
          'longitude': longitude,
        }),
      ),
    );
    if (r.statusCode != 200) throw _erro(r);
  }

  static Future<void> excluirConta(String token) async {
    final r = await _comAuth(
      token,
      (t) => http.delete(
        Uri.parse('$base/auth/conta'),
        headers: _cabecalhos(token: t),
      ),
    );
    if (r.statusCode != 200) throw _erro(r);
  }

  static Future<Map<String, dynamic>> trocarSenha({
    required String token,
    required String senhaAtual,
    required String senhaNova,
  }) async {
    final r = await _comAuth(
      token,
      (t) => http.post(
        Uri.parse('$base/auth/senha'),
        headers: _cabecalhos(token: t),
        body: jsonEncode({
          'senhaAtual': senhaAtual,
          'senhaNova': senhaNova,
        }),
      ),
    );
    if (r.statusCode != 200) throw _erro(r);
    return _corpo(r);
  }

  /// Crash do aparelho. Sem ficha nem e-mail. Falha de rede é ignorada.
  static Future<void> relatarCrash({
    required String tipo,
    required String mensagem,
    required String ambiente,
  }) async {
    try {
      await http
          .post(
            Uri.parse('$base/monitor/evento'),
            headers: _cabecalhos(),
            body: jsonEncode({
              'tipo': tipo,
              'mensagem': mensagem,
              'ambiente': ambiente,
            }),
          )
          .timeout(_timeout);
    } catch (_) {}
  }
}
