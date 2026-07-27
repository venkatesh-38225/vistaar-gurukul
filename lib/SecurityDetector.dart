import 'package:flutter/services.dart';


class SecurityService {
  static const platform = MethodChannel('com.vistaar.security/frida');

  static Future<bool> isFridaDetected() async {
    return await platform.invokeMethod<bool>('isFridaDetected') ?? false;
  }

  static Future<bool> isMagiskDetected() async {
    return await platform.invokeMethod<bool>('isMagiskDetected') ?? false;
  }

  static Future<bool> isXposedDetected() async {
    return await platform.invokeMethod<bool>('isXposedDetected') ?? false;
  }

  static Future<bool> isAnyThreatDetected() async {
    final frida = await isFridaDetected();
    final magisk = await isMagiskDetected();
    final xposed = await isXposedDetected();
    return frida || magisk || xposed;
  }
}
