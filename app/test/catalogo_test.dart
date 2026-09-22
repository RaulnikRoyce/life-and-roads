import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:life_and_roads/ficha/catalogo.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('catálogo tem flex com km/l de álcool e gasolina-only sem álcool', () {
    expect(catalogoMotos.length, greaterThanOrEqualTo(100));

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
      // 1.000 km na maioria; algumas indianas pedem a cada 500 no manual.
      expect(m.correnteKm, anyOf(500, 1000), reason: m.rotulo);
    }
  });

  test('tanque e cilindrada cabem nos campos da ficha', () {
    for (final m in catalogoMotos) {
      expect(m.tanqueLitros, lessThanOrEqualTo(40), reason: m.rotulo);
      expect(m.cilindradaCc, lessThanOrEqualTo(2000), reason: m.rotulo);
    }
  });

  test('filtro cidade e trail e motos novas', () {
    expect(catalogoFiltrado(null), catalogoMotos);
    expect(
      catalogoFiltrado(UsoCatalogo.cidade)
          .every((m) => m.uso == UsoCatalogo.cidade),
      isTrue,
    );
    expect(
      catalogoFiltrado(UsoCatalogo.trail)
          .every((m) => m.uso == UsoCatalogo.trail),
      isTrue,
    );

    expect(catalogoMotos.any((m) => m.modelo == 'Himalayan 450'), isTrue);
    expect(catalogoMotos.any((m) => m.modelo == 'Ibex 700'), isTrue);
    expect(catalogoMotos.any((m) => m.modelo == 'Ténéré 250'), isTrue);
    expect(catalogoMotos.any((m) => m.modelo == 'Speed 400'), isTrue);
    expect(catalogoMotos.any((m) => m.modelo == 'Tiger 900'), isTrue);
    expect(catalogoMotos.any((m) => m.modelo == 'Versys 650'), isTrue);

    final speed = catalogoMotos.firstWhere((m) => m.modelo == 'Speed 400');
    expect(speed.uso, UsoCatalogo.cidade);
    expect(speed.flex, isFalse);

    final ibex = catalogoMotos.firstWhere((m) => m.modelo == 'Ibex 700');
    expect(ibex.uso, UsoCatalogo.trail);
    expect(ibex.tanqueLitros, 20);
  });

  test('filtro esportiva e foto da categoria', () {
    final esporte = catalogoFiltrado(UsoCatalogo.esporte);
    expect(esporte, isNotEmpty);
    expect(esporte.every((m) => m.uso == UsoCatalogo.esporte), isTrue);
    expect(esporte.any((m) => m.modelo == 'CBR 500R'), isTrue);
    expect(esporte.any((m) => m.modelo == 'CB 500F'), isTrue);
    expect(esporte.any((m) => m.modelo == 'R3'), isTrue);
    expect(esporte.any((m) => m.modelo == 'MT-03'), isTrue);
    expect(esporte.any((m) => m.modelo == 'Ninja 400'), isTrue);
    expect(esporte.any((m) => m.modelo == 'Duke 390'), isTrue);

    final cbr = catalogoMotos.firstWhere((m) => m.modelo == 'CBR 500R');
    expect(cbr.flex, isFalse);
    expect(cbr.kmPorLitroAlcool, isNull);
    expect(cbr.assetSilhueta, 'assets/catalogo/esporte.png');

    final elite = catalogoMotos.firstWhere((m) => m.modelo == 'Elite 125');
    expect(elite.assetSilhueta, 'assets/catalogo/cidade.png');

    final bros = catalogoMotos.firstWhere((m) => m.modelo == 'NXR 160 Bros');
    expect(bros.assetSilhueta, 'assets/catalogo/trail.png');

    final cg = catalogoMotos.firstWhere((m) => m.modelo == 'CG 160');
    expect(cg.flex, isTrue);
    expect(cg.kmPorLitroAlcool, 35);
    expect(cg.assetSilhueta, 'assets/catalogo/cidade.png');
  });

  test('BMW GS de motoclube: corrente nas F e cardã nas R', () {
    final g310 = catalogoMotos.firstWhere((m) => m.modelo == 'G 310 GS');
    expect(g310.uso, UsoCatalogo.trail);
    expect(g310.flex, isFalse);
    expect(g310.tanqueLitros, 11);
    expect(g310.correnteKm, 1000);

    final f850 = catalogoMotos.firstWhere((m) => m.modelo == 'F 850 GS');
    expect(f850.correnteKm, 1000);
    expect(f850.tanqueLitros, 15);

    final gsa = catalogoMotos.firstWhere(
      (m) => m.modelo == 'R 1250 GS Adventure',
    );
    expect(gsa.tanqueLitros, 30);
    expect(gsa.correnteKm, isNull);
    expect(gsa.flex, isFalse);

    final r1300 = catalogoMotos.firstWhere((m) => m.modelo == 'R 1300 GS');
    expect(r1300.cilindradaCc, 1300);
    expect(r1300.correnteKm, isNull);
    expect(r1300.uso, UsoCatalogo.trail);
  });

  test('estrada é custom, clássica e touring de asfalto', () {
    final estrada = catalogoFiltrado(UsoCatalogo.estrada);
    expect(estrada, isNotEmpty);
    expect(estrada.every((m) => m.uso == UsoCatalogo.estrada), isTrue);
    for (final modelo in [
      'Fat Boy',
      'Street Glide',
      'Bonneville T120',
      'Vulcan S',
      'Super Meteor 650',
      'Interceptor 650',
      'R 1250 RT',
      'Tracer 9',
    ]) {
      expect(estrada.any((m) => m.modelo == modelo), isTrue, reason: modelo);
    }
    final fatBoy = catalogoMotos.firstWhere((m) => m.modelo == 'Fat Boy');
    expect(fatBoy.assetSilhueta, 'assets/catalogo/estrada.png');
    // Correia na Harley custom, então nada de lubrificar corrente.
    expect(fatBoy.correnteKm, isNull);
  });

  test('motos populares do ranking estão no catálogo', () {
    for (final modelo in [
      'Sport 110i',
      'Biz 110i',
      'SHI 175',
      'Jet 125',
      'DK 150',
      'Aerox 160',
      'Dominar 400',
      'Neo 125',
    ]) {
      expect(
        catalogoMotos.any((m) => m.modelo == modelo),
        isTrue,
        reason: modelo,
      );
    }

    // O manual da SHI 175 manda trocar o óleo a cada 1.000 km.
    final shi = catalogoMotos.firstWhere((m) => m.modelo == 'SHI 175');
    expect(shi.oleoKm, 1000);
    expect(shi.uso, UsoCatalogo.trail);
    expect(shi.psiDianteiro, 22);

    // Scooter não tem corrente.
    for (final modelo in ['Neo 125', 'Aerox 160', 'XMAX 250', 'Citycom 300']) {
      final m = catalogoMotos.firstWhere((x) => x.modelo == modelo);
      expect(m.correnteKm, isNull, reason: modelo);
    }
  });

  test('catálogo não tem modelo repetido', () {
    final vistos = <String>{};
    for (final m in catalogoMotos) {
      expect(vistos.add('${m.marca} ${m.modelo}'), isTrue, reason: m.rotulo);
    }
  });

  test('fotos das quatro categorias estão no bundle', () async {
    for (final p in [
      'assets/catalogo/cidade.png',
      'assets/catalogo/trail.png',
      'assets/catalogo/estrada.png',
      'assets/catalogo/esporte.png',
    ]) {
      final dados = await rootBundle.load(p);
      expect(dados.lengthInBytes, greaterThan(100), reason: p);
      expect(dados.lengthInBytes, lessThan(400000), reason: p);
    }
  });
}
