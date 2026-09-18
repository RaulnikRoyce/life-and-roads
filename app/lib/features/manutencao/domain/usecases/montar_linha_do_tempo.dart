import 'package:life_and_roads/features/manutencao/domain/agenda_manutencao.dart';
import 'package:life_and_roads/manutencao/extra.dart';
import 'package:life_and_roads/manutencao/regras.dart';
import 'package:life_and_roads/viagem/calculo.dart';

enum EstadoItem { emDia, atencao, atrasado }

/// Um vencimento na linha do tempo da oficina.
class ItemLinhaDoTempo {
  const ItemLinhaDoTempo({
    required this.id,
    required this.titulo,
    required this.detalhe,
    required this.fracao,
    required this.estado,
    required this.ordem,
    this.porKm = false,
  });

  final String id;
  final String titulo;

  /// "12/03/27, em 40 dias" ou "em 1.500 km".
  final String detalhe;

  /// Quanto do intervalo já passou, de 0 a 1 (1 = venceu).
  final double fracao;
  final EstadoItem estado;

  /// Para ordenar: dias ou km que faltam (negativo = atrasado).
  final double ordem;
  final bool porKm;
}

/// Transforma agenda, km e CNH em itens ordenados do mais urgente ao mais
/// folgado, cada um com a fração do intervalo consumida (para a barra).
///
/// Sem "última", assume intervalo de um ano para a papelada (IPVA, seguro,
/// licenciamento) e seis meses para óleo e pneus.
class MontarLinhaDoTempo {
  const MontarLinhaDoTempo();

  static const _diasAtencao = 14;
  static const _kmAtencao = 200;

  List<ItemLinhaDoTempo> executar({
    required AgendaManutencao agenda,
    required ManutencaoExtra extra,
    required double? kmAtual,
    DateTime? agora,
  }) {
    final hoje = _dia(agora ?? DateTime.now());
    final itens = <ItemLinhaDoTempo>[
      ?_porData(
        'oleo',
        'Óleo',
        agenda.oleoUltima,
        agenda.oleoProxima,
        hoje,
        182,
      ),
      ?_porKm(
        'oleo-km',
        'Óleo por km',
        extra.oleoKmUltima,
        extra.oleoKmIntervalo,
        kmAtual,
      ),
      ?_porKm(
        'corrente-km',
        'Corrente',
        extra.correnteKmUltima,
        extra.correnteKmIntervalo,
        kmAtual,
      ),
      ?_porData(
        'pneus',
        'Pneus',
        agenda.pneusUltima,
        agenda.pneusProxima,
        hoje,
        365,
      ),
      ?_porData('ipva', 'IPVA', null, agenda.ipvaProxima, hoje, 365),
      ?_porData('seguro', 'Seguro', null, agenda.seguroProxima, hoje, 365),
      ?_porData(
        'licenciamento',
        'Licenciamento',
        null,
        agenda.licenciamentoProxima,
        hoje,
        365,
      ),
      ?_porData('cnh', 'CNH', null, _iso(extra.cnhProxima), hoje, 365 * 5),
    ];
    itens.sort((a, b) => a.ordem.compareTo(b.ordem));
    return itens;
  }

  ItemLinhaDoTempo? _porData(
    String id,
    String titulo,
    DateTime? ultima,
    DateTime? proxima,
    DateTime hoje,
    int intervaloPadraoDias,
  ) {
    if (proxima == null) return null;
    final fim = _dia(proxima);
    final dias = fim.difference(hoje).inDays;
    final inicio = ultima == null
        ? fim.subtract(Duration(days: intervaloPadraoDias))
        : _dia(ultima);
    final total = fim.difference(inicio).inDays;
    final passado = hoje.difference(inicio).inDays;
    final fracao = total <= 0 ? 1.0 : (passado / total).clamp(0.0, 1.0);
    final quando = dias < 0
        ? 'atrasado há ${-dias} dia${-dias == 1 ? '' : 's'}'
        : dias == 0
        ? 'vence hoje'
        : 'em $dias dia${dias == 1 ? '' : 's'}';
    return ItemLinhaDoTempo(
      id: id,
      titulo: titulo,
      detalhe: '${dataBr(fim)}, $quando',
      fracao: fracao,
      estado: dias < 0
          ? EstadoItem.atrasado
          : dias <= _diasAtencao
          ? EstadoItem.atencao
          : EstadoItem.emDia,
      ordem: dias.toDouble(),
    );
  }

  ItemLinhaDoTempo? _porKm(
    String id,
    String titulo,
    double? ultima,
    double intervalo,
    double? kmAtual,
  ) {
    if (kmAtual == null || ultima == null || intervalo <= 0) return null;
    final proxima = kmDaProximaTroca(kmUltima: ultima, intervaloKm: intervalo);
    if (proxima == null) return null;
    final falta = kmAteATroca(kmAtual: kmAtual, kmProxima: proxima);
    if (falta == null) return null;
    final fracao = ((kmAtual - ultima) / intervalo).clamp(0.0, 1.0);
    final quando = falta < 0
        ? 'atrasado ${_milhar(-falta)} km'
        : 'em ${_milhar(falta)} km';
    return ItemLinhaDoTempo(
      id: id,
      titulo: titulo,
      detalhe: 'troca aos ${_milhar(proxima.round())} km, $quando',
      fracao: fracao,
      estado: falta < 0
          ? EstadoItem.atrasado
          : falta <= _kmAtencao
          ? EstadoItem.atencao
          : EstadoItem.emDia,
      // Km e dias na mesma régua: ~50 km por dia de uso.
      ordem: falta / 50,
      porKm: true,
    );
  }

  static DateTime _dia(DateTime d) => DateTime(d.year, d.month, d.day);

  static DateTime? _iso(String? valor) {
    final t = (valor ?? '').trim();
    if (t.length < 10) return null;
    return DateTime.tryParse(t.substring(0, 10));
  }

  static String _milhar(num v) {
    final n = v.round().toString();
    final b = StringBuffer();
    for (var i = 0; i < n.length; i++) {
      final resto = n.length - i;
      b.write(n[i]);
      if (resto > 1 && resto % 3 == 1) b.write('.');
    }
    return b.toString();
  }
}
