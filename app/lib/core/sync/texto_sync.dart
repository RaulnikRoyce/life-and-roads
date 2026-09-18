import 'package:life_and_roads/core/sync/status_sync.dart';

/// Frase curta do estado da sincronização, para a Ficha e a Manutenção.
///
/// Null quando não há o que dizer (conflito tem cartão próprio). Só faz
/// sentido com conta; sem conta a caderneta é do aparelho e pronto.
String? textoSync(MetadadoSync meta, {bool offline = false}) {
  switch (meta.status) {
    case StatusSync.conflict:
      return null;
    case StatusSync.synced:
      // A última tentativa falhou: o que está em dia é o aparelho, não o
      // servidor. Sem fila, porque nada mudou aqui.
      if (offline) return 'Sem resposta do servidor. Caderneta neste aparelho.';
      final quando = meta.remoteUpdatedAt;
      if (quando == null) return 'No servidor.';
      return 'No servidor. Atualizado ${dataHoraCurta(quando)}.';
    case StatusSync.pending:
    case StatusSync.failed:
      final desde = meta.localUpdatedAt;
      final base = desde == null
          ? 'Aguardando o servidor.'
          : 'Aguardando o servidor desde ${dataHoraCurta(desde)}.';
      final erro = meta.lastSyncError?.trim();
      if (erro == null || erro.isEmpty) return base;
      return '$base $erro';
  }
}

/// `17/09 14:32` na hora local do aparelho.
String dataHoraCurta(DateTime d) {
  final l = d.toLocal();
  String dois(int n) => n.toString().padLeft(2, '0');
  return '${dois(l.day)}/${dois(l.month)} ${dois(l.hour)}:${dois(l.minute)}';
}
