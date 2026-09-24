import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:life_and_roads/core/backup/backup_nuvem.dart';
import 'package:life_and_roads/core/legal/textos.dart';
import 'package:life_and_roads/core/sync/lido_do_servidor.dart';
import 'package:life_and_roads/features/auth/data/auth_remote_datasource.dart';
import 'package:life_and_roads/features/ficha/data/caderneta_nuvem_repository.dart';
import 'package:life_and_roads/features/ficha/data/ficha_local_datasource.dart';
import 'package:life_and_roads/features/ficha/data/ficha_remote_datasource.dart';
import 'package:life_and_roads/features/ficha/domain/ficha_moto.dart';
import 'package:life_and_roads/features/ficha/presentation/ficha_controller.dart';
import 'package:life_and_roads/features/ficha/presentation/nuvem_controller.dart';
import 'package:life_and_roads/features/ficha/presentation/tela_ficha.dart';
import 'package:life_and_roads/features/ficha/presentation/widgets/bloco_conta.dart';
import 'package:life_and_roads/features/ficha/presentation/widgets/cartao_aceite_nuvem.dart';
import 'package:life_and_roads/features/manutencao/data/manutencao_remote_datasource.dart';
import 'package:life_and_roads/features/manutencao/domain/agenda_manutencao.dart';
import 'package:life_and_roads/features/manutencao/presentation/manutencao_controller.dart';
import 'package:life_and_roads/main.dart';
import 'package:life_and_roads/viagem/calculo.dart';
import 'package:life_and_roads/viagem/historico.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../helpers/banco_teste.dart';

class _ContaRemota extends AuthRemoteDatasource {
  final aceites = <String>[];
  final cadastros = <String?>[];

  @override
  Future<void> aceitarTermos(String token, String versao) async {
    aceites.add(versao);
  }

  @override
  Future<void> registrar(
    String email,
    String senha, {
    required String termosVersao,
  }) async {
    cadastros.add(termosVersao);
  }

  @override
  Future<ParSessao> login(String email, String senha) async => (
    token: 'abc',
    email: email,
    refresh: 'refresh',
    termosVersao: cadastros.isEmpty ? null : cadastros.last,
  );
}

class _FichaSemServidor implements FichaRemoteDatasource {
  final salvas = <FichaMoto>[];

  @override
  Future<LidoDoServidor<FichaMoto>?> buscar(String token) async => null;

  @override
  Future<DateTime?> salvar(String token, FichaMoto ficha) async {
    salvas.add(ficha);
    return DateTime.utc(2026, 9, 24);
  }
}

class _ManutencaoSemServidor extends ManutencaoRemoteDatasource {
  @override
  Future<LidoDoServidor<AgendaManutencao>?> buscar(String token) async => null;
}

class _Servidor {
  Map<String, dynamic>? conteudo;
  String? carimbo;
  int apagados = 0;
  int envios = 0;

  Future<Map<String, dynamic>?> buscar(String token) async {
    final c = conteudo;
    if (c == null) return null;
    return jsonDecode(jsonEncode({'conteudo': c, 'atualizadoEm': carimbo}))
        as Map<String, dynamic>;
  }

  Future<String> enviar(
    String token,
    Map<String, dynamic> novo, {
    required String? carimboBase,
  }) async {
    envios++;
    conteudo = novo;
    carimbo = '2026-09-24T12:00:0$envios.000Z';
    return carimbo!;
  }

  Future<void> apagar(String token) async {
    apagados++;
    conteudo = null;
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

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  GoogleFonts.config.allowRuntimeFetching = false;

  late _ContaRemota contaRemota;
  late _Servidor servidor;
  late _FichaSemServidor fichaRemota;

  setUp(() async {
    SharedPreferences.setMockInitialValues({
      'token_life_and_roads': 'abc',
      'email_life_and_roads': 'a@b.c',
    });
    await abrirBancoTeste();
    await FichaLocalDatasource().gravar(
      const FichaMoto(marca: 'Honda', modelo: 'Bros', kmLitro: 35, kmAtual: 1000),
    );
    await HistoricoAbastecimento.acrescentar(_abastecimento);
    contaRemota = _ContaRemota();
    servidor = _Servidor();
    fichaRemota = _FichaSemServidor();
  });

  tearDown(fecharBancoTeste);

  Widget app() {
    return ProviderScope(
      overrides: [
        authRemoteDatasourceProvider.overrideWith((_) => contaRemota),
        fichaRemoteDatasourceProvider.overrideWith((_) => fichaRemota),
        manutencaoRemoteDatasourceProvider.overrideWith(
          (_) => _ManutencaoSemServidor(),
        ),
        backupNuvemProvider.overrideWith((ref) {
          final b = BackupNuvem(enviar: servidor.enviar);
          ref.onDispose(b.descartar);
          return b;
        }),
        cadernetaNuvemRepositoryProvider.overrideWith(
          (ref) => CadernetaNuvemRepository(
            backup: ref.watch(backupNuvemProvider),
            auth: ref.watch(authRepositoryProvider),
            buscar: servidor.buscar,
            apagar: servidor.apagar,
          ),
        ),
      ],
      child: const LifeAndRoadsApp(pularAbertura: true),
    );
  }

  testWidgets('conta antiga vê o aviso, nada sobe, e aceitar manda a caderneta',
      (tester) async {
    await tester.pumpWidget(app());
    await tester.pumpAndSettle();

    expect(find.byType(CartaoAceiteNuvem), findsOneWidget);
    expect(find.text(CartaoAceiteNuvem.titulo), findsOneWidget);
    expect(servidor.envios, 0, reason: 'antes de responder, nada sobe');

    await tester.tap(find.text('Aceito, manter ligado'));
    await tester.pumpAndSettle();

    expect(contaRemota.aceites, [versaoTermos]);
    expect(find.byType(CartaoAceiteNuvem), findsNothing);
    expect(servidor.envios, 1);
    expect((servidor.conteudo!['abastecimentos'] as List), hasLength(1));
  });

  testWidgets('Desligar no aviso apaga na conta e não pergunta de novo',
      (tester) async {
    await tester.pumpWidget(app());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Desligar'));
    await tester.pumpAndSettle();

    expect(servidor.apagados, 1);
    expect(find.byType(CartaoAceiteNuvem), findsNothing);
    expect(await const EstadoNuvem().ligada(), isFalse);
    expect(servidor.envios, 0);
  });

  testWidgets('caderneta diferente na conta mostra os dois lados e troca',
      (tester) async {
    await const EstadoNuvem().gravarTermosAceitos(versaoTermos);
    servidor.conteudo = {
      'v': 1,
      'abastecimentos': [
        for (var i = 0; i < 4; i++)
          {..._abastecimento.paraJson(), 'kmPainel': 20000 + i},
      ],
      'servicos': <Object>[],
      'pins': <Object>[],
      'extra': null,
      'precoGasolina': '6,59',
      'precoAlcool': null,
      'psi': {'dianteiro': null, 'traseiro': null},
    };
    servidor.carimbo = '2026-09-23T10:00:00.000Z';

    await tester.pumpWidget(app());
    await tester.pumpAndSettle();

    expect(find.text('Caderneta diferente na conta'), findsOneWidget);
    expect(
      find.text('Neste aparelho: 1 abastecimento, 0 serviços e 0 pinos.'),
      findsOneWidget,
    );
    expect(servidor.envios, 0);

    await tester.tap(find.text('Usar a do servidor'));
    await tester.pumpAndSettle();

    expect(find.text('Caderneta diferente na conta'), findsNothing);
    expect(await HistoricoAbastecimento.carregar(), hasLength(4));
    expect(
      find.text('A caderneta da conta veio para este aparelho.'),
      findsOneWidget,
    );
    // O Posto já estava montado e relê o preço sem reabrir o app.
    expect(find.text('6,59', skipOffstage: false), findsOneWidget);
  });

  testWidgets('criar a conta leva a ficha e a caderneta deste aparelho',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(app());
    await tester.pumpAndSettle();

    // As quatro abas ficam montadas; rola só a lista da Ficha.
    final lista = find
        .descendant(of: find.byType(TelaFicha), matching: find.byType(Scrollable))
        .first;
    await tester.scrollUntilVisible(
      find.text('Conta (opcional)'),
      200,
      scrollable: lista,
    );
    await tester.tap(find.text('Conta (opcional)'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text(BlocoConta.rotuloAceite),
      200,
      scrollable: lista,
    );
    await tester.enterText(
      find.widgetWithText(TextField, 'E-mail da conta'),
      'nova@teste.local',
    );
    await tester.enterText(
      find.widgetWithText(TextField, 'Senha (mín. 8)'),
      'senha1234',
    );
    await tester.tap(find.text(BlocoConta.rotuloAceite));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(OutlinedButton, 'Cadastrar'));
    await tester.pumpAndSettle();

    expect(contaRemota.cadastros, [versaoTermos]);
    expect(fichaRemota.salvas.single.modelo, 'Bros',
        reason: 'a ficha que já existia foi para a conta sem salvar de novo');
    expect(servidor.envios, 1, reason: 'a caderneta foi logo em seguida');
    expect(
      find.text('Conta criada. A ficha deste aparelho já está na conta.'),
      findsOneWidget,
    );
  });

  testWidgets('cadastro só libera com a caixa dos termos marcada',
      (tester) async {
    var aceite = false;
    var cadastros = 0;
    final ctrls = List.generate(5, (_) => TextEditingController());
    addTearDown(() {
      for (final c in ctrls) {
        c.dispose();
      }
    });

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: StatefulBuilder(
            builder: (context, setState) => ListView(
              children: [
                BlocoConta(
                  chave: const ValueKey('aberto'),
                  logado: false,
                  email: null,
                  reenviar: false,
                  emailCtrl: ctrls[0],
                  senhaCtrl: ctrls[1],
                  senhaAtualCtrl: ctrls[2],
                  senhaNovaCtrl: ctrls[3],
                  servidorCtrl: ctrls[4],
                  aoEntrar: () {},
                  aoCadastrar: () => cadastros++,
                  aoSair: () {},
                  aoTrocarSenha: () {},
                  aoEsqueciSenha: () {},
                  aoExcluirConta: () {},
                  aoMostrarTexto: (_, _) {},
                  aceitouTermos: aceite,
                  aoMudarAceite: (v) => setState(() => aceite = v),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final caixa = find.widgetWithText(CheckboxListTile, BlocoConta.rotuloAceite);
    expect(tester.widget<CheckboxListTile>(caixa).value, isFalse);
    await tester.tap(find.widgetWithText(OutlinedButton, 'Cadastrar'));
    expect(cadastros, 0, reason: 'desmarcada, o botão não responde');

    await tester.tap(caixa);
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(OutlinedButton, 'Cadastrar'));
    expect(cadastros, 1);
  });
}
