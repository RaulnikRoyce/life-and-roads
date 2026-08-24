import 'dart:convert';
import 'dart:typed_data';

import 'package:shared_preferences/shared_preferences.dart';

/// Uma foto da moto, neste aparelho. Sem placa no arquivo.
class FotoMoto {
  static const chave = 'foto_moto_v1';

  static Future<Uint8List?> carregar() async {
    final prefs = await SharedPreferences.getInstance();
    final bruto = prefs.getString(chave);
    if (bruto == null || bruto.isEmpty) return null;
    try {
      return base64Decode(bruto);
    } on FormatException {
      return null;
    }
  }

  static Future<void> salvar(Uint8List bytes) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(chave, base64Encode(bytes));
  }

  static Future<void> apagar() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(chave);
  }
}
