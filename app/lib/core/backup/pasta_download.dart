import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Grava um arquivo na pasta Download do aparelho, sempre com o mesmo nome.
///
/// O lado Android usa a MediaStore, que é o caminho sancionado desde o
/// Android 10 para escrever em Download sem pedir permissão. Fora do
/// Android não existe pasta equivalente, então devolve null e quem chamou
/// segue a vida.
class PastaDownload {
  const PastaDownload();

  static const canal = MethodChannel('life_and_roads/download');

  /// Se este aparelho tem pasta Download para gravar sozinho.
  ///
  /// A tela lê isto para não prometer ao piloto de iPhone uma cópia que só
  /// acontece no Android.
  static bool get disponivel =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  /// Devolve o caminho visível ao piloto, ou null quando não deu.
  Future<String?> salvar({
    required String nome,
    required String conteudo,
  }) async {
    if (!disponivel) return null;
    try {
      return await canal.invokeMethod<String>('salvar', {
        'nome': nome,
        'conteudo': conteudo,
      });
    } on PlatformException {
      return null;
    } on MissingPluginException {
      // Versão antiga do app sem o canal, ou teste sem o lado nativo.
      return null;
    }
  }
}
