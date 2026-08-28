import 'dart:convert';

/// Aceita a lista crua (backup v2) ou a string JSON das chaves v1.
List<T> listaDeBackup<T>(Object? valor, T? Function(Object?) parse) {
  Object? bruto = valor;
  if (bruto is String) {
    if (bruto.isEmpty) return [];
    try {
      bruto = jsonDecode(bruto);
    } on FormatException {
      return [];
    }
  }
  if (bruto is! List) return [];
  return [
    for (final item in bruto)
      if (parse(item) case final T v) v,
  ];
}
