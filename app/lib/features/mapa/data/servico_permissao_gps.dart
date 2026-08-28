import 'package:geolocator/geolocator.dart';
import 'package:life_and_roads/core/permissoes/mensagens_permissao.dart';

/// GPS deste aparelho. A tela só mostra o texto; o plugin fica aqui.
abstract class ConsultaPermissaoGps {
  Future<String?> recusar({required bool web});
}

class ServicoPermissaoGps implements ConsultaPermissaoGps {
  @override
  Future<String?> recusar({required bool web}) async {
    final ligado = await Geolocator.isLocationServiceEnabled();
    if (!ligado) return MensagensPermissao.gpsDesligado(web: web);

    var perm = await Geolocator.checkPermission();
    if (perm == LocationPermission.denied) {
      perm = await Geolocator.requestPermission();
    }
    if (perm == LocationPermission.denied ||
        perm == LocationPermission.deniedForever) {
      return MensagensPermissao.gpsNegada(web: web);
    }
    return null;
  }
}
