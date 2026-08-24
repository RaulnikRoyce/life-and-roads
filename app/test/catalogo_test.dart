import 'package:flutter_test/flutter_test.dart';
import 'package:life_and_roads/ficha/catalogo.dart';

void main() {
  test('catálogo tem flex com km/l de álcool e gasolina-only sem álcool', () {
    expect(catalogoMotos.length, greaterThanOrEqualTo(20));

    final cg = catalogoMotos.firstWhere((m) => m.modelo == 'CG 160');
    expect(cg.flex, isTrue);
    expect(cg.kmPorLitroAlcool, 35);
    expect(cg.psiDianteiro, 25);
    expect(cg.correnteKm, 1000);
    expect(cg.uso, UsoCatalogo.cidade);

    final elite = catalogoMotos.firstWhere((m) => m.modelo == 'Elite 125');
    expect(elite.flex, isFalse);
    expect(elite.kmPorLitroAlcool, isNull);
    expect(elite.tanqueLitros, 5.3);
    expect(elite.correnteKm, isNull);

    final pop = catalogoMotos.firstWhere((m) => m.modelo == 'Pop 110i');
    expect(pop.flex, isFalse);
    expect(pop.kmPorLitroAlcool, isNull);
    expect(pop.correnteKm, 1000);
  });

  test('toda moto flex declara km/l de álcool', () {
    for (final m in catalogoMotos) {
      if (m.flex) {
        expect(m.kmPorLitroAlcool, isNotNull, reason: m.rotulo);
      } else {
        expect(m.kmPorLitroAlcool, isNull, reason: m.rotulo);
      }
    }
  });

  test('toda moto de corrente declara intervalo; scooter não', () {
    for (final m in catalogoMotos) {
      if (m.correnteKm == null) {
        continue;
      }
      expect(m.correnteKm, 1000, reason: m.rotulo);
    }
  });

  test('tanque e cilindrada cabem nos campos da ficha', () {
    for (final m in catalogoMotos) {
      expect(m.tanqueLitros, lessThanOrEqualTo(40), reason: m.rotulo);
      expect(m.cilindradaCc, lessThanOrEqualTo(2000), reason: m.rotulo);
    }
  });

  test('filtro cidade e estrada e motos novas', () {
    expect(catalogoFiltrado(null), catalogoMotos);
    expect(
      catalogoFiltrado(UsoCatalogo.cidade).every((m) => m.uso == UsoCatalogo.cidade),
      isTrue,
    );
    expect(
      catalogoFiltrado(UsoCatalogo.estrada).every((m) => m.uso == UsoCatalogo.estrada),
      isTrue,
    );

    expect(
      catalogoMotos.any((m) => m.modelo == 'Himalayan 450'),
      isTrue,
    );
    expect(catalogoMotos.any((m) => m.modelo == 'Ibex 700'), isTrue);
    expect(catalogoMotos.any((m) => m.modelo == 'Ténéré 250'), isTrue);
    expect(catalogoMotos.any((m) => m.modelo == 'Speed 400'), isTrue);
    expect(catalogoMotos.any((m) => m.modelo == 'Tiger 900'), isTrue);
    expect(catalogoMotos.any((m) => m.modelo == 'Versys 650'), isTrue);

    final speed = catalogoMotos.firstWhere((m) => m.modelo == 'Speed 400');
    expect(speed.uso, UsoCatalogo.cidade);
    expect(speed.flex, isFalse);

    final ibex = catalogoMotos.firstWhere((m) => m.modelo == 'Ibex 700');
    expect(ibex.uso, UsoCatalogo.estrada);
    expect(ibex.tanqueLitros, 20);
  });

  test('BMW GS de motoclube: corrente nas F e cardã nas R', () {
    final g310 = catalogoMotos.firstWhere((m) => m.modelo == 'G 310 GS');
    expect(g310.uso, UsoCatalogo.estrada);
    expect(g310.flex, isFalse);
    expect(g310.tanqueLitros, 11);
    expect(g310.correnteKm, 1000);

    final f850 = catalogoMotos.firstWhere((m) => m.modelo == 'F 850 GS');
    expect(f850.correnteKm, 1000);
    expect(f850.tanqueLitros, 15);

    final gsa = catalogoMotos.firstWhere((m) => m.modelo == 'R 1250 GS Adventure');
    expect(gsa.tanqueLitros, 30);
    expect(gsa.correnteKm, isNull);
    expect(gsa.flex, isFalse);

    final r1300 = catalogoMotos.firstWhere((m) => m.modelo == 'R 1300 GS');
    expect(r1300.cilindradaCc, 1300);
    expect(r1300.correnteKm, isNull);
    expect(r1300.uso, UsoCatalogo.estrada);
  });
}
