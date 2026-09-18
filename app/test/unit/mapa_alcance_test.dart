import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:life_and_roads/features/ficha/domain/ficha_moto.dart';
import 'package:life_and_roads/features/mapa/domain/usecases/autonomia_no_mapa.dart';
import 'package:life_and_roads/features/mapa/domain/usecases/links_do_ponto.dart';
import 'package:life_and_roads/viagem/calculo.dart';

void main() {
  const alcance = AutonomiaNoMapa();

  test('alcance é tanque × km/l do combustível atual', () {
    const gasolina = FichaMoto(
      marca: 'Honda',
      modelo: 'Bros',
      kmLitro: 35,
      kmLitroAlcool: 25,
      kmAtual: 1000,
      tanqueLitros: 12,
    );
    expect(alcance.executar(gasolina), 420);
    expect(
      alcance.executar(gasolina.copiarCom(combustivel: Combustivel.alcool)),
      300,
    );
  });

  test('sem tanque ou sem ficha não há círculo', () {
    const semTanque = FichaMoto(
      marca: 'Honda',
      modelo: 'Bros',
      kmLitro: 35,
      kmAtual: 1000,
    );
    expect(alcance.executar(semTanque), isNull);
    expect(alcance.executar(null), isNull);
  });

  test('álcool sem km/l próprio usa o da gasolina', () {
    const flexSemAlcool = FichaMoto(
      marca: 'Honda',
      modelo: 'Bros',
      kmLitro: 30,
      kmAtual: 1000,
      tanqueLitros: 10,
      combustivel: Combustivel.alcool,
    );
    expect(alcance.executar(flexSemAlcool), 300);
  });

  group('links do ponto', () {
    const links = LinksDoPonto();
    const p = LatLng(-23.55052, -46.633308);

    test('geo: com rótulo codificado', () {
      final u = links.navegacao(p, rotulo: 'Posto Ipiranga');
      expect(u.scheme, 'geo');
      expect(
        u.toString(),
        'geo:-23.550520,-46.633308?q=-23.550520,-46.633308(Posto%20Ipiranga)',
      );
    });

    test('geo: sem rótulo', () {
      expect(
        links.navegacao(p).toString(),
        'geo:-23.550520,-46.633308?q=-23.550520,-46.633308',
      );
    });

    test('fallback web e texto de compartilhar', () {
      expect(
        links.navegacaoWeb(p).toString(),
        contains('query=-23.550520,-46.633308'),
      );
      expect(
        links.ondeEstou(p),
        'Estou aqui: https://maps.google.com/?q=-23.550520,-46.633308',
      );
    });
  });
}
