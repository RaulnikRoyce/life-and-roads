/// Ponto de entrada do life.and.roads.
///
/// Quatro abas (Ficha, Manutenção, Posto, Viagem) em [IndexedStack], para o
/// estado de cada tela sobreviver à troca. Posto e Manutenção relêem a
/// ficha ao ficarem visíveis.
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:life_and_roads/api.dart';
import 'package:life_and_roads/core/database/caderneta_banco.dart';
import 'package:life_and_roads/core/database/migracao_prefs.dart';
import 'package:life_and_roads/core/marca/logo_pintor.dart';
import 'package:life_and_roads/core/monitor/crash.dart';
import 'package:life_and_roads/core/permissoes/mensagens_permissao.dart';
import 'package:life_and_roads/core/widgets/barra_abas.dart';
import 'package:life_and_roads/core/widgets/movimento.dart';
import 'package:life_and_roads/features/ficha/presentation/ficha_controller.dart';
import 'package:life_and_roads/features/ficha/presentation/tela_ficha.dart';
import 'package:life_and_roads/features/manutencao/presentation/avisos_controller.dart';
import 'package:life_and_roads/features/manutencao/presentation/botao_sininho.dart';
import 'package:life_and_roads/features/manutencao/presentation/tela_manutencao.dart';
import 'package:life_and_roads/features/mapa/presentation/tela_mapa.dart';
import 'package:life_and_roads/tema.dart';
import 'package:life_and_roads/tema_pref.dart';
import 'package:life_and_roads/tela_abertura.dart';
import 'package:life_and_roads/features/viagem/presentation/tela_posto.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await CadernetaBanco.abrirArquivo();
  await MigracaoPrefsDrift.executar();
  await ApiCaderneta.carregarBase();
  // Com conta, acorda a API do Render enquanto a abertura roda.
  unawaited(ApiCaderneta.aquecer());
  instalarCrashReporting();
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ),
  );
  runApp(const ProviderScope(child: LifeAndRoadsApp()));
}

class LifeAndRoadsApp extends ConsumerWidget {
  const LifeAndRoadsApp({super.key, this.pularAbertura = false});

  /// Testes das abas entram direto; a abertura continua no aparelho.
  final bool pularAbertura;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final modo = ref.watch(temaProvider);
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
      themeMode: modo,
      builder: (context, child) {
        final b = Theme.of(context).brightness;
        final icone = b == Brightness.dark ? Brightness.light : Brightness.dark;
        SystemChrome.setSystemUIOverlayStyle(
          SystemUiOverlayStyle(
            statusBarColor: Colors.transparent,
            statusBarIconBrightness: icone,
            systemNavigationBarColor: Theme.of(context).scaffoldBackgroundColor,
            systemNavigationBarIconBrightness: icone,
          ),
        );
        return child ?? const SizedBox.shrink();
      },
      // A abertura empurra a rota das abas: a logo voa para a barra (Hero)
      // enquanto a abertura sai em fade.
      home: pularAbertura
          ? const TelaPrincipal()
          : Builder(
              builder: (context) => TelaAbertura(
                aoTerminar: () =>
                    Navigator.of(context)
                        .pushReplacement(rotaPrincipal(const TelaPrincipal())),
              ),
            ),
    );
  }
}

class TelaPrincipal extends ConsumerStatefulWidget {
  const TelaPrincipal({super.key});

  @override
  ConsumerState<TelaPrincipal> createState() => _TelaPrincipalState();
}

class _TelaPrincipalState extends ConsumerState<TelaPrincipal>
    with SingleTickerProviderStateMixin {
  int _indice = 0;

  /// Entrada da aba: o IndexedStack continua guardando o estado das quatro
  /// telas; só o que muda é a opacidade e um deslize curto por cima.
  late final AnimationController _entrada = AnimationController(
    vsync: this,
    duration: Movimento.curto,
    value: 1,
  );
  late final Animation<Offset> _deslize = Tween(
    begin: const Offset(0, 0.015),
    end: Offset.zero,
  ).animate(CurvedAnimation(parent: _entrada, curve: Movimento.curva));

  static const _abas = [
    Aba(titulo: 'Ficha', icone: Icons.two_wheeler),
    Aba(titulo: 'Manutenção', icone: Icons.build_outlined, ativo: Icons.build),
    Aba(
      titulo: 'Posto',
      icone: Icons.local_gas_station_outlined,
      ativo: Icons.local_gas_station,
    ),
    Aba(titulo: 'Viagem', icone: Icons.route_outlined, ativo: Icons.route),
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
  void dispose() {
    _entrada.dispose();
    super.dispose();
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

    final modo = ref.watch(temaProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Row(
          children: [
            Hero(tag: TelaAbertura.heroLogo, child: LogoMarca(tamanho: 36)),
            SizedBox(width: 10),
            Text('life.and.roads'),
          ],
        ),
        actions: [
          const BotaoSininho(),
          IconButton(
            tooltip: PreferenciaTema.rotulo(modo),
            onPressed: () => ref.read(temaProvider.notifier).ciclar(),
            icon: Icon(PreferenciaTema.icone(modo)),
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
      body: FadeTransition(
        opacity: _entrada,
        child: SlideTransition(
          position: _deslize,
          child: IndexedStack(
            index: _indice,
            children: [
              const TelaFicha(),
              TelaManutencao(visivel: _indice == 1),
              TelaPosto(visivel: _indice == 2),
              TelaMapa(visivel: _indice == 3),
            ],
          ),
        ),
      ),
      bottomNavigationBar: BarraAbas(
        abas: _abas,
        indice: _indice,
        aoEscolher: (i) {
          setState(() => _indice = i);
          _entrada.forward(from: 0);
        },
      ),
    );
  }
}
