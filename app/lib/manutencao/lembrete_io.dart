import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:life_and_roads/features/manutencao/domain/aviso_caderneta.dart';
import 'package:life_and_roads/features/manutencao/domain/usecases/montar_horarios_lembrete.dart';
import 'package:life_and_roads/manutencao/resultado_lembrete.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

const _detalhe = NotificationDetails(
  android: AndroidNotificationDetails(
    'manutencao',
    'Manutenção',
    channelDescription: 'Lembrete de óleo, pneus e documentos',
  ),
);

/// Agenda 9h (Brasília). Data passada vira amanhã; semana se falta mais de 7 dias.
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
  try {
    tzdata.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('America/Sao_Paulo'));

    final plugin = FlutterLocalNotificationsPlugin();
    await plugin.initialize(
      const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      ),
    );

    final android = plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (android != null) {
      final ok = await android.requestNotificationsPermission();
      if (ok == false) return ResultadoLembrete.permissaoNegada;
    }

    await plugin.cancelAll();
    final agora = tz.TZDateTime.now(tz.local);
    final disparos = const MontarHorariosLembrete().executar(
      agora: DateTime(
        agora.year,
        agora.month,
        agora.day,
        agora.hour,
        agora.minute,
        agora.second,
      ),
      oleo: oleo,
      pneus: pneus,
      ipva: ipva,
      seguro: seguro,
      licenciamento: licenciamento,
      cnh: cnh,
    );
    for (final d in disparos) {
      await plugin.zonedSchedule(
        d.id,
        d.titulo,
        d.corpo,
        tz.TZDateTime(tz.local, d.quando.year, d.quando.month, d.quando.day, 9),
        _detalhe,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      );
    }

    if (dispararKmAgora) {
      var idKm = 21;
      for (final a in kmAtrasados) {
        await plugin.show(idKm, 'Manutenção', a.texto, _detalhe);
        idKm++;
      }
    }
    return ResultadoLembrete.ok;
  } catch (_) {
    return ResultadoLembrete.indisponivel;
  }
}
