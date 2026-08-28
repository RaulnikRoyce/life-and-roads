import 'package:life_and_roads/features/manutencao/domain/aviso_caderneta.dart';
import 'package:life_and_roads/manutencao/resultado_lembrete.dart';

/// No Chrome não há notificação do sistema. O aviso fica na própria aba.
Future<ResultadoLembrete> agendarLembretes({
  DateTime? oleo,
  DateTime? pneus,
  DateTime? ipva,
  DateTime? seguro,
  DateTime? licenciamento,
  DateTime? cnh,
  List<AvisoCaderneta> kmAtrasados = const [],
  bool dispararKmAgora = false,
}) async {
  return ResultadoLembrete.ok;
}
