import 'dart:math';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:gurukul/provider/tab_provider.dart';
import 'package:gurukul/provider/theme_provider.dart';
import 'package:gurukul/utils/colors.dart';
import 'package:provider/provider.dart';

import '../../provider/api_provider.dart';

class GridCardWithProgress extends StatefulWidget {
  const GridCardWithProgress({
    super.key,
    required this.progress,
    required this.cardName,
    required this.numberOfTask,
    required this.outerCircleColor,
    required this.progressIndicatorColor,
  });

  final double progress;
  final String cardName;
  final int numberOfTask;
  final Color outerCircleColor;
  final Color progressIndicatorColor;

  @override
  State<GridCardWithProgress> createState() => _GridCardWithProgressState();
}

class _GridCardWithProgressState extends State<GridCardWithProgress> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    bool isDark = Theme.of(context).brightness == Brightness.dark;
    double progress = double.parse(gridViewCardPerc());

    return Consumer<UserProvider>(builder: (context, userProvider, child) {
      return GestureDetector(
        onTapDown: (_) => setState(() => _isPressed = true),
        onTapUp: (_) => setState(() => _isPressed = false),
        onTapCancel: () => setState(() => _isPressed = false),
        onTap: () {
          if (widget.cardName == "Completed") {
            context.read<TabProvider>().setIsFromCompleted = true;
            context
                .push('/completed')
                .then((value) => context.read<UserProvider>()
                  ..setPercAndStatus()
                  ..getOtherTrainingData());
          }
          if (widget.cardName == "Yet to Start") {
            context.read<TabProvider>().setIsFromCompleted = false;
            context
                .push('/training-list-screen')
                .then((value) => context.read<UserProvider>()
                  ..setPercAndStatus()
                  ..getOtherTrainingData());
          }
          if (widget.cardName == "In Progress") {
            context.read<TabProvider>().setIsFromCompleted = false;
            context
                .push('/in-progress')
                .then((value) => context.read<UserProvider>()
                  ..setPercAndStatus()
                  ..getOtherTrainingData());
          }
          if (widget.cardName == "Others") {
            context.read<TabProvider>().setIsFromCompleted = false;
            context.push('/others').then((value) => context.read<UserProvider>()
              ..setPercAndStatus()
              ..getOtherTrainingData());
          }
        },
        child: AnimatedScale(
          scale: _isPressed ? 0.96 : 1.0,
          duration: const Duration(milliseconds: 100),
          curve: Curves.easeInOut,
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isDark
                    ? [
                        ColorConstraints.cardColor(context),
                        widget.progressIndicatorColor.withOpacity(0.06),
                      ]
                    : [
                        Colors.white,
                        widget.progressIndicatorColor.withOpacity(0.04),
                      ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: widget.progressIndicatorColor
                      .withOpacity(isDark ? 0.08 : 0.05),
                  spreadRadius: 0,
                  blurRadius: 18,
                  offset: const Offset(0, 8),
                ),
              ],
              border: Border.all(
                color: widget.progressIndicatorColor
                    .withOpacity(isDark ? 0.15 : 0.10),
                width: 1.2,
              ),
            ),
            padding:
                const EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Top Row: Icon Container & Percentage Badge
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: widget.progressIndicatorColor.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(
                        _getCardIcon(),
                        color: widget.progressIndicatorColor,
                        size: 22,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: widget.progressIndicatorColor.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        widget.cardName != "Others"
                            ? "${(progress * 100).toStringAsFixed(0)}%"
                            : "Active",
                        style: GoogleFonts.plusJakartaSans(
                          color: widget.progressIndicatorColor,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),

                // Bottom Column: Count & Metric Info & Progress Bar
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      gridViewCardTaskNo(),
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      widget.cardName,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : const Color(0xFF1E293B),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      widget.cardName == "Others"
                          ? "extra modules"
                          : "training modules",
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color:
                            isDark ? Colors.white38 : const Color(0xFF64748B),
                      ),
                    ),
                    if (widget.cardName != "Others") ...[
                      const SizedBox(height: 8),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: progress,
                          minHeight: 4,
                          backgroundColor: isDark
                              ? Colors.white.withOpacity(0.08)
                              : widget.progressIndicatorColor.withOpacity(0.1),
                          valueColor: AlwaysStoppedAnimation<Color>(
                              widget.progressIndicatorColor),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ),
      );
    });
  }

  IconData _getCardIcon() {
    switch (widget.cardName) {
      case "Completed":
        return Icons.check_circle_rounded;
      case "In Progress":
        return Icons.play_circle_fill_rounded;
      case "Yet to Start":
        return Icons.alarm_rounded;
      default:
        return Icons.grid_view_rounded;
    }
  }

  String gridViewCardTaskNo() {
    if (widget.cardName == "Yet to Start") {
      return ("${context.read<UserProvider>().trainingStatusAndProgress['New'].length}");
    }
    if (widget.cardName == "In Progress") {
      return ("${context.read<UserProvider>().trainingStatusAndProgress['InProgress'].length}");
    }
    if (widget.cardName == "Completed") {
      return ("${context.read<UserProvider>().trainingStatusAndProgress['Completed'].length}");
    } else {
      return "${context.watch<UserProvider>().otherTrainingListLength.toInt()}";
    }
  }

  String gridViewCardPerc() {
    if (widget.cardName == "Yet to Start") {
      return ("${context.read<UserProvider>().newPerc}");
    }
    if (widget.cardName == "In Progress") {
      return ("${(context.read<UserProvider>().inProgressPerc)}");
    }
    if (widget.cardName == "Completed") {
      return ("${context.read<UserProvider>().completedPerc}");
    } else {
      return "0";
    }
  }
}
