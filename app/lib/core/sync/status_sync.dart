/// Estado da ficha em relação à API opcional.
///
/// Abastecimentos, serviços e pins não sobem ao servidor.
enum StatusSync {
  synced,
  pending,
  failed,
  conflict;

  static StatusSync de(String bruto) {
    for (final s in StatusSync.values) {
      if (s.name == bruto) return s;
    }
    return StatusSync.pending;
  }
}

class MetadadoSync {
  const MetadadoSync({
    this.status = StatusSync.synced,
    this.localUpdatedAt,
    this.remoteUpdatedAt,
    this.lastSyncError,
    this.tentativas = 0,
  });

  final StatusSync status;
  final DateTime? localUpdatedAt;
  final DateTime? remoteUpdatedAt;
  final String? lastSyncError;
  final int tentativas;

  /// Última alteração local ainda não confirmada no servidor.
  bool get deveReenviar =>
      status == StatusSync.pending || status == StatusSync.failed;

  bool get emConflito => status == StatusSync.conflict;
}
