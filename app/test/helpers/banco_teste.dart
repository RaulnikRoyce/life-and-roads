import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:life_and_roads/core/database/caderneta_banco.dart';
import 'package:life_and_roads/core/database/caderneta_database.dart';

Future<void> abrirBancoTeste() async {
  await CadernetaBanco.fechar();
  CadernetaBanco.usar(
    CadernetaDatabase(
      DatabaseConnection(
        NativeDatabase.memory(),
        closeStreamsSynchronously: true,
      ),
    ),
  );
}

Future<void> fecharBancoTeste() => CadernetaBanco.fechar();
