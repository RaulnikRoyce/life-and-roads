/// Ponto de entrada do life.and.roads.
///
/// Quatro abas (Ficha, Manutenção, Viagem, Mapa) em [IndexedStack], para o
/// estado de cada tela sobreviver à troca. Viagem e Manutenção relêem a
/// ficha ao ficarem visíveis.
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:life_and_roads/api.dart';
import 'package:life_and_roads/core/database/caderneta_banco.dart';
import 'package:life_and_roads/core/database/migracao_prefs.dart';
import 'package:life_and_roads/core/monitor/crash.dart';
import 'package:life_and_roads/core/permissoes/mensagens_permissao.dart';
import 'package:life_and_roads/features/ficha/presentation/ficha_controller.dart';
import 'package:life_and_roads/features/ficha/presentation/tela_ficha.dart';
import 'package:life_and_roads/features/manutencao/presentation/avisos_controller.dart';
import 'package:life_and_roads/features/manutencao/presentation/botao_sininho.dart';
import 'package:life_and_roads/features/manutencao/presentation/tela_manutencao.dart';
import 'package:life_and_roads/features/mapa/presentation/tela_mapa.dart';
import 'package:life_and_roads/tema.dart';
import 'package:life_and_roads/tema_pref.dart';
import 'package:life_and_roads/tela_abertura.dart';
import 'package:life_and_roads/features/viagem/presentation/tela_viagem.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await CadernetaBanco.abrirArquivo();
  await MigracaoPrefsDrift.executar();
  await ApiCaderneta.carregarBase();
  instalarCrashReporting();
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ),
  );
  runApp(const ProviderScope(child: LifeAndRoadsApp()));
}

class LifeAndRoadsApp extends StatefulWidget {
  const LifeAndRoadsApp({super.key, this.pularAbertura = false});

  /// Testes das abas entram direto; a abertura continua no aparelho.
  final bool pularAbertura;

  @override
  State<LifeAndRoadsApp> createState() => _LifeAndRoadsAppState();
}

class _LifeAndRoadsAppState extends State<LifeAndRoadsApp> {
  ThemeMode _modo = ThemeMode.system;
  late bool _abertura = !widget.pularAbertura;

  @override
  void initState() {
    super.initState();
    PreferenciaTema.carregar().then((m) {
      if (mounted) setState(() => _modo = m);
    });
  }

  Future<void> _cicloTema() async {
    final n = PreferenciaTema.seguinte(_modo);
    await PreferenciaTema.salvar(n);
    if (mounted) setState(() => _modo = n);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'life.and.roads',
      debugShowCheckedModeBanner: false,
      locale: const Locale('pt', 'BR'),
      supportedLocales: const [Locale('pt', 'BR')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      theme: temaOficinaClaro(),
      darkTheme: temaOficina(),
      themeMode: _modo,
      builder: (context, child) {
        final b = Theme.of(context).brightness;
        final icone =
            b == Brightness.dark ? Brightness.light : Brightness.dark;
        SystemChrome.setSystemUIOverlayStyle(
          SystemUiOverlayStyle(
            statusBarColor: Colors.transparent,
            statusBarIconBrightness: icone,
            systemNavigationBarColor:
                Theme.of(context).scaffoldBackgroundColor,
            systemNavigationBarIconBrightness: icone,
          ),
        );
        return child ?? const SizedBox.shrink();
      },
      home: _abertura
          ? TelaAbertura(
              aoTerminar: () {
                if (mounted) setState(() => _abertura = false);
              },
            )
          : TelaPrincipal(modoTema: _modo, aoCiclarTema: _cicloTema),
    );
  }
}

class _Aba {
  const _Aba({
    required this.titulo,
    required this.icone,
  });

  final String titulo;
  final IconData icone;
}

class TelaPrincipal extends ConsumerStatefulWidget {
  const TelaPrincipal({
    super.key,
    required this.modoTema,
    required this.aoCiclarTema,
  });

  final ThemeMode modoTema;
  final VoidCallback aoCiclarTema;

  @override
  ConsumerState<TelaPrincipal> createState() => _TelaPrincipalState();
}

class _TelaPrincipalState extends ConsumerState<TelaPrincipal> {
  int _indice = 0;

  static const _abas = [
    _Aba(titulo: 'Ficha', icone: Icons.two_wheeler),
    _Aba(titulo: 'Manutenção', icone: Icons.build),
    _Aba(titulo: 'Viagem', icone: Icons.route),
    _Aba(titulo: 'Mapa', icone: Icons.map),
  ];

  @override
  void initState() {
    super.initState();
    Future<void>.microtask(() {
      if (mounted) {
        ref
            .read(avisosControllerProvider.notifier)
            .recarregar(dispararSistema: true);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(fichaControllerProvider, (anterior, atual) {
      if (anterior?.ficha?.kmAtual != atual.ficha?.kmAtual) {
        ref.read(avisosControllerProvider.notifier).recarregar();
      }
    });
    ref.listen(avisosControllerProvider, (anterior, atual) {
      if (atual.permissaoNegada && anterior?.permissaoNegada != true) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text(MensagensPermissao.notificacao)),
          );
        });
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: const Row(
          children: [
            ClipOval(
              child: Image(
                image: AssetImage('assets/lr.png'),
                width: 36,
                height: 36,
                fit: BoxFit.cover,
              ),
            ),
            SizedBox(width: 10),
            Text('life.and.roads'),
          ],
        ),
        actions: [
          const BotaoSininho(),
          IconButton(
            tooltip: PreferenciaTema.rotulo(widget.modoTema),
            onPressed: widget.aoCiclarTema,
            icon: Icon(PreferenciaTema.icone(widget.modoTema)),
          ),
        ],
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(2),
          child: ColoredBox(
            color: Oficina.vinho,
            child: SizedBox(height: 2, width: double.infinity),
          ),
        ),
      ),
      body: IndexedStack(
        index: _indice,
        children: [
          const TelaFicha(),
          TelaManutencao(visivel: _indice == 1),
          TelaViagem(visivel: _indice == 2),
          const TelaMapa(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _indice,
        onDestinationSelected: (i) {
          setState(() => _indice = i);
        },
        destinations: [
          for (final aba in _abas)
            NavigationDestination(
              icon: Icon(aba.icone),
              label: aba.titulo,
            ),
        ],
      ),
    );
  }
}
