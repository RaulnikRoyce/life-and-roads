import 'dart:convert';

import 'package:life_and_roads/api.dart';
import 'package:life_and_roads/ficha/foto.dart';
import 'package:life_and_roads/manutencao/extra.dart';
import 'package:life_and_roads/manutencao/servicos.dart';
import 'package:life_and_roads/mapa/pins.dart';
import 'package:life_and_roads/mapa/ponto.dart';
import 'package:life_and_roads/viagem/historico.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Cópia da caderneta neste aparelho. Sem placa. Quem não quer login usa isto.
class BackupCaderneta {
  static const versao = 1;
  static const chavePrecoGasolina = 'preco_litro_v1';
  static const chavePrecoAlcool = 'preco_alcool_v1';
  static const chaveManutencao = 'manutencao_v1';

  static Future<String> exportar() async {
    final prefs = await SharedPreferences.getInstance();
    final mapa = <String, dynamic>{
      'v': versao,
      'ficha': prefs.getString(ApiCaderneta.chaveFicha),
      'foto': prefs.getString(FotoMoto.chave),
      'manutencao': prefs.getString(chaveManutencao),
      'manutencaoKm': prefs.getString(ManutencaoExtra.chave),
      'servicos': prefs.getString(HistoricoServico.chave),
      'abastecimentos': prefs.getString(HistoricoAbastecimento.chave),
      'pins': prefs.getString(PinsMapa.chave),
      'ultimoPonto': prefs.getString(chaveUltimoPonto),
      'precoGasolina': prefs.getString(chavePrecoGasolina),
      'precoAlcool': prefs.getString(chavePrecoAlcool),
    };
    return jsonEncode(mapa);
  }

  static Future<String?> restaurar(String bruto) async {
    final Object decodificado;
    try {
      decodificado = jsonDecode(bruto.trim());
    } on FormatException {
      return 'Backup inválido.';
    }
    if (decodificado is! Map) return 'Backup inválido.';
    final mapa = Map<String, dynamic>.from(decodificado);
    if (mapa['v'] != versao) return 'Backup de outra versão.';

    final prefs = await SharedPreferences.getInstance();
    await _grava(prefs, ApiCaderneta.chaveFicha, mapa['ficha']);
    await _grava(prefs, FotoMoto.chave, mapa['foto']);
    await _grava(prefs, chaveManutencao, mapa['manutencao']);
    await _grava(prefs, ManutencaoExtra.chave, mapa['manutencaoKm']);
    await _grava(prefs, HistoricoServico.chave, mapa['servicos']);
    await _grava(prefs, HistoricoAbastecimento.chave, mapa['abastecimentos']);
    await _grava(prefs, PinsMapa.chave, mapa['pins']);
    await _grava(prefs, chaveUltimoPonto, mapa['ultimoPonto']);
    await _grava(prefs, chavePrecoGasolina, mapa['precoGasolina']);
    await _grava(prefs, chavePrecoAlcool, mapa['precoAlcool']);
    return null;
  }

  static Future<void> _grava(
    SharedPreferences prefs,
    String chave,
    Object? valor,
  ) async {
    if (valor is! String || valor.isEmpty) {
      await prefs.remove(chave);
      return;
    }
    await prefs.setString(chave, valor);
  }
}
