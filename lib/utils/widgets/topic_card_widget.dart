import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:gurukul/provider/theme_provider.dart';
import 'package:gurukul/utils/colors.dart';
import 'package:provider/provider.dart';

class TopicCardWidget extends StatefulWidget {
  const TopicCardWidget({
    super.key,
    required this.height,
    required this.width,
    required this.topicName,
    required this.heroTag,
    this.iconName = Icons.chevron_right_rounded,
    this.isLoading,
    this.accentColor,
    this.subtitle,
    this.progress,
  });

  final double height;
  final double width;
  final String topicName;
  final Key heroTag;
  final IconData iconName;
  final String? isLoading;
  final Color? accentColor;
  final String? subtitle;
  final double? progress;

  @override
  State<TopicCardWidget> createState() => _TopicCardWidgetState();
}

class _TopicCardWidgetState extends State<TopicCardWidget> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    bool isDark = Theme.of(context).brightness == Brightness.dark;
    Color statusColor =
        widget.accentColor ?? ColorConstraints.primaryColor(context);

    return Listener(
      onPointerDown: (_) => setState(() => _isPressed = true),
      onPointerUp: (_) => setState(() => _isPressed = false),
      onPointerCancel: (_) => setState(() => _isPressed = false),
      child: AnimatedScale(
        scale: _isPressed ? 0.97 : 1.0,
        duration: const Duration(milliseconds: 100),
        curve: Curves.easeInOut,
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 8.0),
          padding: const EdgeInsets.all(18.0),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF131A2E) : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDark
                  ? Colors.white.withOpacity(0.06)
                  : Colors.grey.withOpacity(0.12),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: isDark ? Colors.black38 : Colors.grey.withOpacity(0.05),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            children: [
              // Icon representation for training (exactly matching Recommended Course card)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF003B75).withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.menu_book_rounded,
                  color: Color(0xFF003B75),
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      widget.topicName,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.subtitle ?? "Tap to start training session",
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: widget.accentColor ??
                            (isDark ? Colors.white38 : const Color(0xFF64748B)),
                      ),
                    ),
                    if (widget.progress != null) ...[
                      const SizedBox(height: 8),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: widget.progress,
                          minHeight: 4,
                          backgroundColor: isDark
                              ? Colors.white.withOpacity(0.08)
                              : statusColor.withOpacity(0.10),
                          valueColor:
                              AlwaysStoppedAnimation<Color>(statusColor),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                widget.iconName,
                color: widget.iconName == Icons.chevron_right_rounded
                    ? Colors.grey
                    : statusColor,
                size: 24,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
