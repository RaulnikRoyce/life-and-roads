import 'dart:convert';

import 'package:life_and_roads/api.dart';
import 'package:life_and_roads/core/backup/lista_backup.dart';
import 'package:life_and_roads/core/database/armazem_kv.dart';
import 'package:life_and_roads/core/database/caderneta_banco.dart';
import 'package:life_and_roads/core/database/chaves_kv.dart';
import 'package:life_and_roads/core/sync/ficha_sync_store.dart';
import 'package:life_and_roads/features/manutencao/data/manutencao_sync_store.dart';
import 'package:life_and_roads/ficha/foto.dart';
import 'package:life_and_roads/manutencao/servicos.dart';
import 'package:life_and_roads/mapa/pins.dart';
import 'package:life_and_roads/viagem/calculo.dart';
import 'package:life_and_roads/viagem/historico.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Exportação e restauração local da caderneta (JSON).
///
/// v1: listas como string nas chaves do SharedPreferences.
/// v2: listas estruturadas (SQLite). A restauração aceita as duas.
class BackupCaderneta {
  static const versao = 2;

  static Future<String> exportar() async {
    final foto = await FotoMoto.carregar();
    final abastecimentos = await HistoricoAbastecimento.carregar();
    final servicos = await HistoricoServico.carregar();
    final pins = await PinsMapa.carregar();
    final mapa = <String, dynamic>{
      'v': versao,
      'ficha': await ArmazemKv.lerTexto(ChavesKv.ficha),
      'foto': foto == null ? null : base64Encode(foto),
      'manutencao': await ArmazemKv.lerTexto(ChavesKv.agenda),
      'manutencaoKm': await ArmazemKv.lerTexto(ChavesKv.extra),
      'servicos': [for (final s in servicos) s.paraJson()],
      'abastecimentos': [for (final r in abastecimentos) r.paraJson()],
      'pins': [for (final p in pins) p.paraJson()],
      'ultimoPonto': await ArmazemKv.lerTexto(ChavesKv.ponto),
      'precoGasolina': await ArmazemKv.lerTexto(ChavesKv.precoGasolina),
      'precoAlcool': await ArmazemKv.lerTexto(ChavesKv.precoAlcool),
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
    final v = mapa['v'];
    if (v != 1 && v != 2) return 'Backup de outra versão.';

    await _gravaKv(ChavesKv.ficha, _textoOuMapa(mapa['ficha']));
    await _gravaFoto(mapa['foto']);
    await _gravaKv(ChavesKv.agenda, mapa['manutencao']);
    await _gravaKv(ChavesKv.extra, mapa['manutencaoKm']);
    await _gravaKv(ChavesKv.ponto, mapa['ultimoPonto']);
    await _gravaKv(ChavesKv.precoGasolina, mapa['precoGasolina']);
    await _gravaKv(ChavesKv.precoAlcool, mapa['precoAlcool']);

    final db = CadernetaBanco.instancia;
    await db.apagarAbastecimentos();
    await db.apagarServicos();
    await db.apagarPins();
    for (final r in listaDeBackup(
      mapa['abastecimentos'],
      RegistroAbastecimento.deJson,
    ).reversed) {
      await HistoricoAbastecimento.inserirLinha(r);
    }
    for (final r in listaDeBackup(
      mapa['servicos'],
      RegistroServico.deJson,
    ).reversed) {
      await HistoricoServico.inserirLinha(r);
    }
    final pins = listaDeBackup(mapa['pins'], PinoMapa.deJson);
    if (pins.isNotEmpty) await PinsMapa.salvar(pins);

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(HistoricoAbastecimento.chave);
    await prefs.remove(HistoricoServico.chave);
    await prefs.remove(PinsMapa.chave);
    for (final chave in ChavesKv.textos) {
      await prefs.remove(chave);
    }
    await prefs.remove(FotoMoto.chave);

    final token = prefs.getString(ApiCaderneta.chaveToken);
    if (token != null && token.isNotEmpty) {
      await FichaSyncStore().marcarPendente();
      await ManutencaoSyncStore().marcarPendente();
    }
    return null;
  }

  static Object? _textoOuMapa(Object? valor) {
    if (valor is Map) return jsonEncode(valor);
    return valor;
  }

  static Future<void> _gravaKv(String chave, Object? valor) async {
    if (valor is! String || valor.isEmpty) {
      await ArmazemKv.gravarTexto(chave, null);
      return;
    }
    await ArmazemKv.gravarTexto(chave, valor);
  }

  static Future<void> _gravaFoto(Object? valor) async {
    if (valor is! String || valor.isEmpty) {
      await FotoMoto.apagar();
      return;
    }
    try {
      await FotoMoto.salvar(base64Decode(valor));
    } on FormatException {
      await FotoMoto.apagar();
    }
  }
}
