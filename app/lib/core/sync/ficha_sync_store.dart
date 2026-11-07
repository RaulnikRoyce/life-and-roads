import 'package:drift/drift.dart';
import 'package:life_and_roads/core/database/chaves_kv.dart';
import 'package:life_and_roads/core/database/caderneta_banco.dart';
import 'package:life_and_roads/core/database/caderneta_database.dart';
import 'package:life_and_roads/core/sync/status_sync.dart';

/// Persistência dos metadados de sync da ficha.
class FichaSyncStore {
  CadernetaDatabase get _db => CadernetaBanco.instancia;

  Future<MetadadoSync> ler() async {
    final linha = await _db.lerFichaSync();
    if (linha == null) return const MetadadoSync();
    return MetadadoSync(
      status: StatusSync.de(linha.status),
      localUpdatedAt: linha.localUpdatedAt,
      remoteUpdatedAt:
          DateTime.tryParse(
            await _db.lerTextoKv(ChavesKv.fichaCarimbo) ?? '',
          ) ??
          linha.remoteUpdatedAt,
      lastSyncError: linha.lastSyncError,
      tentativas: linha.tentativas,
    );
  }

  Future<void> marcarPendente({String? erro}) {
    return _gravar(StatusSync.pending, erro: erro, tocarLocal: true);
  }

  /// [carimbo] é o `atualizadoEm` do servidor. Sem ele, guarda a hora local,
  /// que nunca bate com o servidor e por isso força a pergunta de conflito.
  Future<void> marcarSincronizado({DateTime? carimbo, DateTime? seLocalEm}) {
    return _gravar(
      StatusSync.synced,
      remotoAgora: true,
      carimbo: carimbo,
      zerarTentativas: true,
      seLocalEm: seLocalEm,
    );
  }

  Future<void> marcarFalhou(String erro, {DateTime? seLocalEm}) {
    return _gravar(
      StatusSync.failed,
      erro: erro,
      somarTentativa: true,
      seLocalEm: seLocalEm,
    );
  }

  Future<void> marcarConflito({DateTime? seLocalEm}) {
    return _gravar(
      StatusSync.conflict,
      erro: 'Divergiu do servidor.',
      seLocalEm: seLocalEm,
    );
  }

  Future<void> _gravar(
    StatusSync status, {
    String? erro,
    bool tocarLocal = false,
    bool remotoAgora = false,
    DateTime? carimbo,
    bool somarTentativa = false,
    bool zerarTentativas = false,
    DateTime? seLocalEm,
  }) => _db.transaction(() async {
    final agora = DateTime.fromMillisecondsSinceEpoch(
      DateTime.now().millisecondsSinceEpoch ~/ 1000 * 1000,
      isUtc: true,
    );
    final atual = await _db.lerFichaSync();
    if (seLocalEm != null && atual?.localUpdatedAt != seLocalEm) return;
    final tentativas = zerarTentativas
        ? 0
        : somarTentativa
        ? (atual?.tentativas ?? 0) + 1
        : (atual?.tentativas ?? 0);
    final anterior = atual?.localUpdatedAt;
    final proximo = anterior != null && !agora.isAfter(anterior)
        ? anterior.add(const Duration(seconds: 1))
        : agora;
    final local = tocarLocal ? proximo : (anterior ?? agora);
    final remoto = remotoAgora
        ? (carimbo?.toUtc() ?? agora)
        : atual?.remoteUpdatedAt;
    if (remotoAgora) {
      await _db.gravarTextoKv(ChavesKv.fichaCarimbo, remoto?.toIso8601String());
    }
    await _db.gravarFichaSync(
      FichaSyncCompanion.insert(
        status: status.name,
        localUpdatedAt: local,
        remoteUpdatedAt: Value(remoto),
        lastSyncError: Value(erro),
        tentativas: Value(tentativas),
      ),
    );
  });
}
