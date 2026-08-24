import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// Um serviço na oficina: km do painel + o que pagou. Neste aparelho.
class RegistroServico {
  const RegistroServico({
    required this.em,
    required this.tipo,
    required this.kmPainel,
    required this.reais,
  });

  final String em;
  final String tipo;
  final double kmPainel;
  final double reais;

  Map<String, dynamic> paraJson() => {
        'em': em,
        'tipo': tipo,
        'kmPainel': kmPainel,
        'reais': reais,
      };

  static RegistroServico? deJson(Object? bruto) {
    if (bruto is! Map) return null;
    final mapa = Map<String, dynamic>.from(bruto);
    final km = _num(mapa['kmPainel']);
    final reais = _num(mapa['reais']);
    final tipo = '${mapa['tipo'] ?? ''}'.trim();
    if (km == null || reais == null || tipo.isEmpty) return null;
    if (km < 0 || km > 999999 || reais < 0 || reais > 20000) return null;
    final em = '${mapa['em'] ?? ''}'.trim();
    return RegistroServico(
      em: em.isEmpty ? DateTime.now().toIso8601String() : em,
      tipo: tipo.length > 40 ? tipo.substring(0, 40) : tipo,
      kmPainel: km,
      reais: reais,
    );
  }

  static double? _num(Object? valor) {
    if (valor == null) return null;
    if (valor is num) return valor.toDouble();
    return double.tryParse('$valor'.trim().replaceAll(',', '.'));
  }
}

class HistoricoServico {
  static const chave = 'servicos_v1';
  static const max = 20;

  static Future<List<RegistroServico>> carregar() async {
    final prefs = await SharedPreferences.getInstance();
    final bruto = prefs.getString(chave);
    if (bruto == null || bruto.isEmpty) return [];
    try {
      final lista = jsonDecode(bruto);
      if (lista is! List) return [];
      return lista.map(RegistroServico.deJson).whereType<RegistroServico>().toList();
    } on FormatException {
      return [];
    }
  }

  static Future<List<RegistroServico>> acrescentar(RegistroServico registro) async {
    final atual = await carregar();
    final juntos = [registro, ...atual].take(max).toList();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      chave,
      jsonEncode([for (final r in juntos) r.paraJson()]),
    );
    return juntos;
  }
}
