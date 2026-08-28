import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:life_and_roads/backup.dart';
import 'package:life_and_roads/core/database/armazem_kv.dart';
import 'package:life_and_roads/core/database/migracao_prefs.dart';
import 'package:life_and_roads/ficha/foto.dart';
import 'package:life_and_roads/mapa/pins.dart';
import 'package:life_and_roads/mapa/ponto.dart';
import 'package:life_and_roads/viagem/calculo.dart';
import 'package:life_and_roads/viagem/historico.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../helpers/banco_teste.dart';

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await abrirBancoTeste();
  });

  tearDown(() async {
    await fecharBancoTeste();
  });

  test('JSON legado de abastecimento migra para o SQLite', () async {
    final prefs = await SharedPreferences.getInstance();
    final consumo = consumoDoPainel(kmAnterior: 1000, kmPainel: 1200, litros: 5)!;
    final registro = registroDoPosto(
      consumo: consumo,
      litros: 5,
      precoLitro: 6,
      kmPainel: 1200,
      combustivel: Combustivel.gasolina,
      agora: DateTime(2026, 8, 24),
    )!;
    await prefs.setString(
      HistoricoAbastecimento.chave,
      jsonEncode([registro.paraJson()]),
    );
    await prefs.setString(
      PinsMapa.chave,
      jsonEncode([
        {'tipo': 'posto', 'latitude': -23.5, 'longitude': -46.6},
      ]),
    );

    await MigracaoPrefsDrift.executar();

    final lista = await HistoricoAbastecimento.carregar();
    expect(lista, hasLength(1));
    expect(lista.first.reaisPorKm, 0.15);
    expect(prefs.getString(HistoricoAbastecimento.chave), isNull);

    final pins = await PinsMapa.carregar();
    expect(pins, hasLength(1));
    expect(pins.first.tipo, 'posto');
  });

  test('backup v1 restaura ficha e listas no SQLite', () async {
    final v1 = jsonEncode({
      'v': 1,
      'ficha': '{"marca":"Honda","modelo":"CG 160"}',
      'abastecimentos': jsonEncode([
        {
          'em': '2026-08-24T00:00:00.000',
          'combustivel': 'gasolina',
          'kmPainel': 1200,
          'kmRodados': 200,
          'litros': 5,
          'precoLitro': 6,
          'reais': 30,
          'kmPorLitro': 40,
          'reaisPorKm': 0.15,
        },
      ]),
    });
    expect(await BackupCaderneta.restaurar(v1), isNull);
    final prefs = await SharedPreferences.getInstance();
    expect(await ArmazemKv.lerTexto('ficha_moto_v1'), contains('CG 160'));
    expect(prefs.getString('ficha_moto_v1'), isNull);
    expect(await HistoricoAbastecimento.carregar(), hasLength(1));
  });

  test('backup v2 exporta listas estruturadas', () async {
    final consumo = consumoDoPainel(kmAnterior: 1000, kmPainel: 1200, litros: 5)!;
    final registro = registroDoPosto(
      consumo: consumo,
      litros: 5,
      precoLitro: 6,
      kmPainel: 1200,
      combustivel: Combustivel.gasolina,
      agora: DateTime(2026, 8, 24),
    )!;
    await HistoricoAbastecimento.acrescentar(registro);
    final bruto = await BackupCaderneta.exportar();
    final mapa = jsonDecode(bruto) as Map<String, dynamic>;
    expect(mapa['v'], 2);
    expect(mapa['abastecimentos'], isA<List>());
    expect((mapa['abastecimentos'] as List), hasLength(1));
  });

  test('ficha, foto e ponto migram para o KV; token e tema ficam nas prefs',
      () async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('ficha_moto_v1', '{"marca":"Honda"}');
    await prefs.setString('foto_moto_v1', base64Encode([9, 8, 7]));
    await prefs.setString(
      'ultimo_ponto_v1',
      '{"latitude":-23.5,"longitude":-46.6}',
    );
    await prefs.setString('preco_litro_v1', '6.19');
    await prefs.setString('token_life_and_roads', 'abc');
    await prefs.setString('tema_v1', 'escuro');
    await prefs.setString('api_base_v1', 'http://10.0.0.2:3001');

    await MigracaoPrefsDrift.executar();

    expect(prefs.getString('ficha_moto_v1'), isNull);
    expect(prefs.getString('foto_moto_v1'), isNull);
    expect(prefs.getString('ultimo_ponto_v1'), isNull);
    expect(prefs.getString('preco_litro_v1'), isNull);
    expect(prefs.getString('token_life_and_roads'), 'abc');
    expect(prefs.getString('tema_v1'), 'escuro');
    expect(prefs.getString('api_base_v1'), 'http://10.0.0.2:3001');
    expect(await ArmazemKv.lerTexto('ficha_moto_v1'), contains('Honda'));
    expect(await ArmazemKv.lerTexto('preco_litro_v1'), '6.19');
    expect(await FotoMoto.carregar(), [9, 8, 7]);
    expect((await carregarUltimoPonto())?.latitude, -23.5);
  });
}
