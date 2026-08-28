import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:life_and_roads/features/manutencao/data/avisos_lidos_datasource.dart';
import 'package:life_and_roads/features/manutencao/domain/manutencao_repository.dart';
import 'package:life_and_roads/features/manutencao/domain/usecases/montar_avisos_caderneta.dart';
import 'package:life_and_roads/features/manutencao/presentation/avisos_estado.dart';
import 'package:life_and_roads/features/manutencao/presentation/manutencao_controller.dart';
import 'package:life_and_roads/manutencao/lembrete.dart';

final avisosLidosDatasourceProvider = Provider<AvisosLidosDatasource>(
  (_) => AvisosLidosDatasource(),
);

class AvisosController extends Notifier<AvisosEstado> {
  ManutencaoRepository get _repo => ref.read(manutencaoRepositoryProvider);
  AvisosLidosDatasource get _lidos => ref.read(avisosLidosDatasourceProvider);
  static const _montar = MontarAvisosCaderneta();

  @override
  AvisosEstado build() => const AvisosEstado();

  Future<void> recarregar({bool dispararSistema = false}) async {
    final c = await _repo.carregar();
    final avisos = _montar.executar(
      agenda: c.agenda,
      extra: c.extra,
      kmAtual: c.kmAtual,
    );
    final lidos = await _lidos.ler();
    var permissaoNegada = false;
    if (dispararSistema) {
      final cnhIso = (c.extra.cnhProxima ?? '').trim();
      final cnh = cnhIso.length < 10
          ? null
          : DateTime.tryParse(cnhIso.substring(0, 10));
      final r = await agendarLembretes(
        oleo: c.agenda.oleoProxima,
        pneus: c.agenda.pneusProxima,
        ipva: c.agenda.ipvaProxima,
        seguro: c.agenda.seguroProxima,
        licenciamento: c.agenda.licenciamentoProxima,
        cnh: cnh,
        kmAtrasados: avisos.where((a) => a.atrasado && a.porKm).toList(),
        dispararKmAgora: true,
      );
      permissaoNegada = r == ResultadoLembrete.permissaoNegada;
    }
    state = AvisosEstado(
      avisos: avisos,
      lidos: lidos,
      permissaoNegada: permissaoNegada,
    );
  }

  Future<void> marcarLido(String id) async {
    final juntos = {...state.lidos, id};
    await _lidos.gravar(juntos);
    state = state.copiarCom(lidos: juntos);
  }

  Future<void> marcarTodos() async {
    final juntos = {for (final a in state.avisos) a.id, ...state.lidos};
    await _lidos.gravar(juntos);
    state = state.copiarCom(lidos: juntos);
  }
}

final avisosControllerProvider =
    NotifierProvider<AvisosController, AvisosEstado>(AvisosController.new);
