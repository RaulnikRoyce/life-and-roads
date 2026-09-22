import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:life_and_roads/backup.dart';
import 'package:life_and_roads/core/backup/pasta_download.dart';
import 'package:life_and_roads/core/database/armazem_kv.dart';
import 'package:life_and_roads/core/database/chaves_kv.dart';

/// Grava a caderneta em Download sozinho, sempre no mesmo arquivo.
///
/// O piloto pediu para não depender de lembrar do backup. A cada mudança
/// que vale (ficha, manutenção, abastecimento) o app regrava
/// `Download/life.and.roads/caderneta.json`, que sobrevive a desinstalar o
/// app e a trocar de celular.
///
/// Espera um pouco antes de gravar, porque salvar acontece em rajada
/// (digitar o km dispara vários), e falha em silêncio: backup que atrapalha
/// o uso é pior que backup que não aconteceu.
class BackupAutomatico {
  BackupAutomatico({
    this.pasta = const PastaDownload(),
    Future<String> Function()? exportar,
    this.espera = const Duration(seconds: 3),
  }) : _exportar = exportar ?? BackupCaderneta.exportar;

  final PastaDownload pasta;
  final Future<String> Function() _exportar;
  final Duration espera;

  static const nomeArquivo = 'caderneta.json';

  Timer? _timer;
  bool _gravando = false;

  /// Marca que a caderneta mudou. Várias chamadas seguidas viram uma só.
  void agendar() {
    _timer?.cancel();
    _timer = Timer(espera, () => unawaited(gravarAgora()));
  }

  /// Grava na hora. Devolve o caminho, ou null quando não deu.
  Future<String?> gravarAgora() async {
    if (_gravando) return null;
    _gravando = true;
    try {
      final caminho = await pasta.salvar(
        nome: nomeArquivo,
        conteudo: await _exportar(),
      );
      if (caminho != null) {
        // O carimbo é só para a tela dizer "salvo há 5 min". Falhar aqui
        // não desfaz o backup, que já está gravado.
        try {
          await ArmazemKv.gravarTexto(
            ChavesKv.backupAutomaticoEm,
            DateTime.now().toIso8601String(),
          );
        } catch (_) {}
      }
      return caminho;
    } catch (_) {
      return null;
    } finally {
      _gravando = false;
    }
  }

  /// Quando o backup automático gravou pela última vez. Null se nunca.
  static Future<DateTime?> ultimoEm() async {
    final txt = await ArmazemKv.lerTexto(ChavesKv.backupAutomaticoEm);
    return txt == null ? null : DateTime.tryParse(txt);
  }

  void descartar() {
    _timer?.cancel();
    _timer = null;
  }
}

/// Um só para o app inteiro: a espera junta as rajadas de salvar.
final backupAutomaticoProvider = Provider<BackupAutomatico>((ref) {
  final b = BackupAutomatico();
  ref.onDispose(b.descartar);
  return b;
});
