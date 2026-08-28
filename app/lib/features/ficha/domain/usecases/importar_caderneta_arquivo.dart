import 'package:life_and_roads/backup.dart';
import 'package:life_and_roads/features/ficha/data/pasta_caderneta.dart';

/// Lê o JSON v2 (ou v1) de um arquivo e restaura neste aparelho.
class ImportarCadernetaArquivo {
  const ImportarCadernetaArquivo({this.pasta});

  final String? pasta;

  Future<String?> executar({String? caminho, String? json}) async {
    final bruto = json ?? await lerCadernetaJson(caminho: caminho, pasta: pasta);
    if (bruto == null || bruto.trim().isEmpty) {
      return 'Arquivo de backup não encontrado.';
    }
    return BackupCaderneta.restaurar(bruto);
  }
}
