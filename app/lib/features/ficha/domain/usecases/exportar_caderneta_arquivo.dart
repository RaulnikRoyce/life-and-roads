import 'package:life_and_roads/backup.dart';
import 'package:life_and_roads/features/ficha/data/pasta_caderneta.dart';

/// Grava o JSON v2 da caderneta num arquivo neste aparelho.
class ExportarCadernetaArquivo {
  const ExportarCadernetaArquivo({this.pasta});

  /// Pasta de teste. No aparelho usa Documents.
  final String? pasta;

  Future<({String? caminho, String? erro})> executar() async {
    final json = await BackupCaderneta.exportar();
    return gravarCadernetaJson(json, pasta: pasta);
  }
}
