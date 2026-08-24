import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

/// Agenda 9h (Brasília) no dia do vencimento. Só roda no Android/APK.
Future<void> agendarLembretes({
  DateTime? oleo,
  DateTime? pneus,
  DateTime? ipva,
  DateTime? seguro,
  DateTime? licenciamento,
  DateTime? cnh,
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

    await plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();

    await plugin.cancelAll();
    await _um(plugin, 1, oleo, 'Óleo da moto', 'Hoje vence a troca de óleo.');
    await _um(plugin, 2, pneus, 'Pneus da moto', 'Hoje vence a troca de pneus.');
    await _um(plugin, 3, ipva, 'IPVA', 'Hoje vence o IPVA.');
    await _um(plugin, 4, seguro, 'Seguro', 'Hoje vence o seguro.');
    await _um(plugin, 5, licenciamento, 'Licenciamento', 'Hoje vence o licenciamento.');
    await _um(plugin, 6, cnh, 'CNH', 'Hoje vence a CNH.');
  } catch (_) {
    // Teste, web ou permissão negada: o aviso na tela continua valendo.
  }
}

Future<void> _um(
  FlutterLocalNotificationsPlugin plugin,
  int id,
  DateTime? dia,
  String titulo,
  String corpo,
) async {
  if (dia == null) return;

  final quando = tz.TZDateTime(
    tz.local,
    dia.year,
    dia.month,
    dia.day,
    9,
  );
  if (quando.isBefore(tz.TZDateTime.now(tz.local))) return;

  await plugin.zonedSchedule(
    id,
    titulo,
    corpo,
    quando,
    const NotificationDetails(
      android: AndroidNotificationDetails(
        'manutencao',
        'Manutenção',
        channelDescription: 'Lembrete de óleo, pneus e papelada',
      ),
    ),
    androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
  );
}
