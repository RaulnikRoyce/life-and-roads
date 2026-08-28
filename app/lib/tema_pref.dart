import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Preferência de tema (claro, escuro ou automático). Persistida neste aparelho.
class PreferenciaTema {
  static const chave = 'tema_v1';

  static ThemeMode deTexto(String? v) {
    return switch (v) {
      'light' => ThemeMode.light,
      'dark' => ThemeMode.dark,
      _ => ThemeMode.system,
    };
  }

  static String paraTexto(ThemeMode modo) {
    return switch (modo) {
      ThemeMode.light => 'light',
      ThemeMode.dark => 'dark',
      ThemeMode.system => 'system',
    };
  }

  static ThemeMode seguinte(ThemeMode atual) {
    return switch (atual) {
      ThemeMode.system => ThemeMode.light,
      ThemeMode.light => ThemeMode.dark,
      ThemeMode.dark => ThemeMode.system,
    };
  }

  static String rotulo(ThemeMode modo) {
    return switch (modo) {
      ThemeMode.system => 'Automático',
      ThemeMode.light => 'Claro',
      ThemeMode.dark => 'Escuro',
    };
  }

  static IconData icone(ThemeMode modo) {
    return switch (modo) {
      ThemeMode.system => Icons.brightness_auto,
      ThemeMode.light => Icons.light_mode,
      ThemeMode.dark => Icons.dark_mode,
    };
  }

  static Future<ThemeMode> carregar() async {
    final prefs = await SharedPreferences.getInstance();
    return deTexto(prefs.getString(chave));
  }

  static Future<void> salvar(ThemeMode modo) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(chave, paraTexto(modo));
  }
}
