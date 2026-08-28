import 'dart:convert';

import 'package:life_and_roads/core/database/armazem_kv.dart';
import 'package:life_and_roads/core/database/chaves_kv.dart';
import 'package:life_and_roads/core/sync/status_sync.dart';

/// Metadados de sync das datas. Km, CNH e serviço não sobem.
class ManutencaoSyncStore {
  static const chave = ChavesKv.manutencaoSync;

  Future<MetadadoSync> ler() async {
    final bruto = await ArmazemKv.lerTexto(chave);
    if (bruto == null) return const MetadadoSync();
    try {
      final mapa = jsonDecode(bruto);
      if (mapa is! Map) return const MetadadoSync();
      return MetadadoSync(
        status: StatusSync.de('${mapa['status'] ?? ''}'),
        localUpdatedAt: DateTime.tryParse('${mapa['localUpdatedAt'] ?? ''}'),
        remoteUpdatedAt: DateTime.tryParse('${mapa['remoteUpdatedAt'] ?? ''}'),
        lastSyncError: '${mapa['lastSyncError'] ?? ''}'.trim().isEmpty
            ? null
            : '${mapa['lastSyncError']}'.trim(),
        tentativas: (mapa['tentativas'] is num)
            ? (mapa['tentativas'] as num).toInt()
            : 0,
      );
    } on FormatException {
      return const MetadadoSync();
    }
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
    final atual = await ler();
    final tentativas = zerarTentativas
        ? 0
        : somarTentativa
            ? atual.tentativas + 1
            : atual.tentativas;
    final local = tocarLocal ? agora : (atual.localUpdatedAt ?? agora);
    final remoto = remotoAgora ? agora : atual.remoteUpdatedAt;
    await ArmazemKv.gravarTexto(
      chave,
      jsonEncode({
        'status': status.name,
        'localUpdatedAt': local.toIso8601String(),
        'remoteUpdatedAt': remoto?.toIso8601String(),
        'lastSyncError': erro,
        'tentativas': tentativas,
      }),
    );
  }
}
