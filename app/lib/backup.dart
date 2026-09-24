import 'dart:convert';

import 'package:life_and_roads/core/backup/lista_backup.dart';
import 'package:life_and_roads/core/database/armazem_kv.dart';
import 'package:life_and_roads/core/database/caderneta_banco.dart';
import 'package:life_and_roads/core/database/chaves_kv.dart';
import 'package:life_and_roads/core/security/sessao_segura.dart';
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

    // Com conta, o que veio do backup precisa subir na próxima abertura.
    final token = await SessaoSegura().lerToken();
    if (token != null && token.isNotEmpty) {
      await FichaSyncStore().marcarPendente();
      await ManutencaoSyncStore().marcarPendente();
    }
    return null;
  }

  // Caderneta na nuvem (ADR 0038).

  static const versaoNuvem = 1;

  /// O que só existe neste aparelho, menos a foto. Ficha, datas de
  /// manutenção e último ponto têm rota própria e ficam de fora, para cada
  /// dado ter uma fonte só. As chaves são as do `ConteudoCaderneta` do
  /// openapi.yaml, e a API recusa qualquer outra.
  static Future<Map<String, dynamic>> exportarParaNuvem() async {
    final abastecimentos = await HistoricoAbastecimento.carregar();
    final servicos = await HistoricoServico.carregar();
    final pins = await PinsMapa.carregar();
    final ficha = await _fichaCrua();
    return {
      'v': versaoNuvem,
      'abastecimentos': [for (final r in abastecimentos) r.paraJson()],
      'servicos': [for (final s in servicos) s.paraJson()],
      'pins': [for (final p in pins) p.paraJson()],
      'extra': await ArmazemKv.lerTexto(ChavesKv.extra),
      'precoGasolina': await ArmazemKv.lerTexto(ChavesKv.precoGasolina),
      'precoAlcool': await ArmazemKv.lerTexto(ChavesKv.precoAlcool),
      'psi': {
        'dianteiro': _psi(ficha?['psiDianteiro']),
        'traseiro': _psi(ficha?['psiTraseiro']),
      },
    };
  }

  /// Troca abastecimentos, serviços, pinos, km e CNH e preços pelos da nuvem.
  /// Não passa pelo [restaurar]: lá a falta de foto apaga a foto, e aqui ela
  /// nunca vem. O PSI entra na ficha que já existe sem mexer no resto dela;
  /// sem ficha no aparelho, fica para depois que a ficha chegar da conta.
  static Future<String?> restaurarDaNuvem(Map<String, dynamic> conteudo) async {
    if (conteudo['v'] != versaoNuvem) return 'Caderneta de outra versão.';

    final db = CadernetaBanco.instancia;
    // Tudo ou nada: parar no meio deixaria o aparelho sem histórico.
    await db.transaction(() async {
      await db.apagarAbastecimentos();
      await db.apagarServicos();
      await db.apagarPins();
      for (final r in listaDeBackup(
        conteudo['abastecimentos'],
        RegistroAbastecimento.deJson,
      ).reversed) {
        await HistoricoAbastecimento.inserirLinha(r);
      }
      for (final r in listaDeBackup(
        conteudo['servicos'],
        RegistroServico.deJson,
      ).reversed) {
        await HistoricoServico.inserirLinha(r);
      }
      final pins = listaDeBackup(conteudo['pins'], PinoMapa.deJson);
      if (pins.isNotEmpty) await PinsMapa.salvar(pins);

      await _gravaKv(ChavesKv.extra, conteudo['extra']);
      await _gravaKv(ChavesKv.precoGasolina, conteudo['precoGasolina']);
      await _gravaKv(ChavesKv.precoAlcool, conteudo['precoAlcool']);
      await _mesclarPsi(conteudo['psi']);
    });
    return null;
  }

  static Future<Map<String, dynamic>?> _fichaCrua() async {
    final bruto = await ArmazemKv.lerTexto(ChavesKv.ficha);
    if (bruto == null) return null;
    try {
      final mapa = jsonDecode(bruto);
      return mapa is Map ? Map<String, dynamic>.from(mapa) : null;
    } on FormatException {
      return null;
    }
  }

  /// A API aceita 0 a 200. Fora disso vai nulo, para um número estranho
  /// não travar o envio da caderneta inteira.
  static int? _psi(Object? valor) {
    final n = valor is int ? valor : int.tryParse('${valor ?? ''}'.trim());
    if (n == null || n < 0 || n > 200) return null;
    return n;
  }

  /// Só o PSI muda, e só o lado que a nuvem trouxe. A ficha guarda o PSI
  /// como texto, do mesmo jeito que a tela grava.
  static Future<void> _mesclarPsi(Object? psi) async {
    if (psi is! Map) return;
    final ficha = await _fichaCrua();
    if (ficha == null) return;
    final dianteiro = _psi(psi['dianteiro']);
    final traseiro = _psi(psi['traseiro']);
    if (dianteiro == null && traseiro == null) return;
    if (dianteiro != null) ficha['psiDianteiro'] = '$dianteiro';
    if (traseiro != null) ficha['psiTraseiro'] = '$traseiro';
    await ArmazemKv.gravarTexto(ChavesKv.ficha, jsonEncode(ficha));
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
