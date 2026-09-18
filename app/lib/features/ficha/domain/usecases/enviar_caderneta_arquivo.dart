import 'package:life_and_roads/backup.dart';
import 'package:life_and_roads/features/ficha/data/pasta_caderneta.dart';

/// Quem de fato abre o "compartilhar". Injetável para teste.
typedef Enviador = Future<bool> Function({String? caminho, String? json});

/// Gera o JSON v2, grava num arquivo e entrega ao piloto pelo compartilhar
/// do sistema. No Chrome, onde não há arquivo, vai o texto.
class EnviarCadernetaArquivo {
  const EnviarCadernetaArquivo({required this.enviar, this.pasta});

  final Enviador enviar;

  /// Pasta de teste. No aparelho usa Documents.
  final String? pasta;

  Future<({bool enviado, String? erro})> executar() async {
    final json = await BackupCaderneta.exportar();
    final arquivo = await gravarCadernetaJson(json, pasta: pasta);
    final ok = arquivo.caminho != null
        ? await enviar(caminho: arquivo.caminho)
        : await enviar(json: json);
    if (!ok) {
      return (
        enviado: false,
        erro: 'Este aparelho não abriu o compartilhar. Use Copiar backup.',
      );
    }
    return (enviado: true, erro: null);
  }
}
