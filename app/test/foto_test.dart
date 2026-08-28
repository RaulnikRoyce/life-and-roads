import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:life_and_roads/ficha/foto.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'helpers/banco_teste.dart';

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await abrirBancoTeste();
  });

  tearDown(() async {
    await fecharBancoTeste();
  });

  test('salva e carrega a foto neste aparelho', () async {
    final bytes = Uint8List.fromList([1, 2, 3, 4]);
    await FotoMoto.salvar(bytes);
    expect(await FotoMoto.carregar(), bytes);
  });

  test('apaga a foto', () async {
    SharedPreferences.setMockInitialValues({
      FotoMoto.chave: base64Encode([9, 9]),
    });
    await FotoMoto.apagar();
    expect(await FotoMoto.carregar(), isNull);
  });

  test('foto base64 nas prefs migra para o blob', () async {
    SharedPreferences.setMockInitialValues({
      FotoMoto.chave: base64Encode([1, 2, 3]),
    });
    expect(await FotoMoto.carregar(), [1, 2, 3]);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString(FotoMoto.chave), isNull);
  });
}
