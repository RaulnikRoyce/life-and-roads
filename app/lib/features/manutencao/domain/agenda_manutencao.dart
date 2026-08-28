import 'package:life_and_roads/manutencao/regras.dart';

/// Datas da oficina e da papelada que a API replica (sem km, CNH nem serviço).
class AgendaManutencao {
  const AgendaManutencao({
    this.oleoUltima,
    this.oleoProxima,
    this.revisaoUltima,
    this.pneusUltima,
    this.pneusProxima,
    this.ipvaProxima,
    this.seguroProxima,
    this.licenciamentoProxima,
  });

  final DateTime? oleoUltima;
  final DateTime? oleoProxima;
  final DateTime? revisaoUltima;
  final DateTime? pneusUltima;
  final DateTime? pneusProxima;
  final DateTime? ipvaProxima;
  final DateTime? seguroProxima;
  final DateTime? licenciamentoProxima;

  bool get vazia =>
      oleoUltima == null &&
      oleoProxima == null &&
      revisaoUltima == null &&
      pneusUltima == null &&
      pneusProxima == null &&
      ipvaProxima == null &&
      seguroProxima == null &&
      licenciamentoProxima == null;

  /// `null` se a ordem das datas estiver ok.
  String? tentar() {
    if (oleoUltima != null &&
        oleoProxima != null &&
        oleoProxima!.isBefore(oleoUltima!)) {
      return 'Próximo óleo não pode ser antes da última troca.';
    }
    if (pneusUltima != null &&
        pneusProxima != null &&
        pneusProxima!.isBefore(pneusUltima!)) {
      return 'Próximos pneus não podem ser antes da última troca.';
    }
    return null;
  }

  AgendaManutencao normalizarAnuais({DateTime? hoje}) {
    return copiarCom(
      ipvaProxima:
          ipvaProxima == null ? null : proximaAnual(ipvaProxima!, hoje: hoje),
      seguroProxima: seguroProxima == null
          ? null
          : proximaAnual(seguroProxima!, hoje: hoje),
      licenciamentoProxima: licenciamentoProxima == null
          ? null
          : proximaAnual(licenciamentoProxima!, hoje: hoje),
    );
  }

  AgendaManutencao copiarCom({
    DateTime? oleoUltima,
    bool limparOleoUltima = false,
    DateTime? oleoProxima,
    bool limparOleoProxima = false,
    DateTime? revisaoUltima,
    bool limparRevisao = false,
    DateTime? pneusUltima,
    bool limparPneusUltima = false,
    DateTime? pneusProxima,
    bool limparPneusProxima = false,
    DateTime? ipvaProxima,
    bool limparIpva = false,
    DateTime? seguroProxima,
    bool limparSeguro = false,
    DateTime? licenciamentoProxima,
    bool limparLicenciamento = false,
  }) {
    return AgendaManutencao(
      oleoUltima: limparOleoUltima ? null : (oleoUltima ?? this.oleoUltima),
      oleoProxima: limparOleoProxima ? null : (oleoProxima ?? this.oleoProxima),
      revisaoUltima:
          limparRevisao ? null : (revisaoUltima ?? this.revisaoUltima),
      pneusUltima:
          limparPneusUltima ? null : (pneusUltima ?? this.pneusUltima),
      pneusProxima:
          limparPneusProxima ? null : (pneusProxima ?? this.pneusProxima),
      ipvaProxima: limparIpva ? null : (ipvaProxima ?? this.ipvaProxima),
      seguroProxima:
          limparSeguro ? null : (seguroProxima ?? this.seguroProxima),
      licenciamentoProxima: limparLicenciamento
          ? null
          : (licenciamentoProxima ?? this.licenciamentoProxima),
    );
  }
}
