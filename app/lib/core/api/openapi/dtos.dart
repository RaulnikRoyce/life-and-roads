/// DTOs do contrato OpenAPI (`docs/openapi.yaml`, components.schemas).
/// Sem placa, PSI, foto, pins ou histórico.
library;

class FichaDto {
  const FichaDto({
    required this.marca,
    required this.modelo,
    this.ano,
    this.cilindrada,
    required this.kmLitro,
    this.kmLitroAlcool,
    this.combustivel = 'gasolina',
    required this.kmAtual,
    this.tanqueLitros,
    this.personalizacoes = '',
  });

  static const chaves = [
    'marca',
    'modelo',
    'ano',
    'cilindrada',
    'kmLitro',
    'kmLitroAlcool',
    'combustivel',
    'kmAtual',
    'tanqueLitros',
    'personalizacoes',
  ];

  final String marca;
  final String modelo;
  final int? ano;
  final int? cilindrada;
  final double kmLitro;
  final double? kmLitroAlcool;
  final String combustivel;
  final double kmAtual;
  final double? tanqueLitros;
  final String personalizacoes;

  factory FichaDto.fromJson(Map<String, dynamic> mapa) {
    return FichaDto(
      marca: '${mapa['marca'] ?? ''}',
      modelo: '${mapa['modelo'] ?? ''}',
      ano: _inteiro(mapa['ano']),
      cilindrada: _inteiro(mapa['cilindrada']),
      kmLitro: _numero(mapa['kmLitro']) ?? 0,
      kmLitroAlcool: _numero(mapa['kmLitroAlcool']),
      combustivel: mapa['combustivel'] == 'alcool' ? 'alcool' : 'gasolina',
      kmAtual: _numero(mapa['kmAtual']) ?? 0,
      tanqueLitros: _numero(mapa['tanqueLitros']),
      personalizacoes: '${mapa['personalizacoes'] ?? ''}',
    );
  }

  Map<String, dynamic> toJson() => {
        'marca': marca,
        'modelo': modelo,
        'ano': ano,
        'cilindrada': cilindrada,
        'kmLitro': kmLitro,
        'kmLitroAlcool': kmLitroAlcool,
        'combustivel': combustivel,
        'kmAtual': kmAtual,
        'tanqueLitros': tanqueLitros,
        'personalizacoes': personalizacoes,
      };
}

class ManutencaoDto {
  const ManutencaoDto({
    this.oleoUltima,
    this.oleoProxima,
    this.revisaoUltima,
    this.pneusUltima,
    this.pneusProxima,
    this.ipvaProxima,
    this.seguroProxima,
    this.licenciamentoProxima,
  });

  static const chaves = [
    'oleoUltima',
    'oleoProxima',
    'revisaoUltima',
    'pneusUltima',
    'pneusProxima',
    'ipvaProxima',
    'seguroProxima',
    'licenciamentoProxima',
  ];

  final String? oleoUltima;
  final String? oleoProxima;
  final String? revisaoUltima;
  final String? pneusUltima;
  final String? pneusProxima;
  final String? ipvaProxima;
  final String? seguroProxima;
  final String? licenciamentoProxima;

  factory ManutencaoDto.fromJson(Map<String, dynamic> mapa) {
    return ManutencaoDto(
      oleoUltima: _iso(mapa['oleoUltima']),
      oleoProxima: _iso(mapa['oleoProxima']),
      revisaoUltima: _iso(mapa['revisaoUltima']),
      pneusUltima: _iso(mapa['pneusUltima']),
      pneusProxima: _iso(mapa['pneusProxima']),
      ipvaProxima: _iso(mapa['ipvaProxima']),
      seguroProxima: _iso(mapa['seguroProxima']),
      licenciamentoProxima: _iso(mapa['licenciamentoProxima']),
    );
  }

  Map<String, dynamic> toJson() => {
        'oleoUltima': oleoUltima,
        'oleoProxima': oleoProxima,
        'revisaoUltima': revisaoUltima,
        'pneusUltima': pneusUltima,
        'pneusProxima': pneusProxima,
        'ipvaProxima': ipvaProxima,
        'seguroProxima': seguroProxima,
        'licenciamentoProxima': licenciamentoProxima,
      };
}

class LocalizacaoDto {
  const LocalizacaoDto({required this.latitude, required this.longitude});

  static const chaves = ['latitude', 'longitude'];

  final double latitude;
  final double longitude;

  factory LocalizacaoDto.fromJson(Map<String, dynamic> mapa) {
    return LocalizacaoDto(
      latitude: _numero(mapa['latitude']) ?? 0,
      longitude: _numero(mapa['longitude']) ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
        'latitude': latitude,
        'longitude': longitude,
      };
}

class CredenciaisDto {
  const CredenciaisDto({required this.email, required this.senha});

  static const chaves = ['email', 'senha'];

  final String email;
  final String senha;

  Map<String, dynamic> toJson() => {'email': email, 'senha': senha};
}

class TrocaSenhaDto {
  const TrocaSenhaDto({
    required this.senhaAtual,
    required this.senhaNova,
  });

  static const chaves = ['senhaAtual', 'senhaNova'];

  final String senhaAtual;
  final String senhaNova;

  Map<String, dynamic> toJson() => {
        'senhaAtual': senhaAtual,
        'senhaNova': senhaNova,
      };
}

double? _numero(Object? valor) {
  if (valor == null) return null;
  if (valor is num) return valor.toDouble();
  return double.tryParse('$valor'.trim().replaceAll(',', '.'));
}

int? _inteiro(Object? valor) {
  if (valor == null) return null;
  if (valor is int) return valor;
  if (valor is num) return valor.toInt();
  final t = '$valor'.trim();
  if (t.isEmpty) return null;
  return int.tryParse(t);
}

String? _iso(Object? valor) {
  final t = '${valor ?? ''}'.trim();
  if (t.isEmpty) return null;
  return t;
}
