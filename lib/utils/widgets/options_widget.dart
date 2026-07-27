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
  Color backgroundCo = Colors.white;
  // late final UserProvider provider;

  @override
  void initState() {
    super.initState();
    // debugPrint("options = ${widget.options}");

    if (widget.correctOption == 1) {
      // optionSelect["${widget.questionIndex}"] =
      //     optionSelect["${widget.questionIndex}"] ?? {};
      // optionSelect["${widget.questionIndex}"]!['correct'] = widget.options;

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
    var getAllAnswers = Provider.of<UserProvider>(context, listen: false).selectedAnswers;
    if (getAllAnswers[questionIndex.toString()] == null ||
        getAllAnswers[questionIndex.toString()]['selectedOption'] == null ||
        getAllAnswers[questionIndex.toString()]['selectedOption'] == "") {
      return context.read<ThemeChanger>().isNightMode
          ? Colors.white.withOpacity(0.08)
          : Colors.black.withOpacity(0.05);
    }
    
    if (getAllAnswers[questionIndex.toString()]['selectedOption'] == option) {
      return getAllAnswers[questionIndex.toString()]['selectedOption'] == getAllAnswers[questionIndex.toString()]['correct']
          ? const Color(0xFF10B981)
          : const Color(0xFFEF4444);
    }
    
    if (getAllAnswers[questionIndex.toString()]['correct'] == option) {
      return const Color(0xFF10B981);
    }
    
    return context.read<ThemeChanger>().isNightMode
        ? Colors.white.withOpacity(0.05)
        : Colors.black.withOpacity(0.03);
  }

  Color _getOptionLetterTextColor(int questionIndex, String option) {
    var getAllAnswers = Provider.of<UserProvider>(context, listen: false).selectedAnswers;
    if (getAllAnswers[questionIndex.toString()] == null ||
        getAllAnswers[questionIndex.toString()]['selectedOption'] == null ||
        getAllAnswers[questionIndex.toString()]['selectedOption'] == "") {
      return ColorConstraints.iconColor(context);
    }
    
    if (getAllAnswers[questionIndex.toString()]['selectedOption'] == option ||
        getAllAnswers[questionIndex.toString()]['correct'] == option) {
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
          var getAllAnswers =
              Provider.of<UserProvider>(context, listen: false).selectedAnswers;

          if (getAllAnswers[widget.questionIndex.toString()] == null ||
              getAllAnswers[widget.questionIndex.toString()]
                      ['selectedOption'] ==
                  null ||
              getAllAnswers[widget.questionIndex.toString()]
                      ['selectedOption'] ==
                  "") {
            if (widget.correctOption == 1) {
              backgroundCo = Colors.green;
              Provider.of<UserProvider>(context, listen: false).addMarks =
                  Provider.of<UserProvider>(context, listen: false).getMarks +
                      1;
            }
            setState(() {});
            Provider.of<UserProvider>(context, listen: false).userSelect(
                correctOption: getAllAnswers[widget.questionIndex.toString()]
                    ['correct'],
                questionIndex: widget.questionIndex,
                selectedOption: widget.options);
            context.read<TabProvider>()
              ..setOpSelected = widget.optionIndex
              ..setQID = widget.questionId;
            Provider.of<UserProvider>(context, listen: false)
                .handleOptions[widget.questionIndex] = true;
            widget.pageController.animateToPage(
                widget.pageController.page!.toInt() + 1,
                duration: const Duration(milliseconds: 400),
                curve: Curves.easeIn);
          } else {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                content: Text("Sorry! You cannot change your answers")));
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
                  color: _getOptionLetterBgColor(widget.questionIndex, widget.options),
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Text(
                  String.fromCharCode(65 + widget.optionIndex), // 'A', 'B', etc.
                  style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: _getOptionLetterTextColor(widget.questionIndex, widget.options),
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

    if (getAllAnswers[questionIndex.toString()]['selectedOption'] ==
        getAllAnswers[questionIndex.toString()]['correct']) {
      return (getAllAnswers[questionIndex.toString()]['selectedOption'] ==
                  option ||
              getAllAnswers[questionIndex.toString()]['correct'] == option)
          ? const Color(0xFFD1FAE5) // light emerald
          : ColorConstraints.cardColor(context);
    }

    return getAllAnswers[questionIndex.toString()]['selectedOption'] == option
        ? const Color(0xFFFEE2E2) // light rose red
        : (getAllAnswers[questionIndex.toString()]['correct'] == option)
            ? const Color(0xFFD1FAE5)
            : ColorConstraints.cardColor(context);
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

    if (getAllAnswers[questionIndex.toString()]['selectedOption'] ==
        getAllAnswers[questionIndex.toString()]['correct']) {
      return (getAllAnswers[questionIndex.toString()]['selectedOption'] ==
                  option ||
              getAllAnswers[questionIndex.toString()]['correct'] == option)
          ? const Color(0xFF10B981) // emerald
          : (context.read<ThemeChanger>().isNightMode
              ? Colors.white.withOpacity(0.12)
              : Colors.grey.shade200);
    }

    return getAllAnswers[questionIndex.toString()]['selectedOption'] == option
        ? const Color(0xFFEF4444) // rose red
        : (getAllAnswers[questionIndex.toString()]['correct'] == option)
            ? const Color(0xFF10B981)
            : (context.read<ThemeChanger>().isNightMode
                ? Colors.white.withOpacity(0.12)
                : Colors.grey.shade200);
  }

  Color answerTextColor(int questionIndex, String option) {
    var getAllAnswers =
        Provider.of<UserProvider>(context, listen: false).selectedAnswers;

    if (getAllAnswers[questionIndex.toString()] == null ||
        getAllAnswers[questionIndex.toString()]['selectedOption'] == null ||
        getAllAnswers[questionIndex.toString()]['selectedOption'] == "") {
      return ColorConstraints.iconColor(context);
    }

    if (getAllAnswers[questionIndex.toString()]['selectedOption'] == option ||
        getAllAnswers[questionIndex.toString()]['correct'] == option) {
      if (getAllAnswers[questionIndex.toString()]['correct'] == option) {
        return const Color(0xFF047857); // dark emerald text
      }
      return const Color(0xFFB91C1C); // dark rose text
    }

    return ColorConstraints.iconColor(context);
  }
}
