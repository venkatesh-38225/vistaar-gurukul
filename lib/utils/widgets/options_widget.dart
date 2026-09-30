import 'package:flutter/material.dart';
import 'package:gurukul/provider/tab_provider.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:gurukul/utils/colors.dart';
import 'package:gurukul/provider/theme_provider.dart';

import '../../provider/api_provider.dart';

class OptionButtonWidget extends StatefulWidget {
  const OptionButtonWidget({
    super.key,
    required this.options,
    required this.correctOption,
    required this.questionIndex,
    required this.optionIndex,
    required this.pageController,
    required this.totalNumberOfPage,
    required this.questionId,
  });

  final String options;
  final int correctOption;
  final int questionIndex;
  final int optionIndex;
  final PageController pageController;
  final int totalNumberOfPage;
  final int questionId;

  @override
  State<OptionButtonWidget> createState() => _OptionButtonWidgetState();
}

class _OptionButtonWidgetState extends State<OptionButtonWidget> {
  @override
  void initState() {
    super.initState();
    // debugPrint("options = ${widget.options}");

    if (widget.correctOption == 1) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        bool alreadyAnswered = Provider.of<UserProvider>(context, listen: false)
            .selectedAnswers
            .containsKey(widget.questionIndex.toString());
        if (!alreadyAnswered) {
          Provider.of<UserProvider>(context, listen: false).userSelect(
              correctOption: widget.options,
              questionIndex: widget.questionIndex,
              selectedOption: "");
        }
      });
    }
  }

  Color _getOptionLetterBgColor(int questionIndex, String option) {
    var getAllAnswers =
        Provider.of<UserProvider>(context, listen: false).selectedAnswers;
    if (getAllAnswers[questionIndex.toString()] == null ||
        getAllAnswers[questionIndex.toString()]['selectedOption'] == null ||
        getAllAnswers[questionIndex.toString()]['selectedOption'] == "") {
      return context.read<ThemeChanger>().isNightMode
          ? Colors.white.withOpacity(0.08)
          : Colors.black.withOpacity(0.05);
    }

    if (getAllAnswers[questionIndex.toString()]['selectedOption'] == option) {
      return const Color(0xFF005BB5);
    }

    return context.read<ThemeChanger>().isNightMode
        ? Colors.white.withOpacity(0.05)
        : Colors.black.withOpacity(0.03);
  }

  Color _getOptionLetterTextColor(int questionIndex, String option) {
    var getAllAnswers =
        Provider.of<UserProvider>(context, listen: false).selectedAnswers;
    if (getAllAnswers[questionIndex.toString()] == null ||
        getAllAnswers[questionIndex.toString()]['selectedOption'] == null ||
        getAllAnswers[questionIndex.toString()]['selectedOption'] == "") {
      return ColorConstraints.iconColor(context);
    }

    if (getAllAnswers[questionIndex.toString()]['selectedOption'] == option) {
      return Colors.white;
    }

    return ColorConstraints.iconColor(context).withOpacity(0.5);
  }

  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      width: size.width / 1.2,
      child: ElevatedButton(
        onPressed: () async {
          final userProvider =
              Provider.of<UserProvider>(context, listen: false);
          final tabProvider = context.read<TabProvider>();
          final qKey = widget.questionIndex.toString();
          final currentAnswerMap = userProvider.selectedAnswers[qKey];

          final String prevSelectedOption =
              currentAnswerMap != null ? (currentAnswerMap['selectedOption'] ?? "") : "";
          final bool prevWasCorrect =
              currentAnswerMap != null ? (currentAnswerMap['wasCorrect'] ?? false) : false;
          final bool isNowCorrect = widget.correctOption == 1;

          // If user taps the already selected option, advance to next question
          if (prevSelectedOption == widget.options) {
            if (widget.questionIndex + 1 < widget.totalNumberOfPage) {
              widget.pageController.animateToPage(
                widget.questionIndex + 1,
                duration: const Duration(milliseconds: 350),
                curve: Curves.easeInOut,
              );
            }
            return;
          }

          // Dynamically adjust marks based on previous vs new choice
          int currentMarks = userProvider.getMarks;
          if (prevSelectedOption.isEmpty) {
            // First time answering this question
            if (isNowCorrect) {
              userProvider.addMarks = currentMarks + 1;
            }
          } else {
            // Modifying an existing answer
            if (prevWasCorrect && !isNowCorrect) {
              userProvider.addMarks = (currentMarks > 0) ? currentMarks - 1 : 0;
            } else if (!prevWasCorrect && isNowCorrect) {
              userProvider.addMarks = currentMarks + 1;
            }
          }

          setState(() {});

          userProvider.userSelect(
            correctOption: currentAnswerMap != null
                ? (currentAnswerMap['correct'] ?? "")
                : "",
            questionIndex: widget.questionIndex,
            selectedOption: widget.options,
            wasCorrect: isNowCorrect,
          );

          tabProvider.setAnswer(widget.questionId, widget.optionIndex);

          if (widget.questionIndex < userProvider.handleOptions.length) {
            userProvider.handleOptions[widget.questionIndex] = true;
          }

          if (widget.questionIndex + 1 < widget.totalNumberOfPage) {
            widget.pageController.animateToPage(
              widget.questionIndex + 1,
              duration: const Duration(milliseconds: 350),
              curve: Curves.easeInOut,
            );
          }
        },
        style: ElevatedButton.styleFrom(
          backgroundColor:
              answerButtonColor(widget.questionIndex, widget.options),
          elevation: 0,
          shadowColor: Colors.transparent,
          side: BorderSide(
            color: answerBorderColor(widget.questionIndex, widget.options),
            width: 1.5,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 14.0, horizontal: 16.0),
          child: Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: _getOptionLetterBgColor(
                      widget.questionIndex, widget.options),
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Text(
                  String.fromCharCode(
                      65 + widget.optionIndex), // 'A', 'B', etc.
                  style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: _getOptionLetterTextColor(
                        widget.questionIndex, widget.options),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  widget.options,
                  textAlign: TextAlign.left,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: answerTextColor(widget.questionIndex, widget.options),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color answerButtonColor(int questionIndex, String option) {
    var getAllAnswers =
        Provider.of<UserProvider>(context, listen: false).selectedAnswers;

    if (getAllAnswers[questionIndex.toString()] == null ||
        getAllAnswers[questionIndex.toString()]['selectedOption'] == null ||
        getAllAnswers[questionIndex.toString()]['selectedOption'] == "") {
      return ColorConstraints.cardColor(context);
    }

    if (getAllAnswers[questionIndex.toString()]['selectedOption'] == option) {
      return context.read<ThemeChanger>().isNightMode
          ? const Color(0xFF005BB5).withOpacity(0.2)
          : const Color(0xFFE0F2FE); // subtle active blue
    }

    return ColorConstraints.cardColor(context);
  }

  Color answerBorderColor(int questionIndex, String option) {
    var getAllAnswers =
        Provider.of<UserProvider>(context, listen: false).selectedAnswers;

    if (getAllAnswers[questionIndex.toString()] == null ||
        getAllAnswers[questionIndex.toString()]['selectedOption'] == null ||
        getAllAnswers[questionIndex.toString()]['selectedOption'] == "") {
      return context.read<ThemeChanger>().isNightMode
          ? Colors.white.withOpacity(0.12)
          : Colors.grey.shade200;
    }

    if (getAllAnswers[questionIndex.toString()]['selectedOption'] == option) {
      return const Color(0xFF005BB5); // Brand blue border
    }

    return context.read<ThemeChanger>().isNightMode
        ? Colors.white.withOpacity(0.12)
        : Colors.grey.shade200;
  }

  Color answerTextColor(int questionIndex, String option) {
    var getAllAnswers =
        Provider.of<UserProvider>(context, listen: false).selectedAnswers;

    if (getAllAnswers[questionIndex.toString()] == null ||
        getAllAnswers[questionIndex.toString()]['selectedOption'] == null ||
        getAllAnswers[questionIndex.toString()]['selectedOption'] == "") {
      return ColorConstraints.iconColor(context);
    }

    if (getAllAnswers[questionIndex.toString()]['selectedOption'] == option) {
      return context.read<ThemeChanger>().isNightMode
          ? Colors.white
          : const Color(0xFF003B75); // Selected option text color
    }

    return ColorConstraints.iconColor(context).withOpacity(0.7);
  }
}
