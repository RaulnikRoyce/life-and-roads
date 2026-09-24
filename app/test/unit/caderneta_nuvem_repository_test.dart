import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:life_and_roads/api.dart';
import 'package:life_and_roads/backup.dart';
import 'package:life_and_roads/core/backup/backup_nuvem.dart';
import 'package:life_and_roads/core/legal/textos.dart';
import 'package:life_and_roads/features/auth/domain/auth_repository.dart';
import 'package:life_and_roads/features/auth/domain/sessao.dart';
import 'package:life_and_roads/features/ficha/data/caderneta_nuvem_repository.dart';
import 'package:life_and_roads/mapa/pins.dart';
import 'package:life_and_roads/viagem/calculo.dart';
import 'package:life_and_roads/viagem/historico.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../helpers/banco_teste.dart';

class _ContaFalsa implements AuthRepository {
  String? token = 'access';
  final aceites = <String>[];
  bool falharAceite = false;

  @override
  Future<Sessao> carregar() async =>
      Sessao(token: token, email: 'a@b.c', servidor: 'http://api');

  @override
  Future<void> aceitarTermos(String versao) async {
    if (falharAceite) throw FalhaApi('API fora do ar.');
    aceites.add(versao);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// A conta no servidor: o que está guardado, e o que chegou.
class _ServidorFalso {
  Map<String, dynamic>? conteudo;
  String? carimbo;
  int apagados = 0;
  int lidos = 0;
  bool fora = false;
  final envios = <({Map<String, dynamic> conteudo, String? base})>[];

  Future<Map<String, dynamic>?> buscar(String token) async {
    lidos++;
    if (fora) throw FalhaApi('API fora do ar.');
    final c = conteudo;
    if (c == null) return null;
    // Passa por JSON como na rede.
    return jsonDecode(jsonEncode({'conteudo': c, 'atualizadoEm': carimbo}))
        as Map<String, dynamic>;
  }

  Future<String> enviar(
    String token,
    Map<String, dynamic> novo, {
    required String? carimboBase,
  }) async {
    envios.add((conteudo: novo, base: carimboBase));
    if (conteudo != null && carimboBase != carimbo) {
      throw ConflitoNuvem('mudou', atualizadoEm: carimbo);
    }
    conteudo = novo;
    carimbo = '2026-09-24T12:00:0${envios.length}.000Z';
    return carimbo!;
  }

  Future<void> apagar(String token) async {
    if (fora) throw FalhaApi('API fora do ar.');
    apagados++;
    conteudo = null;
    carimbo = null;
  }
}

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

Map<String, dynamic> _pacoteDaConta({int abastecimentos = 2}) => {
  'v': 1,
  'abastecimentos': [
    for (var i = 0; i < abastecimentos; i++)
      {..._abastecimento.paraJson(), 'kmPainel': 20000 + i},
  ],
  'servicos': <Object>[],
  'pins': [
    {'tipo': 'oficina', 'latitude': -21.0, 'longitude': -43.0},
  ],
  'extra': null,
  'precoGasolina': null,
  'precoAlcool': null,
  'psi': {'dianteiro': null, 'traseiro': null},
};

void main() {
  late _ContaFalsa conta;
  late _ServidorFalso servidor;
  late BackupNuvem backup;
  late CadernetaNuvemRepository repo;
  const estado = EstadoNuvem();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await abrirBancoTeste();
    conta = _ContaFalsa();
    servidor = _ServidorFalso();
    backup = BackupNuvem(
      lerToken: () async => conta.token,
      enviar: servidor.enviar,
    );
    repo = CadernetaNuvemRepository(
      backup: backup,
      auth: conta,
      buscar: servidor.buscar,
      apagar: servidor.apagar,
    );
    await estado.gravarTermosAceitos(versaoTermos);
  });

  tearDown(() async {
    backup.descartar();
    await fecharBancoTeste();
  });

  group('antes de olhar a conta', () {
    test('sem conta não pergunta nada ao servidor', () async {
      conta.token = null;
      final s = await repo.verificar();
      expect(s.logado, isFalse);
      expect(servidor.lidos, 0);
    });

    test('desligada não lê nem manda', () async {
      await estado.ligar(false);
      final s = await repo.verificar();
      expect(s.ligada, isFalse);
      expect(servidor.lidos, 0);
    });

    test('conta sem o aceite atual pede o aceite e não lê nem manda', () async {
      await estado.gravarTermosAceitos('2026-08-26');
      await HistoricoAbastecimento.acrescentar(_abastecimento);

      final s = await repo.verificar();

      expect(s.precisaAceite, isTrue);
      expect(servidor.lidos, 0);
      expect(servidor.envios, isEmpty);
    });
  });

  test('aceitar registra no servidor, guarda aqui e então manda', () async {
    await estado.gravarTermosAceitos(null);
    await HistoricoAbastecimento.acrescentar(_abastecimento);

    final s = await repo.aceitar();

    expect(conta.aceites, [versaoTermos]);
    expect(await estado.termosAceitos(), versaoTermos);
    expect(s.precisaAceite, isFalse);
    expect(servidor.envios, hasLength(1));
  });

  test('aceite que não chegou ao servidor não libera nada', () async {
    await estado.gravarTermosAceitos(null);
    conta.falharAceite = true;

    await expectLater(repo.aceitar(), throwsA(isA<FalhaApi>()));

    expect(await estado.termosAceitos(), isNull);
    expect(servidor.envios, isEmpty);
  });

  test('aparelho com dados e conta vazia: manda na hora', () async {
    await HistoricoAbastecimento.acrescentar(_abastecimento);

    final s = await repo.verificar();

    expect(servidor.envios.single.base, isNull);
    expect(s.guardadaEm, isNotNull);
    expect(s.conflito, isNull);
  });

  test('nada nos dois lados: não manda caderneta vazia', () async {
    await repo.verificar();
    expect(servidor.envios, isEmpty);
  });

  test('aparelho vazio e conta com caderneta: traz sem perguntar', () async {
    servidor.conteudo = _pacoteDaConta();
    servidor.carimbo = '2026-09-23T10:00:00.000Z';

    final s = await repo.verificar();

    expect(s.restaurou, isTrue);
    expect(await HistoricoAbastecimento.carregar(), hasLength(2));
    expect((await PinsMapa.carregar()).single.tipo, 'oficina');
    expect(await estado.carimbo(), '2026-09-23T10:00:00.000Z');
    expect(servidor.envios, isEmpty);

    // Na próxima abertura é a mesma: não sobe de novo.
    await repo.verificar();
    expect(servidor.envios, isEmpty);
  });

  test('os dois iguais sem carimbo guardado: adota sem perguntar', () async {
    await HistoricoAbastecimento.acrescentar(_abastecimento);
    servidor.conteudo = await BackupCaderneta.exportarParaNuvem();
    servidor.carimbo = '2026-09-23T10:00:00.000Z';

    final s = await repo.verificar();

    expect(s.conflito, isNull);
    expect(servidor.envios, isEmpty);
    expect(await estado.carimbo(), '2026-09-23T10:00:00.000Z');
  });

  test('os dois com histórico diferente: pergunta, com os dois lados', () async {
    await HistoricoAbastecimento.acrescentar(_abastecimento);
    servidor.conteudo = _pacoteDaConta(abastecimentos: 5);
    servidor.carimbo = '2026-09-23T10:00:00.000Z';

    final s = await repo.verificar();

    expect(s.conflito, isNotNull);
    expect(s.conflito!.aparelho.abastecimentos, 1);
    expect(s.conflito!.nuvem.abastecimentos, 5);
    expect(s.conflito!.nuvemEm, DateTime.utc(2026, 9, 23, 10));
    expect(await estado.emConflito(), isTrue);
    expect(servidor.envios, isEmpty);
    expect(
      await backup.enviarAgora(),
      ResultadoNuvem.parada,
      reason: 'o envio por trás não passa por cima enquanto ninguém escolheu',
    );
  });

  test('conflito resolvido mantendo a deste aparelho: manda por cima', () async {
    await HistoricoAbastecimento.acrescentar(_abastecimento);
    servidor.conteudo = _pacoteDaConta(abastecimentos: 5);
    servidor.carimbo = '2026-09-23T10:00:00.000Z';
    await repo.verificar();

    final s = await repo.manterAparelho();

    expect(servidor.envios.single.base, '2026-09-23T10:00:00.000Z');
    expect((servidor.conteudo!['abastecimentos'] as List), hasLength(1));
    expect(s.conflito, isNull);
    expect(await estado.emConflito(), isFalse);
  });

  test('conflito resolvido usando a da conta: troca a deste aparelho', () async {
    await HistoricoAbastecimento.acrescentar(_abastecimento);
    servidor.conteudo = _pacoteDaConta(abastecimentos: 5);
    servidor.carimbo = '2026-09-23T10:00:00.000Z';
    await repo.verificar();

    final s = await repo.usarDaConta();

    expect(s.restaurou, isTrue);
    expect(await HistoricoAbastecimento.carregar(), hasLength(5));
    expect(await estado.emConflito(), isFalse);
    expect(servidor.envios, isEmpty);
  });

  test('conta com caderneta vazia e carimbo desconhecido: adota e manda', () async {
    await HistoricoAbastecimento.acrescentar(_abastecimento);
    servidor.conteudo = _pacoteDaConta(abastecimentos: 0)..['pins'] = [];
    servidor.carimbo = '2026-09-23T10:00:00.000Z';

    await repo.verificar();

    expect(servidor.envios.single.base, '2026-09-23T10:00:00.000Z');
    expect(await estado.emConflito(), isFalse);
  });

  test('sem rede, nada muda e ninguém pergunta', () async {
    await HistoricoAbastecimento.acrescentar(_abastecimento);
    servidor.fora = true;

    final s = await repo.verificar();

    expect(s.offline, isTrue);
    expect(s.conflito, isNull);
    expect(await estado.carimbo(), isNull);
  });

  test('desligar apaga a cópia da conta e para os envios', () async {
    await HistoricoAbastecimento.acrescentar(_abastecimento);
    await repo.verificar();

    final s = await repo.desligar();

    expect(servidor.apagados, 1);
    expect(s.ligada, isFalse);
    expect(await estado.ligada(), isFalse);
    expect(await estado.carimbo(), isNull);
    expect(await backup.enviarAgora(), ResultadoNuvem.parada);
  });

  test('desligar sem resposta do servidor não desliga aqui', () async {
    servidor.fora = true;

    await expectLater(repo.desligar(), throwsA(isA<FalhaApi>()));

    expect(await estado.ligada(), isTrue);
  });

  test('religar começa do zero e manda de novo', () async {
    await HistoricoAbastecimento.acrescentar(_abastecimento);
    await repo.verificar();
    await repo.desligar();

    await repo.ligar();

    expect(servidor.envios, hasLength(2));
    expect(servidor.envios.last.base, isNull);
  });
}
