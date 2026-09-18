import 'package:latlong2/latlong.dart';
import 'package:life_and_roads/features/mapa/domain/usecases/links_do_ponto.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

const _links = LinksDoPonto();

/// Entrega o ponto ao app de mapas do piloto. Tenta `geo:`; sem app que
/// atenda (Chrome), abre o Google Maps no navegador. False se nada abriu.
Future<bool> abrirNoAppDeMapas(LatLng ponto, {String? rotulo}) async {
  final geo = _links.navegacao(ponto, rotulo: rotulo);
  if (await canLaunchUrl(geo)) {
    return launchUrl(geo, mode: LaunchMode.externalApplication);
  }
  return launchUrl(
    _links.navegacaoWeb(ponto),
    mode: LaunchMode.externalApplication,
  );
}

/// Abre o compartilhar do sistema com o link do ponto.
Future<bool> compartilharOndeEstou(LatLng ponto) async {
  final r = await SharePlus.instance.share(
    ShareParams(text: _links.ondeEstou(ponto), subject: 'Onde estou'),
  );
  return r.status != ShareResultStatus.unavailable;
}
