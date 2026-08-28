import 'dart:convert';
import 'dart:typed_data';

import 'package:life_and_roads/core/database/caderneta_banco.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Lê o SQLite; se vazio, copia a chave legado das prefs e apaga a prefs.
class ArmazemKv {
  static Future<String?> lerTexto(String chave) async {
    final db = CadernetaBanco.instancia;
    final atual = await db.lerTextoKv(chave);
    if (atual != null && atual.isNotEmpty) return atual;
    final prefs = await SharedPreferences.getInstance();
    final legado = prefs.getString(chave);
    if (legado == null || legado.isEmpty) return null;
    await db.gravarTextoKv(chave, legado);
    await prefs.remove(chave);
    return legado;
  }

  static Future<void> gravarTexto(String chave, String? valor) async {
    await CadernetaBanco.instancia.gravarTextoKv(chave, valor);
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(chave);
  }

  static Future<Uint8List?> lerBlob(String chave) async {
    final db = CadernetaBanco.instancia;
    final atual = await db.lerBlobKv(chave);
    if (atual != null && atual.isNotEmpty) return atual;
    final prefs = await SharedPreferences.getInstance();
    final bruto = prefs.getString(chave);
    if (bruto == null || bruto.isEmpty) return null;
    try {
      final bytes = base64Decode(bruto);
      if (bytes.isEmpty) return null;
      await db.gravarBlobKv(chave, bytes);
      await prefs.remove(chave);
      return bytes;
    } on FormatException {
      return null;
    }
  }

  static Future<void> gravarBlob(String chave, Uint8List? bytes) async {
    await CadernetaBanco.instancia.gravarBlobKv(chave, bytes);
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(chave);
  }
}
