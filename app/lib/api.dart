import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class FalhaApi implements Exception {
  FalhaApi(this.mensagem);
  final String mensagem;

  @override
  String toString() => mensagem;
}

/// Cliente da API life.and.roads (porta 3001). O Beco fica no 3000.
class ApiCaderneta {
  static const padrao = String.fromEnvironment(
    'API_BASE',
    defaultValue: 'http://localhost:3001',
  );
  static const chaveToken = 'token_life_and_roads';
  static const chaveFicha = 'ficha_moto_v1';
  static const chaveBase = 'api_base_v1';
  static const _timeout = Duration(seconds: 8);

  static String _base = padrao;
  static String get base => _base;

  static String _semBarra(String url) {
    final t = url.trim();
    if (t.endsWith('/')) return t.substring(0, t.length - 1);
    return t;
  }

  static Future<void> carregarBase() async {
    final prefs = await SharedPreferences.getInstance();
    final salvo = prefs.getString(chaveBase);
    if (salvo == null || salvo.trim().isEmpty) {
      _base = padrao;
      return;
    }
    _base = _semBarra(salvo);
  }

  static Future<void> definirBase(String url) async {
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

  static Future<Map<String, dynamic>?> buscarFicha(String token) async {
    final r = await http
        .get(Uri.parse('$base/ficha'), headers: _cabecalhos(token: token))
        .timeout(_timeout);
    if (r.statusCode == 404) return null;
    if (r.statusCode != 200) throw _erro(r);
    return _corpo(r);
  }

  static Future<void> salvarFicha(String token, Map<String, dynamic> ficha) async {
    final r = await http
        .put(
          Uri.parse('$base/ficha'),
          headers: _cabecalhos(token: token),
          body: jsonEncode(ficha),
        )
        .timeout(_timeout);
    if (r.statusCode != 200) throw _erro(r);
  }

  static Future<Map<String, dynamic>?> buscarManutencao(String token) async {
    final r = await http
        .get(Uri.parse('$base/manutencao'), headers: _cabecalhos(token: token))
        .timeout(_timeout);
    if (r.statusCode == 404) return null;
    if (r.statusCode != 200) throw _erro(r);
    return _corpo(r);
  }

  static Future<void> salvarManutencao(
    String token,
    Map<String, dynamic> manutencao,
  ) async {
    final r = await http
        .put(
          Uri.parse('$base/manutencao'),
          headers: _cabecalhos(token: token),
          body: jsonEncode(manutencao),
        )
        .timeout(_timeout);
    if (r.statusCode != 200) throw _erro(r);
  }

  static Future<Map<String, dynamic>?> buscarLocalizacao(String token) async {
    final r = await http
        .get(Uri.parse('$base/localizacao'), headers: _cabecalhos(token: token))
        .timeout(_timeout);
    if (r.statusCode == 404) return null;
    if (r.statusCode != 200) throw _erro(r);
    return _corpo(r);
  }

  static Future<void> salvarLocalizacao(
    String token, {
    required double latitude,
    required double longitude,
  }) async {
    final r = await http
        .put(
          Uri.parse('$base/localizacao'),
          headers: _cabecalhos(token: token),
          body: jsonEncode({
            'latitude': latitude,
            'longitude': longitude,
          }),
        )
        .timeout(_timeout);
    if (r.statusCode != 200) throw _erro(r);
  }
}
