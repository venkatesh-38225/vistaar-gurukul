import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lottie/lottie.dart';

/// A modern animated loading widget using Lottie animations.
/// Replaces the basic CircularProgressIndicator throughout the app.
class LottieLoadingWidget extends StatelessWidget {
  const LottieLoadingWidget({
    super.key,
    this.size = 120,
    this.message,
  });

  final double size;
  final String? message;

  // Smooth, modern loading animation
  static const String _loadingUrl =
      'https://lottie.host/b18e3e6e-cc58-4787-8e33-483c03de3d16/ZaHhkIOitY.json';

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: size,
            height: size,
            child: Lottie.network(
              _loadingUrl,
              fit: BoxFit.contain,
              frameRate: FrameRate.max,
              errorBuilder: (context, error, stackTrace) {
                // Graceful fallback to CircularProgressIndicator
                return const Center(child: CircularProgressIndicator());
              },
            ),
          ),
          if (message != null) ...[
            const SizedBox(height: 12),
            Text(
              message!,
              textAlign: TextAlign.center,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.white60
                    : const Color(0xFF64748B),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// A modern animated empty-state widget using Lottie animations.
/// Replaces plain "No data" text messages throughout the app.
class LottieEmptyWidget extends StatelessWidget {
  const LottieEmptyWidget({
    super.key,
    required this.message,
    this.size = 180,
    this.subtitle,
  });

  final String message;
  final double size;
  final String? subtitle;

  // Friendly empty-state / no-data animation
  static const String _emptyUrl =
      'https://lottie.host/ef416d99-4a98-43d8-bed1-7af4aeef0e03/YwkXjzR5ID.json';

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: size,
              height: size,
              child: Lottie.network(
                _emptyUrl,
                fit: BoxFit.contain,
                frameRate: FrameRate.max,
                errorBuilder: (context, error, stackTrace) {
                  // Fallback to a simple icon
                  return Icon(
                    Icons.inbox_rounded,
                    size: size * 0.5,
                    color: isDark ? Colors.white24 : Colors.grey[300],
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: isDark ? Colors.white70 : const Color(0xFF334155),
              ),
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 8),
              Text(
                subtitle!,
                textAlign: TextAlign.center,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  height: 1.5,
                  color: isDark ? Colors.white38 : const Color(0xFF94A3B8),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Utility class to show/dismiss a Lottie-powered loading dialog.
/// Drop-in replacement for the current `showDialog(... CircularProgressIndicator ...)` pattern.
class LottieLoadingDialog {
  static void show(BuildContext context, {String? message}) {
    showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black45,
      builder: (context) => PopScope(
        canPop: false,
        child: Center(
          child: Container(
            padding: const EdgeInsets.all(28),
            margin: const EdgeInsets.symmetric(horizontal: 60),
            decoration: BoxDecoration(
              color: Theme.of(context).brightness == Brightness.dark
                  ? const Color(0xFF1E293B)
                  : Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.12),
                  blurRadius: 30,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 90,
                  height: 90,
                  child: Lottie.network(
                    LottieLoadingWidget._loadingUrl,
                    fit: BoxFit.contain,
                    frameRate: FrameRate.max,
                    errorBuilder: (context, error, stackTrace) {
                      return const Center(child: CircularProgressIndicator());
                    },
                  ),
                ),
                if (message != null) ...[
                  const SizedBox(height: 16),
                  Text(
                    message,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Theme.of(context).brightness == Brightness.dark
                          ? Colors.white60
                          : const Color(0xFF64748B),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  static void dismiss(BuildContext context) {
    Navigator.of(context).pop();
  }
}
