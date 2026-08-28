// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'caderneta_database.dart';

// ignore_for_file: type=lint
class $AbastecimentosTable extends Abastecimentos
    with TableInfo<$AbastecimentosTable, LinhaAbastecimento> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AbastecimentosTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _emMeta = const VerificationMeta('em');
  @override
  late final GeneratedColumn<String> em = GeneratedColumn<String>(
    'em',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _combustivelMeta = const VerificationMeta(
    'combustivel',
  );
  @override
  late final GeneratedColumn<String> combustivel = GeneratedColumn<String>(
    'combustivel',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _kmPainelMeta = const VerificationMeta(
    'kmPainel',
  );
  @override
  late final GeneratedColumn<double> kmPainel = GeneratedColumn<double>(
    'km_painel',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _kmRodadosMeta = const VerificationMeta(
    'kmRodados',
  );
  @override
  late final GeneratedColumn<double> kmRodados = GeneratedColumn<double>(
    'km_rodados',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _litrosMeta = const VerificationMeta('litros');
  @override
  late final GeneratedColumn<double> litros = GeneratedColumn<double>(
    'litros',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _precoLitroMeta = const VerificationMeta(
    'precoLitro',
  );
  @override
  late final GeneratedColumn<double> precoLitro = GeneratedColumn<double>(
    'preco_litro',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _reaisMeta = const VerificationMeta('reais');
  @override
  late final GeneratedColumn<double> reais = GeneratedColumn<double>(
    'reais',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _kmPorLitroMeta = const VerificationMeta(
    'kmPorLitro',
  );
  @override
  late final GeneratedColumn<double> kmPorLitro = GeneratedColumn<double>(
    'km_por_litro',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _reaisPorKmMeta = const VerificationMeta(
    'reaisPorKm',
  );
  @override
  late final GeneratedColumn<double> reaisPorKm = GeneratedColumn<double>(
    'reais_por_km',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    em,
    combustivel,
    kmPainel,
    kmRodados,
    litros,
    precoLitro,
    reais,
    kmPorLitro,
    reaisPorKm,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'abastecimentos';
  @override
  VerificationContext validateIntegrity(
    Insertable<LinhaAbastecimento> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('em')) {
      context.handle(_emMeta, em.isAcceptableOrUnknown(data['em']!, _emMeta));
    } else if (isInserting) {
      context.missing(_emMeta);
    }
    if (data.containsKey('combustivel')) {
      context.handle(
        _combustivelMeta,
        combustivel.isAcceptableOrUnknown(
          data['combustivel']!,
          _combustivelMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_combustivelMeta);
    }
    if (data.containsKey('km_painel')) {
      context.handle(
        _kmPainelMeta,
        kmPainel.isAcceptableOrUnknown(data['km_painel']!, _kmPainelMeta),
      );
    } else if (isInserting) {
      context.missing(_kmPainelMeta);
    }
    if (data.containsKey('km_rodados')) {
      context.handle(
        _kmRodadosMeta,
        kmRodados.isAcceptableOrUnknown(data['km_rodados']!, _kmRodadosMeta),
      );
    } else if (isInserting) {
      context.missing(_kmRodadosMeta);
    }
    if (data.containsKey('litros')) {
      context.handle(
        _litrosMeta,
        litros.isAcceptableOrUnknown(data['litros']!, _litrosMeta),
      );
    } else if (isInserting) {
      context.missing(_litrosMeta);
    }
    if (data.containsKey('preco_litro')) {
      context.handle(
        _precoLitroMeta,
        precoLitro.isAcceptableOrUnknown(data['preco_litro']!, _precoLitroMeta),
      );
    } else if (isInserting) {
      context.missing(_precoLitroMeta);
    }
    if (data.containsKey('reais')) {
      context.handle(
        _reaisMeta,
        reais.isAcceptableOrUnknown(data['reais']!, _reaisMeta),
      );
    } else if (isInserting) {
      context.missing(_reaisMeta);
    }
    if (data.containsKey('km_por_litro')) {
      context.handle(
        _kmPorLitroMeta,
        kmPorLitro.isAcceptableOrUnknown(
          data['km_por_litro']!,
          _kmPorLitroMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_kmPorLitroMeta);
    }
    if (data.containsKey('reais_por_km')) {
      context.handle(
        _reaisPorKmMeta,
        reaisPorKm.isAcceptableOrUnknown(
          data['reais_por_km']!,
          _reaisPorKmMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_reaisPorKmMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  LinhaAbastecimento map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LinhaAbastecimento(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      em: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}em'],
      )!,
      combustivel: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}combustivel'],
      )!,
      kmPainel: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}km_painel'],
      )!,
      kmRodados: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}km_rodados'],
      )!,
      litros: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}litros'],
      )!,
      precoLitro: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}preco_litro'],
      )!,
      reais: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}reais'],
      )!,
      kmPorLitro: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}km_por_litro'],
      )!,
      reaisPorKm: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}reais_por_km'],
      )!,
    );
  }

  @override
  $AbastecimentosTable createAlias(String alias) {
    return $AbastecimentosTable(attachedDatabase, alias);
  }
}

class LinhaAbastecimento extends DataClass
    implements Insertable<LinhaAbastecimento> {
  final int id;
  final String em;
  final String combustivel;
  final double kmPainel;
  final double kmRodados;
  final double litros;
  final double precoLitro;
  final double reais;
  final double kmPorLitro;
  final double reaisPorKm;
  const LinhaAbastecimento({
    required this.id,
    required this.em,
    required this.combustivel,
    required this.kmPainel,
    required this.kmRodados,
    required this.litros,
    required this.precoLitro,
    required this.reais,
    required this.kmPorLitro,
    required this.reaisPorKm,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['em'] = Variable<String>(em);
    map['combustivel'] = Variable<String>(combustivel);
    map['km_painel'] = Variable<double>(kmPainel);
    map['km_rodados'] = Variable<double>(kmRodados);
    map['litros'] = Variable<double>(litros);
    map['preco_litro'] = Variable<double>(precoLitro);
    map['reais'] = Variable<double>(reais);
    map['km_por_litro'] = Variable<double>(kmPorLitro);
    map['reais_por_km'] = Variable<double>(reaisPorKm);
    return map;
  }

  AbastecimentosCompanion toCompanion(bool nullToAbsent) {
    return AbastecimentosCompanion(
      id: Value(id),
      em: Value(em),
      combustivel: Value(combustivel),
      kmPainel: Value(kmPainel),
      kmRodados: Value(kmRodados),
      litros: Value(litros),
      precoLitro: Value(precoLitro),
      reais: Value(reais),
      kmPorLitro: Value(kmPorLitro),
      reaisPorKm: Value(reaisPorKm),
    );
  }

  factory LinhaAbastecimento.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LinhaAbastecimento(
      id: serializer.fromJson<int>(json['id']),
      em: serializer.fromJson<String>(json['em']),
      combustivel: serializer.fromJson<String>(json['combustivel']),
      kmPainel: serializer.fromJson<double>(json['kmPainel']),
      kmRodados: serializer.fromJson<double>(json['kmRodados']),
      litros: serializer.fromJson<double>(json['litros']),
      precoLitro: serializer.fromJson<double>(json['precoLitro']),
      reais: serializer.fromJson<double>(json['reais']),
      kmPorLitro: serializer.fromJson<double>(json['kmPorLitro']),
      reaisPorKm: serializer.fromJson<double>(json['reaisPorKm']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'em': serializer.toJson<String>(em),
      'combustivel': serializer.toJson<String>(combustivel),
      'kmPainel': serializer.toJson<double>(kmPainel),
      'kmRodados': serializer.toJson<double>(kmRodados),
      'litros': serializer.toJson<double>(litros),
      'precoLitro': serializer.toJson<double>(precoLitro),
      'reais': serializer.toJson<double>(reais),
      'kmPorLitro': serializer.toJson<double>(kmPorLitro),
      'reaisPorKm': serializer.toJson<double>(reaisPorKm),
    };
  }

  LinhaAbastecimento copyWith({
    int? id,
    String? em,
    String? combustivel,
    double? kmPainel,
    double? kmRodados,
    double? litros,
    double? precoLitro,
    double? reais,
    double? kmPorLitro,
    double? reaisPorKm,
  }) => LinhaAbastecimento(
    id: id ?? this.id,
    em: em ?? this.em,
    combustivel: combustivel ?? this.combustivel,
    kmPainel: kmPainel ?? this.kmPainel,
    kmRodados: kmRodados ?? this.kmRodados,
    litros: litros ?? this.litros,
    precoLitro: precoLitro ?? this.precoLitro,
    reais: reais ?? this.reais,
    kmPorLitro: kmPorLitro ?? this.kmPorLitro,
    reaisPorKm: reaisPorKm ?? this.reaisPorKm,
  );
  LinhaAbastecimento copyWithCompanion(AbastecimentosCompanion data) {
    return LinhaAbastecimento(
      id: data.id.present ? data.id.value : this.id,
      em: data.em.present ? data.em.value : this.em,
      combustivel: data.combustivel.present
          ? data.combustivel.value
          : this.combustivel,
      kmPainel: data.kmPainel.present ? data.kmPainel.value : this.kmPainel,
      kmRodados: data.kmRodados.present ? data.kmRodados.value : this.kmRodados,
      litros: data.litros.present ? data.litros.value : this.litros,
      precoLitro: data.precoLitro.present
          ? data.precoLitro.value
          : this.precoLitro,
      reais: data.reais.present ? data.reais.value : this.reais,
      kmPorLitro: data.kmPorLitro.present
          ? data.kmPorLitro.value
          : this.kmPorLitro,
      reaisPorKm: data.reaisPorKm.present
          ? data.reaisPorKm.value
          : this.reaisPorKm,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LinhaAbastecimento(')
          ..write('id: $id, ')
          ..write('em: $em, ')
          ..write('combustivel: $combustivel, ')
          ..write('kmPainel: $kmPainel, ')
          ..write('kmRodados: $kmRodados, ')
          ..write('litros: $litros, ')
          ..write('precoLitro: $precoLitro, ')
          ..write('reais: $reais, ')
          ..write('kmPorLitro: $kmPorLitro, ')
          ..write('reaisPorKm: $reaisPorKm')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    em,
    combustivel,
    kmPainel,
    kmRodados,
    litros,
    precoLitro,
    reais,
    kmPorLitro,
    reaisPorKm,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LinhaAbastecimento &&
          other.id == this.id &&
          other.em == this.em &&
          other.combustivel == this.combustivel &&
          other.kmPainel == this.kmPainel &&
          other.kmRodados == this.kmRodados &&
          other.litros == this.litros &&
          other.precoLitro == this.precoLitro &&
          other.reais == this.reais &&
          other.kmPorLitro == this.kmPorLitro &&
          other.reaisPorKm == this.reaisPorKm);
}

class AbastecimentosCompanion extends UpdateCompanion<LinhaAbastecimento> {
  final Value<int> id;
  final Value<String> em;
  final Value<String> combustivel;
  final Value<double> kmPainel;
  final Value<double> kmRodados;
  final Value<double> litros;
  final Value<double> precoLitro;
  final Value<double> reais;
  final Value<double> kmPorLitro;
  final Value<double> reaisPorKm;
  const AbastecimentosCompanion({
    this.id = const Value.absent(),
    this.em = const Value.absent(),
    this.combustivel = const Value.absent(),
    this.kmPainel = const Value.absent(),
    this.kmRodados = const Value.absent(),
    this.litros = const Value.absent(),
    this.precoLitro = const Value.absent(),
    this.reais = const Value.absent(),
    this.kmPorLitro = const Value.absent(),
    this.reaisPorKm = const Value.absent(),
  });
  AbastecimentosCompanion.insert({
    this.id = const Value.absent(),
    required String em,
    required String combustivel,
    required double kmPainel,
    required double kmRodados,
    required double litros,
    required double precoLitro,
    required double reais,
    required double kmPorLitro,
    required double reaisPorKm,
  }) : em = Value(em),
       combustivel = Value(combustivel),
       kmPainel = Value(kmPainel),
       kmRodados = Value(kmRodados),
       litros = Value(litros),
       precoLitro = Value(precoLitro),
       reais = Value(reais),
       kmPorLitro = Value(kmPorLitro),
       reaisPorKm = Value(reaisPorKm);
  static Insertable<LinhaAbastecimento> custom({
    Expression<int>? id,
    Expression<String>? em,
    Expression<String>? combustivel,
    Expression<double>? kmPainel,
    Expression<double>? kmRodados,
    Expression<double>? litros,
    Expression<double>? precoLitro,
    Expression<double>? reais,
    Expression<double>? kmPorLitro,
    Expression<double>? reaisPorKm,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (em != null) 'em': em,
      if (combustivel != null) 'combustivel': combustivel,
      if (kmPainel != null) 'km_painel': kmPainel,
      if (kmRodados != null) 'km_rodados': kmRodados,
      if (litros != null) 'litros': litros,
      if (precoLitro != null) 'preco_litro': precoLitro,
      if (reais != null) 'reais': reais,
      if (kmPorLitro != null) 'km_por_litro': kmPorLitro,
      if (reaisPorKm != null) 'reais_por_km': reaisPorKm,
    });
  }

  AbastecimentosCompanion copyWith({
    Value<int>? id,
    Value<String>? em,
    Value<String>? combustivel,
    Value<double>? kmPainel,
    Value<double>? kmRodados,
    Value<double>? litros,
    Value<double>? precoLitro,
    Value<double>? reais,
    Value<double>? kmPorLitro,
    Value<double>? reaisPorKm,
  }) {
    return AbastecimentosCompanion(
      id: id ?? this.id,
      em: em ?? this.em,
      combustivel: combustivel ?? this.combustivel,
      kmPainel: kmPainel ?? this.kmPainel,
      kmRodados: kmRodados ?? this.kmRodados,
      litros: litros ?? this.litros,
      precoLitro: precoLitro ?? this.precoLitro,
      reais: reais ?? this.reais,
      kmPorLitro: kmPorLitro ?? this.kmPorLitro,
      reaisPorKm: reaisPorKm ?? this.reaisPorKm,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (em.present) {
      map['em'] = Variable<String>(em.value);
    }
    if (combustivel.present) {
      map['combustivel'] = Variable<String>(combustivel.value);
    }
    if (kmPainel.present) {
      map['km_painel'] = Variable<double>(kmPainel.value);
    }
    if (kmRodados.present) {
      map['km_rodados'] = Variable<double>(kmRodados.value);
    }
    if (litros.present) {
      map['litros'] = Variable<double>(litros.value);
    }
    if (precoLitro.present) {
      map['preco_litro'] = Variable<double>(precoLitro.value);
    }
    if (reais.present) {
      map['reais'] = Variable<double>(reais.value);
    }
    if (kmPorLitro.present) {
      map['km_por_litro'] = Variable<double>(kmPorLitro.value);
    }
    if (reaisPorKm.present) {
      map['reais_por_km'] = Variable<double>(reaisPorKm.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AbastecimentosCompanion(')
          ..write('id: $id, ')
          ..write('em: $em, ')
          ..write('combustivel: $combustivel, ')
          ..write('kmPainel: $kmPainel, ')
          ..write('kmRodados: $kmRodados, ')
          ..write('litros: $litros, ')
          ..write('precoLitro: $precoLitro, ')
          ..write('reais: $reais, ')
          ..write('kmPorLitro: $kmPorLitro, ')
          ..write('reaisPorKm: $reaisPorKm')
          ..write(')'))
        .toString();
  }
}

class $ServicosTable extends Servicos
    with TableInfo<$ServicosTable, LinhaServico> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ServicosTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _emMeta = const VerificationMeta('em');
  @override
  late final GeneratedColumn<String> em = GeneratedColumn<String>(
    'em',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _tipoMeta = const VerificationMeta('tipo');
  @override
  late final GeneratedColumn<String> tipo = GeneratedColumn<String>(
    'tipo',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _kmPainelMeta = const VerificationMeta(
    'kmPainel',
  );
  @override
  late final GeneratedColumn<double> kmPainel = GeneratedColumn<double>(
    'km_painel',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _reaisMeta = const VerificationMeta('reais');
  @override
  late final GeneratedColumn<double> reais = GeneratedColumn<double>(
    'reais',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [id, em, tipo, kmPainel, reais];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'servicos';
  @override
  VerificationContext validateIntegrity(
    Insertable<LinhaServico> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('em')) {
      context.handle(_emMeta, em.isAcceptableOrUnknown(data['em']!, _emMeta));
    } else if (isInserting) {
      context.missing(_emMeta);
    }
    if (data.containsKey('tipo')) {
      context.handle(
        _tipoMeta,
        tipo.isAcceptableOrUnknown(data['tipo']!, _tipoMeta),
      );
    } else if (isInserting) {
      context.missing(_tipoMeta);
    }
    if (data.containsKey('km_painel')) {
      context.handle(
        _kmPainelMeta,
        kmPainel.isAcceptableOrUnknown(data['km_painel']!, _kmPainelMeta),
      );
    } else if (isInserting) {
      context.missing(_kmPainelMeta);
    }
    if (data.containsKey('reais')) {
      context.handle(
        _reaisMeta,
        reais.isAcceptableOrUnknown(data['reais']!, _reaisMeta),
      );
    } else if (isInserting) {
      context.missing(_reaisMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  LinhaServico map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LinhaServico(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      em: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}em'],
      )!,
      tipo: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}tipo'],
      )!,
      kmPainel: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}km_painel'],
      )!,
      reais: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}reais'],
      )!,
    );
  }

  @override
  $ServicosTable createAlias(String alias) {
    return $ServicosTable(attachedDatabase, alias);
  }
}

class LinhaServico extends DataClass implements Insertable<LinhaServico> {
  final int id;
  final String em;
  final String tipo;
  final double kmPainel;
  final double reais;
  const LinhaServico({
    required this.id,
    required this.em,
    required this.tipo,
    required this.kmPainel,
    required this.reais,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['em'] = Variable<String>(em);
    map['tipo'] = Variable<String>(tipo);
    map['km_painel'] = Variable<double>(kmPainel);
    map['reais'] = Variable<double>(reais);
    return map;
  }

  ServicosCompanion toCompanion(bool nullToAbsent) {
    return ServicosCompanion(
      id: Value(id),
      em: Value(em),
      tipo: Value(tipo),
      kmPainel: Value(kmPainel),
      reais: Value(reais),
    );
  }

  factory LinhaServico.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LinhaServico(
      id: serializer.fromJson<int>(json['id']),
      em: serializer.fromJson<String>(json['em']),
      tipo: serializer.fromJson<String>(json['tipo']),
      kmPainel: serializer.fromJson<double>(json['kmPainel']),
      reais: serializer.fromJson<double>(json['reais']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'em': serializer.toJson<String>(em),
      'tipo': serializer.toJson<String>(tipo),
      'kmPainel': serializer.toJson<double>(kmPainel),
      'reais': serializer.toJson<double>(reais),
    };
  }

  LinhaServico copyWith({
    int? id,
    String? em,
    String? tipo,
    double? kmPainel,
    double? reais,
  }) => LinhaServico(
    id: id ?? this.id,
    em: em ?? this.em,
    tipo: tipo ?? this.tipo,
    kmPainel: kmPainel ?? this.kmPainel,
    reais: reais ?? this.reais,
  );
  LinhaServico copyWithCompanion(ServicosCompanion data) {
    return LinhaServico(
      id: data.id.present ? data.id.value : this.id,
      em: data.em.present ? data.em.value : this.em,
      tipo: data.tipo.present ? data.tipo.value : this.tipo,
      kmPainel: data.kmPainel.present ? data.kmPainel.value : this.kmPainel,
      reais: data.reais.present ? data.reais.value : this.reais,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LinhaServico(')
          ..write('id: $id, ')
          ..write('em: $em, ')
          ..write('tipo: $tipo, ')
          ..write('kmPainel: $kmPainel, ')
          ..write('reais: $reais')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, em, tipo, kmPainel, reais);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LinhaServico &&
          other.id == this.id &&
          other.em == this.em &&
          other.tipo == this.tipo &&
          other.kmPainel == this.kmPainel &&
          other.reais == this.reais);
}

class ServicosCompanion extends UpdateCompanion<LinhaServico> {
  final Value<int> id;
  final Value<String> em;
  final Value<String> tipo;
  final Value<double> kmPainel;
  final Value<double> reais;
  const ServicosCompanion({
    this.id = const Value.absent(),
    this.em = const Value.absent(),
    this.tipo = const Value.absent(),
    this.kmPainel = const Value.absent(),
    this.reais = const Value.absent(),
  });
  ServicosCompanion.insert({
    this.id = const Value.absent(),
    required String em,
    required String tipo,
    required double kmPainel,
    required double reais,
  }) : em = Value(em),
       tipo = Value(tipo),
       kmPainel = Value(kmPainel),
       reais = Value(reais);
  static Insertable<LinhaServico> custom({
    Expression<int>? id,
    Expression<String>? em,
    Expression<String>? tipo,
    Expression<double>? kmPainel,
    Expression<double>? reais,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (em != null) 'em': em,
      if (tipo != null) 'tipo': tipo,
      if (kmPainel != null) 'km_painel': kmPainel,
      if (reais != null) 'reais': reais,
    });
  }

  ServicosCompanion copyWith({
    Value<int>? id,
    Value<String>? em,
    Value<String>? tipo,
    Value<double>? kmPainel,
    Value<double>? reais,
  }) {
    return ServicosCompanion(
      id: id ?? this.id,
      em: em ?? this.em,
      tipo: tipo ?? this.tipo,
      kmPainel: kmPainel ?? this.kmPainel,
      reais: reais ?? this.reais,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (em.present) {
      map['em'] = Variable<String>(em.value);
    }
    if (tipo.present) {
      map['tipo'] = Variable<String>(tipo.value);
    }
    if (kmPainel.present) {
      map['km_painel'] = Variable<double>(kmPainel.value);
    }
    if (reais.present) {
      map['reais'] = Variable<double>(reais.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ServicosCompanion(')
          ..write('id: $id, ')
          ..write('em: $em, ')
          ..write('tipo: $tipo, ')
          ..write('kmPainel: $kmPainel, ')
          ..write('reais: $reais')
          ..write(')'))
        .toString();
  }
}

class $PinsTable extends Pins with TableInfo<$PinsTable, LinhaPin> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PinsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _tipoMeta = const VerificationMeta('tipo');
  @override
  late final GeneratedColumn<String> tipo = GeneratedColumn<String>(
    'tipo',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _latitudeMeta = const VerificationMeta(
    'latitude',
  );
  @override
  late final GeneratedColumn<double> latitude = GeneratedColumn<double>(
    'latitude',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _longitudeMeta = const VerificationMeta(
    'longitude',
  );
  @override
  late final GeneratedColumn<double> longitude = GeneratedColumn<double>(
    'longitude',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [id, tipo, latitude, longitude];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'pins';
  @override
  VerificationContext validateIntegrity(
    Insertable<LinhaPin> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('tipo')) {
      context.handle(
        _tipoMeta,
        tipo.isAcceptableOrUnknown(data['tipo']!, _tipoMeta),
      );
    } else if (isInserting) {
      context.missing(_tipoMeta);
    }
    if (data.containsKey('latitude')) {
      context.handle(
        _latitudeMeta,
        latitude.isAcceptableOrUnknown(data['latitude']!, _latitudeMeta),
      );
    } else if (isInserting) {
      context.missing(_latitudeMeta);
    }
    if (data.containsKey('longitude')) {
      context.handle(
        _longitudeMeta,
        longitude.isAcceptableOrUnknown(data['longitude']!, _longitudeMeta),
      );
    } else if (isInserting) {
      context.missing(_longitudeMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  LinhaPin map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LinhaPin(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      tipo: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}tipo'],
      )!,
      latitude: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}latitude'],
      )!,
      longitude: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}longitude'],
      )!,
    );
  }

  @override
  $PinsTable createAlias(String alias) {
    return $PinsTable(attachedDatabase, alias);
  }
}

class LinhaPin extends DataClass implements Insertable<LinhaPin> {
  final int id;
  final String tipo;
  final double latitude;
  final double longitude;
  const LinhaPin({
    required this.id,
    required this.tipo,
    required this.latitude,
    required this.longitude,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['tipo'] = Variable<String>(tipo);
    map['latitude'] = Variable<double>(latitude);
    map['longitude'] = Variable<double>(longitude);
    return map;
  }

  PinsCompanion toCompanion(bool nullToAbsent) {
    return PinsCompanion(
      id: Value(id),
      tipo: Value(tipo),
      latitude: Value(latitude),
      longitude: Value(longitude),
    );
  }

  factory LinhaPin.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LinhaPin(
      id: serializer.fromJson<int>(json['id']),
      tipo: serializer.fromJson<String>(json['tipo']),
      latitude: serializer.fromJson<double>(json['latitude']),
      longitude: serializer.fromJson<double>(json['longitude']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'tipo': serializer.toJson<String>(tipo),
      'latitude': serializer.toJson<double>(latitude),
      'longitude': serializer.toJson<double>(longitude),
    };
  }

  LinhaPin copyWith({
    int? id,
    String? tipo,
    double? latitude,
    double? longitude,
  }) => LinhaPin(
    id: id ?? this.id,
    tipo: tipo ?? this.tipo,
    latitude: latitude ?? this.latitude,
    longitude: longitude ?? this.longitude,
  );
  LinhaPin copyWithCompanion(PinsCompanion data) {
    return LinhaPin(
      id: data.id.present ? data.id.value : this.id,
      tipo: data.tipo.present ? data.tipo.value : this.tipo,
      latitude: data.latitude.present ? data.latitude.value : this.latitude,
      longitude: data.longitude.present ? data.longitude.value : this.longitude,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LinhaPin(')
          ..write('id: $id, ')
          ..write('tipo: $tipo, ')
          ..write('latitude: $latitude, ')
          ..write('longitude: $longitude')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, tipo, latitude, longitude);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LinhaPin &&
          other.id == this.id &&
          other.tipo == this.tipo &&
          other.latitude == this.latitude &&
          other.longitude == this.longitude);
}

class PinsCompanion extends UpdateCompanion<LinhaPin> {
  final Value<int> id;
  final Value<String> tipo;
  final Value<double> latitude;
  final Value<double> longitude;
  const PinsCompanion({
    this.id = const Value.absent(),
    this.tipo = const Value.absent(),
    this.latitude = const Value.absent(),
    this.longitude = const Value.absent(),
  });
  PinsCompanion.insert({
    this.id = const Value.absent(),
    required String tipo,
    required double latitude,
    required double longitude,
  }) : tipo = Value(tipo),
       latitude = Value(latitude),
       longitude = Value(longitude);
  static Insertable<LinhaPin> custom({
    Expression<int>? id,
    Expression<String>? tipo,
    Expression<double>? latitude,
    Expression<double>? longitude,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (tipo != null) 'tipo': tipo,
      if (latitude != null) 'latitude': latitude,
      if (longitude != null) 'longitude': longitude,
    });
  }

  PinsCompanion copyWith({
    Value<int>? id,
    Value<String>? tipo,
    Value<double>? latitude,
    Value<double>? longitude,
  }) {
    return PinsCompanion(
      id: id ?? this.id,
      tipo: tipo ?? this.tipo,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (tipo.present) {
      map['tipo'] = Variable<String>(tipo.value);
    }
    if (latitude.present) {
      map['latitude'] = Variable<double>(latitude.value);
    }
    if (longitude.present) {
      map['longitude'] = Variable<double>(longitude.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PinsCompanion(')
          ..write('id: $id, ')
          ..write('tipo: $tipo, ')
          ..write('latitude: $latitude, ')
          ..write('longitude: $longitude')
          ..write(')'))
        .toString();
  }
}

class $FichaSyncTable extends FichaSync
    with TableInfo<$FichaSyncTable, LinhaFichaSync> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $FichaSyncTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _localUpdatedAtMeta = const VerificationMeta(
    'localUpdatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> localUpdatedAt =
      GeneratedColumn<DateTime>(
        'local_updated_at',
        aliasedName,
        false,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: true,
      );
  static const VerificationMeta _remoteUpdatedAtMeta = const VerificationMeta(
    'remoteUpdatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> remoteUpdatedAt =
      GeneratedColumn<DateTime>(
        'remote_updated_at',
        aliasedName,
        true,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _lastSyncErrorMeta = const VerificationMeta(
    'lastSyncError',
  );
  @override
  late final GeneratedColumn<String> lastSyncError = GeneratedColumn<String>(
    'last_sync_error',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _tentativasMeta = const VerificationMeta(
    'tentativas',
  );
  @override
  late final GeneratedColumn<int> tentativas = GeneratedColumn<int>(
    'tentativas',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    status,
    localUpdatedAt,
    remoteUpdatedAt,
    lastSyncError,
    tentativas,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'ficha_sync';
  @override
  VerificationContext validateIntegrity(
    Insertable<LinhaFichaSync> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    } else if (isInserting) {
      context.missing(_statusMeta);
    }
    if (data.containsKey('local_updated_at')) {
      context.handle(
        _localUpdatedAtMeta,
        localUpdatedAt.isAcceptableOrUnknown(
          data['local_updated_at']!,
          _localUpdatedAtMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_localUpdatedAtMeta);
    }
    if (data.containsKey('remote_updated_at')) {
      context.handle(
        _remoteUpdatedAtMeta,
        remoteUpdatedAt.isAcceptableOrUnknown(
          data['remote_updated_at']!,
          _remoteUpdatedAtMeta,
        ),
      );
    }
    if (data.containsKey('last_sync_error')) {
      context.handle(
        _lastSyncErrorMeta,
        lastSyncError.isAcceptableOrUnknown(
          data['last_sync_error']!,
          _lastSyncErrorMeta,
        ),
      );
    }
    if (data.containsKey('tentativas')) {
      context.handle(
        _tentativasMeta,
        tentativas.isAcceptableOrUnknown(data['tentativas']!, _tentativasMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  LinhaFichaSync map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LinhaFichaSync(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
      localUpdatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}local_updated_at'],
      )!,
      remoteUpdatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}remote_updated_at'],
      ),
      lastSyncError: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}last_sync_error'],
      ),
      tentativas: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}tentativas'],
      )!,
    );
  }

  @override
  $FichaSyncTable createAlias(String alias) {
    return $FichaSyncTable(attachedDatabase, alias);
  }
}

class LinhaFichaSync extends DataClass implements Insertable<LinhaFichaSync> {
  final int id;
  final String status;
  final DateTime localUpdatedAt;
  final DateTime? remoteUpdatedAt;
  final String? lastSyncError;
  final int tentativas;
  const LinhaFichaSync({
    required this.id,
    required this.status,
    required this.localUpdatedAt,
    this.remoteUpdatedAt,
    this.lastSyncError,
    required this.tentativas,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['status'] = Variable<String>(status);
    map['local_updated_at'] = Variable<DateTime>(localUpdatedAt);
    if (!nullToAbsent || remoteUpdatedAt != null) {
      map['remote_updated_at'] = Variable<DateTime>(remoteUpdatedAt);
    }
    if (!nullToAbsent || lastSyncError != null) {
      map['last_sync_error'] = Variable<String>(lastSyncError);
    }
    map['tentativas'] = Variable<int>(tentativas);
    return map;
  }

  FichaSyncCompanion toCompanion(bool nullToAbsent) {
    return FichaSyncCompanion(
      id: Value(id),
      status: Value(status),
      localUpdatedAt: Value(localUpdatedAt),
      remoteUpdatedAt: remoteUpdatedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(remoteUpdatedAt),
      lastSyncError: lastSyncError == null && nullToAbsent
          ? const Value.absent()
          : Value(lastSyncError),
      tentativas: Value(tentativas),
    );
  }

  factory LinhaFichaSync.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LinhaFichaSync(
      id: serializer.fromJson<int>(json['id']),
      status: serializer.fromJson<String>(json['status']),
      localUpdatedAt: serializer.fromJson<DateTime>(json['localUpdatedAt']),
      remoteUpdatedAt: serializer.fromJson<DateTime?>(json['remoteUpdatedAt']),
      lastSyncError: serializer.fromJson<String?>(json['lastSyncError']),
      tentativas: serializer.fromJson<int>(json['tentativas']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'status': serializer.toJson<String>(status),
      'localUpdatedAt': serializer.toJson<DateTime>(localUpdatedAt),
      'remoteUpdatedAt': serializer.toJson<DateTime?>(remoteUpdatedAt),
      'lastSyncError': serializer.toJson<String?>(lastSyncError),
      'tentativas': serializer.toJson<int>(tentativas),
    };
  }

  LinhaFichaSync copyWith({
    int? id,
    String? status,
    DateTime? localUpdatedAt,
    Value<DateTime?> remoteUpdatedAt = const Value.absent(),
    Value<String?> lastSyncError = const Value.absent(),
    int? tentativas,
  }) => LinhaFichaSync(
    id: id ?? this.id,
    status: status ?? this.status,
    localUpdatedAt: localUpdatedAt ?? this.localUpdatedAt,
    remoteUpdatedAt: remoteUpdatedAt.present
        ? remoteUpdatedAt.value
        : this.remoteUpdatedAt,
    lastSyncError: lastSyncError.present
        ? lastSyncError.value
        : this.lastSyncError,
    tentativas: tentativas ?? this.tentativas,
  );
  LinhaFichaSync copyWithCompanion(FichaSyncCompanion data) {
    return LinhaFichaSync(
      id: data.id.present ? data.id.value : this.id,
      status: data.status.present ? data.status.value : this.status,
      localUpdatedAt: data.localUpdatedAt.present
          ? data.localUpdatedAt.value
          : this.localUpdatedAt,
      remoteUpdatedAt: data.remoteUpdatedAt.present
          ? data.remoteUpdatedAt.value
          : this.remoteUpdatedAt,
      lastSyncError: data.lastSyncError.present
          ? data.lastSyncError.value
          : this.lastSyncError,
      tentativas: data.tentativas.present
          ? data.tentativas.value
          : this.tentativas,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LinhaFichaSync(')
          ..write('id: $id, ')
          ..write('status: $status, ')
          ..write('localUpdatedAt: $localUpdatedAt, ')
          ..write('remoteUpdatedAt: $remoteUpdatedAt, ')
          ..write('lastSyncError: $lastSyncError, ')
          ..write('tentativas: $tentativas')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    status,
    localUpdatedAt,
    remoteUpdatedAt,
    lastSyncError,
    tentativas,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LinhaFichaSync &&
          other.id == this.id &&
          other.status == this.status &&
          other.localUpdatedAt == this.localUpdatedAt &&
          other.remoteUpdatedAt == this.remoteUpdatedAt &&
          other.lastSyncError == this.lastSyncError &&
          other.tentativas == this.tentativas);
}

class FichaSyncCompanion extends UpdateCompanion<LinhaFichaSync> {
  final Value<int> id;
  final Value<String> status;
  final Value<DateTime> localUpdatedAt;
  final Value<DateTime?> remoteUpdatedAt;
  final Value<String?> lastSyncError;
  final Value<int> tentativas;
  const FichaSyncCompanion({
    this.id = const Value.absent(),
    this.status = const Value.absent(),
    this.localUpdatedAt = const Value.absent(),
    this.remoteUpdatedAt = const Value.absent(),
    this.lastSyncError = const Value.absent(),
    this.tentativas = const Value.absent(),
  });
  FichaSyncCompanion.insert({
    this.id = const Value.absent(),
    required String status,
    required DateTime localUpdatedAt,
    this.remoteUpdatedAt = const Value.absent(),
    this.lastSyncError = const Value.absent(),
    this.tentativas = const Value.absent(),
  }) : status = Value(status),
       localUpdatedAt = Value(localUpdatedAt);
  static Insertable<LinhaFichaSync> custom({
    Expression<int>? id,
    Expression<String>? status,
    Expression<DateTime>? localUpdatedAt,
    Expression<DateTime>? remoteUpdatedAt,
    Expression<String>? lastSyncError,
    Expression<int>? tentativas,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (status != null) 'status': status,
      if (localUpdatedAt != null) 'local_updated_at': localUpdatedAt,
      if (remoteUpdatedAt != null) 'remote_updated_at': remoteUpdatedAt,
      if (lastSyncError != null) 'last_sync_error': lastSyncError,
      if (tentativas != null) 'tentativas': tentativas,
    });
  }

  FichaSyncCompanion copyWith({
    Value<int>? id,
    Value<String>? status,
    Value<DateTime>? localUpdatedAt,
    Value<DateTime?>? remoteUpdatedAt,
    Value<String?>? lastSyncError,
    Value<int>? tentativas,
  }) {
    return FichaSyncCompanion(
      id: id ?? this.id,
      status: status ?? this.status,
      localUpdatedAt: localUpdatedAt ?? this.localUpdatedAt,
      remoteUpdatedAt: remoteUpdatedAt ?? this.remoteUpdatedAt,
      lastSyncError: lastSyncError ?? this.lastSyncError,
      tentativas: tentativas ?? this.tentativas,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (localUpdatedAt.present) {
      map['local_updated_at'] = Variable<DateTime>(localUpdatedAt.value);
    }
    if (remoteUpdatedAt.present) {
      map['remote_updated_at'] = Variable<DateTime>(remoteUpdatedAt.value);
    }
    if (lastSyncError.present) {
      map['last_sync_error'] = Variable<String>(lastSyncError.value);
    }
    if (tentativas.present) {
      map['tentativas'] = Variable<int>(tentativas.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('FichaSyncCompanion(')
          ..write('id: $id, ')
          ..write('status: $status, ')
          ..write('localUpdatedAt: $localUpdatedAt, ')
          ..write('remoteUpdatedAt: $remoteUpdatedAt, ')
          ..write('lastSyncError: $lastSyncError, ')
          ..write('tentativas: $tentativas')
          ..write(')'))
        .toString();
  }
}

class $CadernetaKvTable extends CadernetaKv
    with TableInfo<$CadernetaKvTable, LinhaKv> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CadernetaKvTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _chaveMeta = const VerificationMeta('chave');
  @override
  late final GeneratedColumn<String> chave = GeneratedColumn<String>(
    'chave',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _textoMeta = const VerificationMeta('texto');
  @override
  late final GeneratedColumn<String> texto = GeneratedColumn<String>(
    'texto',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _bytesMeta = const VerificationMeta('bytes');
  @override
  late final GeneratedColumn<Uint8List> bytes = GeneratedColumn<Uint8List>(
    'bytes',
    aliasedName,
    true,
    type: DriftSqlType.blob,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [chave, texto, bytes];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'caderneta_kv';
  @override
  VerificationContext validateIntegrity(
    Insertable<LinhaKv> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('chave')) {
      context.handle(
        _chaveMeta,
        chave.isAcceptableOrUnknown(data['chave']!, _chaveMeta),
      );
    } else if (isInserting) {
      context.missing(_chaveMeta);
    }
    if (data.containsKey('texto')) {
      context.handle(
        _textoMeta,
        texto.isAcceptableOrUnknown(data['texto']!, _textoMeta),
      );
    }
    if (data.containsKey('bytes')) {
      context.handle(
        _bytesMeta,
        bytes.isAcceptableOrUnknown(data['bytes']!, _bytesMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {chave};
  @override
  LinhaKv map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LinhaKv(
      chave: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}chave'],
      )!,
      texto: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}texto'],
      ),
      bytes: attachedDatabase.typeMapping.read(
        DriftSqlType.blob,
        data['${effectivePrefix}bytes'],
      ),
    );
  }

  @override
  $CadernetaKvTable createAlias(String alias) {
    return $CadernetaKvTable(attachedDatabase, alias);
  }
}

class LinhaKv extends DataClass implements Insertable<LinhaKv> {
  final String chave;
  final String? texto;
  final Uint8List? bytes;
  const LinhaKv({required this.chave, this.texto, this.bytes});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['chave'] = Variable<String>(chave);
    if (!nullToAbsent || texto != null) {
      map['texto'] = Variable<String>(texto);
    }
    if (!nullToAbsent || bytes != null) {
      map['bytes'] = Variable<Uint8List>(bytes);
    }
    return map;
  }

  CadernetaKvCompanion toCompanion(bool nullToAbsent) {
    return CadernetaKvCompanion(
      chave: Value(chave),
      texto: texto == null && nullToAbsent
          ? const Value.absent()
          : Value(texto),
      bytes: bytes == null && nullToAbsent
          ? const Value.absent()
          : Value(bytes),
    );
  }

  factory LinhaKv.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LinhaKv(
      chave: serializer.fromJson<String>(json['chave']),
      texto: serializer.fromJson<String?>(json['texto']),
      bytes: serializer.fromJson<Uint8List?>(json['bytes']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'chave': serializer.toJson<String>(chave),
      'texto': serializer.toJson<String?>(texto),
      'bytes': serializer.toJson<Uint8List?>(bytes),
    };
  }

  LinhaKv copyWith({
    String? chave,
    Value<String?> texto = const Value.absent(),
    Value<Uint8List?> bytes = const Value.absent(),
  }) => LinhaKv(
    chave: chave ?? this.chave,
    texto: texto.present ? texto.value : this.texto,
    bytes: bytes.present ? bytes.value : this.bytes,
  );
  LinhaKv copyWithCompanion(CadernetaKvCompanion data) {
    return LinhaKv(
      chave: data.chave.present ? data.chave.value : this.chave,
      texto: data.texto.present ? data.texto.value : this.texto,
      bytes: data.bytes.present ? data.bytes.value : this.bytes,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LinhaKv(')
          ..write('chave: $chave, ')
          ..write('texto: $texto, ')
          ..write('bytes: $bytes')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(chave, texto, $driftBlobEquality.hash(bytes));
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LinhaKv &&
          other.chave == this.chave &&
          other.texto == this.texto &&
          $driftBlobEquality.equals(other.bytes, this.bytes));
}

class CadernetaKvCompanion extends UpdateCompanion<LinhaKv> {
  final Value<String> chave;
  final Value<String?> texto;
  final Value<Uint8List?> bytes;
  final Value<int> rowid;
  const CadernetaKvCompanion({
    this.chave = const Value.absent(),
    this.texto = const Value.absent(),
    this.bytes = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CadernetaKvCompanion.insert({
    required String chave,
    this.texto = const Value.absent(),
    this.bytes = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : chave = Value(chave);
  static Insertable<LinhaKv> custom({
    Expression<String>? chave,
    Expression<String>? texto,
    Expression<Uint8List>? bytes,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (chave != null) 'chave': chave,
      if (texto != null) 'texto': texto,
      if (bytes != null) 'bytes': bytes,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CadernetaKvCompanion copyWith({
    Value<String>? chave,
    Value<String?>? texto,
    Value<Uint8List?>? bytes,
    Value<int>? rowid,
  }) {
    return CadernetaKvCompanion(
      chave: chave ?? this.chave,
      texto: texto ?? this.texto,
      bytes: bytes ?? this.bytes,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (chave.present) {
      map['chave'] = Variable<String>(chave.value);
    }
    if (texto.present) {
      map['texto'] = Variable<String>(texto.value);
    }
    if (bytes.present) {
      map['bytes'] = Variable<Uint8List>(bytes.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CadernetaKvCompanion(')
          ..write('chave: $chave, ')
          ..write('texto: $texto, ')
          ..write('bytes: $bytes, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$CadernetaDatabase extends GeneratedDatabase {
  _$CadernetaDatabase(QueryExecutor e) : super(e);
  $CadernetaDatabaseManager get managers => $CadernetaDatabaseManager(this);
  late final $AbastecimentosTable abastecimentos = $AbastecimentosTable(this);
  late final $ServicosTable servicos = $ServicosTable(this);
  late final $PinsTable pins = $PinsTable(this);
  late final $FichaSyncTable fichaSync = $FichaSyncTable(this);
  late final $CadernetaKvTable cadernetaKv = $CadernetaKvTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    abastecimentos,
    servicos,
    pins,
    fichaSync,
    cadernetaKv,
  ];
}

typedef $$AbastecimentosTableCreateCompanionBuilder =
    AbastecimentosCompanion Function({
      Value<int> id,
      required String em,
      required String combustivel,
      required double kmPainel,
      required double kmRodados,
      required double litros,
      required double precoLitro,
      required double reais,
      required double kmPorLitro,
      required double reaisPorKm,
    });
typedef $$AbastecimentosTableUpdateCompanionBuilder =
    AbastecimentosCompanion Function({
      Value<int> id,
      Value<String> em,
      Value<String> combustivel,
      Value<double> kmPainel,
      Value<double> kmRodados,
      Value<double> litros,
      Value<double> precoLitro,
      Value<double> reais,
      Value<double> kmPorLitro,
      Value<double> reaisPorKm,
    });

class $$AbastecimentosTableFilterComposer
    extends Composer<_$CadernetaDatabase, $AbastecimentosTable> {
  $$AbastecimentosTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get em => $composableBuilder(
    column: $table.em,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get combustivel => $composableBuilder(
    column: $table.combustivel,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get kmPainel => $composableBuilder(
    column: $table.kmPainel,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get kmRodados => $composableBuilder(
    column: $table.kmRodados,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get litros => $composableBuilder(
    column: $table.litros,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get precoLitro => $composableBuilder(
    column: $table.precoLitro,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get reais => $composableBuilder(
    column: $table.reais,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get kmPorLitro => $composableBuilder(
    column: $table.kmPorLitro,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get reaisPorKm => $composableBuilder(
    column: $table.reaisPorKm,
    builder: (column) => ColumnFilters(column),
  );
}

class $$AbastecimentosTableOrderingComposer
    extends Composer<_$CadernetaDatabase, $AbastecimentosTable> {
  $$AbastecimentosTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get em => $composableBuilder(
    column: $table.em,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get combustivel => $composableBuilder(
    column: $table.combustivel,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get kmPainel => $composableBuilder(
    column: $table.kmPainel,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get kmRodados => $composableBuilder(
    column: $table.kmRodados,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get litros => $composableBuilder(
    column: $table.litros,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get precoLitro => $composableBuilder(
    column: $table.precoLitro,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get reais => $composableBuilder(
    column: $table.reais,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get kmPorLitro => $composableBuilder(
    column: $table.kmPorLitro,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get reaisPorKm => $composableBuilder(
    column: $table.reaisPorKm,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$AbastecimentosTableAnnotationComposer
    extends Composer<_$CadernetaDatabase, $AbastecimentosTable> {
  $$AbastecimentosTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get em =>
      $composableBuilder(column: $table.em, builder: (column) => column);

  GeneratedColumn<String> get combustivel => $composableBuilder(
    column: $table.combustivel,
    builder: (column) => column,
  );

  GeneratedColumn<double> get kmPainel =>
      $composableBuilder(column: $table.kmPainel, builder: (column) => column);

  GeneratedColumn<double> get kmRodados =>
      $composableBuilder(column: $table.kmRodados, builder: (column) => column);

  GeneratedColumn<double> get litros =>
      $composableBuilder(column: $table.litros, builder: (column) => column);

  GeneratedColumn<double> get precoLitro => $composableBuilder(
    column: $table.precoLitro,
    builder: (column) => column,
  );

  GeneratedColumn<double> get reais =>
      $composableBuilder(column: $table.reais, builder: (column) => column);

  GeneratedColumn<double> get kmPorLitro => $composableBuilder(
    column: $table.kmPorLitro,
    builder: (column) => column,
  );

  GeneratedColumn<double> get reaisPorKm => $composableBuilder(
    column: $table.reaisPorKm,
    builder: (column) => column,
  );
}

class $$AbastecimentosTableTableManager
    extends
        RootTableManager<
          _$CadernetaDatabase,
          $AbastecimentosTable,
          LinhaAbastecimento,
          $$AbastecimentosTableFilterComposer,
          $$AbastecimentosTableOrderingComposer,
          $$AbastecimentosTableAnnotationComposer,
          $$AbastecimentosTableCreateCompanionBuilder,
          $$AbastecimentosTableUpdateCompanionBuilder,
          (
            LinhaAbastecimento,
            BaseReferences<
              _$CadernetaDatabase,
              $AbastecimentosTable,
              LinhaAbastecimento
            >,
          ),
          LinhaAbastecimento,
          PrefetchHooks Function()
        > {
  $$AbastecimentosTableTableManager(
    _$CadernetaDatabase db,
    $AbastecimentosTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AbastecimentosTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$AbastecimentosTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$AbastecimentosTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> em = const Value.absent(),
                Value<String> combustivel = const Value.absent(),
                Value<double> kmPainel = const Value.absent(),
                Value<double> kmRodados = const Value.absent(),
                Value<double> litros = const Value.absent(),
                Value<double> precoLitro = const Value.absent(),
                Value<double> reais = const Value.absent(),
                Value<double> kmPorLitro = const Value.absent(),
                Value<double> reaisPorKm = const Value.absent(),
              }) => AbastecimentosCompanion(
                id: id,
                em: em,
                combustivel: combustivel,
                kmPainel: kmPainel,
                kmRodados: kmRodados,
                litros: litros,
                precoLitro: precoLitro,
                reais: reais,
                kmPorLitro: kmPorLitro,
                reaisPorKm: reaisPorKm,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String em,
                required String combustivel,
                required double kmPainel,
                required double kmRodados,
                required double litros,
                required double precoLitro,
                required double reais,
                required double kmPorLitro,
                required double reaisPorKm,
              }) => AbastecimentosCompanion.insert(
                id: id,
                em: em,
                combustivel: combustivel,
                kmPainel: kmPainel,
                kmRodados: kmRodados,
                litros: litros,
                precoLitro: precoLitro,
                reais: reais,
                kmPorLitro: kmPorLitro,
                reaisPorKm: reaisPorKm,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$AbastecimentosTableProcessedTableManager =
    ProcessedTableManager<
      _$CadernetaDatabase,
      $AbastecimentosTable,
      LinhaAbastecimento,
      $$AbastecimentosTableFilterComposer,
      $$AbastecimentosTableOrderingComposer,
      $$AbastecimentosTableAnnotationComposer,
      $$AbastecimentosTableCreateCompanionBuilder,
      $$AbastecimentosTableUpdateCompanionBuilder,
      (
        LinhaAbastecimento,
        BaseReferences<
          _$CadernetaDatabase,
          $AbastecimentosTable,
          LinhaAbastecimento
        >,
      ),
      LinhaAbastecimento,
      PrefetchHooks Function()
    >;
typedef $$ServicosTableCreateCompanionBuilder =
    ServicosCompanion Function({
      Value<int> id,
      required String em,
      required String tipo,
      required double kmPainel,
      required double reais,
    });
typedef $$ServicosTableUpdateCompanionBuilder =
    ServicosCompanion Function({
      Value<int> id,
      Value<String> em,
      Value<String> tipo,
      Value<double> kmPainel,
      Value<double> reais,
    });

class $$ServicosTableFilterComposer
    extends Composer<_$CadernetaDatabase, $ServicosTable> {
  $$ServicosTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get em => $composableBuilder(
    column: $table.em,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get tipo => $composableBuilder(
    column: $table.tipo,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get kmPainel => $composableBuilder(
    column: $table.kmPainel,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get reais => $composableBuilder(
    column: $table.reais,
    builder: (column) => ColumnFilters(column),
  );
}

class $$ServicosTableOrderingComposer
    extends Composer<_$CadernetaDatabase, $ServicosTable> {
  $$ServicosTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get em => $composableBuilder(
    column: $table.em,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get tipo => $composableBuilder(
    column: $table.tipo,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get kmPainel => $composableBuilder(
    column: $table.kmPainel,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get reais => $composableBuilder(
    column: $table.reais,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ServicosTableAnnotationComposer
    extends Composer<_$CadernetaDatabase, $ServicosTable> {
  $$ServicosTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get em =>
      $composableBuilder(column: $table.em, builder: (column) => column);

  GeneratedColumn<String> get tipo =>
      $composableBuilder(column: $table.tipo, builder: (column) => column);

  GeneratedColumn<double> get kmPainel =>
      $composableBuilder(column: $table.kmPainel, builder: (column) => column);

  GeneratedColumn<double> get reais =>
      $composableBuilder(column: $table.reais, builder: (column) => column);
}

class $$ServicosTableTableManager
    extends
        RootTableManager<
          _$CadernetaDatabase,
          $ServicosTable,
          LinhaServico,
          $$ServicosTableFilterComposer,
          $$ServicosTableOrderingComposer,
          $$ServicosTableAnnotationComposer,
          $$ServicosTableCreateCompanionBuilder,
          $$ServicosTableUpdateCompanionBuilder,
          (
            LinhaServico,
            BaseReferences<_$CadernetaDatabase, $ServicosTable, LinhaServico>,
          ),
          LinhaServico,
          PrefetchHooks Function()
        > {
  $$ServicosTableTableManager(_$CadernetaDatabase db, $ServicosTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ServicosTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ServicosTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ServicosTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> em = const Value.absent(),
                Value<String> tipo = const Value.absent(),
                Value<double> kmPainel = const Value.absent(),
                Value<double> reais = const Value.absent(),
              }) => ServicosCompanion(
                id: id,
                em: em,
                tipo: tipo,
                kmPainel: kmPainel,
                reais: reais,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String em,
                required String tipo,
                required double kmPainel,
                required double reais,
              }) => ServicosCompanion.insert(
                id: id,
                em: em,
                tipo: tipo,
                kmPainel: kmPainel,
                reais: reais,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$ServicosTableProcessedTableManager =
    ProcessedTableManager<
      _$CadernetaDatabase,
      $ServicosTable,
      LinhaServico,
      $$ServicosTableFilterComposer,
      $$ServicosTableOrderingComposer,
      $$ServicosTableAnnotationComposer,
      $$ServicosTableCreateCompanionBuilder,
      $$ServicosTableUpdateCompanionBuilder,
      (
        LinhaServico,
        BaseReferences<_$CadernetaDatabase, $ServicosTable, LinhaServico>,
      ),
      LinhaServico,
      PrefetchHooks Function()
    >;
typedef $$PinsTableCreateCompanionBuilder =
    PinsCompanion Function({
      Value<int> id,
      required String tipo,
      required double latitude,
      required double longitude,
    });
typedef $$PinsTableUpdateCompanionBuilder =
    PinsCompanion Function({
      Value<int> id,
      Value<String> tipo,
      Value<double> latitude,
      Value<double> longitude,
    });

class $$PinsTableFilterComposer
    extends Composer<_$CadernetaDatabase, $PinsTable> {
  $$PinsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get tipo => $composableBuilder(
    column: $table.tipo,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get latitude => $composableBuilder(
    column: $table.latitude,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get longitude => $composableBuilder(
    column: $table.longitude,
    builder: (column) => ColumnFilters(column),
  );
}

class $$PinsTableOrderingComposer
    extends Composer<_$CadernetaDatabase, $PinsTable> {
  $$PinsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get tipo => $composableBuilder(
    column: $table.tipo,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get latitude => $composableBuilder(
    column: $table.latitude,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get longitude => $composableBuilder(
    column: $table.longitude,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$PinsTableAnnotationComposer
    extends Composer<_$CadernetaDatabase, $PinsTable> {
  $$PinsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get tipo =>
      $composableBuilder(column: $table.tipo, builder: (column) => column);

  GeneratedColumn<double> get latitude =>
      $composableBuilder(column: $table.latitude, builder: (column) => column);

  GeneratedColumn<double> get longitude =>
      $composableBuilder(column: $table.longitude, builder: (column) => column);
}

class $$PinsTableTableManager
    extends
        RootTableManager<
          _$CadernetaDatabase,
          $PinsTable,
          LinhaPin,
          $$PinsTableFilterComposer,
          $$PinsTableOrderingComposer,
          $$PinsTableAnnotationComposer,
          $$PinsTableCreateCompanionBuilder,
          $$PinsTableUpdateCompanionBuilder,
          (LinhaPin, BaseReferences<_$CadernetaDatabase, $PinsTable, LinhaPin>),
          LinhaPin,
          PrefetchHooks Function()
        > {
  $$PinsTableTableManager(_$CadernetaDatabase db, $PinsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PinsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PinsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PinsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> tipo = const Value.absent(),
                Value<double> latitude = const Value.absent(),
                Value<double> longitude = const Value.absent(),
              }) => PinsCompanion(
                id: id,
                tipo: tipo,
                latitude: latitude,
                longitude: longitude,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String tipo,
                required double latitude,
                required double longitude,
              }) => PinsCompanion.insert(
                id: id,
                tipo: tipo,
                latitude: latitude,
                longitude: longitude,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$PinsTableProcessedTableManager =
    ProcessedTableManager<
      _$CadernetaDatabase,
      $PinsTable,
      LinhaPin,
      $$PinsTableFilterComposer,
      $$PinsTableOrderingComposer,
      $$PinsTableAnnotationComposer,
      $$PinsTableCreateCompanionBuilder,
      $$PinsTableUpdateCompanionBuilder,
      (LinhaPin, BaseReferences<_$CadernetaDatabase, $PinsTable, LinhaPin>),
      LinhaPin,
      PrefetchHooks Function()
    >;
typedef $$FichaSyncTableCreateCompanionBuilder =
    FichaSyncCompanion Function({
      Value<int> id,
      required String status,
      required DateTime localUpdatedAt,
      Value<DateTime?> remoteUpdatedAt,
      Value<String?> lastSyncError,
      Value<int> tentativas,
    });
typedef $$FichaSyncTableUpdateCompanionBuilder =
    FichaSyncCompanion Function({
      Value<int> id,
      Value<String> status,
      Value<DateTime> localUpdatedAt,
      Value<DateTime?> remoteUpdatedAt,
      Value<String?> lastSyncError,
      Value<int> tentativas,
    });

class $$FichaSyncTableFilterComposer
    extends Composer<_$CadernetaDatabase, $FichaSyncTable> {
  $$FichaSyncTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get localUpdatedAt => $composableBuilder(
    column: $table.localUpdatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get remoteUpdatedAt => $composableBuilder(
    column: $table.remoteUpdatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get lastSyncError => $composableBuilder(
    column: $table.lastSyncError,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get tentativas => $composableBuilder(
    column: $table.tentativas,
    builder: (column) => ColumnFilters(column),
  );
}

class $$FichaSyncTableOrderingComposer
    extends Composer<_$CadernetaDatabase, $FichaSyncTable> {
  $$FichaSyncTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get localUpdatedAt => $composableBuilder(
    column: $table.localUpdatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get remoteUpdatedAt => $composableBuilder(
    column: $table.remoteUpdatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get lastSyncError => $composableBuilder(
    column: $table.lastSyncError,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get tentativas => $composableBuilder(
    column: $table.tentativas,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$FichaSyncTableAnnotationComposer
    extends Composer<_$CadernetaDatabase, $FichaSyncTable> {
  $$FichaSyncTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<DateTime> get localUpdatedAt => $composableBuilder(
    column: $table.localUpdatedAt,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get remoteUpdatedAt => $composableBuilder(
    column: $table.remoteUpdatedAt,
    builder: (column) => column,
  );

  GeneratedColumn<String> get lastSyncError => $composableBuilder(
    column: $table.lastSyncError,
    builder: (column) => column,
  );

  GeneratedColumn<int> get tentativas => $composableBuilder(
    column: $table.tentativas,
    builder: (column) => column,
  );
}

class $$FichaSyncTableTableManager
    extends
        RootTableManager<
          _$CadernetaDatabase,
          $FichaSyncTable,
          LinhaFichaSync,
          $$FichaSyncTableFilterComposer,
          $$FichaSyncTableOrderingComposer,
          $$FichaSyncTableAnnotationComposer,
          $$FichaSyncTableCreateCompanionBuilder,
          $$FichaSyncTableUpdateCompanionBuilder,
          (
            LinhaFichaSync,
            BaseReferences<
              _$CadernetaDatabase,
              $FichaSyncTable,
              LinhaFichaSync
            >,
          ),
          LinhaFichaSync,
          PrefetchHooks Function()
        > {
  $$FichaSyncTableTableManager(_$CadernetaDatabase db, $FichaSyncTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$FichaSyncTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$FichaSyncTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$FichaSyncTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<DateTime> localUpdatedAt = const Value.absent(),
                Value<DateTime?> remoteUpdatedAt = const Value.absent(),
                Value<String?> lastSyncError = const Value.absent(),
                Value<int> tentativas = const Value.absent(),
              }) => FichaSyncCompanion(
                id: id,
                status: status,
                localUpdatedAt: localUpdatedAt,
                remoteUpdatedAt: remoteUpdatedAt,
                lastSyncError: lastSyncError,
                tentativas: tentativas,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String status,
                required DateTime localUpdatedAt,
                Value<DateTime?> remoteUpdatedAt = const Value.absent(),
                Value<String?> lastSyncError = const Value.absent(),
                Value<int> tentativas = const Value.absent(),
              }) => FichaSyncCompanion.insert(
                id: id,
                status: status,
                localUpdatedAt: localUpdatedAt,
                remoteUpdatedAt: remoteUpdatedAt,
                lastSyncError: lastSyncError,
                tentativas: tentativas,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$FichaSyncTableProcessedTableManager =
    ProcessedTableManager<
      _$CadernetaDatabase,
      $FichaSyncTable,
      LinhaFichaSync,
      $$FichaSyncTableFilterComposer,
      $$FichaSyncTableOrderingComposer,
      $$FichaSyncTableAnnotationComposer,
      $$FichaSyncTableCreateCompanionBuilder,
      $$FichaSyncTableUpdateCompanionBuilder,
      (
        LinhaFichaSync,
        BaseReferences<_$CadernetaDatabase, $FichaSyncTable, LinhaFichaSync>,
      ),
      LinhaFichaSync,
      PrefetchHooks Function()
    >;
typedef $$CadernetaKvTableCreateCompanionBuilder =
    CadernetaKvCompanion Function({
      required String chave,
      Value<String?> texto,
      Value<Uint8List?> bytes,
      Value<int> rowid,
    });
typedef $$CadernetaKvTableUpdateCompanionBuilder =
    CadernetaKvCompanion Function({
      Value<String> chave,
      Value<String?> texto,
      Value<Uint8List?> bytes,
      Value<int> rowid,
    });

class $$CadernetaKvTableFilterComposer
    extends Composer<_$CadernetaDatabase, $CadernetaKvTable> {
  $$CadernetaKvTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get chave => $composableBuilder(
    column: $table.chave,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get texto => $composableBuilder(
    column: $table.texto,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<Uint8List> get bytes => $composableBuilder(
    column: $table.bytes,
    builder: (column) => ColumnFilters(column),
  );
}

class $$CadernetaKvTableOrderingComposer
    extends Composer<_$CadernetaDatabase, $CadernetaKvTable> {
  $$CadernetaKvTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get chave => $composableBuilder(
    column: $table.chave,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get texto => $composableBuilder(
    column: $table.texto,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<Uint8List> get bytes => $composableBuilder(
    column: $table.bytes,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$CadernetaKvTableAnnotationComposer
    extends Composer<_$CadernetaDatabase, $CadernetaKvTable> {
  $$CadernetaKvTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get chave =>
      $composableBuilder(column: $table.chave, builder: (column) => column);

  GeneratedColumn<String> get texto =>
      $composableBuilder(column: $table.texto, builder: (column) => column);

  GeneratedColumn<Uint8List> get bytes =>
      $composableBuilder(column: $table.bytes, builder: (column) => column);
}

class $$CadernetaKvTableTableManager
    extends
        RootTableManager<
          _$CadernetaDatabase,
          $CadernetaKvTable,
          LinhaKv,
          $$CadernetaKvTableFilterComposer,
          $$CadernetaKvTableOrderingComposer,
          $$CadernetaKvTableAnnotationComposer,
          $$CadernetaKvTableCreateCompanionBuilder,
          $$CadernetaKvTableUpdateCompanionBuilder,
          (
            LinhaKv,
            BaseReferences<_$CadernetaDatabase, $CadernetaKvTable, LinhaKv>,
          ),
          LinhaKv,
          PrefetchHooks Function()
        > {
  $$CadernetaKvTableTableManager(
    _$CadernetaDatabase db,
    $CadernetaKvTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CadernetaKvTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CadernetaKvTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CadernetaKvTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> chave = const Value.absent(),
                Value<String?> texto = const Value.absent(),
                Value<Uint8List?> bytes = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CadernetaKvCompanion(
                chave: chave,
                texto: texto,
                bytes: bytes,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String chave,
                Value<String?> texto = const Value.absent(),
                Value<Uint8List?> bytes = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CadernetaKvCompanion.insert(
                chave: chave,
                texto: texto,
                bytes: bytes,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$CadernetaKvTableProcessedTableManager =
    ProcessedTableManager<
      _$CadernetaDatabase,
      $CadernetaKvTable,
      LinhaKv,
      $$CadernetaKvTableFilterComposer,
      $$CadernetaKvTableOrderingComposer,
      $$CadernetaKvTableAnnotationComposer,
      $$CadernetaKvTableCreateCompanionBuilder,
      $$CadernetaKvTableUpdateCompanionBuilder,
      (
        LinhaKv,
        BaseReferences<_$CadernetaDatabase, $CadernetaKvTable, LinhaKv>,
      ),
      LinhaKv,
      PrefetchHooks Function()
    >;

class $CadernetaDatabaseManager {
  final _$CadernetaDatabase _db;
  $CadernetaDatabaseManager(this._db);
  $$AbastecimentosTableTableManager get abastecimentos =>
      $$AbastecimentosTableTableManager(_db, _db.abastecimentos);
  $$ServicosTableTableManager get servicos =>
      $$ServicosTableTableManager(_db, _db.servicos);
  $$PinsTableTableManager get pins => $$PinsTableTableManager(_db, _db.pins);
  $$FichaSyncTableTableManager get fichaSync =>
      $$FichaSyncTableTableManager(_db, _db.fichaSync);
  $$CadernetaKvTableTableManager get cadernetaKv =>
      $$CadernetaKvTableTableManager(_db, _db.cadernetaKv);
}
