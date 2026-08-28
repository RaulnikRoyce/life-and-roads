import 'dart:convert';

import 'package:life_and_roads/core/database/caderneta_banco.dart';
import 'package:life_and_roads/core/database/chaves_kv.dart';
import 'package:life_and_roads/ficha/foto.dart';
import 'package:life_and_roads/manutencao/servicos.dart';
import 'package:life_and_roads/mapa/pins.dart';
import 'package:life_and_roads/viagem/calculo.dart';
import 'package:life_and_roads/viagem/historico.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Copia JSON legado das prefs para o SQLite e apaga as chaves.
class MigracaoPrefsDrift {
  static Future<void> executar() async {
    final db = CadernetaBanco.instancia;
    final prefs = await SharedPreferences.getInstance();

    if (await db.contar('abastecimentos') == 0) {
      for (final r in _lista(
        prefs.getString(HistoricoAbastecimento.chave),
        RegistroAbastecimento.deJson,
      ).reversed) {
        await HistoricoAbastecimento.inserirLinha(r);
      }
    }
    if (await db.contar('servicos') == 0) {
      for (final r in _lista(
        prefs.getString(HistoricoServico.chave),
        RegistroServico.deJson,
      ).reversed) {
        await HistoricoServico.inserirLinha(r);
      }
    }
    if (await db.contar('pins') == 0) {
      final pins = _lista(prefs.getString(PinsMapa.chave), PinoMapa.deJson);
      if (pins.isNotEmpty) await PinsMapa.salvar(pins);
    }

    for (final chave in ChavesKv.textos) {
      final bruto = prefs.getString(chave);
      if (bruto == null || bruto.isEmpty) continue;
      if (await db.lerTextoKv(chave) != null) continue;
      await db.gravarTextoKv(chave, bruto);
    }

    final fotoPrefs = prefs.getString(FotoMoto.chave);
    if (fotoPrefs != null && fotoPrefs.isNotEmpty) {
      final ja = await db.lerBlobKv(ChavesKv.foto);
      if (ja == null) {
        try {
          final bytes = base64Decode(fotoPrefs);
          if (bytes.isNotEmpty) {
            await db.gravarBlobKv(ChavesKv.foto, bytes);
          }
        } on FormatException {
          // ignora
        }
      }
    }

    await prefs.remove(HistoricoAbastecimento.chave);
    await prefs.remove(HistoricoServico.chave);
    await prefs.remove(PinsMapa.chave);
    for (final chave in ChavesKv.textos) {
      await prefs.remove(chave);
    }
    await prefs.remove(FotoMoto.chave);
  }

  static List<T> _lista<T>(String? bruto, T? Function(Object?) parse) {
    if (bruto == null || bruto.isEmpty) return [];
    try {
      final decodificado = jsonDecode(bruto);
      if (decodificado is! List) return [];
      return [
        for (final item in decodificado)
          if (parse(item) case final T v) v,
      ];
    } on FormatException {
      return [];
    }
  }
}
