import 'package:life_and_roads/api.dart';
import 'package:life_and_roads/features/ficha/domain/ficha_moto.dart';
import 'package:life_and_roads/viagem/calculo.dart';

/// Conversão exclusiva para JSON local (`ficha_moto_v1`) e payload da API.
class FichaMotoModel {
  static FichaMoto fromJson(Map<String, dynamic> mapa) {
    final alcool = ApiCaderneta.numero(mapa['kmLitroAlcool']);
    return FichaMoto(
      marca: _texto(mapa['marca'], 40),
      modelo: _texto(mapa['modelo'], 60),
      ano: _inteiro(mapa['ano']),
      cilindrada: _inteiro(mapa['cilindrada']),
      kmLitro: ApiCaderneta.numero(mapa['kmLitro']) ?? 0,
      kmLitroAlcool: alcool,
      combustivel: combustivelDe(mapa['combustivel']),
      kmAtual: ApiCaderneta.numero(mapa['kmAtual']) ?? 0,
      tanqueLitros: ApiCaderneta.numero(mapa['tanqueLitros']),
      personalizacoes: _texto(mapa['personalizacoes'], 200),
      psiDianteiro: _inteiro(mapa['psiDianteiro']),
      psiTraseiro: _inteiro(mapa['psiTraseiro']),
    );
  }

  /// Mesmas chaves e strings que a tela gravava em `ficha_moto_v1`.
  static Map<String, dynamic> toJson(FichaMoto ficha) {
    return {
      'marca': ficha.marca,
      'modelo': ficha.modelo,
      'ano': ficha.ano?.toString() ?? '',
      'cilindrada': ficha.cilindrada?.toString() ?? '',
      'kmLitro': _decimalLocal(ficha.kmLitro),
      'kmLitroAlcool': ficha.kmLitroAlcool == null
          ? ''
          : _decimalLocal(ficha.kmLitroAlcool!),
      'combustivel': ficha.combustivel.name,
      'kmAtual': _decimalLocal(ficha.kmAtual),
      'tanqueLitros': ficha.tanqueLitros == null
          ? ''
          : _decimalLocal(ficha.tanqueLitros!),
      'personalizacoes': ficha.personalizacoes,
      'psiDianteiro': ficha.psiDianteiro?.toString() ?? '',
      'psiTraseiro': ficha.psiTraseiro?.toString() ?? '',
    };
  }

  /// Sem PSI. Tipos numéricos que o schema Zod espera.
  static Map<String, dynamic> toApiJson(FichaMoto ficha) {
    return {
      'marca': ficha.marca,
      'modelo': ficha.modelo,
      'ano': ficha.ano,
      'cilindrada': ficha.cilindrada,
      'kmLitro': ficha.kmLitro,
      'kmLitroAlcool': ficha.kmLitroAlcool,
      'combustivel': ficha.combustivel.name,
      'kmAtual': ficha.kmAtual,
      'tanqueLitros': ficha.tanqueLitros,
      'personalizacoes': ficha.personalizacoes,
    };
  }

  static String _texto(Object? valor, int max) {
    final t = '${valor ?? ''}'.trim();
    if (t.length <= max) return t;
    return t.substring(0, max);
  }

  static int? _inteiro(Object? valor) {
    if (valor == null) return null;
    if (valor is int) return valor;
    if (valor is num) return valor.toInt();
    final t = '$valor'.trim();
    if (t.isEmpty) return null;
    return int.tryParse(t);
  }

  static String _decimalLocal(double n) {
    if (n == n.roundToDouble()) return n.toStringAsFixed(0);
    return n.toString();
  }
}
