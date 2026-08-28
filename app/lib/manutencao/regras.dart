/// Regras locais de manutenção. Data da última intervenção mais o intervalo vira a próxima.
///
/// Permanecem neste aparelho. Sem placa e sem ida e volta com a API.
DateTime soDia(DateTime d) => DateTime(d.year, d.month, d.day);

DateTime acrescentarMeses(DateTime d, int meses) {
  final base = DateTime(d.year, d.month + meses);
  final ultimo = DateTime(base.year, base.month + 1, 0).day;
  final dia = d.day > ultimo ? ultimo : d.day;
  return DateTime(base.year, base.month, dia);
}

/// IPVA, seguro e licenciamento na mesma data no ano seguinte, até ficar no futuro.
DateTime proximaAnual(DateTime data, {DateTime? hoje}) {
  var n = soDia(data);
  final h = soDia(hoje ?? DateTime.now());
  while (n.isBefore(h)) {
    n = DateTime(n.year + 1, n.month, n.day);
  }
  return n;
}

/// CNH soma 10 anos (padrão) ou 5 se o piloto marcar.
DateTime proximaCnh(DateTime vencimento, {required bool cincoAnos, DateTime? hoje}) {
  final passo = cincoAnos ? 5 : 10;
  var n = soDia(vencimento);
  final h = soDia(hoje ?? DateTime.now());
  while (n.isBefore(h)) {
    n = DateTime(n.year + passo, n.month, n.day);
  }
  return n;
}

/// `13/08/26`, `13/08/2026` ou `13-08-26`.
DateTime? parseDataBr(String bruto) {
  final t = bruto.trim();
  final m = RegExp(r'^(\d{1,2})[/\-](\d{1,2})[/\-](\d{2}|\d{4})$').firstMatch(t);
  if (m == null) return null;
  final dia = int.parse(m.group(1)!);
  final mes = int.parse(m.group(2)!);
  var ano = int.parse(m.group(3)!);
  if (ano < 100) ano += 2000;
  if (mes < 1 || mes > 12 || dia < 1 || dia > 31) return null;
  final d = DateTime(ano, mes, dia);
  if (d.month != mes || d.day != dia) return null;
  return d;
}

String dataBr(DateTime d) {
  final dd = d.day.toString().padLeft(2, '0');
  final mm = d.month.toString().padLeft(2, '0');
  return '$dd/$mm/${d.year}';
}
