import 'package:flutter_test/flutter_test.dart';
import 'package:life_and_roads/backup.dart';
import 'package:life_and_roads/core/database/armazem_kv.dart';
import 'package:life_and_roads/manutencao/extra.dart';
import 'package:life_and_roads/manutencao/servicos.dart';
import 'package:life_and_roads/mapa/pins.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'helpers/banco_teste.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await abrirBancoTeste();
  });

  tearDown(() async {
    await fecharBancoTeste();
  });

  test('serviço válido grava km e reais', () {
    final s = RegistroServico.deJson({
      'em': '2026-08-24T12:00:00.000',
      'tipo': 'óleo',
      'kmPainel': 18400,
      'reais': 45,
    });
    expect(s, isNotNull);
    expect(s!.kmPainel, 18400);
    expect(s.reais, 45);
    expect(RegistroServico.deJson({'tipo': 'óleo', 'kmPainel': -1, 'reais': 10}), isNull);
  });

  test('pino só aceita posto ou oficina', () {
    expect(
      PinoMapa.deJson({'tipo': 'posto', 'latitude': -23.5, 'longitude': -46.6}),
      isNotNull,
    );
    expect(
      PinoMapa.deJson({'tipo': 'casa', 'latitude': -23.5, 'longitude': -46.6}),
      isNull,
    );
  });

  test('CNH 10 ou 5 anos fica no extra local', () {
    final extra = ManutencaoExtra.deJson({
      'oleoKmUltima': 10000,
      'oleoKmIntervalo': 4000,
      'correnteKmUltima': 10800,
      'correnteKmIntervalo': 1000,
      'cnhProxima': '2027-03-15',
    });
    expect(extra.oleoKmUltima, 10000);
    expect(extra.cnhProxima, '2027-03-15');
    expect(extra.cnhCincoAnos, isFalse);
    expect(ManutencaoExtra.deJson({'cnhCincoAnos': true}).cnhCincoAnos, isTrue);
    expect(ManutencaoExtra.deJson(null).oleoKmIntervalo, 4000);
  });

  test('backup volta a caderneta neste aparelho', () async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      'ficha_moto_v1',
      '{"marca":"Honda","modelo":"CG 160"}',
    );
    final bruto = await BackupCaderneta.exportar();
    await prefs.remove('ficha_moto_v1');
    expect(await BackupCaderneta.restaurar(bruto), isNull);
    expect(await ArmazemKv.lerTexto('ficha_moto_v1'), contains('CG 160'));
    expect(prefs.getString('ficha_moto_v1'), isNull);
    expect(await BackupCaderneta.restaurar('{'), 'Backup inválido.');
  });
}
