import 'package:life_and_roads/viagem/calculo.dart';

/// Ficha da única moto da v1. Sem placa, chassi ou RENAVAM.
class FichaMoto {
  const FichaMoto({
    required this.marca,
    required this.modelo,
    this.ano,
    this.cilindrada,
    required this.kmLitro,
    this.kmLitroAlcool,
    this.combustivel = Combustivel.gasolina,
    required this.kmAtual,
    this.tanqueLitros,
    this.personalizacoes = '',
    this.psiDianteiro,
    this.psiTraseiro,
  });

  static const anoMin = 1980;

  final String marca;
  final String modelo;
  final int? ano;
  final int? cilindrada;
  final double kmLitro;
  final double? kmLitroAlcool;
  final Combustivel combustivel;
  final double kmAtual;
  final double? tanqueLitros;
  final String personalizacoes;
  final int? psiDianteiro;
  final int? psiTraseiro;

  bool get flex => kmLitroAlcool != null;
  bool get preenchida => marca.trim().isNotEmpty && modelo.trim().isNotEmpty;

  String get nome {
    final t = '${marca.trim()} ${modelo.trim()}'.trim();
    return t;
  }

  FichaMoto copiarCom({
    String? marca,
    String? modelo,
    int? ano,
    bool limparAno = false,
    int? cilindrada,
    bool limparCilindrada = false,
    double? kmLitro,
    double? kmLitroAlcool,
    bool limparAlcool = false,
    Combustivel? combustivel,
    double? kmAtual,
    double? tanqueLitros,
    bool limparTanque = false,
    String? personalizacoes,
    int? psiDianteiro,
    bool limparPsiDianteiro = false,
    int? psiTraseiro,
    bool limparPsiTraseiro = false,
  }) {
    return FichaMoto(
      marca: marca ?? this.marca,
      modelo: modelo ?? this.modelo,
      ano: limparAno ? null : (ano ?? this.ano),
      cilindrada: limparCilindrada ? null : (cilindrada ?? this.cilindrada),
      kmLitro: kmLitro ?? this.kmLitro,
      kmLitroAlcool:
          limparAlcool ? null : (kmLitroAlcool ?? this.kmLitroAlcool),
      combustivel: combustivel ?? this.combustivel,
      kmAtual: kmAtual ?? this.kmAtual,
      tanqueLitros: limparTanque ? null : (tanqueLitros ?? this.tanqueLitros),
      personalizacoes: personalizacoes ?? this.personalizacoes,
      psiDianteiro:
          limparPsiDianteiro ? null : (psiDianteiro ?? this.psiDianteiro),
      psiTraseiro: limparPsiTraseiro ? null : (psiTraseiro ?? this.psiTraseiro),
    );
  }

  /// Valida faixas já persistidas. Marca e modelo vêm de [tentar].
  String? validar({DateTime? agora}) {
    final anoMax = (agora ?? DateTime.now()).year + 1;
    if (ano != null && (ano! < anoMin || ano! > anoMax)) {
      return 'Ano entre $anoMin e $anoMax.';
    }
    if (cilindrada != null && (cilindrada! < 50 || cilindrada! > 2000)) {
      return 'Cilindrada em cc, entre 50 e 2000.';
    }
    if (kmLitro < 5 || kmLitro > 80) {
      return 'Consumo com gasolina entre 5 e 80 km por litro.';
    }
    if (kmLitroAlcool != null &&
        (kmLitroAlcool! < 5 || kmLitroAlcool! > 80)) {
      return 'Consumo com álcool entre 5 e 80 km por litro.';
    }
    if (kmAtual < 0 || kmAtual > 999999) {
      return 'Km no painel agora entre 0 e 999999.';
    }
    if (tanqueLitros != null &&
        (tanqueLitros! < 2 || tanqueLitros! > 40)) {
      return 'Tanque em litros, entre 2 e 40.';
    }
    if (psiDianteiro != null &&
        (psiDianteiro! < 15 || psiDianteiro! > 50)) {
      return 'PSI dianteiro entre 15 e 50.';
    }
    if (psiTraseiro != null && (psiTraseiro! < 15 || psiTraseiro! > 50)) {
      return 'PSI traseiro entre 15 e 50.';
    }
    return null;
  }

  /// Monta a ficha a partir dos campos da tela. O JSON local continua igual.
  static ({FichaMoto? ficha, String? erro}) tentar({
    required String marca,
    required String modelo,
    String ano = '',
    String cilindrada = '',
    required String kmLitro,
    String kmLitroAlcool = '',
    Combustivel combustivel = Combustivel.gasolina,
    required String kmAtual,
    String tanqueLitros = '',
    String personalizacoes = '',
    String psiDianteiro = '',
    String psiTraseiro = '',
    DateTime? agora,
  }) {
    final m = marca.trim();
    final mod = modelo.trim();
    if (m.isEmpty || mod.isEmpty) {
      return (ficha: null, erro: 'Marca e modelo são obrigatórios.');
    }

    final anoMax = (agora ?? DateTime.now()).year + 1;
    final anoT = ano.trim();
    int? anoN;
    if (anoT.isNotEmpty) {
      anoN = int.tryParse(anoT);
      if (anoN == null || anoN < anoMin || anoN > anoMax) {
        return (ficha: null, erro: 'Ano entre $anoMin e $anoMax.');
      }
    }

    final ccT = cilindrada.trim();
    int? ccN;
    if (ccT.isNotEmpty) {
      ccN = int.tryParse(ccT);
      if (ccN == null || ccN < 50 || ccN > 2000) {
        return (ficha: null, erro: 'Cilindrada em cc, entre 50 e 2000.');
      }
    }

    final kmL = _decimal(kmLitro);
    if (kmL == null || kmL < 5 || kmL > 80) {
      return (ficha: null, erro: 'Consumo com gasolina entre 5 e 80 km por litro.');
    }

    final alcoolT = kmLitroAlcool.trim();
    double? alcoolN;
    if (alcoolT.isNotEmpty) {
      alcoolN = _decimal(alcoolT);
      if (alcoolN == null || alcoolN < 5 || alcoolN > 80) {
        return (ficha: null, erro: 'Consumo com álcool entre 5 e 80 km por litro.');
      }
    }

    final km = _decimal(kmAtual);
    if (km == null || km < 0 || km > 999999) {
      return (ficha: null, erro: 'Km no painel agora entre 0 e 999999.');
    }

    final tanqueT = tanqueLitros.trim();
    double? tanqueN;
    if (tanqueT.isNotEmpty) {
      tanqueN = _decimal(tanqueT);
      if (tanqueN == null || tanqueN < 2 || tanqueN > 40) {
        return (ficha: null, erro: 'Tanque em litros, entre 2 e 40.');
      }
    }

    final psiDT = psiDianteiro.trim();
    int? psiD;
    if (psiDT.isNotEmpty) {
      psiD = int.tryParse(psiDT);
      if (psiD == null || psiD < 15 || psiD > 50) {
        return (ficha: null, erro: 'PSI dianteiro entre 15 e 50.');
      }
    }

    final psiTT = psiTraseiro.trim();
    int? psiT;
    if (psiTT.isNotEmpty) {
      psiT = int.tryParse(psiTT);
      if (psiT == null || psiT < 15 || psiT > 50) {
        return (ficha: null, erro: 'PSI traseiro entre 15 e 50.');
      }
    }

    return (
      ficha: FichaMoto(
        marca: m,
        modelo: mod,
        ano: anoN,
        cilindrada: ccN,
        kmLitro: kmL,
        kmLitroAlcool: alcoolN,
        combustivel: combustivel,
        kmAtual: km,
        tanqueLitros: tanqueN,
        personalizacoes: personalizacoes.trim(),
        psiDianteiro: psiD,
        psiTraseiro: psiT,
      ),
      erro: null,
    );
  }

  static double? _decimal(String bruto) =>
      double.tryParse(bruto.trim().replaceAll(',', '.'));

  @override
  bool operator ==(Object other) {
    return other is FichaMoto &&
        other.marca == marca &&
        other.modelo == modelo &&
        other.ano == ano &&
        other.cilindrada == cilindrada &&
        other.kmLitro == kmLitro &&
        other.kmLitroAlcool == kmLitroAlcool &&
        other.combustivel == combustivel &&
        other.kmAtual == kmAtual &&
        other.tanqueLitros == tanqueLitros &&
        other.personalizacoes == personalizacoes &&
        other.psiDianteiro == psiDianteiro &&
        other.psiTraseiro == psiTraseiro;
  }

  @override
  int get hashCode => Object.hash(
        marca,
        modelo,
        ano,
        cilindrada,
        kmLitro,
        kmLitroAlcool,
        combustivel,
        kmAtual,
        tanqueLitros,
        personalizacoes,
        psiDianteiro,
        psiTraseiro,
      );
}
