import 'dart:convert';

import 'package:file_picker/file_picker.dart';

/// Abre o seletor de arquivos do sistema e devolve o texto do JSON.
///
/// `readAsBytes()` funciona em todas as plataformas (Android e Chrome),
/// então não precisa de `dart:io`. Null quando o piloto cancela.
Future<String?> escolherCadernetaJson() async {
  final arquivo = await FilePicker.pickFile(
    dialogTitle: 'Backup da caderneta',
    type: FileType.any,
  );
  if (arquivo == null) return null;
  try {
    final bytes = await arquivo.readAsBytes();
    if (bytes.isEmpty) return null;
    return utf8.decode(bytes);
  } on FormatException {
    return null;
  }
}
