import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

enum SnackBarType { success, error, info, warning }

class CustomSnackBar {
  static void show(
    BuildContext context, {
    required String message,
    SnackBarType type = SnackBarType.info,
    Duration duration = const Duration(seconds: 3),
    String? actionLabel,
    VoidCallback? onAction,
    bool showCloseButton = true,
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
        icon = Icons.check_circle_rounded;
        break;
      case SnackBarType.error:
        backgroundColor =
            isDark ? const Color(0xFF7F1D1D) : const Color(0xFFFCE8E6);
        iconColor = isDark ? const Color(0xFFF87171) : const Color(0xFFC5221F);
        icon = Icons.error_rounded;
        break;
      case SnackBarType.warning:
        backgroundColor =
            isDark ? const Color(0xFF78350F) : const Color(0xFFFEF7E0);
        iconColor = isDark ? const Color(0xFFF59E0B) : const Color(0xFFB06000);
        icon = Icons.warning_rounded;
        break;
      case SnackBarType.info:
        backgroundColor =
            isDark ? const Color(0xFF1E293B) : const Color(0xFFE8F0FE);
        iconColor = isDark ? const Color(0xFF94A3B8) : const Color(0xFF1A73E8);
        icon = Icons.info_rounded;
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
        dismissDirection: DismissDirection.horizontal,
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        duration: duration,
        content: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(isDark ? 0.35 : 0.08),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
            border: Border.all(
              color: iconColor.withOpacity(isDark ? 0.3 : 0.2),
              width: 1.2,
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  color: iconColor,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  message,
                  style: GoogleFonts.plusJakartaSans(
                    color: textColor,
                    fontWeight: FontWeight.w600,
                    fontSize: 13.5,
                  ),
                ),
              ),
              if (actionLabel != null) ...[
                const SizedBox(width: 8),
                TextButton(
                  style: TextButton.styleFrom(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    backgroundColor: iconColor.withOpacity(0.15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  onPressed: () {
                    ScaffoldMessenger.of(context).hideCurrentSnackBar();
                    onAction?.call();
                  },
                  child: Text(
                    actionLabel,
                    style: GoogleFonts.plusJakartaSans(
                      color: iconColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 12.5,
                    ),
                  ),
                ),
              ],
              if (showCloseButton) ...[
                const SizedBox(width: 6),
                InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: () =>
                      ScaffoldMessenger.of(context).hideCurrentSnackBar(),
                  child: Padding(
                    padding: const EdgeInsets.all(4.0),
                    child: Icon(
                      Icons.close_rounded,
                      color: textColor.withOpacity(0.6),
                      size: 18,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
