import 'dart:convert';

import 'package:life_and_roads/features/ficha/domain/ficha_moto.dart';
import 'package:life_and_roads/viagem/calculo.dart';

/// A capacidade faz parte da referência: alterar o tanque exige novas leituras.
String? referenciaMarcadorDaFicha(FichaMoto? ficha) {
  final capacidade = ficha?.tanqueLitros;
  if (ficha == null ||
      !ficha.preenchida ||
      capacidade == null ||
      !capacidade.isFinite ||
      capacidade < 2 ||
      capacidade > 40) {
    return null;
  }
  String normalizar(String texto) =>
      texto.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');
  return jsonEncode([
    normalizar(ficha.marca),
    normalizar(ficha.modelo),
    ficha.ano,
    ficha.cilindrada,
    capacidade,
  ]);
}

class FaixaMarcador {
  const FaixaMarcador({
    required this.minimo,
    required this.maximo,
    required this.referencias,
  });
  final double minimo, maximo;
  final int referencias;
}

class CalibracaoMarcador {
  const CalibracaoMarcador({
    this.niveis = const {},
    this.contraditoria = false,
  });
  final Map<int, FaixaMarcador> niveis;
  final bool contraditoria;
  FaixaMarcador? consultar(int nivel) {
    final faixa = niveis[nivel];
    return !contraditoria &&
            faixa != null &&
            faixa.referencias >= CalibrarMarcador.minimoReferencias
        ? faixa
        : null;
  }
}

/// Aprende cada nível independentemente. Não interpola nem supõe barras iguais.
class CalibrarMarcador {
  const CalibrarMarcador();
  static const minimoReferencias = 3;

  CalibracaoMarcador executar({
    required FichaMoto? ficha,
    required List<RegistroAbastecimento> historico,
    required int totalBarras,
  }) {
    final referencia = referenciaMarcadorDaFicha(ficha);
    if (referencia == null || totalBarras < 1 || totalBarras > 30) {
      return const CalibracaoMarcador();
    }
    final capacidade = ficha!.tanqueLitros!;
    final amostras = <int, List<double>>{};
    final vistos = <String>{};
    for (final r in historico) {
      final antes = r.barrasAntes;
      if (r.referenciaMarcador != referencia ||
          !r.tanqueCheio ||
          r.totalBarras != totalBarras ||
          r.barrasDepois != totalBarras ||
          antes == null ||
          antes < 0 ||
          antes > totalBarras ||
          !r.litros.isFinite ||
          r.litros <= 0 ||
          r.litros > capacidade ||
          !vistos.add('${r.em}|${r.kmPainel}')) {
        continue;
      }
      (amostras[antes] ??= []).add(capacidade - r.litros);
    }
    final niveis = <int, FaixaMarcador>{};
    for (final entrada in amostras.entries) {
      entrada.value.sort();
      niveis[entrada.key] = FaixaMarcador(
        minimo: entrada.value.first,
        maximo: entrada.value.last,
        referencias: entrada.value.length,
      );
    }
    // Se todas as leituras de um nível baixo superam as de um nível mais alto,
    // não há uma curva coerente para apresentar ao piloto.
    var contraditoria = false;
    for (final a in niveis.entries) {
      for (final b in niveis.entries) {
        if (a.key < b.key && a.value.minimo > b.value.maximo) {
          contraditoria = true;
        }
      }
    }
    return CalibracaoMarcador(
      niveis: Map.unmodifiable(niveis),
      contraditoria: contraditoria,
    );
  }
}
