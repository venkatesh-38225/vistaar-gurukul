import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

enum SnackBarType { success, error, info, warning }

class CustomSnackBar {
  static void show(
    BuildContext context, {
    required String message,
    SnackBarType type = SnackBarType.info,
    Duration duration = const Duration(seconds: 3),
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Clear previous snackbars first to avoid toast queuing lag
    ScaffoldMessenger.of(context).hideCurrentSnackBar();

    Color backgroundColor;
    Color iconColor;
    IconData icon;

    switch (type) {
      case SnackBarType.success:
        backgroundColor =
            isDark ? const Color(0xFF064E3B) : const Color(0xFFE6F4EA);
        iconColor = isDark ? const Color(0xFF34D399) : const Color(0xFF137333);
        icon = Icons.check_circle_outline_rounded;
        break;
      case SnackBarType.error:
        backgroundColor =
            isDark ? const Color(0xFF7F1D1D) : const Color(0xFFFCE8E6);
        iconColor = isDark ? const Color(0xFFF87171) : const Color(0xFFC5221F);
        icon = Icons.error_outline_rounded;
        break;
      case SnackBarType.warning:
        backgroundColor =
            isDark ? const Color(0xFF78350F) : const Color(0xFFFEF7E0);
        iconColor = isDark ? const Color(0xFFF59E0B) : const Color(0xFFB06000);
        icon = Icons.warning_amber_rounded;
        break;
      case SnackBarType.info:
      default:
        backgroundColor =
            isDark ? const Color(0xFF1E293B) : const Color(0xFFE8F0FE);
        iconColor = isDark ? const Color(0xFF94A3B8) : const Color(0xFF1A73E8);
        icon = Icons.info_outline_rounded;
        break;
    }

    final textColor = isDark
        ? Colors.white
        : (type == SnackBarType.info
            ? const Color(0xFF1A73E8)
            : const Color(0xFF202124));

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        duration: duration,
        content: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.06),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
            border: Border.all(
              color: iconColor.withValues(alpha: isDark ? 0.25 : 0.15),
              width: 1.5,
            ),
          ),
          child: Row(
            children: [
              Icon(
                icon,
                color: iconColor,
                size: 22,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  message,
                  style: GoogleFonts.plusJakartaSans(
                    color: textColor,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
