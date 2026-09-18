import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:life_and_roads/core/database/armazem_kv.dart';
import 'package:life_and_roads/core/database/chaves_kv.dart';
import 'package:life_and_roads/features/ficha/domain/usecases/enviar_caderneta_arquivo.dart';
import 'package:life_and_roads/features/ficha/domain/usecases/importar_caderneta_arquivo.dart';
import 'package:life_and_roads/features/viagem/domain/usecases/resumo_consumo.dart';
import 'package:life_and_roads/viagem/calculo.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../helpers/banco_teste.dart';

RegistroAbastecimento _posto(double reaisPorKm, {double km = 100}) {
  return RegistroAbastecimento(
    em: '2026-08-01T12:00:00.000',
    combustivel: Combustivel.gasolina,
    kmPainel: 1100,
    kmRodados: km,
    litros: 5,
    precoLitro: 6,
    reais: reaisPorKm * km,
    kmPorLitro: 20,
    reaisPorKm: reaisPorKm,
  );
}

void main() {
  test('resumo vazio e barras proporcionais ao R\$/km', () {
    const regra = ResumoConsumo();
    expect(regra.executar(const []).barras, isEmpty);
    expect(regra.executar(const []).media, isNull);

    final r = regra.executar([_posto(0.10), _posto(0.20)]);
    expect(r.media, closeTo(0.15, 0.001));
    expect(r.barras, hasLength(2));
    expect(r.barras.first.fracao, closeTo(0.5, 0.001));
    expect(r.barras.last.fracao, 1);
  });

  test('exporta e importa o JSON v2 num arquivo', () async {
    SharedPreferences.setMockInitialValues({});
    await abrirBancoTeste();
    addTearDown(fecharBancoTeste);
    final dir = await Directory.systemTemp.createTemp('caderneta');
    addTearDown(() => dir.delete(recursive: true));

    await ArmazemKv.gravarTexto(
      ChavesKv.ficha,
      '{"marca":"Honda","modelo":"Bros"}',
    );
    String? gerado;
    final saida = await EnviarCadernetaArquivo(
      pasta: dir.path,
      enviar: ({String? caminho, String? json}) async {
        gerado = caminho;
        return true;
      },
    ).executar();
    expect(saida.erro, isNull);
    expect(gerado, isNotNull);
    final arquivo = File(gerado!);
    expect(arquivo.existsSync(), isTrue);

    await ArmazemKv.gravarTexto(ChavesKv.ficha, null);
    expect(await ArmazemKv.lerTexto(ChavesKv.ficha), isNull);

    // O que a tela faz depois do seletor de arquivos: lê e passa o texto.
    final texto = await arquivo.readAsString();
    expect(await const ImportarCadernetaArquivo().executar(texto), isNull);
    expect(await ArmazemKv.lerTexto(ChavesKv.ficha), contains('Bros'));
  });

  test('backup vazio avisa em PT-BR', () async {
    SharedPreferences.setMockInitialValues({});
    await abrirBancoTeste();
    addTearDown(fecharBancoTeste);
    expect(
      await const ImportarCadernetaArquivo().executar('   '),
      'Arquivo de backup vazio.',
    );
  });
}
