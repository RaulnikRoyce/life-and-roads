import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:life_and_roads/api.dart';
import 'package:life_and_roads/ficha/tela_ficha.dart';
import 'package:life_and_roads/manutencao/tela_manutencao.dart';
import 'package:life_and_roads/mapa/tela_mapa.dart';
import 'package:life_and_roads/tema.dart';
import 'package:life_and_roads/viagem/tela_viagem.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await ApiCaderneta.carregarBase();
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ),
  );
  runApp(const LifeAndRoadsApp());
}

class LifeAndRoadsApp extends StatelessWidget {
  const LifeAndRoadsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'life.and.roads',
      debugShowCheckedModeBanner: false,
      theme: temaOficina(),
      home: const TelaPrincipal(),
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

class TelaPrincipal extends StatefulWidget {
  const TelaPrincipal({super.key});

  @override
  State<TelaPrincipal> createState() => _TelaPrincipalState();
}

class _TelaPrincipalState extends State<TelaPrincipal> {
  int _indice = 0;

  static const _abas = [
    _Aba(titulo: 'Ficha', icone: Icons.two_wheeler),
    _Aba(titulo: 'Manutenção', icone: Icons.build),
    _Aba(titulo: 'Viagem', icone: Icons.route),
    _Aba(titulo: 'Mapa', icone: Icons.map),
  ];

  @override
  Widget build(BuildContext context) {
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
        children: const [
          TelaFicha(),
          TelaManutencao(),
          TelaViagem(),
          TelaMapa(),
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
