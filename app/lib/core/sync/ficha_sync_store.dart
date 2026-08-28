import 'package:drift/drift.dart';
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
      remoteUpdatedAt: linha.remoteUpdatedAt,
      lastSyncError: linha.lastSyncError,
      tentativas: linha.tentativas,
    );
  }

  Future<void> marcarPendente({String? erro}) {
    return _gravar(StatusSync.pending, erro: erro, tocarLocal: true);
  }

  Future<void> marcarSincronizado() {
    return _gravar(
      StatusSync.synced,
      remotoAgora: true,
      zerarTentativas: true,
    );
  }

  Future<void> marcarFalhou(String erro) {
    return _gravar(StatusSync.failed, erro: erro, somarTentativa: true);
  }

  Future<void> marcarConflito() {
    return _gravar(StatusSync.conflict, erro: 'Divergiu do servidor.');
  }

  Future<void> _gravar(
    StatusSync status, {
    String? erro,
    bool tocarLocal = false,
    bool remotoAgora = false,
    bool somarTentativa = false,
    bool zerarTentativas = false,
  }) async {
    final agora = DateTime.now().toUtc();
    final atual = await _db.lerFichaSync();
    final tentativas = zerarTentativas
        ? 0
        : somarTentativa
            ? (atual?.tentativas ?? 0) + 1
            : (atual?.tentativas ?? 0);
    final local = tocarLocal ? agora : (atual?.localUpdatedAt ?? agora);
    final remoto = remotoAgora ? agora : atual?.remoteUpdatedAt;
    await _db.gravarFichaSync(
      FichaSyncCompanion.insert(
        status: status.name,
        localUpdatedAt: local,
        remoteUpdatedAt: Value(remoto),
        lastSyncError: Value(erro),
        tentativas: Value(tentativas),
      ),
    );
  }
}
