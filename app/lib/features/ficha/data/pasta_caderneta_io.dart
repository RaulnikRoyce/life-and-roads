import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

const nomeArquivoCaderneta = 'caderneta-life-and-roads.json';

Future<String> _pastaPadrao() async {
  final dir = await getApplicationDocumentsDirectory();
  return dir.path;
}

Future<({String? caminho, String? erro})> gravarCadernetaJson(
  String json, {
  String? pasta,
}) async {
  try {
    final dir = pasta ?? await _pastaPadrao();
    final file = File(p.join(dir, nomeArquivoCaderneta));
    await file.writeAsString(json);
    return (caminho: file.path, erro: null);
  } catch (_) {
    return (caminho: null, erro: 'Não foi possível salvar o arquivo.');
  }
}

Future<String?> lerCadernetaJson({String? caminho, String? pasta}) async {
  try {
    final file = File(
      caminho ??
          p.join(pasta ?? await _pastaPadrao(), nomeArquivoCaderneta),
    );
    if (!await file.exists()) return null;
    return await file.readAsString();
  } catch (_) {
    return null;
  }
}
