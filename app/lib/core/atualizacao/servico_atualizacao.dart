import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:life_and_roads/core/atualizacao/versao_app.dart';

abstract class FonteAtualizacao {
  Future<VersaoInstalada> instalada();
  Future<VersaoPublicada> publicada();
  Future<bool> abrir(Uri apk);
}

class ServicoAtualizacao implements FonteAtualizacao {
  ServicoAtualizacao({
    http.Client Function()? criarCliente,
    this.tempoLimite = const Duration(seconds: 8),
  }) : _criarCliente = criarCliente ?? http.Client.new;
  final http.Client Function() _criarCliente;
  final Duration tempoLimite;
  static final endpoint = Uri.https(
    'api.github.com',
    '/repos/RaulnikRoyce/life-and-roads/releases/latest',
  );

  @override
  Future<VersaoInstalada> instalada() async {
    final info = await PackageInfo.fromPlatform();
    return VersaoInstalada(info.version, info.buildNumber);
  }

  @override
  Future<VersaoPublicada> publicada() async {
    // Cliente próprio: a conta e os tokens do app não participam da consulta.
    final client = _criarCliente();
    try {
      final resposta = await client
          .get(
            endpoint,
            headers: {
              'Accept': 'application/vnd.github+json',
              'User-Agent': 'life-and-roads',
            },
          )
          .timeout(tempoLimite);
      if (resposta.statusCode != 200) {
        throw StateError('Consulta de atualização indisponível.');
      }
      return VersaoPublicada.deJson(jsonDecode(resposta.body));
    } finally {
      client.close();
    }
  }

  @override
  Future<bool> abrir(Uri apk) =>
      launchUrl(apk, mode: LaunchMode.externalApplication);
}
