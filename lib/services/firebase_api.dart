import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
// import 'package:gurukul/main.dart';
import 'package:gurukul/services/notification_service.dart';

class FirebaseApi {
  final _firebaseMessaging = FirebaseMessaging.instance;

  Future<void> initNotification() async {
    await _firebaseMessaging.requestPermission();
    late final String? fcmToken;
    try {
      fcmToken = await _firebaseMessaging.getToken();
      debugPrint("token : $fcmToken");
    } catch (e) {
      debugPrint("exception: $e");
    }

    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint('Got a message whilst in the foreground!');
      // debugPrint('Message data: ${message.data}');
      RemoteNotification? notification = message.notification;
      AndroidNotification? android = message.notification?.android;
      AppleNotification? apple = message.notification?.apple;
      if (notification != null && android != null) {}
      if (notification != null && apple != null) {}

      if (message.notification != null) {
        // debugPrint(
        //     'Message also contained a notification: ${message.notification}');
        notificationHandler();
      }
      handleMessage(message);
    });

    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      debugPrint('Got a message whilst the app was in the background!');
      debugPrint('Message data: ${message.data}');

      if (message.notification != null) {
        debugPrint(
            'Message also contained a notification: ${message.notification?.body}');
        // notificationHandler();
      }
      handleMessage(message);
    });

    FirebaseMessaging.onBackgroundMessage(_firebaseBackgroundMessageHandler);
  }

  static Future<void> _firebaseBackgroundMessageHandler(
      RemoteMessage message) async {
    debugPrint('Got a message whilst the app was terminated!');
    // debugPrint('Message data: ${message.notification?.title}');
    // debugPrint('Message data: ${message.notification?.body}');

    if (message.notification != null) {
      debugPrint(
          'Message also contained a notification: ${message.notification}');
    }
    // Add your notification handling logic here
  }

  void handleMessage(RemoteMessage? message) {
    if (message == null) return;
    // navigatorKey.currentContext?.push('inProgress');
  }

  static void notificationHandler() {
    debugPrint("notification trying....");
    FirebaseMessaging.onMessage.listen((event) async {
      debugPrint("event = ${event.messageId}");
      await NotificationService().pushNotification(event);
    });
  }
}
