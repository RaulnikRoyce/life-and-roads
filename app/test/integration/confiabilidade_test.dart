import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:life_and_roads/api.dart';
import 'package:life_and_roads/core/permissoes/mensagens_permissao.dart';
import 'package:life_and_roads/core/widgets/cartao_conflito.dart';
import 'package:life_and_roads/features/ficha/data/ficha_local_datasource.dart';
import 'package:life_and_roads/features/ficha/data/ficha_remote_datasource.dart';
import 'package:life_and_roads/features/ficha/domain/ficha_moto.dart';
import 'package:life_and_roads/features/ficha/presentation/ficha_controller.dart';
import 'package:life_and_roads/features/mapa/data/servico_permissao_gps.dart';
import 'package:life_and_roads/features/mapa/presentation/mapa_controller.dart';
import 'package:life_and_roads/main.dart';
import 'package:life_and_roads/tema.dart';
import 'package:life_and_roads/tema_pref.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../helpers/banco_teste.dart';

class _FichaRemotaFake implements FichaRemoteDatasource {
  _FichaRemotaFake({this.remota, this.falhar = false});

  FichaMoto? remota;
  bool falhar;

  @override
  Future<FichaMoto?> buscar(String token) async {
    if (falhar) throw FalhaApi('API fora do ar.');
    return remota;
  }

  @override
  Future<void> salvar(String token, FichaMoto ficha) async {
    if (falhar) throw FalhaApi('API fora do ar.');
    remota = ficha;
  }
}

class _GpsNegado implements ConsultaPermissaoGps {
  @override
  Future<String?> recusar({required bool web}) async {
    return MensagensPermissao.gpsNegada(web: false);
  }
}

Finder _aba(String nome) => find.descendant(
      of: find.byType(NavigationBar),
      matching: find.text(nome),
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  GoogleFonts.config.allowRuntimeFetching = false;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await abrirBancoTeste();
  });

  tearDown(() async {
    await fecharBancoTeste();
  });

  testWidgets('tema cicla claro e escuro', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(child: LifeAndRoadsApp(pularAbertura: true)),
    );
    await tester.pumpAndSettle();

    expect(find.byTooltip('Automático'), findsOneWidget);
    await tester.tap(find.byTooltip('Automático'));
    await tester.pumpAndSettle();
    expect(find.byTooltip('Claro'), findsOneWidget);
    await tester.tap(find.byTooltip('Claro'));
    await tester.pumpAndSettle();
    expect(find.byTooltip('Escuro'), findsOneWidget);
    expect(PreferenciaTema.seguinte(ThemeMode.light), ThemeMode.dark);
  });

  testWidgets('DuplaCampos empilha na tela estreita e alinha na larga',
      (tester) async {
    Widget alvo(double largura) {
      return MediaQuery(
        data: MediaQueryData(size: Size(largura, 800)),
        child: const MaterialApp(
          home: Scaffold(
            body: DuplaCampos(
              esquerda: Text('Esq'),
              direita: Text('Dir'),
            ),
          ),
        ),
      );
    }

    await tester.pumpWidget(alvo(400));
    expect(find.byType(Column), findsWidgets);
    expect(find.byType(Row), findsNothing);

    await tester.pumpWidget(alvo(800));
    expect(find.byType(Row), findsOneWidget);
  });

  testWidgets('GPS recusado avisa sem rastrear', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          permissaoGpsProvider.overrideWith((_) => _GpsNegado()),
        ],
        child: const LifeAndRoadsApp(pularAbertura: true),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(_aba('Mapa'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Rastrear'));
    await tester.pumpAndSettle();
    expect(find.text(MensagensPermissao.gpsNegada(web: false)), findsOneWidget);
    expect(find.text('Parar'), findsNothing);
  });

  testWidgets('câmera recusada tem texto estável', (tester) async {
    expect(MensagensPermissao.camera, contains('câmera'));
    expect(MensagensPermissao.camera, contains('galeria'));
  });

  testWidgets('offline não apaga a ficha deste aparelho', (tester) async {
    SharedPreferences.setMockInitialValues({
      'token_life_and_roads': 'abc',
      'email_life_and_roads': 'a@b.c',
    });
    await FichaLocalDatasource().gravar(
      const FichaMoto(
        marca: 'Honda',
        modelo: 'Bros',
        kmLitro: 35,
        kmAtual: 1000,
      ),
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          fichaRemoteDatasourceProvider.overrideWith(
            (_) => _FichaRemotaFake(falhar: true),
          ),
        ],
        child: const LifeAndRoadsApp(pularAbertura: true),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Honda Bros'), findsOneWidget);
    expect(find.text('Sem API, caderneta neste aparelho.'), findsOneWidget);
  });

  testWidgets('ficha de outro aparelho pede escolha e usa a do servidor',
      (tester) async {
    SharedPreferences.setMockInitialValues({
      'token_life_and_roads': 'abc',
      'email_life_and_roads': 'a@b.c',
    });
    await FichaLocalDatasource().gravar(
      const FichaMoto(
        marca: 'Honda',
        modelo: 'Bros',
        kmLitro: 35,
        kmAtual: 1000,
      ),
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          fichaRemoteDatasourceProvider.overrideWith(
            (_) => _FichaRemotaFake(
              remota: const FichaMoto(
                marca: 'Yamaha',
                modelo: 'Fazer',
                kmLitro: 40,
                kmAtual: 2000,
              ),
            ),
          ),
        ],
        child: const LifeAndRoadsApp(pularAbertura: true),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byType(CartaoConflito), findsOneWidget);
    expect(find.text('Ficha diferente no servidor'), findsOneWidget);
    expect(find.text('Honda Bros'), findsOneWidget);

    await tester.tap(find.text('Usar a do servidor'));
    await tester.pumpAndSettle();
    expect(find.byType(CartaoConflito), findsNothing);
    expect(find.text('Yamaha Fazer'), findsOneWidget);
  });

  testWidgets('sessão encerrada mantém a caderneta local', (tester) async {
    await FichaLocalDatasource().gravar(
      const FichaMoto(
        marca: 'Honda',
        modelo: 'Bros',
        kmLitro: 35,
        kmAtual: 1000,
      ),
    );
    await tester.pumpWidget(
      const ProviderScope(child: LifeAndRoadsApp(pularAbertura: true)),
    );
    await tester.pumpAndSettle();
    expect(find.text('Honda Bros'), findsOneWidget);
  });
}
