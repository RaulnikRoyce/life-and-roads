import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:life_and_roads/api.dart';
import 'package:life_and_roads/backup.dart';
import 'package:life_and_roads/core/backup/backup_nuvem.dart';
import 'package:life_and_roads/core/database/caderneta_banco.dart';
import 'package:life_and_roads/core/legal/textos.dart';
import 'package:life_and_roads/features/auth/domain/auth_repository.dart';
import 'package:life_and_roads/features/auth/domain/sessao.dart';
import 'package:life_and_roads/features/ficha/data/caderneta_nuvem_repository.dart';
import 'package:life_and_roads/features/ficha/data/ficha_local_datasource.dart';
import 'package:life_and_roads/features/ficha/domain/ficha_moto.dart';
import 'package:life_and_roads/features/viagem/domain/usecases/montar_abastecimento.dart';
import 'package:life_and_roads/ficha/foto.dart';
import 'package:life_and_roads/viagem/calculo.dart';
import 'package:life_and_roads/viagem/historico.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../helpers/banco_teste.dart';

class _Conta implements AuthRepository {
  String? token = 'falso';
  @override
  Future<Sessao> carregar() async =>
      Sessao(token: token, servidor: 'http://teste');
  @override
  dynamic noSuchMethod(Invocation i) => super.noSuchMethod(i);
}

const _ficha = FichaMoto(
  marca: 'Honda',
  modelo: 'Bros',
  kmLitro: 35,
  kmLitroAlcool: 28,
  kmAtual: 1000,
  tanqueLitros: 12,
);
const _registro = RegistroAbastecimento(
  em: '2026-10-30',
  combustivel: Combustivel.gasolina,
  kmPainel: 1000,
  kmRodados: 0,
  litros: 3,
  precoLitro: 6,
  reais: 18,
  kmPorLitro: 0,
  reaisPorKm: 0,
  tipoConsumo: 'referencia',
);
void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await abrirBancoTeste();
    await FichaLocalDatasource().gravar(_ficha);
    await FotoMoto.salvar(Uint8List.fromList([1, 2, 3]));
    await HistoricoAbastecimento.acrescentar(_registro);
  });
  tearDown(fecharBancoTeste);
  test('backup incompleto ou malformado preserva toda a caderneta', () async {
    final antes = await BackupCaderneta.exportar();
    for (final invalido in ['{"v":2}', '{"v":1}', '{']) {
      expect(await BackupCaderneta.restaurar(invalido), isNotNull);
      expect(await BackupCaderneta.exportar(), antes);
    }
    final mapa = jsonDecode(antes) as Map<String, dynamic>;
    (mapa['abastecimentos'] as List).first['totalBarras'] = 'NaN';
    expect(await BackupCaderneta.restaurar(jsonEncode(mapa)), isNotNull);
    expect(await BackupCaderneta.exportar(), antes);
    mapa['abastecimentos'] = null;
    expect(await BackupCaderneta.restaurar(jsonEncode(mapa)), isNotNull);
    expect(await BackupCaderneta.exportar(), antes);
  });
  test(
    'erro de escrita restaura ficha, foto e historico anteriores por rollback',
    () async {
      final antes = await BackupCaderneta.exportar();
      final mapa = jsonDecode(antes) as Map<String, dynamic>;
      mapa['ficha'] = jsonEncode({'marca': 'Outra', 'modelo': 'Outra'});
      mapa['foto'] = base64Encode([4, 5, 6]);
      (mapa['abastecimentos'] as List).first['kmPainel'] = 12345;
      await CadernetaBanco.instancia.customStatement(
        "CREATE TRIGGER falhar_importacao BEFORE INSERT ON abastecimentos WHEN NEW.km_painel = 12345 BEGIN SELECT RAISE(ABORT, 'falha simulada'); END",
      );
      expect(
        await BackupCaderneta.restaurar(jsonEncode(mapa)),
        contains('preservados'),
      );
      expect(await BackupCaderneta.exportar(), antes);
    },
  );
  test('registro medido incompleto e barrinhas invalidas sao recusados sem excecao', () {
    for (final campos in [
      {'tipoConsumo': 'medido', 'kmRodados': 200, 'kmPorLitro': 40},
      {'totalBarras': 'NaN', 'barrasAntes': 1, 'barrasDepois': 2},
      {'totalBarras': 6, 'barrasAntes': 1.5, 'barrasDepois': 3},
      {'totalBarras': 6, 'barrasAntes': 4, 'barrasDepois': 3},
      {'tipoConsumo': 'desconhecido'},
      {'litros': 'Infinity'},
    ]) {
      expect(
        RegistroAbastecimento.deJson({..._registro.paraJson(), ...campos}),
        isNull,
      );
    }
  });
  test('caderneta invalida da conta nao apaga registros locais', () async {
    final antes = await BackupCaderneta.exportar();
    final nuvem = await BackupCaderneta.exportarParaNuvem();
    (nuvem['abastecimentos'] as List).first['tipoConsumo'] = 'medido';
    expect(await BackupCaderneta.restaurarDaNuvem(nuvem), isNotNull);
    expect(await BackupCaderneta.exportar(), antes);
  });
  test('desligar espera envio em andamento antes de apagar a copia', () async {
    const estado = EstadoNuvem();
    await estado.gravarTermosAceitos(versaoTermos);
    final iniciou = Completer<void>(), liberar = Completer<void>();
    Map<String, dynamic>? remoto = {'antigo': true};
    final ordem = <String>[];
    final b = BackupNuvem(
      lerToken: () async => 'falso',
      exportar: () async => {'novo': true},
      enviar: (_, conteudo, {required carimboBase}) async {
        iniciou.complete();
        await liberar.future;
        remoto = conteudo;
        ordem.add('enviar');
        return '2026-10-30T12:00:00.000Z';
      },
    );
    addTearDown(b.descartar);
    final repo = CadernetaNuvemRepository(
      backup: b,
      auth: _Conta(),
      apagar: (_) async {
        ordem.add('apagar');
        remoto = null;
      },
    );
    final envio = b.enviarAgora();
    await iniciou.future;
    final desligando = repo.desligar();
    await Future<void>.delayed(Duration.zero);
    expect(ordem, isEmpty);
    liberar.complete();
    await desligando;
    await envio;
    expect(ordem, ['enviar', 'apagar']);
    expect(remoto, isNull);
    expect(await estado.ligada(), isFalse);
    expect(await estado.carimbo(), isNull);
    expect(b.ultimo.value, isNull);
    expect(await b.enviarAgora(), ResultadoNuvem.parada);
  });
  test('falha de envio impede confirmacao de caderneta guardada', () async {
    const estado = EstadoNuvem();
    await estado.gravarTermosAceitos(versaoTermos);
    final b = BackupNuvem(
      lerToken: () async => 'falso',
      exportar: () async => {'novo': true},
      enviar: (_, _, {required carimboBase}) async =>
          throw FalhaApi('Sem rede'),
    );
    addTearDown(b.descartar);
    final repo = CadernetaNuvemRepository(
      backup: b,
      auth: _Conta(),
      buscar: (_) async => null,
    );
    await expectLater(repo.manterAparelho(), throwsA(isA<FalhaApi>()));
    expect(await estado.carimbo(), isNull);
  });
  test(
    'confirmacao explicita espera envio ja iniciado e recebe seu resultado',
    () async {
      const estado = EstadoNuvem();
      await estado.gravarTermosAceitos(versaoTermos);
      final iniciou = Completer<void>(), liberar = Completer<void>();
      final b = BackupNuvem(
        lerToken: () async => 'falso',
        exportar: () async => {'novo': true},
        enviar: (_, _, {required carimboBase}) async {
          if (!iniciou.isCompleted) {
            iniciou.complete();
          }
          await liberar.future;
          return '2026-10-30T12:00:00.000Z';
        },
      );
      addTearDown(b.descartar);
      final primeiro = b.enviarAgora();
      await iniciou.future;
      var terminou = false;
      final segundo = b.enviarConfirmado().then((r) {
        terminou = true;
        return r;
      });
      await Future<void>.delayed(Duration.zero);
      expect(terminou, isFalse);
      liberar.complete();
      await primeiro;
      expect(await segundo, isNot(ResultadoNuvem.emAndamento));
      expect(await estado.carimbo(), isNotNull);
    },
  );
  test('sem sessao nao confirma envio da caderneta', () async {
    final b = BackupNuvem();
    addTearDown(b.descartar);
    final repo = CadernetaNuvemRepository(
      backup: b,
      auth: _Conta()..token = null,
    );
    await expectLater(repo.manterAparelho(), throwsA(isA<FalhaApi>()));
  });
  test('combustivel residual continua como mistura no ciclo seguinte', () {
    const montar = MontarAbastecimento();
    final a = montar.executar(
      ficha: _ficha,
      historico: [],
      kmPainel: 1000,
      litros: 12,
      preco: 6,
      combustivel: Combustivel.gasolina,
      tanqueCheio: true,
    );
    final b = montar.executar(
      ficha: a.ficha,
      historico: [a.registro!],
      kmPainel: 1100,
      litros: 4,
      preco: 4,
      combustivel: Combustivel.alcool,
      tanqueCheio: true,
    );
    expect(b.registro!.combustivelMedido, Combustivel.gasolina);
    expect(b.registro!.misturaNoTanque, isTrue);
    final c = montar.executar(
      ficha: b.ficha,
      historico: [b.registro!, a.registro!],
      kmPainel: 1200,
      litros: 4,
      preco: 4,
      combustivel: Combustivel.alcool,
      tanqueCheio: true,
    );
    expect(c.registro!.tipoConsumo, 'medidoMisto');
    expect(c.registro!.combustivelMedido, isNull);
    expect(c.ficha!.kmLitroAlcool, 28);
    expect(
      RegistroAbastecimento.deJson(c.registro!.paraJson())!.misturaNoTanque,
      isTrue,
    );
  });
}
