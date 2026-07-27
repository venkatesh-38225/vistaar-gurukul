import 'package:flutter/material.dart';
import 'package:gurukul/provider/theme_provider.dart';
import 'package:provider/provider.dart';

class ColorConstraints {
  static Color primaryColor(BuildContext context) {
    return context.watch<ThemeChanger>().isNightMode
        ? const Color(0xFF0F172A) // slate-900
        : const Color(0xFF003366); // Dark Navy Blue
  }

  static Color secondaryColor(BuildContext context) {
    return const Color(0xFFF15A24); // Coral Accent Orange
  }

  static LinearGradient primaryGradient(BuildContext context) {
    return context.watch<ThemeChanger>().isNightMode
        ? const LinearGradient(
            colors: [
              Color(0xFF0A0E1A),
              Color(0xFF131A2E)
            ], // Premium deep space navy
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          )
        : const LinearGradient(
            colors: [
              Color.fromARGB(255, 15, 68, 128),
              Color(0xFF00529B),
              Color(0xFF0077D6)
            ], // Vibrant Blue Gradient
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          );
  }

  static LinearGradient accentGradient(BuildContext context) {
    return const LinearGradient(
      colors: [Color(0xFFF15A24), Color(0xFFFFA07A)], // Coral Sunset Gradient
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );
  }

  static Color iconColor(BuildContext context) {
    return context.watch<ThemeChanger>().isNightMode
        ? Colors.white
        : const Color(0xFF1E293B); // Slate-800
  }

  static Color selectedBackgroundColor(BuildContext context) {
    return context.watch<ThemeChanger>().isNightMode
        ? const Color(0xFF1E293B)
        : Colors.white;
  }

  static Color cardColor(BuildContext context) {
    return context.watch<ThemeChanger>().isNightMode
        ? const Color(0xFF161F38) // Premium Dark Card
        : Colors.white;
  }

  static Color cardShadowColor(BuildContext context) {
    return context.watch<ThemeChanger>().isNightMode
        ? const Color(0x7F000000)
        : const Color(0x0C003B75); // Soft blue shadow for premium feel
  }

  static Color topicCardColor(BuildContext context) {
    return context.watch<ThemeChanger>().isNightMode
        ? const Color(0xFF1E294B) // slate-800
        : const Color(0xFFF8FAFC); // slate-50
  }

  static Color testCardBackgroundColor(BuildContext context) {
    return context.watch<ThemeChanger>().isNightMode
        ? const Color(0xFF0F172A)
        : const Color(0xFFEEF2F6); // modern grey-50
  }

  static Color testControlsColor(BuildContext context) {
    return context.watch<ThemeChanger>().isNightMode
        ? Colors.white
        : const Color(0xFF003B75);
  }

  // Gradients for Dashboard Status Circles
  static LinearGradient completedProgressGradient() {
    return const LinearGradient(
      colors: [Color(0xFF10B981), Color(0xFF34D399)], // vibrant emerald
    );
  }

  static LinearGradient inProgressProgressGradient() {
    return const LinearGradient(
      colors: [Color(0xFF3B82F6), Color(0xFF60A5FA)], // vibrant blue
    );
  }

  static LinearGradient newProgressGradient() {
    return const LinearGradient(
      colors: [Color(0xFFF59E0B), Color(0xFFFBBF24)], // vibrant amber
    );
  }

  static LinearGradient othersProgressGradient() {
    return const LinearGradient(
      colors: [Color(0xFF8B5CF6), Color(0xFFA78BFA)], // vibrant violet
    );
  }
}
