import 'package:life_and_roads/core/sync/status_sync.dart';
import 'package:life_and_roads/features/ficha/domain/ficha_moto.dart';

class FichaEstado {
  const FichaEstado({
    this.carregando = true,
    this.ficha,
    this.remoto,
    this.token,
    this.email,
    this.servidor = '',
    this.aviso,
    this.erro,
    this.offline = false,
    this.sync = const MetadadoSync(),
  });

  final bool carregando;
  final FichaMoto? ficha;
  final FichaMoto? remoto;
  final String? token;
  final String? email;
  final String servidor;
  final String? aviso;
  final String? erro;
  final bool offline;
  final MetadadoSync sync;

  bool get logado => token != null && token!.isNotEmpty;
  bool get salvo => ficha != null && ficha!.preenchida;
  bool get emConflito => sync.emConflito && remoto != null;

  FichaEstado copiarCom({
    bool? carregando,
    FichaMoto? ficha,
    bool limparFicha = false,
    FichaMoto? remoto,
    bool limparRemoto = false,
    String? token,
    String? email,
    bool limparSessao = false,
    String? servidor,
    String? aviso,
    bool limparAviso = false,
    String? erro,
    bool limparErro = false,
    bool? offline,
    MetadadoSync? sync,
  }) {
    return FichaEstado(
      carregando: carregando ?? this.carregando,
      ficha: limparFicha ? null : (ficha ?? this.ficha),
      remoto: limparRemoto ? null : (remoto ?? this.remoto),
      token: limparSessao ? null : (token ?? this.token),
      email: limparSessao ? null : (email ?? this.email),
      servidor: servidor ?? this.servidor,
      aviso: limparAviso ? null : (aviso ?? this.aviso),
      erro: limparErro ? null : (erro ?? this.erro),
      offline: offline ?? this.offline,
      sync: sync ?? this.sync,
    );
  }
}
