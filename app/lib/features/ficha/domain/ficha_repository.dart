import 'package:life_and_roads/core/sync/status_sync.dart';
import 'package:life_and_roads/features/auth/domain/sessao.dart';
import 'package:life_and_roads/features/ficha/domain/ficha_moto.dart';

class FichaCarregada {
  const FichaCarregada({
    required this.sessao,
    this.ficha,
    this.remoto,
    this.offline = false,
    this.sync = const MetadadoSync(),
  });

  final Sessao sessao;
  final FichaMoto? ficha;
  final FichaMoto? remoto;
  final bool offline;
  final MetadadoSync sync;
}

class FichaSalva {
  const FichaSalva({
    required this.ficha,
    required this.mensagem,
    this.sincronizada = false,
    this.offline = false,
    this.sync = const MetadadoSync(),
  });

  final FichaMoto ficha;
  final String mensagem;
  final bool sincronizada;
  final bool offline;
  final MetadadoSync sync;
}

abstract class FichaRepository {
  /// Só o que está no aparelho, sem tocar na rede. Para a tela abrir na hora.
  Future<FichaCarregada> carregarLocal();

  /// Local + servidor (GET, retry da fila, conflito). Pode demorar.
  Future<FichaCarregada> carregar();
  Future<FichaSalva> salvar(FichaMoto ficha);
  Future<FichaCarregada> manterLocal();
  Future<FichaCarregada> usarRemoto();
}
