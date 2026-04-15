import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

/// Servicio para manejar notificaciones locales programadas
class NotificationService {
  static final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  static bool _initialized = false;

  /// Inicializa el servicio de notificaciones
  static Future<void> initialize() async {
    if (_initialized) return;

    // Inicializar timezone usando la zona del dispositivo
    tz.initializeTimeZones();
    try {
      // Intentar obtener la zona horaria del offset del dispositivo
      final offsetMinutes = DateTime.now().timeZoneOffset.inMinutes;
      final offsetHours = offsetMinutes ~/ 60;
      // Mapear offset a zona IANA más cercana
      final tzName = {
        -8: 'America/Los_Angeles',
        -7: 'America/Mazatlan',
        -6: 'America/Mexico_City',
        -5: 'America/Mexico_City', // CDT
        -4: 'America/Caracas',
        -3: 'America/Argentina/Buenos_Aires',
        0:  'UTC',
      }[offsetHours] ?? 'America/Mexico_City';
      tz.setLocalLocation(tz.getLocation(tzName));
      debugPrint('⏰ Timezone: $tzName (offset: ${offsetHours}h)');
    } catch (_) {
      tz.setLocalLocation(tz.UTC);
    }

    // Configuración para Android
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');

    // Configuración para iOS
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (response) {
        debugPrint('Notificación tocada: ${response.payload}');
        // Aquí puedes manejar qué hacer cuando el usuario toca la notificación
      },
    );

    _initialized = true;
    debugPrint('✅ NotificationService inicializado');
  }

  /// Solicita permisos de notificaciones Y alarmas exactas
  static Future<bool> requestPermissions() async {
    if (!_initialized) await initialize();

    final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
        _notifications.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();

    if (androidImplementation != null) {
      // 1. Permiso de notificaciones (Android 13+)
      final granted = await androidImplementation.requestNotificationsPermission();
      // 2. Permiso de alarmas exactas (Android 12+) - necesario para Honor/Huawei
      try {
        await androidImplementation.requestExactAlarmsPermission();
        debugPrint('✅ Permiso de alarmas exactas solicitado');
      } catch (e) {
        debugPrint('⚠️ requestExactAlarmsPermission no disponible: $e');
      }
      return granted ?? false;
    }

    // iOS
    final IOSFlutterLocalNotificationsPlugin? iosImplementation =
        _notifications.resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>();

    if (iosImplementation != null) {
      final granted = await iosImplementation.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );
      return granted ?? false;
    }

    return true;
  }

  /// Programa una notificación para una cita médica
  static Future<int> scheduleAppointmentNotification({
    required String type,
    required DateTime date,
    required TimeOfDay time,
    String? notes,
  }) async {
    if (!_initialized) await initialize();

    // Generar ID único
    final id = DateTime.now().millisecondsSinceEpoch ~/ 1000;

    // Combinar fecha y hora
    final scheduledDate = DateTime(
      date.year,
      date.month,
      date.day,
      time.hour,
      time.minute,
    );

    // Programar notificación 1 hora antes
    final notificationTime = scheduledDate.subtract(const Duration(hours: 1));

    // Solo programar si es en el futuro
    if (notificationTime.isBefore(DateTime.now())) {
      debugPrint('⚠️ Notificación en el pasado, no se programa');
      return id;
    }

    await _notifications.zonedSchedule(
      id,
      '🏥 Recordatorio: $type',
      notes != null && notes.isNotEmpty
          ? notes
          : 'Tienes una cita médica en 1 hora — ${type}',
      tz.TZDateTime.from(notificationTime, tz.local),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'appointments_channel',
          'Citas Médicas',
          channelDescription: 'Notificaciones de citas médicas y vacunas',
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );

    debugPrint('✅ Notificación programada: ID=$id, fecha=$notificationTime');
    return id;
  }

  /// Programa notificaciones recurrentes para medicamentos
  static Future<List<int>> scheduleMedicineNotifications({
    required String medicineName,
    required String dosage,
    required List<TimeOfDay> times,
  }) async {
    if (!_initialized) await initialize();

    final notificationIds = <int>[];

    for (final time in times) {
      final id = DateTime.now().millisecondsSinceEpoch ~/ 1000 + times.indexOf(time);

      // Calcular próxima ocurrencia de esta hora
      final now = DateTime.now();
      var scheduledDate = DateTime(
        now.year,
        now.month,
        now.day,
        time.hour,
        time.minute,
      );

      // Si ya pasó hoy, programar para mañana
      if (scheduledDate.isBefore(now)) {
        scheduledDate = scheduledDate.add(const Duration(days: 1));
      }

      // Programar notificación diaria
      await _notifications.zonedSchedule(
        id,
        '💊 Hora de tomar: $medicineName',
        'Dosis: $dosage',
        tz.TZDateTime.from(scheduledDate, tz.local),
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'medicines_channel',
            'Medicamentos',
            channelDescription: 'Recordatorios de medicamentos',
            importance: Importance.high,
            priority: Priority.high,
            icon: '@mipmap/ic_launcher',
          ),
          iOS: DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.time, // Repetir diariamente
      );

      notificationIds.add(id);
      debugPrint('✅ Recordatorio medicamento programado: ID=$id, hora=${time.hour}:${time.minute.toString().padLeft(2, '0')}');
    }

    return notificationIds;
  }

  /// Programa recordatorio de próxima comida
  static Future<int> scheduleNextFeedingNotification({
    required DateTime nextFeedingTime,
    required String babyName,
  }) async {
    if (!_initialized) await initialize();

    final id = 999999; // ID fijo para recordatorio de comida

    // Solo programar si es en el futuro
    if (nextFeedingTime.isBefore(DateTime.now())) {
      debugPrint('⚠️ Próxima comida en el pasado, no se programa');
      return id;
    }

    // Cancelar notificación anterior si existe
    await _notifications.cancel(id);

    await _notifications.zonedSchedule(
      id,
      '🍼 Hora de alimentar a $babyName',
      'Es hora de la próxima toma',
      tz.TZDateTime.from(nextFeedingTime, tz.local),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'feeding_channel',
          'Alimentación',
          channelDescription: 'Recordatorios de alimentación',
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );

    debugPrint('✅ Recordatorio comida programado: ID=$id, hora=$nextFeedingTime');
    return id;
  }

  /// Programa un recordatorio manual a una hora específica elegida por el usuario.
  /// Usa ID fijo 888888 para no interferir con el cálculo automático.
  static Future<bool> scheduleCustomFeedingReminder({
    required DateTime scheduledTime,
    required String babyName,
  }) async {
    if (!_initialized) await initialize();

    const id = 888888;

    if (scheduledTime.isBefore(DateTime.now())) {
      debugPrint('⚠️ Recordatorio personalizado en el pasado, no se programa');
      return false;
    }

    // Cancelar recordatorio anterior si existía
    await _notifications.cancel(id);

    await _notifications.zonedSchedule(
      id,
      '🍼 Recordatorio de toma — $babyName',
      'Es hora de alimentar a $babyName',
      tz.TZDateTime.from(scheduledTime, tz.local),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'feeding_reminder_channel',
          'Recordatorios de toma',
          channelDescription: 'Recordatorios manuales de alimentación',
          importance: Importance.max,
          priority: Priority.max,
          icon: '@mipmap/ic_launcher',
          playSound: true,
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );

    debugPrint('✅ Recordatorio personalizado programado: $scheduledTime');
    return true;
  }

  /// Cancela una notificación por ID
  static Future<void> cancelNotification(int id) async {
    await _notifications.cancel(id);
    debugPrint('🗑️ Notificación cancelada: ID=$id');
  }

  /// Cancela múltiples notificaciones
  static Future<void> cancelNotifications(List<int> ids) async {
    for (final id in ids) {
      await cancelNotification(id);
    }
  }

  /// Cancela todas las notificaciones
  static Future<void> cancelAllNotifications() async {
    await _notifications.cancelAll();
    debugPrint('🗑️ Todas las notificaciones canceladas');
  }

  /// Muestra una notificación inmediata (para testing)
  static Future<void> showTestNotification() async {
    if (!_initialized) await initialize();

    await _notifications.show(
      0,
      '🎉 KOA - Notificaciones activas',
      'El sistema de notificaciones está funcionando correctamente',
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'test_channel',
          'Pruebas',
          channelDescription: 'Canal para notificaciones de prueba',
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
    );
  }
}
