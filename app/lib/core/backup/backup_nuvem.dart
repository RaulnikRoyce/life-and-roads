import 'dart:async';
import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:life_and_roads/api.dart';
import 'package:life_and_roads/backup.dart';
import 'package:life_and_roads/core/database/armazem_kv.dart';
import 'package:life_and_roads/core/database/chaves_kv.dart';
import 'package:life_and_roads/core/legal/textos.dart';
import 'package:life_and_roads/core/security/sessao_segura.dart';

/// O que o envio para a nuvem lembra neste aparelho. Tudo na tabela KV.
class EstadoNuvem {
  const EstadoNuvem();

  Future<bool> ligada() async =>
      await ArmazemKv.lerTexto(ChavesKv.nuvemLigada) != 'nao';

  Future<void> ligar(bool sim) =>
      ArmazemKv.gravarTexto(ChavesKv.nuvemLigada, sim ? null : 'nao');

  Future<String?> termosAceitos() => ArmazemKv.lerTexto(ChavesKv.termosAceitos);

  Future<void> gravarTermosAceitos(String? versao) =>
      ArmazemKv.gravarTexto(ChavesKv.termosAceitos, versao);

  /// O `atualizadoEm` da última gravação conhecida, como o servidor mandou.
  Future<String?> carimbo() => ArmazemKv.lerTexto(ChavesKv.nuvemCarimbo);

  Future<String?> assinatura() => ArmazemKv.lerTexto(ChavesKv.nuvemAssinatura);

  Future<bool> emConflito() async =>
      await ArmazemKv.lerTexto(ChavesKv.nuvemConflito) == 'sim';

  /// Aparelho e nuvem iguais: depois de mandar ou de restaurar.
  Future<void> marcarIgual({
    required String carimbo,
    required String assinatura,
  }) async {
    await ArmazemKv.gravarTexto(ChavesKv.nuvemCarimbo, carimbo);
    await ArmazemKv.gravarTexto(ChavesKv.nuvemAssinatura, assinatura);
    await ArmazemKv.gravarTexto(ChavesKv.nuvemConflito, null);
  }

  Future<void> marcarConflito() =>
      ArmazemKv.gravarTexto(ChavesKv.nuvemConflito, 'sim');

  Future<void> limparConflito() =>
      ArmazemKv.gravarTexto(ChavesKv.nuvemConflito, null);

  /// O piloto escolheu mandar o deste aparelho por cima da nuvem. Assume o
  /// carimbo que está lá, e o próximo envio sobe mesmo sem mudança nova.
  Future<void> adotarCarimbo(String carimbo) async {
    await ArmazemKv.gravarTexto(ChavesKv.nuvemCarimbo, carimbo);
    await ArmazemKv.gravarTexto(ChavesKv.nuvemAssinatura, null);
    await ArmazemKv.gravarTexto(ChavesKv.nuvemConflito, null);
  }

  /// Interruptor desligado e cópia da conta apagada. Religar começa do
  /// zero, como a primeira vez.
  Future<void> desligar() async {
    await ligar(false);
    await ArmazemKv.gravarTexto(ChavesKv.nuvemCarimbo, null);
    await ArmazemKv.gravarTexto(ChavesKv.nuvemAssinatura, null);
    await ArmazemKv.gravarTexto(ChavesKv.nuvemConflito, null);
  }

  /// Saiu da conta: carimbo, assinatura, conflito e aceite eram dela. O
  /// interruptor fica, porque desligar foi escolha da pessoa neste aparelho.
  Future<void> esquecerConta() async {
    await ArmazemKv.gravarTexto(ChavesKv.nuvemCarimbo, null);
    await ArmazemKv.gravarTexto(ChavesKv.nuvemAssinatura, null);
    await ArmazemKv.gravarTexto(ChavesKv.nuvemConflito, null);
    await ArmazemKv.gravarTexto(ChavesKv.termosAceitos, null);
  }
}

enum ResultadoNuvem {
  /// Subiu, e o carimbo novo está guardado.
  enviada,

  /// A nuvem já tem exatamente isto.
  semMudanca,

  /// Outro aparelho gravou antes. Nada sobe até o piloto escolher.
  conflito,

  /// Sem rede, API fora ou erro dela. Tenta de novo na próxima mudança.
  falhou,

  /// Sem conta, desligada, sem o aceite atual ou com conflito pendente.
  parada,

  /// Já havia um envio no ar. Este pedido vai junto, logo depois dele.
  emAndamento,
}

typedef EnviarCaderneta = Future<String> Function(
  String token,
  Map<String, dynamic> conteudo, {
  required String? carimboBase,
});

/// Manda a caderneta para a conta sozinho, sem pressa (ADR 0038).
///
/// Espera [espera] sem mudança nova antes de mandar, para uma tarde de
/// lançamentos virar um envio só, e manda na hora quando o app vai para
/// segundo plano. Falha em silêncio, como o backup em Download: sem rede,
/// tenta de novo na próxima mudança ou na próxima abertura.
///
/// Nada sobe sem conta, com o interruptor desligado, sem o aceite da versão
/// atual dos termos, ou com um conflito esperando o piloto decidir.
class BackupNuvem {
  BackupNuvem({
    this.estado = const EstadoNuvem(),
    Future<Map<String, dynamic>> Function()? exportar,
    Future<String?> Function()? lerToken,
    EnviarCaderneta? enviar,
    this.espera = const Duration(minutes: 2),
    this.versaoTermosAtual = versaoTermos,
  }) : _exportar = exportar ?? BackupCaderneta.exportarParaNuvem,
       _lerToken = lerToken ?? SessaoSegura().lerToken,
       _enviar = enviar ?? ApiCaderneta.salvarCaderneta;

  final EstadoNuvem estado;
  final Future<Map<String, dynamic>> Function() _exportar;
  final Future<String?> Function() _lerToken;
  final EnviarCaderneta _enviar;
  final Duration espera;
  final String versaoTermosAtual;

  /// O carimbo da última gravação que este aparelho fez ou recebeu, para a
  /// tela trocar "guardada há 5 min" sem reabrir o app.
  final ultimo = ValueNotifier<String?>(null);

  /// Vira true quando um envio por trás recebe 409, para a tela perguntar
  /// sem esperar a próxima abertura.
  final conflito = ValueNotifier<bool>(false);

  Timer? _timer;
  bool _enviando = false;
  bool _deNovo = false;

  /// sha256 do pacote. Mesma caderneta, mesma assinatura.
  static String assinar(Map<String, dynamic> conteudo) =>
      sha256.convert(utf8.encode(jsonEncode(conteudo))).toString();

  /// Marca que a caderneta mudou. Várias chamadas seguidas viram uma só.
  void agendar() {
    _timer?.cancel();
    _timer = Timer(espera, () => unawaited(enviarAgora()));
  }

  bool get pendente => _timer?.isActive ?? false;

  /// O app foi para segundo plano: manda o que estava esperando.
  Future<void> enviarSePendente() async {
    if (!pendente) return;
    _timer?.cancel();
    await enviarAgora();
  }

  Future<ResultadoNuvem> enviarAgora() async {
    if (_enviando) {
      // Mudou de novo durante o envio. Manda outra vez ao terminar.
      _deNovo = true;
      return ResultadoNuvem.emAndamento;
    }
    _enviando = true;
    try {
      var resultado = await _enviarUmaVez();
      while (_deNovo && resultado != ResultadoNuvem.conflito) {
        _deNovo = false;
        resultado = await _enviarUmaVez();
      }
      return resultado;
    } finally {
      _enviando = false;
      _deNovo = false;
    }
  }

  Future<ResultadoNuvem> _enviarUmaVez() async {
    try {
      final token = await _lerToken();
      if (token == null || token.isEmpty) return ResultadoNuvem.parada;
      if (!await estado.ligada()) return ResultadoNuvem.parada;
      if (await estado.termosAceitos() != versaoTermosAtual) {
        return ResultadoNuvem.parada;
      }
      if (await estado.emConflito()) return ResultadoNuvem.parada;

      final conteudo = await _exportar();
      final assinatura = assinar(conteudo);
      final base = await estado.carimbo();
      if (base != null && assinatura == await estado.assinatura()) {
        return ResultadoNuvem.semMudanca;
      }

      final carimbo = await _enviar(token, conteudo, carimboBase: base);
      await estado.marcarIgual(carimbo: carimbo, assinatura: assinatura);
      ultimo.value = carimbo;
      conflito.value = false;
      return ResultadoNuvem.enviada;
    } on ConflitoNuvem {
      await estado.marcarConflito();
      conflito.value = true;
      return ResultadoNuvem.conflito;
    } catch (_) {
      return ResultadoNuvem.falhou;
    }
  }

  /// Depois de trazer a caderneta da nuvem para o aparelho. Assina o que
  /// ficou no aparelho, e não o que veio, porque a volta pelo banco pode
  /// mudar a forma dos números sem mudar o dado.
  Future<void> registrarRestaurada(String carimbo) async {
    final assinatura = assinar(await _exportar());
    await estado.marcarIgual(carimbo: carimbo, assinatura: assinatura);
    ultimo.value = carimbo;
    conflito.value = false;
  }

  /// Os dois lados já têm o mesmo conteúdo: guarda o carimbo da nuvem e a
  /// assinatura do aparelho, sem mandar nem trazer nada.
  Future<void> adotarIgual(String carimbo) => registrarRestaurada(carimbo);

  /// Interruptor desligado. Para o que estava esperando.
  Future<void> desligar() async {
    _timer?.cancel();
    _timer = null;
    await estado.desligar();
    ultimo.value = null;
    conflito.value = false;
  }

  /// Saiu da conta ou apagou a conta.
  Future<void> esquecerConta() async {
    _timer?.cancel();
    _timer = null;
    await estado.esquecerConta();
    ultimo.value = null;
    conflito.value = false;
  }

  void descartar() {
    _timer?.cancel();
    _timer = null;
    ultimo.dispose();
    conflito.dispose();
  }
}

/// Um só para o app inteiro: a espera junta as rajadas de salvar.
final backupNuvemProvider = Provider<BackupNuvem>((ref) {
  final b = BackupNuvem();
  ref.onDispose(b.descartar);
  return b;
});
