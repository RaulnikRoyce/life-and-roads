import 'package:life_and_roads/core/sync/status_sync.dart';
import 'package:life_and_roads/features/manutencao/domain/agenda_manutencao.dart';
import 'package:life_and_roads/manutencao/extra.dart';
import 'package:life_and_roads/manutencao/servicos.dart';

class ManutencaoCarregada {
  const ManutencaoCarregada({
    required this.agenda,
    required this.extra,
    required this.servicos,
    this.remoto,
    this.kmAtual,
    this.offline = false,
    this.sync = const MetadadoSync(),
  });

  final AgendaManutencao agenda;
  final AgendaManutencao? remoto;
  final ManutencaoExtra extra;
  final List<RegistroServico> servicos;
  final double? kmAtual;
  final bool offline;
  final MetadadoSync sync;
}

class ManutencaoSalva {
  const ManutencaoSalva({
    required this.agenda,
    required this.extra,
    required this.mensagem,
    this.sincronizada = false,
    this.offline = false,
    this.sync = const MetadadoSync(),
  });

  final AgendaManutencao agenda;
  final ManutencaoExtra extra;
  final String mensagem;
  final bool sincronizada;
  final bool offline;
  final MetadadoSync sync;
}

abstract class ManutencaoRepository {
  Future<ManutencaoCarregada> carregar();
  Future<double?> lerKmDaFicha();
  Future<ManutencaoSalva> salvar(AgendaManutencao agenda, ManutencaoExtra extra);
  Future<List<RegistroServico>> acrescentarServico(RegistroServico registro);
  Future<ManutencaoCarregada> manterLocal();
  Future<ManutencaoCarregada> usarRemoto();
}
