
import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
// import 'package:flutter_jailbreak_detection/flutter_jailbreak_detection.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:gurukul/common/environment.dart';
import 'package:gurukul/common/shared_pref.dart';
// import 'package:gurukul/constants/environment_dev.dart';
// import 'package:gurukul/constants/environment_prod.dart';
import 'package:gurukul/firebase_options.dart';
import 'package:gurukul/provider/api_provider.dart';
import 'package:gurukul/provider/auth_provider.dart';
import 'package:gurukul/provider/tab_provider.dart';
import 'package:gurukul/provider/theme_provider.dart';
import 'package:gurukul/routes/routes.dart';
import 'package:gurukul/services/firebase_api.dart';
import 'package:gurukul/services/notification_service.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:workmanager/workmanager.dart';

import 'package:gurukul/constants/environment_dev.dart';
import 'package:gurukul/constants/environment_prod.dart';
import 'SecurityDetector.dart';


Environment? environment;

void callDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    tz.initializeTimeZones();
    NotificationService().showNotificationWithoutSched(
      title: "Complete your training",
      body: "You have training pending, please complete your training!",
    );

    return Future.value(true);
  });
}

//Select environment here between DevEnv or ProdEnv
void selectEnvironment() {
  environment = DevEnv();
  // environment = ProdEnv();
  print("Running : ${environment?.baseUrl}");
}


void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase with safety wrapper
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    debugPrint("Firebase initialization failed: $e");
  }

  // Initialize notifications safely
  try {
    await NotificationService().initGurukulNotification();
    if (!kIsWeb) {
      await FirebaseApi().initNotification();
    }
  } catch (e) {
    debugPrint("Notification initialization failed: $e");
  }

  // Initialize timezones safely
  try {
    tz.initializeTimeZones();
  } catch (e) {
    debugPrint("Timezone initialization failed: $e");
  }

  // Initialize Hive safely
  try {
    await Hive.initFlutter();
  } catch (e) {
    debugPrint("Hive initialization failed: $e");
  }

  selectEnvironment();

  // Request permission asynchronously without blocking startup
  try {
    Permission.notification.isDenied.then((value) {
      if (value) {
        Permission.notification.request();
      }
    }).catchError((e) {
      debugPrint("Notification permission error: $e");
    });
  } catch (e) {
    debugPrint("Permission exception: $e");
  }

  runApp(const GurukulApp());
}

class GurukulApp extends StatefulWidget {
  const GurukulApp({super.key});

  @override
  State<GurukulApp> createState() => _GurukulAppState();
}

class _GurukulAppState extends State<GurukulApp> with WidgetsBindingObserver {
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  bool isRooted = false;
  bool _isRooted = false;
  bool _isThreatDetected = false;
  @override
  void initState() {
    super.initState();
   // checkRootStatus();
    takeNotificationPermission();
    if (!kIsWeb) {
      debugPrint('${_firebaseMessaging.getToken()}');
      FirebaseMessaging.instance
          .getInitialMessage()
          .then((RemoteMessage? message) {
        if (message != null) {}
      });
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        RemoteNotification? notification = message.notification;
        AndroidNotification? android = message.notification?.android;
        if (notification != null && android != null) {}
      });
      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        //message when open
      });
    }
   // checkRootStatus();

  }


  /* Future<void> checkRootStatus() async {
    bool? rooted = await RootCheckerPlus.isRootChecker();
    if (mounted) {
      setState(() {
        isRooted = rooted!;
      });

      // If rooted, exit the app
      if (rooted!) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text("Warning"),
            content: const Text("This app does not support rooted devices."),
            actions: [
              TextButton(
                onPressed: () => exit(0),
                child: const Text("Close"),
              ),
            ],
          ),
        );
        UserPreference().removeUser();
        context.read<UserProvider>().reset();
        context.read<TabProvider>().reset();
        context.go('/');// Closes the app
      }
    }
  }
*/

  Future<void> checkAppUpdate() async {
    debugPrint("Checking for update");
  }

  void takeNotificationPermission() async {
    await Permission.notification.isDenied.then((value) {
      if (value) {
        Permission.notification.request();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]).then(
      (_) => SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual,
          overlays: []),
    );
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => TabProvider()),
        ChangeNotifierProvider(create: (context) => AuthProvider()),
        ChangeNotifierProvider(create: (context) => UserProvider()),
        ChangeNotifierProvider<ThemeChanger>(create: (_) => ThemeChanger()),
      ],
      child: Builder(builder: (context) {
        final themeChanger = Provider.of<ThemeChanger>(context);
        return MaterialApp.router(
          darkTheme: ThemeData(
            brightness: Brightness.dark,
            scaffoldBackgroundColor: const Color(0xFF0A0E1A),
            dialogBackgroundColor: const Color(0xFF131A2E),
            cardColor: const Color(0xFF161F38),
            fontFamily: GoogleFonts.plusJakartaSans().fontFamily,
            dividerColor: Colors.white.withOpacity(0.08),
            textTheme: const TextTheme(
              bodyLarge: TextStyle(color: Colors.white, fontSize: 16),
              bodyMedium: TextStyle(color: Colors.white70, fontSize: 14),
              bodySmall: TextStyle(color: Colors.white54, fontSize: 12),
            ),
          ),
          themeMode:
              themeChanger.isNightMode ? ThemeMode.dark : ThemeMode.light,
          theme: ThemeData(
            brightness: Brightness.light,
            scaffoldBackgroundColor: const Color(0xFFF8FAFC),
            dialogBackgroundColor: Colors.white,
            cardColor: Colors.white,
            fontFamily: GoogleFonts.plusJakartaSans().fontFamily,
            dividerColor: Colors.grey.withOpacity(0.12),
            textTheme: const TextTheme(
              bodyLarge: TextStyle(color: Color(0xFF0F172A), fontSize: 16),
              bodyMedium: TextStyle(color: Color(0xFF334155), fontSize: 14),
              bodySmall: TextStyle(color: Color(0xFF64748B), fontSize: 12),
            ),
          ),
          routerConfig: router,
          builder: (context, child) => child ?? const SizedBox.shrink(),
          debugShowCheckedModeBanner: false,
        );
      }),
    );
  }
}
