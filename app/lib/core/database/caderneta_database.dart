import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

part 'caderneta_database.g.dart';

@DataClassName('LinhaAbastecimento')
class Abastecimentos extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get em => text()();
  TextColumn get combustivel => text()();
  RealColumn get kmPainel => real()();
  RealColumn get kmRodados => real()();
  RealColumn get litros => real()();
  RealColumn get precoLitro => real()();
  RealColumn get reais => real()();
  RealColumn get kmPorLitro => real()();
  RealColumn get reaisPorKm => real()();
}

@DataClassName('LinhaServico')
class Servicos extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get em => text()();
  TextColumn get tipo => text()();
  RealColumn get kmPainel => real()();
  RealColumn get reais => real()();
}

@DataClassName('LinhaPin')
class Pins extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get tipo => text()();
  RealColumn get latitude => real()();
  RealColumn get longitude => real()();
}

/// Uma linha: metadados da ficha (única entidade desta fatia que vai à API).
@DataClassName('LinhaFichaSync')
class FichaSync extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get status => text()();
  DateTimeColumn get localUpdatedAt => dateTime()();
  DateTimeColumn get remoteUpdatedAt => dateTime().nullable()();
  TextColumn get lastSyncError => text().nullable()();
  IntColumn get tentativas => integer().withDefault(const Constant(0))();
}

/// Ficha, agenda, extra, foto, preços e último ponto (antes nas prefs).
@DataClassName('LinhaKv')
class CadernetaKv extends Table {
  TextColumn get chave => text()();
  TextColumn get texto => text().nullable()();
  BlobColumn get bytes => blob().nullable()();

  @override
  Set<Column> get primaryKey => {chave};
}

@DriftDatabase(
  tables: [Abastecimentos, Servicos, Pins, FichaSync, CadernetaKv],
)
class CadernetaDatabase extends _$CadernetaDatabase {
  CadernetaDatabase(super.e);

  CadernetaDatabase.arquivo() : super(driftDatabase(name: 'caderneta'));

  @override
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) async => m.createAll(),
        onUpgrade: (m, from, to) async {
          if (from < 2) {
            await m.createTable(cadernetaKv);
          }
        },
      );

  Future<List<LinhaAbastecimento>> listarAbastecimentos() {
    return (select(abastecimentos)
          ..orderBy([(t) => OrderingTerm.desc(t.id)]))
        .get();
  }

  Future<void> inserirAbastecimento(AbastecimentosCompanion linha) {
    return into(abastecimentos).insert(linha);
  }

  Future<List<LinhaServico>> listarServicos() {
    return (select(servicos)..orderBy([(t) => OrderingTerm.desc(t.id)])).get();
  }

  Future<void> inserirServico(ServicosCompanion linha) {
    return into(servicos).insert(linha);
  }

  Future<List<LinhaPin>> listarPins() => select(pins).get();

  Future<void> inserirPin(PinsCompanion linha) => into(pins).insert(linha);

  Future<void> apagarPins() => delete(pins).go();

  Future<void> apagarAbastecimentos() => delete(abastecimentos).go();

  Future<void> apagarServicos() => delete(servicos).go();

  Future<LinhaFichaSync?> lerFichaSync() async {
    final linhas = await select(fichaSync).get();
    return linhas.isEmpty ? null : linhas.first;
  }

  Future<void> gravarFichaSync(FichaSyncCompanion linha) async {
    final atual = await select(fichaSync).get();
    if (atual.isEmpty) {
      await into(fichaSync).insert(linha);
      return;
    }
    await (update(fichaSync)..where((t) => t.id.equals(atual.first.id)))
        .write(linha);
  }

  Future<String?> lerTextoKv(String chave) async {
    final linha = await (select(cadernetaKv)
          ..where((t) => t.chave.equals(chave)))
        .getSingleOrNull();
    return linha?.texto;
  }

  Future<Uint8List?> lerBlobKv(String chave) async {
    final linha = await (select(cadernetaKv)
          ..where((t) => t.chave.equals(chave)))
        .getSingleOrNull();
    return linha?.bytes;
  }

  Future<void> gravarTextoKv(String chave, String? valor) async {
    if (valor == null || valor.isEmpty) {
      await (delete(cadernetaKv)..where((t) => t.chave.equals(chave))).go();
      return;
    }
    await into(cadernetaKv).insertOnConflictUpdate(
      CadernetaKvCompanion.insert(chave: chave, texto: Value(valor)),
    );
  }

  Future<void> gravarBlobKv(String chave, Uint8List? bytes) async {
    if (bytes == null || bytes.isEmpty) {
      await (delete(cadernetaKv)..where((t) => t.chave.equals(chave))).go();
      return;
    }
    await into(cadernetaKv).insertOnConflictUpdate(
      CadernetaKvCompanion.insert(chave: chave, bytes: Value(bytes)),
    );
  }

  Future<int> contar(String tabela) async {
    final q = await customSelect(
      'SELECT COUNT(*) AS c FROM $tabela',
    ).getSingle();
    return q.read<int>('c');
  }

  Future<void> podarMaisAntigos(String tabela, int max) async {
    final n = await contar(tabela);
    if (n <= max) return;
    await customStatement(
      'DELETE FROM $tabela WHERE id IN '
      '(SELECT id FROM $tabela ORDER BY id ASC LIMIT ?)',
      [n - max],
    );
  }
}
