import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_core_platform_interface/test.dart';
import 'package:gurukul/main.dart';
import 'package:hive_flutter/hive_flutter.dart';

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();

    // Setup standard firebase core mocks
    setupFirebaseCoreMocks();

    // Mock firebase_messaging
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('plugins.flutter.io/firebase_messaging'),
      (MethodCall methodCall) async {
        if (methodCall.method == 'getToken') {
          return 'mock-token';
        }
        return null;
      },
    );

    // Initialize Firebase mock
    await Firebase.initializeApp();

    // Initialize Hive mock directory
    Hive.init('.');
  });

  testWidgets('Open app and click Completed tab', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const GurukulApp());

    // Verify that the app is opened
    expect(find.byType(GurukulApp), findsOneWidget);

    // Tap the 'Completed' tab.
    await tester.tap(find.text('Completed'));
    await tester.pump();

    // Verify that the Completed tab is opened.
    expect(find.text('Completed'), findsOneWidget);
  });
}
