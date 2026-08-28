import 'package:life_and_roads/features/manutencao/domain/agenda_manutencao.dart';

/// Conversão exclusiva para JSON local (`manutencao_v1`) e payload da API.
class AgendaManutencaoModel {
  static AgendaManutencao fromJson(Map<String, dynamic> mapa) {
    return AgendaManutencao(
      oleoUltima: deIso(mapa['oleoUltima']),
      oleoProxima: deIso(mapa['oleoProxima']),
      revisaoUltima: deIso(mapa['revisaoUltima']),
      pneusUltima: deIso(mapa['pneusUltima']),
      pneusProxima: deIso(mapa['pneusProxima']),
      ipvaProxima: deIso(mapa['ipvaProxima']),
      seguroProxima: deIso(mapa['seguroProxima']),
      licenciamentoProxima: deIso(mapa['licenciamentoProxima']),
    );
  }

  static Map<String, dynamic> toJson(AgendaManutencao agenda) {
    return {
      'oleoUltima': paraIso(agenda.oleoUltima),
      'oleoProxima': paraIso(agenda.oleoProxima),
      'revisaoUltima': paraIso(agenda.revisaoUltima),
      'pneusUltima': paraIso(agenda.pneusUltima),
      'pneusProxima': paraIso(agenda.pneusProxima),
      'ipvaProxima': paraIso(agenda.ipvaProxima),
      'seguroProxima': paraIso(agenda.seguroProxima),
      'licenciamentoProxima': paraIso(agenda.licenciamentoProxima),
    };
  }

  /// Mesmas chaves camelCase que o schema Zod da API.
  static Map<String, dynamic> toApiJson(AgendaManutencao agenda) =>
      toJson(agenda);

  static DateTime? deIso(Object? valor) {
    final t = '${valor ?? ''}'.trim();
    if (t.length < 10) return null;
    return DateTime.tryParse(t.substring(0, 10));
  }

  static String? paraIso(DateTime? d) {
    if (d == null) return null;
    final m = d.month.toString().padLeft(2, '0');
    final dia = d.day.toString().padLeft(2, '0');
    return '${d.year}-$m-$dia';
  }
}
