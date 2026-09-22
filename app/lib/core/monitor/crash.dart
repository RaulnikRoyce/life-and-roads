import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:life_and_roads/api.dart';
import 'package:life_and_roads/core/config/ambiente.dart';
import 'package:life_and_roads/core/monitor/plataforma.dart';

/// Relato de falha no aparelho. Sem ficha, e-mail ou placa.
void instalarCrashReporting() {
  FlutterError.onError = (details) {
    FlutterError.presentError(details);
    relatar('flutter_error', details.exceptionAsString(), pilha: details.stack);
  };
  PlatformDispatcher.instance.onError = (erro, stack) {
    relatar('flutter_zone', '$erro', pilha: stack);
    return false;
  };
}

void relatar(String tipo, String mensagem, {StackTrace? pilha}) {
  if (!Ambiente.relataCrash) return;
  final texto = mensagem.trim();
  if (texto.isEmpty) return;
  unawaited(
    ApiCaderneta.relatarCrash(
      tipo: tipo,
      mensagem: cortar(texto, 500),
      ambiente: Ambiente.nome,
      versaoApp: Ambiente.versaoApp,
      plataforma: descreverPlataforma(),
      pilha: pilha == null ? null : cortar(pilha.toString(), 2000),
    ),
  );
}

/// Motivo que o piloto escreveu ao dispensar o convite de criar conta.
///
/// Vai pela mesma rota anônima do crash, sem e-mail, sem id e sem nada da
/// caderneta. Falha de rede é ignorada, como no crash.
void relatarRecusaDeConta(String motivo) {
  if (!Ambiente.relataCrash) return;
  relatar('conta_recusada', motivo);
}

/// Limite do contrato (`/monitor/evento`). Corta no fim, mantém o começo,
/// que é onde a pilha diz onde quebrou.
String cortar(String texto, int max) =>
    texto.length > max ? texto.substring(0, max) : texto;
