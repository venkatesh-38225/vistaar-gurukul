package com.vistaar.coachapplication


import android.os.Bundle
import android.util.Log
import java.io.BufferedReader
import java.io.InputStreamReader
import java.io.File
import android.content.pm.PackageManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {

    private val CHANNEL = "com.vistaar.security/frida"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "isFridaDetected" -> result.success(isFridaPresent())
                    "isMagiskDetected" -> result.success(isMagiskPresent())
                    "isXposedDetected" -> result.success(isXposedPresent())
                    else -> result.notImplemented()
                }
            }
    }

    private fun isFridaPresent(): Boolean {
        return try {
            val process = Runtime.getRuntime().exec("ps")
            val reader = BufferedReader(InputStreamReader(process.inputStream))
            val lines = reader.readLines()
            lines.any { it.contains("frida") || it.contains("frida-server") }
        } catch (e: Exception) {
            e.printStackTrace()
            false
        }
    }

    private fun isMagiskPresent(): Boolean {
        val magiskPaths = listOf(
            "/sbin/magisk", "/init.magisk.rc", "/system/bin/magisk",
            "/system/xbin/daemonsu", "/cache/magisk.log"
        )
        val magiskPackages = listOf("com.topjohnwu.magisk")

        return try {
            magiskPaths.any { File(it).exists() } ||
                    magiskPackages.any {
                        try {
                            applicationContext.packageManager.getPackageInfo(it, 0)
                            true
                        } catch (_: PackageManager.NameNotFoundException) {
                            false
                        }
                    }
        } catch (e: Exception) {
            Log.e("SecurityCheck", "Error checking Magisk: ${e.message}")
            false
        }
    }

    private fun isXposedPresent(): Boolean {
        return try {
            try {
                throw Exception("Test Xposed")
            } catch (e: Exception) {
                if (e.stackTrace.any { it.className.contains("XposedBridge") }) {
                    return true
                }
            }

            val xposedClasses = listOf(
                "de.robv.android.xposed.XposedBridge",
                "de.robv.android.xposed.XposedHelpers"
            )
            xposedClasses.any {
                try {
                    Class.forName(it)
                    true
                } catch (_: ClassNotFoundException) {
                    false
                }
            }
        } catch (e: Exception) {
            false
        }
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        // Uncomment this if you want to prevent screenshots
        // window.setFlags(WindowManager.LayoutParams.FLAG_SECURE, WindowManager.LayoutParams.FLAG_SECURE)
    }
}
