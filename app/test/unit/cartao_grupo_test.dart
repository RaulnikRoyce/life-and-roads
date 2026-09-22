import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:life_and_roads/features/manutencao/presentation/widgets/cartao_grupo.dart';
import 'package:life_and_roads/tema.dart';

void main() {
  GoogleFonts.config.allowRuntimeFetching = false;

  testWidgets(
    'mostra rótulos em caixa alta, "-" no vazio e responde ao toque',
    (tester) async {
      var toques = 0;
      await tester.pumpWidget(
        MaterialApp(
          theme: temaOficina(),
          home: Scaffold(
            body: Padding(
              padding: const EdgeInsets.all(20),
              child: CartaoGrupo(
                icone: Icons.tire_repair_outlined,
                titulo: 'Pneus',
                pares: const [
                  ParGrupo('Última', '12/03/2026'),
                  ParGrupo('Próxima', null),
                  ParGrupo('Km na troca', ''),
                ],
                onTap: () => toques++,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('PNEUS'), findsOneWidget);
      expect(find.text('ÚLTIMA'), findsOneWidget);
      expect(find.text('PRÓXIMA'), findsOneWidget);
      expect(find.text('KM NA TROCA'), findsOneWidget);
      expect(find.text('12/03/2026'), findsOneWidget);
      expect(find.text('-'), findsNWidgets(2));
      expect(find.byIcon(Icons.tire_repair_outlined), findsOneWidget);
      expect(find.byIcon(Icons.tune), findsOneWidget);

      await tester.tap(find.text('12/03/2026'));
      await tester.pump();
      expect(toques, 1);
    },
  );
}
