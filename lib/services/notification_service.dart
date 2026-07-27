import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:gurukul/constants/app_constants.dart';
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  final FlutterLocalNotificationsPlugin gurukulLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  Future<void> initGurukulNotification() async {
    AndroidInitializationSettings initializationSettingsGurukul =
        const AndroidInitializationSettings('vist_guru_nobg');

    const DarwinInitializationSettings initializationSettingsDarwin =
        DarwinInitializationSettings();

    var initializationSettings = InitializationSettings(
        android: initializationSettingsGurukul,
        iOS: initializationSettingsDarwin);

    await gurukulLocalNotificationsPlugin.initialize(
      initializationSettings,

      // onDidReceiveBackgroundNotificationResponse: (details) {
      //   debugPrint(
      //       "notifcation background response from service = ${details.input}");
      // },
      // onDidReceiveNotificationResponse: (NotificationResponse notificationRes) {
      //   debugPrint("notifcation response from service = $notificationRes");
      // },
    );
  }

  notificationDetails() {
    return const NotificationDetails(
        android: AndroidNotificationDetails(
      notificationChannelId,
      noticiationChannelName,
      importance: Importance.max,
      priority: Priority.high,
    ));
  }

  Future showNotification({
    int id = 0,
    String? title,
    String? body,
    String? payload,
    required DateTime scheduledNotificationDateTime,
  }) async {
    return gurukulLocalNotificationsPlugin.zonedSchedule(
      id,
      title,
      body,
      tz.TZDateTime.from(scheduledNotificationDateTime, tz.local),
      await notificationDetails(),
     // androidAllowWhileIdle: true,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime, androidScheduleMode: AndroidScheduleMode.exact,
    );
  }

  Future showNotificationWithoutSched({
    int id = 0,
    String? title,
    String? body,
    String? payload,
  }) async {
    return gurukulLocalNotificationsPlugin.show(
      id,
      title,
      body,
      // tz.TZDateTime.from(scheduledNotificationDateTime, tz.local),
      await notificationDetails(),
      // androidAllowWhileIdle: true,
      // uiLocalNotificationDateInterpretation:
      //     UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  Future pushNotification(
    RemoteMessage message,
  ) async {
    debugPrint("message is ${message.notification!.title}");
    var androidPlatformChannelSpecifics = const AndroidNotificationDetails(
      notificationChannelId,
      noticiationChannelName,
      channelDescription: 'Gurukul notification',
      importance: Importance.max,
      priority: Priority.high,
    );
    var iOSPlatformChannelSpecifics = const DarwinNotificationDetails();
    var platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
      iOS: iOSPlatformChannelSpecifics,
    );
    await gurukulLocalNotificationsPlugin.show(
      0,
      message.notification!.title,
      message.notification!.body,
      platformChannelSpecifics,
    );
  }

  Future cancelNotification() async {
    return gurukulLocalNotificationsPlugin.cancel(0);
  }
}
