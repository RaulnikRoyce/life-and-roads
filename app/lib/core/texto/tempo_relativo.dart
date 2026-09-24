/// "agora", "há 5 min", "há 3 h", "ontem", "há 4 dias". Usado pelo backup
/// em Download e pela caderneta na nuvem para dizer quando guardaram.
String haQuanto(DateTime d, {DateTime? agora}) {
  final ate = agora ?? DateTime.now();
  final minutos = ate.difference(d).inMinutes;
  if (minutos < 1) return 'agora';
  if (minutos < 60) return 'há $minutos min';
  final horas = ate.difference(d).inHours;
  if (horas < 24) return 'há $horas h';
  final dias = ate.difference(d).inDays;
  return dias == 1 ? 'ontem' : 'há $dias dias';
}
