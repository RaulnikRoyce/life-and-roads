import 'package:life_and_roads/core/sync/status_sync.dart';
import 'package:life_and_roads/features/manutencao/domain/agenda_manutencao.dart';
import 'package:life_and_roads/manutencao/extra.dart';
import 'package:life_and_roads/manutencao/servicos.dart';

class ManutencaoEstado {
  const ManutencaoEstado({
    this.carregando = true,
    this.agenda = const AgendaManutencao(),
    this.remoto,
    this.extra = const ManutencaoExtra(),
    this.servicos = const [],
    this.kmAtual,
    this.aviso,
    this.erro,
    this.offline = false,
    this.sync = const MetadadoSync(),
  });

  final bool carregando;
  final AgendaManutencao agenda;
  final AgendaManutencao? remoto;
  final ManutencaoExtra extra;
  final List<RegistroServico> servicos;
  final double? kmAtual;
  final String? aviso;
  final String? erro;
  final bool offline;
  final MetadadoSync sync;

  bool get emConflito => sync.emConflito && remoto != null;

  ManutencaoEstado copiarCom({
    bool? carregando,
    AgendaManutencao? agenda,
    AgendaManutencao? remoto,
    bool limparRemoto = false,
    ManutencaoExtra? extra,
    List<RegistroServico>? servicos,
    double? kmAtual,
    bool limparKm = false,
    String? aviso,
    bool limparAviso = false,
    String? erro,
    bool limparErro = false,
    bool? offline,
    MetadadoSync? sync,
  }) {
    return ManutencaoEstado(
      carregando: carregando ?? this.carregando,
      agenda: agenda ?? this.agenda,
      remoto: limparRemoto ? null : (remoto ?? this.remoto),
      extra: extra ?? this.extra,
      servicos: servicos ?? this.servicos,
      kmAtual: limparKm ? null : (kmAtual ?? this.kmAtual),
      aviso: limparAviso ? null : (aviso ?? this.aviso),
      erro: limparErro ? null : (erro ?? this.erro),
      offline: offline ?? this.offline,
      sync: sync ?? this.sync,
    );
  }
}
