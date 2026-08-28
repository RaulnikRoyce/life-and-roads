import 'dart:typed_data';

import 'package:life_and_roads/core/database/armazem_kv.dart';
import 'package:life_and_roads/core/database/chaves_kv.dart';

/// Uma foto da moto, neste aparelho. Sem placa no arquivo.
class FotoMoto {
  static const chave = ChavesKv.foto;

  static Future<Uint8List?> carregar() => ArmazemKv.lerBlob(chave);

  static Future<void> salvar(Uint8List bytes) =>
      ArmazemKv.gravarBlob(chave, bytes);

  static Future<void> apagar() => ArmazemKv.gravarBlob(chave, null);
}
