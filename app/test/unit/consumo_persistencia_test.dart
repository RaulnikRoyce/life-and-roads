import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:life_and_roads/backup.dart';
import 'package:life_and_roads/core/database/caderneta_banco.dart';
import 'package:life_and_roads/core/database/caderneta_database.dart';
import 'package:life_and_roads/viagem/calculo.dart';
import 'package:life_and_roads/viagem/historico.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../helpers/banco_teste.dart';

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await abrirBancoTeste();
  });
  tearDown(fecharBancoTeste);
  const registro = RegistroAbastecimento(
    em: '2026-10-30T20:00:00',
    combustivel: Combustivel.gasolina,
    kmPainel: 1350,
    kmRodados: 250,
    litros: 8,
    precoLitro: 6,
    reais: 48,
    kmPorLitro: 35,
    reaisPorKm: 60 / 350,
    tipoConsumo: 'medido',
    tanqueCheio: true,
    kmMedidos: 350,
    litrosMedidos: 10,
    reaisMedidos: 60,
    combustivelMedido: Combustivel.gasolina,
    totalBarras: 6,
    barrasAntes: 1,
    barrasDepois: 6,
  );
  test(
    'SQLite, backup local e pacote da conta preservam a medicao e o marcador',
    () async {
      await HistoricoAbastecimento.acrescentar(registro);
      final lido = (await HistoricoAbastecimento.carregar()).single;
      expect(lido.paraJson(), registro.paraJson());
      final local = await BackupCaderneta.exportar();
      expect(await BackupCaderneta.restaurar(local), isNull);
      expect(
        (await HistoricoAbastecimento.carregar()).single.paraJson(),
        registro.paraJson(),
      );
      final nuvem = await BackupCaderneta.exportarParaNuvem();
      expect(await BackupCaderneta.restaurarDaNuvem(nuvem), isNull);
      expect(
        (await HistoricoAbastecimento.carregar()).single.paraJson(),
        registro.paraJson(),
      );
    },
  );
  test('historico preserva mais de 20 parciais', () async {
    for (var i = 0; i < 25; i++) {
      final json = registro.paraJson()
        ..['em'] = '2026-10-30T20:00:${i.toString().padLeft(2, '0')}';
      await HistoricoAbastecimento.acrescentar(
        RegistroAbastecimento.deJson(json)!,
      );
    }
    expect(await HistoricoAbastecimento.carregar(), hasLength(25));
  });
  test('migracao da versao 2 preserva o abastecimento antigo', () async {
    await fecharBancoTeste();
    final banco = CadernetaDatabase(
      NativeDatabase.memory(
        setup: (db) {
          db.execute(
            'CREATE TABLE abastecimentos (id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT, em TEXT NOT NULL, combustivel TEXT NOT NULL, km_painel REAL NOT NULL, km_rodados REAL NOT NULL, litros REAL NOT NULL, preco_litro REAL NOT NULL, reais REAL NOT NULL, km_por_litro REAL NOT NULL, reais_por_km REAL NOT NULL)',
          );
          db.execute(
            "INSERT INTO abastecimentos VALUES (1, '2026-09-01', 'gasolina', 1200, 200, 5, 6, 30, 40, 0.15)",
          );
          db.execute('PRAGMA user_version = 2');
        },
      ),
    );
    CadernetaBanco.usar(banco);
    final r = (await HistoricoAbastecimento.carregar()).single;
    expect(r.kmPainel, 1200);
    expect(r.tipoConsumo, 'legado');
    expect(r.medido, isFalse);
    await HistoricoAbastecimento.acrescentar(registro);
    expect((await HistoricoAbastecimento.carregar()).first.totalBarras, 6);
  });
}
