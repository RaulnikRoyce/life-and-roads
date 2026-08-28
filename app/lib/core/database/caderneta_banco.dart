import 'package:life_and_roads/core/database/caderneta_database.dart';

/// Ponto único do SQLite da caderneta.
///
/// No aparelho: arquivo via [CadernetaDatabase.arquivo].
/// Nos testes: [usar] com `NativeDatabase.memory()`.
class CadernetaBanco {
  CadernetaBanco._();

  static CadernetaDatabase? _db;

  static CadernetaDatabase get instancia {
    final atual = _db;
    if (atual == null) {
      throw StateError(
        'CadernetaBanco não aberto. Chame abrirArquivo() ou usar().',
      );
    }
    return atual;
  }

  static bool get aberto => _db != null;

  static void usar(CadernetaDatabase db) {
    _db = db;
  }

  static Future<void> abrirArquivo() async {
    await fechar();
    _db = CadernetaDatabase.arquivo();
  }

  static Future<void> fechar() async {
    final atual = _db;
    _db = null;
    if (atual != null) await atual.close();
  }
}
