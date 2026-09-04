import 'package:flutter_test/flutter_test.dart';
import 'package:life_and_roads/core/config/ambiente.dart';

void main() {
  test('sem dart-define o build é development e não relata crash', () {
    expect(Ambiente.nome, 'development');
    expect(Ambiente.producao, isFalse);
    expect(Ambiente.relataCrash, isFalse);
    expect(Ambiente.apiPadrao, 'http://localhost:3001');
    expect(Ambiente.exibeCampoServidor, isTrue);
  });

  test('exibeCampoServidor some em produção e staging', () {
    expect(
      Ambiente.exibeCampoServidorDe(producao: false, staging: false),
      isTrue,
    );
    expect(
      Ambiente.exibeCampoServidorDe(producao: true, staging: false),
      isFalse,
    );
    expect(
      Ambiente.exibeCampoServidorDe(producao: false, staging: true),
      isFalse,
    );
  });

  test('staging e produção recusam API sem HTTPS', () {
    expect(
      () => Ambiente.validarApiBase(
        'http://api.exemplo.com',
        producao: true,
        staging: false,
      ),
      throwsStateError,
    );
    expect(
      Ambiente.validarApiBase(
        'https://api.exemplo.com/',
        producao: false,
        staging: true,
      ),
      'https://api.exemplo.com',
    );
  });
}
