import 'dart:io';

/// Ex. `android 14`. Só o sistema e a versão; nada do aparelho ou do piloto.
String descreverPlataforma() {
  final sistema = Platform.operatingSystem;
  final versao = Platform.operatingSystemVersion.trim();
  final texto = versao.isEmpty ? sistema : '$sistema $versao';
  return texto.length > 80 ? texto.substring(0, 80) : texto;
}
