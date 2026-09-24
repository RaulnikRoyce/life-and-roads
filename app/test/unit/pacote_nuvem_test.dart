import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:life_and_roads/backup.dart';
import 'package:life_and_roads/core/backup/backup_nuvem.dart';
import 'package:life_and_roads/core/database/armazem_kv.dart';
import 'package:life_and_roads/core/database/caderneta_banco.dart';
import 'package:life_and_roads/core/database/chaves_kv.dart';
import 'package:life_and_roads/ficha/foto.dart';
import 'package:life_and_roads/manutencao/servicos.dart';
import 'package:life_and_roads/mapa/pins.dart';
import 'package:life_and_roads/viagem/calculo.dart';
import 'package:life_and_roads/viagem/historico.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../helpers/banco_teste.dart';

const _abastecimento = RegistroAbastecimento(
  em: '2026-09-20',
  combustivel: Combustivel.gasolina,
  kmPainel: 12000,
  kmRodados: 310,
  litros: 9.5,
  precoLitro: 6.29,
  reais: 59.76,
  kmPorLitro: 32.6,
  reaisPorKm: 0.19,
);

const _servico = RegistroServico(
  em: '2026-09-01',
  tipo: 'oleo',
  kmPainel: 11800,
  reais: 80,
);

const _pino = PinoMapa(tipo: 'posto', latitude: -20.75, longitude: -42.88);

final _foto = Uint8List.fromList([7, 7, 7]);

Future<void> _gravarFicha({String psiD = '25', String psiT = '29'}) {
  return ArmazemKv.gravarTexto(
    ChavesKv.ficha,
    jsonEncode({
      'marca': 'Honda',
      'modelo': 'Bros 160',
      'kmLitro': '35',
      'kmAtual': '12000',
      'psiDianteiro': psiD,
      'psiTraseiro': psiT,
    }),
  );
}

/// Um celular com tudo preenchido.
Future<void> _encherAparelho() async {
  await _gravarFicha();
  await FotoMoto.salvar(_foto);
  await ArmazemKv.gravarTexto(ChavesKv.agenda, '{"oleoUltima":"2026-09-01"}');
  await ArmazemKv.gravarTexto(ChavesKv.ponto, '{"lat":-20.7,"lng":-42.8}');
  await ArmazemKv.gravarTexto(ChavesKv.extra, '{"kmOleo":"11800"}');
  await ArmazemKv.gravarTexto(ChavesKv.precoGasolina, '6,29');
  await ArmazemKv.gravarTexto(ChavesKv.precoAlcool, '4,39');
  await HistoricoAbastecimento.acrescentar(_abastecimento);
  await HistoricoServico.acrescentar(_servico);
  await PinsMapa.salvar([_pino]);
}

Future<Map<String, dynamic>> _fichaGuardada() async {
  final bruto = await ArmazemKv.lerTexto(ChavesKv.ficha);
  return Map<String, dynamic>.from(jsonDecode(bruto!) as Map);
}

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await abrirBancoTeste();
  });

  tearDown(fecharBancoTeste);

  test('o pacote leva o que só existe no aparelho, e nada além', () async {
    await _encherAparelho();

    final pacote = await BackupCaderneta.exportarParaNuvem();

    expect(pacote.keys, [
      'v',
      'abastecimentos',
      'servicos',
      'pins',
      'extra',
      'precoGasolina',
      'precoAlcool',
      'psi',
    ]);
    expect(pacote['v'], 1);
    expect(pacote['abastecimentos'], [_abastecimento.paraJson()]);
    expect(pacote['servicos'], [_servico.paraJson()]);
    expect(pacote['pins'], [_pino.paraJson()]);
    expect(pacote['extra'], '{"kmOleo":"11800"}');
    expect(pacote['precoGasolina'], '6,29');
    expect(pacote['psi'], {'dianteiro': 25, 'traseiro': 29});

    final texto = jsonEncode(pacote);
    expect(texto, isNot(contains('Bros')), reason: 'a ficha tem rota própria');
    expect(texto, isNot(contains('oleoUltima')), reason: 'as datas também');
    expect(texto, isNot(contains('-42.8}')), reason: 'e o último ponto');
    expect(texto, isNot(contains(base64Encode(_foto))), reason: 'foto fica');
  });

  test('aparelho vazio vira pacote vazio, que a API aceita', () async {
    final pacote = await BackupCaderneta.exportarParaNuvem();
    expect(pacote['abastecimentos'], isEmpty);
    expect(pacote['extra'], isNull);
    expect(pacote['psi'], {'dianteiro': null, 'traseiro': null});
  });

  test('PSI fora do que a API aceita vai nulo em vez de travar o envio', () async {
    await _gravarFicha(psiD: '999', psiT: 'abc');
    final pacote = await BackupCaderneta.exportarParaNuvem();
    expect(pacote['psi'], {'dianteiro': null, 'traseiro': null});
  });

  test('restaurar troca o histórico e mantém foto, ficha, datas e ponto', () async {
    await _encherAparelho();
    final pacote = {
      'v': 1,
      'abastecimentos': [
        {..._abastecimento.paraJson(), 'kmPainel': 15000.0},
        {..._abastecimento.paraJson(), 'kmPainel': 14000.0},
      ],
      'servicos': <Object>[],
      'pins': [
        {'tipo': 'oficina', 'latitude': -21.0, 'longitude': -43.0},
      ],
      'extra': '{"kmOleo":"14500"}',
      'precoGasolina': '6,59',
      'precoAlcool': null,
      'psi': {'dianteiro': 28, 'traseiro': 33},
    };

    expect(await BackupCaderneta.restaurarDaNuvem(pacote), isNull);

    final abastecimentos = await HistoricoAbastecimento.carregar();
    expect([for (final r in abastecimentos) r.kmPainel], [15000, 14000],
        reason: 'mesma ordem de quem mandou');
    expect(await HistoricoServico.carregar(), isEmpty);
    final pins = await PinsMapa.carregar();
    expect(pins.single.tipo, 'oficina');
    expect(await ArmazemKv.lerTexto(ChavesKv.extra), '{"kmOleo":"14500"}');
    expect(await ArmazemKv.lerTexto(ChavesKv.precoGasolina), '6,59');
    expect(await ArmazemKv.lerTexto(ChavesKv.precoAlcool), isNull);

    final ficha = await _fichaGuardada();
    expect(ficha['psiDianteiro'], '28');
    expect(ficha['psiTraseiro'], '33');
    expect(ficha['modelo'], 'Bros 160', reason: 'o resto da ficha não muda');
    expect(await FotoMoto.carregar(), _foto, reason: 'a foto nunca vai nem volta');
    expect(await ArmazemKv.lerTexto(ChavesKv.agenda), '{"oleoUltima":"2026-09-01"}');
    expect(await ArmazemKv.lerTexto(ChavesKv.ponto), '{"lat":-20.7,"lng":-42.8}');
  });

  test('PSI vazio na nuvem deixa o do aparelho', () async {
    await _gravarFicha(psiD: '26', psiT: '30');
    final pacote = await BackupCaderneta.exportarParaNuvem();
    pacote['psi'] = {'dianteiro': null, 'traseiro': 31};

    await BackupCaderneta.restaurarDaNuvem(pacote);

    final ficha = await _fichaGuardada();
    expect(ficha['psiDianteiro'], '26');
    expect(ficha['psiTraseiro'], '31');
  });

  test('sem ficha no aparelho, o PSI não inventa uma', () async {
    final pacote = await BackupCaderneta.exportarParaNuvem();
    pacote['psi'] = {'dianteiro': 25, 'traseiro': 29};

    await BackupCaderneta.restaurarDaNuvem(pacote);

    expect(await ArmazemKv.lerTexto(ChavesKv.ficha), isNull);
  });

  test('versão desconhecida é recusada e nada muda', () async {
    await _encherAparelho();

    final erro = await BackupCaderneta.restaurarDaNuvem({'v': 2});

    expect(erro, isNotNull);
    expect(await HistoricoAbastecimento.carregar(), hasLength(1));
    expect(await PinsMapa.carregar(), hasLength(1));
  });

  test('ida e volta: outro celular fica com a mesma assinatura', () async {
    await _encherAparelho();
    final daqui = await BackupCaderneta.exportarParaNuvem();
    // O que a API devolve passou por JSON.
    final pelaRede =
        Map<String, dynamic>.from(jsonDecode(jsonEncode(daqui)) as Map);

    // Celular novo: só a ficha chegou da conta, sem PSI.
    await CadernetaBanco.fechar();
    await abrirBancoTeste();
    await _gravarFicha(psiD: '', psiT: '');
    await BackupCaderneta.restaurarDaNuvem(pelaRede);

    final dali = await BackupCaderneta.exportarParaNuvem();
    expect(BackupNuvem.assinar(dali), BackupNuvem.assinar(daqui));
  });
}
