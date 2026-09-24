import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:life_and_roads/core/backup/backup_automatico.dart';
import 'package:life_and_roads/core/backup/backup_nuvem.dart';

/// Um aviso só de que a caderneta mudou (ADR 0038).
///
/// Quem grava dado do piloto chama [avisar], e os dois backups ficam
/// sabendo: o arquivo em Download e a caderneta na nuvem. Antes cada tela
/// chamava o backup em Download por conta própria, e pino, serviço novo e
/// preço do dia ficavam de fora.
class CadernetaMudou {
  CadernetaMudou(this._ref);

  final Ref _ref;

  void avisar() {
    _ref.read(backupAutomaticoProvider).agendar();
    _ref.read(backupNuvemProvider).agendar();
  }

  /// O app foi para segundo plano. Grava e manda o que estava esperando.
  Future<void> aoSairDoApp() async {
    await _ref.read(backupAutomaticoProvider).gravarSePendente();
    await _ref.read(backupNuvemProvider).enviarSePendente();
  }
}

final cadernetaMudouProvider = Provider<CadernetaMudou>(
  (ref) => CadernetaMudou(ref),
);
