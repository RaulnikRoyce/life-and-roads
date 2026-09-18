import 'package:life_and_roads/backup.dart';

/// Restaura a caderneta a partir do texto de um backup (JSON v2 ou v1).
///
/// Quem lê o arquivo é a tela (seletor do sistema ou clipboard); aqui só
/// entra o conteúdo.
class ImportarCadernetaArquivo {
  const ImportarCadernetaArquivo();

  Future<String?> executar(String json) async {
    if (json.trim().isEmpty) return 'Arquivo de backup vazio.';
    return BackupCaderneta.restaurar(json);
  }
}
