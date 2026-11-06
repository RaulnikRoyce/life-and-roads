class NumeroVersao {
  const NumeroVersao(this.major, this.minor, this.patch, {this.previa = false});
  final int major, minor, patch;
  final bool previa;

  static NumeroVersao? ler(String texto) {
    final m = RegExp(
      r'^v?(0|[1-9]\d*)\.(0|[1-9]\d*)\.(0|[1-9]\d*)(?:-([0-9A-Za-z-]+(?:\.[0-9A-Za-z-]+)*))?(?:\+[0-9A-Za-z-]+(?:\.[0-9A-Za-z-]+)*)?$',
    ).firstMatch(texto.trim());
    if (m == null) return null;
    final partes = [for (var i = 1; i <= 3; i++) int.tryParse(m.group(i)!)];
    if (partes.any((n) => n == null)) return null;
    return NumeroVersao(
      partes[0]!,
      partes[1]!,
      partes[2]!,
      previa: m.group(4) != null,
    );
  }

  bool maisNovaQue(NumeroVersao outra) {
    for (final (a, b) in [
      (major, outra.major),
      (minor, outra.minor),
      (patch, outra.patch),
    ]) {
      if (a != b) return a > b;
    }
    return !previa && outra.previa;
  }
}

class VersaoInstalada {
  const VersaoInstalada(this.versao, this.build);
  final String versao, build;
  String get descricao => build.isEmpty ? versao : '$versao (build $build)';
}

class VersaoPublicada {
  const VersaoPublicada({required this.tag, required this.numero, this.apk});
  final String tag;
  final NumeroVersao numero;
  final Uri? apk;
  String get versao => tag.startsWith('v') ? tag.substring(1) : tag;

  static VersaoPublicada deJson(Object? bruto) {
    if (bruto is! Map ||
        bruto['draft'] != false ||
        bruto['prerelease'] != false) {
      throw const FormatException('Release estável inválida.');
    }
    final tag = bruto['tag_name'];
    final numero = tag is String ? NumeroVersao.ler(tag) : null;
    if (numero == null || numero.previa) {
      throw const FormatException('Versão publicada inválida.');
    }
    Uri? apk;
    final assets = bruto['assets'];
    if (assets is List) {
      for (final a in assets) {
        if (a is! Map ||
            a['name'] != 'life-and-roads-beta-aberto.apk' ||
            a['state'] != 'uploaded' ||
            a['size'] is! num ||
            !((a['size'] as num) > 0)) {
          continue;
        }
        final url = a['browser_download_url'];
        final uri = url is String ? Uri.tryParse(url) : null;
        if (uri != null &&
            uri.scheme == 'https' &&
            uri.host == 'github.com' &&
            uri.port == 443 &&
            uri.userInfo.isEmpty &&
            !uri.hasQuery &&
            !uri.hasFragment &&
            uri.pathSegments.join('/') ==
                'RaulnikRoyce/life-and-roads/releases/download/$tag/life-and-roads-beta-aberto.apk') {
          apk = uri;
          break;
        }
      }
    }
    return VersaoPublicada(tag: tag as String, numero: numero, apk: apk);
  }
}
