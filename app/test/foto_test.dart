import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:life_and_roads/ficha/foto.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('salva e carrega a foto neste aparelho', () async {
    SharedPreferences.setMockInitialValues({});
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
}
