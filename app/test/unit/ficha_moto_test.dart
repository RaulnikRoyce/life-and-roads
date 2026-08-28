import 'package:flutter_test/flutter_test.dart';
import 'package:life_and_roads/features/ficha/data/ficha_moto_model.dart';
import 'package:life_and_roads/features/ficha/domain/ficha_moto.dart';
import 'package:life_and_roads/viagem/calculo.dart';

void main() {
  test('JSON legado vira FichaMoto', () {
    final ficha = FichaMotoModel.fromJson({
      'marca': 'Honda',
      'modelo': 'NXR 160 Bros',
      'ano': '2019',
      'cilindrada': '163',
      'kmLitro': '35',
      'kmLitroAlcool': '28',
      'combustivel': 'gasolina',
      'kmAtual': '32130',
      'tanqueLitros': '12',
      'personalizacoes': '',
      'psiDianteiro': '22',
      'psiTraseiro': '29',
    });
    expect(ficha.marca, 'Honda');
    expect(ficha.modelo, 'NXR 160 Bros');
    expect(ficha.ano, 2019);
    expect(ficha.kmLitro, 35);
    expect(ficha.kmLitroAlcool, 28);
    expect(ficha.kmAtual, 32130);
    expect(ficha.tanqueLitros, 12);
    expect(ficha.psiDianteiro, 22);
    expect(ficha.flex, isTrue);
    expect(ficha.validar(agora: DateTime(2026, 8, 26)), isNull);
  });

  test('toJson local preserva as chaves da caderneta', () {
    const ficha = FichaMoto(
      marca: 'Honda',
      modelo: 'Bros',
      kmLitro: 35,
      kmAtual: 1000,
      psiDianteiro: 22,
    );
    final json = FichaMotoModel.toJson(ficha);
    expect(json['marca'], 'Honda');
    expect(json['kmLitro'], '35');
    expect(json['kmAtual'], '1000');
    expect(json['psiDianteiro'], '22');
    expect(json['combustivel'], 'gasolina');
    expect(FichaMotoModel.fromJson(json), ficha);
  });

  test('toApiJson não leva PSI', () {
    const ficha = FichaMoto(
      marca: 'Honda',
      modelo: 'Bros',
      kmLitro: 35,
      kmAtual: 1000,
      psiDianteiro: 22,
      psiTraseiro: 29,
    );
    final api = FichaMotoModel.toApiJson(ficha);
    expect(api.containsKey('psiDianteiro'), isFalse);
    expect(api.containsKey('psiTraseiro'), isFalse);
    expect(api['kmLitro'], 35);
    expect(api['kmAtual'], 1000);
    expect(api['marca'], 'Honda');
  });

  test('API numérica também parseia', () {
    final ficha = FichaMotoModel.fromJson({
      'marca': 'Honda',
      'modelo': 'CG 160',
      'kmLitro': 41,
      'kmLitroAlcool': 35,
      'kmAtual': 1000.0,
      'tanqueLitros': 16.1,
    });
    expect(ficha.kmLitro, 41);
    expect(ficha.tanqueLitros, 16.1);
  });

  test('tentar recusa marca vazia', () {
    final r = FichaMoto.tentar(
      marca: '  ',
      modelo: 'Bros',
      kmLitro: '35',
      kmAtual: '10',
    );
    expect(r.ficha, isNull);
    expect(r.erro, 'Marca e modelo são obrigatórios.');
  });

  test('tentar recusa km/l fora da faixa', () {
    final r = FichaMoto.tentar(
      marca: 'Honda',
      modelo: 'Bros',
      kmLitro: '3',
      kmAtual: '10',
    );
    expect(r.erro, 'Quanto anda com 1 L de gasolina fica entre 5 e 80.');
  });

  test('tentar aceita vírgula decimal', () {
    final r = FichaMoto.tentar(
      marca: 'Honda',
      modelo: 'Bros',
      kmLitro: '35,5',
      kmAtual: '1000',
      tanqueLitros: '12,0',
      agora: DateTime(2026, 1, 1),
    );
    expect(r.erro, isNull);
    expect(r.ficha!.kmLitro, 35.5);
    expect(r.ficha!.tanqueLitros, 12);
    expect(r.ficha!.combustivel, Combustivel.gasolina);
  });
}
