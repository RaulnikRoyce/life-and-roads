import 'package:life_and_roads/features/manutencao/domain/agenda_manutencao.dart';

/// Compara as datas que sobem à API (sem km, CNH nem serviço).
class DetectarConflitoAgenda {
  bool executar(AgendaManutencao local, AgendaManutencao remota) {
    return !_mesmoDia(local.oleoUltima, remota.oleoUltima) ||
        !_mesmoDia(local.oleoProxima, remota.oleoProxima) ||
        !_mesmoDia(local.revisaoUltima, remota.revisaoUltima) ||
        !_mesmoDia(local.pneusUltima, remota.pneusUltima) ||
        !_mesmoDia(local.pneusProxima, remota.pneusProxima) ||
        !_mesmoDia(local.ipvaProxima, remota.ipvaProxima) ||
        !_mesmoDia(local.seguroProxima, remota.seguroProxima) ||
        !_mesmoDia(local.licenciamentoProxima, remota.licenciamentoProxima);
  }

  static bool _mesmoDia(DateTime? a, DateTime? b) {
    if (a == null && b == null) return true;
    if (a == null || b == null) return false;
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }
}
