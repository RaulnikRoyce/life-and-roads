import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:life_and_roads/api.dart';
import 'package:life_and_roads/core/config/ambiente.dart';

/// Relato de falha no aparelho. Sem ficha, e-mail ou placa.
void instalarCrashReporting() {
  FlutterError.onError = (details) {
    FlutterError.presentError(details);
    relatar('flutter_error', details.exceptionAsString());
  };
  PlatformDispatcher.instance.onError = (erro, stack) {
    relatar('flutter_zone', '$erro');
    return false;
  };
}

void relatar(String tipo, String mensagem) {
  if (!Ambiente.relataCrash) return;
  final texto = mensagem.trim();
  if (texto.isEmpty) return;
  final corte = texto.length > 500 ? texto.substring(0, 500) : texto;
  unawaited(
    ApiCaderneta.relatarCrash(
      tipo: tipo,
      mensagem: corte,
      ambiente: Ambiente.nome,
    ),
  );
}
