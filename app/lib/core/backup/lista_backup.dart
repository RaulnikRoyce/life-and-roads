import 'dart:convert';

/// Lê listas v1/v2. Restaurações usam modo estrito para não descartar dados.
List<T> listaDeBackup<T>(
  Object? valor,
  T? Function(Object?) parse, {
  bool estrita = false,
}) {
  Object? bruto = valor;
  if (bruto is String) {
    try {
      bruto = jsonDecode(bruto);
    } catch (_) {
      if (estrita) {
        throw const FormatException('Lista de backup inválida.');
      }
      return [];
    }
  }
  if (bruto is! List) {
    if (estrita) {
      throw const FormatException('Lista de backup ausente ou inválida.');
    }
    return [];
  }
  final resultado = <T>[];
  for (final item in bruto) {
    T? registro;
    try {
      registro = parse(item);
    } catch (_) {
      if (estrita) {
        throw const FormatException('Registro de backup inválido.');
      }
    }
    if (registro == null) {
      if (estrita) {
        throw const FormatException('Registro de backup inválido.');
      }
    } else {
      resultado.add(registro);
    }
  }
  return resultado;
}
