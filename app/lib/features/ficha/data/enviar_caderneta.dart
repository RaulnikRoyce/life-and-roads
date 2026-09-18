import 'package:share_plus/share_plus.dart';

/// Abre o "compartilhar" do sistema com o arquivo da caderneta.
///
/// O piloto escolhe o destino (Drive, WhatsApp, Arquivos). Nada sai do
/// aparelho sem ele apertar. Sem caminho (Chrome), envia o JSON como texto.
Future<bool> enviarCaderneta({String? caminho, String? json}) async {
  final ShareResult r;
  if (caminho != null) {
    r = await SharePlus.instance.share(
      ShareParams(
        files: [XFile(caminho, mimeType: 'application/json')],
        subject: 'Backup life.and.roads',
        text: 'Backup da caderneta life.and.roads.',
      ),
    );
  } else if (json != null) {
    r = await SharePlus.instance.share(
      ShareParams(text: json, subject: 'Backup life.and.roads'),
    );
  } else {
    return false;
  }
  return r.status != ShareResultStatus.unavailable;
}
