import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:life_and_roads/backup.dart';
import 'package:life_and_roads/core/api/openapi/dtos.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../helpers/banco_teste.dart';

void main() {
  late String yaml;

  setUpAll(() {
    final candidatos = [
      File('../docs/openapi.yaml'),
      File('docs/openapi.yaml'),
    ];
    yaml = candidatos
        .firstWhere((f) => f.existsSync())
        .readAsStringSync()
        .replaceAll('\r\n', '\n');
  });

  test('FichaDto espelha o schema OpenAPI', () {
    expect(_chaves(yaml, 'Ficha'), FichaDto.chaves);
    final dto = FichaDto.fromJson({
      'marca': 'Honda',
      'modelo': 'Bros',
      'kmLitro': 35,
      'kmAtual': 1000,
      'psiDianteiro': 32,
    });
    expect(dto.toJson().containsKey('psiDianteiro'), isFalse);
    expect(dto.marca, 'Honda');
  });

  test('ManutencaoDto e LocalizacaoDto espelham o OpenAPI', () {
    expect(_chaves(yaml, 'Manutencao'), ManutencaoDto.chaves);
    expect(_chaves(yaml, 'Localizacao'), LocalizacaoDto.chaves);
    expect(_chaves(yaml, 'Credenciais'), CredenciaisDto.chaves);
    expect(_chaves(yaml, 'TrocaSenha'), TrocaSenhaDto.chaves);
    expect(_chaves(yaml, 'RecuperarSenha'), RecuperarSenhaDto.chaves);
    expect(_chaves(yaml, 'RedefinirSenha'), RedefinirSenhaDto.chaves);
    expect(_chaves(yaml, 'Cadastro'), CadastroDto.chaves);
    expect(_chaves(yaml, 'Termos'), TermosDto.chaves);
  });

  test('o pacote da nuvem tem as chaves do ConteudoCaderneta, nem mais nem menos', () async {
    // A API recusa chave a mais com .strict(); faltar uma também é 400.
    SharedPreferences.setMockInitialValues({});
    await abrirBancoTeste();
    addTearDown(fecharBancoTeste);

    final pacote = await BackupCaderneta.exportarParaNuvem();

    expect(pacote.keys.toList(), _chaves(yaml, 'ConteudoCaderneta'));
  });
}

List<String> _chaves(String yaml, String schema) {
  final bloco = RegExp('    $schema:\\n(?:      .*\\n)+')
      .firstMatch(yaml)
      ?.group(0);
  if (bloco == null) return [];
  final props = bloco.split('properties:\n');
  if (props.length < 2) return [];
  return [
    for (final m in RegExp(
      r'^        (\w+):',
      multiLine: true,
    ).allMatches(props[1]))
      m.group(1)!,
  ];
}
