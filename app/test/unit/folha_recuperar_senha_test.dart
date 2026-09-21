import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:life_and_roads/features/ficha/presentation/widgets/bloco_conta.dart';
import 'package:life_and_roads/features/ficha/presentation/widgets/folha_recuperar_senha.dart';
import 'package:life_and_roads/tema.dart';

/// Bloco Conta deslogado com a folha ligada, sem controller nem banco.
/// Os callbacks devolvem o que o teste mandar (null = deu certo).
class _Cenario {
  _Cenario({String emailInicial = 'piloto@moto.br'})
    : email = TextEditingController(text: emailInicial);

  final TextEditingController email;
  final senha = TextEditingController();
  final senhaAtual = TextEditingController();
  final senhaNova = TextEditingController();
  final servidor = TextEditingController();

  final enviados = <String>[];
  final redefinidos = <(String, String, String)>[];
  String? respostaEnviar;
  String? respostaRedefinir;

  Widget montar() {
    return MaterialApp(
      theme: temaOficina(),
      home: Scaffold(
        body: Builder(
          builder: (context) => ListView(
            padding: const EdgeInsets.all(20),
            children: [
              BlocoConta(
                logado: false,
                email: null,
                reenviar: false,
                emailCtrl: email,
                senhaCtrl: senha,
                senhaAtualCtrl: senhaAtual,
                senhaNovaCtrl: senhaNova,
                servidorCtrl: servidor,
                aoEntrar: () {},
                aoCadastrar: () {},
                aoSair: () {},
                aoTrocarSenha: () {},
                aoEsqueciSenha: () => FolhaRecuperarSenha.abrir(
                  context,
                  emailInicial: email.text.trim().toLowerCase(),
                  aoEnviar: (e) async {
                    enviados.add(e);
                    return respostaEnviar;
                  },
                  aoRedefinir: (e, codigo, senhaNova) async {
                    redefinidos.add((e, codigo, senhaNova));
                    return respostaRedefinir;
                  },
                ),
                aoExcluirConta: () {},
                aoMostrarTexto: (_, _) {},
              ),
            ],
          ),
        ),
      ),
    );
  }

  void descartar() {
    for (final c in [email, senha, senhaAtual, senhaNova, servidor]) {
      c.dispose();
    }
  }
}

Future<_Cenario> _abrirFolha(
  WidgetTester tester, {
  String emailInicial = 'piloto@moto.br',
}) async {
  final c = _Cenario(emailInicial: emailInicial);
  addTearDown(c.descartar);
  await tester.pumpWidget(c.montar());
  await tester.pumpAndSettle();

  await tester.tap(find.text('Conta (opcional)'));
  await tester.pumpAndSettle();
  expect(find.text('Esqueci a senha'), findsOneWidget);

  await tester.tap(find.text('Esqueci a senha'));
  await tester.pumpAndSettle();
  expect(find.byType(FolhaRecuperarSenha), findsOneWidget);
  expect(find.text('1 de 2'), findsOneWidget);
  return c;
}

void main() {
  GoogleFonts.config.allowRuntimeFetching = false;

  testWidgets('passo 1 envia o e-mail do bloco e avança quando dá certo', (
    tester,
  ) async {
    final c = await _abrirFolha(tester);

    final campo = find.widgetWithText(TextField, 'E-mail da conta').last;
    expect(tester.widget<TextField>(campo).controller?.text, 'piloto@moto.br');

    await tester.tap(find.text('Enviar código'));
    await tester.pumpAndSettle();

    expect(c.enviados, ['piloto@moto.br']);
    expect(find.text('2 de 2'), findsOneWidget);
    expect(find.text('Código de 6 dígitos'), findsOneWidget);
    expect(find.text('Senha nova (mín. 8)'), findsOneWidget);
    expect(
      find.textContaining(
        'Código enviado para piloto@moto.br, se esse e-mail tiver conta',
      ),
      findsOneWidget,
    );
  });

  testWidgets('passo 1 fica no passo e mostra o erro quando falha', (
    tester,
  ) async {
    final c = await _abrirFolha(tester);
    c.respostaEnviar = 'API fora do ar. O código não foi enviado.';

    await tester.tap(find.text('Enviar código'));
    await tester.pumpAndSettle();

    expect(c.enviados, ['piloto@moto.br']);
    expect(find.text('1 de 2'), findsOneWidget);
    expect(
      find.text('API fora do ar. O código não foi enviado.'),
      findsOneWidget,
    );
    expect(find.text('Código de 6 dígitos'), findsNothing);
  });

  testWidgets(
    'passo 2 chama redefinir com código e senha; erro mantém, sucesso fecha',
    (tester) async {
      final c = await _abrirFolha(tester);
      await tester.tap(find.text('Enviar código'));
      await tester.pumpAndSettle();

      await tester.enterText(
        find.widgetWithText(TextField, 'Código de 6 dígitos'),
        '12ab3456',
      );
      await tester.enterText(
        find.widgetWithText(TextField, 'Senha nova (mín. 8)'),
        'senha5678',
      );
      await tester.pump();

      c.respostaRedefinir = 'Código inválido ou vencido.';
      await tester.tap(find.text('Redefinir senha'));
      await tester.pumpAndSettle();

      // Só dígitos passam e o campo corta em 6.
      expect(c.redefinidos, [('piloto@moto.br', '123456', 'senha5678')]);
      expect(find.byType(FolhaRecuperarSenha), findsOneWidget);
      expect(find.text('2 de 2'), findsOneWidget);
      expect(find.text('Código inválido ou vencido.'), findsOneWidget);

      c.respostaRedefinir = null;
      await tester.tap(find.text('Redefinir senha'));
      await tester.pumpAndSettle();

      expect(c.redefinidos.length, 2);
      expect(find.byType(FolhaRecuperarSenha), findsNothing);
    },
  );

  testWidgets('Enviar de novo pede outro código sem sair do passo 2', (
    tester,
  ) async {
    final c = await _abrirFolha(tester);
    await tester.tap(find.text('Enviar código'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Enviar de novo'));
    await tester.pumpAndSettle();

    expect(c.enviados, ['piloto@moto.br', 'piloto@moto.br']);
    expect(find.text('2 de 2'), findsOneWidget);
    expect(
      find.textContaining(
        'Código novo enviado para piloto@moto.br, se esse e-mail tiver conta. '
        'O anterior deixou de valer',
      ),
      findsOneWidget,
    );
  });

  testWidgets('Já tenho o código pula para o passo 2 sem enviar', (
    tester,
  ) async {
    final c = await _abrirFolha(tester);

    await tester.tap(find.text('Já tenho o código'));
    await tester.pumpAndSettle();

    expect(c.enviados, isEmpty);
    expect(find.text('2 de 2'), findsOneWidget);
    expect(
      find.textContaining('Digite o código que chegou em'),
      findsOneWidget,
    );
  });

  testWidgets(
    'Já tenho o código fica no passo 1 enquanto o e-mail é inválido',
    (tester) async {
      final c = await _abrirFolha(tester, emailInicial: '');

      await tester.tap(find.text('Já tenho o código'));
      await tester.pumpAndSettle();

      // Sem e-mail o passo 2 não teria como corrigir; o erro fica onde o
      // campo está.
      expect(c.enviados, isEmpty);
      expect(find.text('1 de 2'), findsOneWidget);
      expect(find.text('Informe o e-mail da conta.'), findsOneWidget);
      expect(find.text('Código de 6 dígitos'), findsNothing);

      await tester.enterText(
        find.widgetWithText(TextField, 'E-mail da conta').last,
        'piloto@moto.br',
      );
      await tester.tap(find.text('Já tenho o código'));
      await tester.pumpAndSettle();

      expect(find.text('2 de 2'), findsOneWidget);
      expect(find.text('Informe o e-mail da conta.'), findsNothing);
      expect(
        find.textContaining('Digite o código que chegou em piloto@moto.br'),
        findsOneWidget,
      );
    },
  );
}
