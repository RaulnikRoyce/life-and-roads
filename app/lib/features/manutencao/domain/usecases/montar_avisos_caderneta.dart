import 'package:life_and_roads/features/manutencao/domain/agenda_manutencao.dart';
import 'package:life_and_roads/features/manutencao/domain/aviso_caderneta.dart';
import 'package:life_and_roads/manutencao/extra.dart';
import 'package:life_and_roads/viagem/calculo.dart';

/// Monta os avisos da oficina a partir da agenda, km e CNH locais.
class MontarAvisosCaderneta {
  const MontarAvisosCaderneta();

  List<AvisoCaderneta> executar({
    required AgendaManutencao agenda,
    required ManutencaoExtra extra,
    required double? kmAtual,
    DateTime? agora,
  }) {
    final hoje = agora ?? DateTime.now();
    final cnh = _iso(extra.cnhProxima);
    return [
      _data('oleo', 'Óleo', agenda.oleoProxima, hoje),
      _km('oleo-km', 'Óleo', extra.oleoKmUltima, extra.oleoKmIntervalo, kmAtual),
      _km(
        'corrente-km',
        'Corrente',
        extra.correnteKmUltima,
        extra.correnteKmIntervalo,
        kmAtual,
      ),
      _data('pneus', 'Pneus', agenda.pneusProxima, hoje),
      _data('ipva', 'IPVA', agenda.ipvaProxima, hoje),
      _data('seguro', 'Seguro', agenda.seguroProxima, hoje),
      _data('licenciamento', 'Licenciamento', agenda.licenciamentoProxima, hoje),
      _data('cnh', 'CNH', cnh, hoje),
    ].whereType<AvisoCaderneta>().toList();
  }

  AvisoCaderneta? _data(
    String id,
    String peca,
    DateTime? proxima,
    DateTime agora,
  ) {
    if (proxima == null) return null;
    final a = DateTime(agora.year, agora.month, agora.day);
    final b = DateTime(proxima.year, proxima.month, proxima.day);
    final d = b.difference(a).inDays;
    if (d < 0) {
      return AvisoCaderneta(
        id: id,
        texto: '$peca atrasado há ${-d} dia(s).',
        atrasado: true,
      );
    }
    if (d == 0) {
      return AvisoCaderneta(
        id: id,
        texto: '$peca vence hoje.',
        atrasado: false,
      );
    }
    if (d <= 14) {
      return AvisoCaderneta(
        id: id,
        texto: '$peca em $d dia(s).',
        atrasado: false,
      );
    }
    return null;
  }

  AvisoCaderneta? _km(
    String id,
    String peca,
    double? ultima,
    double intervalo,
    double? kmAtual,
  ) {
    if (kmAtual == null || ultima == null) return null;
    final proxima = kmDaProximaTroca(kmUltima: ultima, intervaloKm: intervalo);
    if (proxima == null) return null;
    final falta = kmAteATroca(kmAtual: kmAtual, kmProxima: proxima);
    if (falta == null) return null;
    if (falta < 0) {
      return AvisoCaderneta(
        id: id,
        texto: '$peca atrasado ${-falta} km.',
        atrasado: true,
        porKm: true,
      );
    }
    if (falta <= 200) {
      return AvisoCaderneta(
        id: id,
        texto: '$peca em $falta km.',
        atrasado: false,
        porKm: true,
      );
    }
    return null;
  }

  DateTime? _iso(String? valor) {
    final t = (valor ?? '').trim();
    if (t.length < 10) return null;
    return DateTime.tryParse(t.substring(0, 10));
  }
}
