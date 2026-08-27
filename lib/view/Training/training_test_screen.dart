import 'dart:async';

import 'package:adaptive_dialog/adaptive_dialog.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:gurukul/provider/api_provider.dart';
import 'package:gurukul/provider/tab_provider.dart';
import 'package:gurukul/provider/theme_provider.dart';
import 'package:gurukul/utils/colors.dart';
import 'package:gurukul/utils/widgets/custom_appbar.dart';
import 'package:provider/provider.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';

import '../../model/training_test.dart';
import '../../utils/widgets/options_widget.dart';

enum TestDecision { Pass, Fail }

class TrainingTestScreen extends StatefulWidget {
  const TrainingTestScreen({
    super.key,
    required this.screenTitle,
    required this.heroTag,
    required this.trainingId,
    required this.trainingType,
    required this.cutOff,
    required this.testTimer,
  });

  final String screenTitle;
  final Key heroTag;
  final int trainingId;
  final String trainingType;
  final int cutOff;
  final int testTimer;

  @override
  State<TrainingTestScreen> createState() => _TrainingTestScreenState();
}

class _TrainingTestScreenState extends State<TrainingTestScreen> {
  final scrollController = ScrollController();
  final _scrollController = ScrollController();
  bool _isSubmitting = false;
  late Future<dynamic> _trainingTestFuture;
  Timer? _testCountdownTimer;
  DateTime? _testDeadline;
  int _remainingSeconds = 0;
  bool _timerExpired = false;
  List<D> _questions = [];

  @override
  void initState() {
    super.initState();
    _trainingTestFuture = context
        .read<UserProvider>()
        .getTrainingTest(trainingId: widget.trainingId);
    _trainingTestFuture.then((value) {
      if (!mounted || value == null) return;
      _questions = List<D>.from(value);
      if (widget.testTimer > 0) {
        _startTestCountdown();
      }
    }).catchError((error) {
      debugPrint("Unable to start assessment timer: $error");
      if (mounted) {
        setState(() => _timerExpired = true);
      }
    });
    // _userProvider = Provider.of<UserProvider>(context, listen: false);
    Future.delayed(const Duration(milliseconds: 100), () {
      // Provider.of<UserProvider>(context, listen: false)
      //     .setPageTrack(_pageTrack, 0);
      context.read<UserProvider>().setTrainingPageTrack = 0;

      // context.read<UserProvider>().setCompletedPdfPages = 0;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!(context.read<TabProvider>().isFromCompleted)) {
        context
            .read<UserProvider>()
            .addTranscript(trainingId: widget.trainingId, trainingType: "T");
      }
    });
    debugPrint("cutOff = ${widget.cutOff}");
  }

  bool get _isTimedTestActive => widget.testTimer > 0 && !_timerExpired;

  void _startTestCountdown() {
    _testCountdownTimer?.cancel();
    _testDeadline = DateTime.now().add(Duration(seconds: widget.testTimer));
    setState(() {
      _remainingSeconds = widget.testTimer;
      _timerExpired = false;
    });
    _testCountdownTimer =
        Timer.periodic(const Duration(seconds: 1), (_) => _updateCountdown());
  }

  void _updateCountdown() {
    final deadline = _testDeadline;
    if (!mounted || deadline == null) return;
    final milliseconds = deadline.difference(DateTime.now()).inMilliseconds;
    final remaining = milliseconds <= 0 ? 0 : (milliseconds / 1000).ceil();
    if (remaining == _remainingSeconds) return;
    setState(() {
      _remainingSeconds = remaining;
      if (remaining == 0) _timerExpired = true;
    });
    if (remaining == 0) {
      _testCountdownTimer?.cancel();
      _autoSubmitTest();
    }
  }

  String get _formattedRemainingTime {
    final hours = _remainingSeconds ~/ 3600;
    final minutes = (_remainingSeconds % 3600) ~/ 60;
    final seconds = _remainingSeconds % 60;
    final mm = minutes.toString().padLeft(2, '0');
    final ss = seconds.toString().padLeft(2, '0');
    return hours > 0
        ? '${hours.toString().padLeft(2, '0')}:$mm:$ss'
        : '$mm:$ss';
  }

  Future<void> _autoSubmitTest() async {
    if (_isSubmitting || _questions.isEmpty) return;
    setState(() => _isSubmitting = true);

    final tabProvider = context.read<TabProvider>();
    final selectedByQuestion = <int, int?>{};
    for (var index = 0;
        index < tabProvider.qId.length && index < tabProvider.opSelected.length;
        index++) {
      selectedByQuestion[tabProvider.qId[index]] =
          tabProvider.opSelected[index];
    }

    final questionIds = _questions.map((question) => question.id!).toList();
    final selectedOptions = questionIds
        .map<int?>((questionId) => selectedByQuestion[questionId])
        .toList();
    final marks = context.read<UserProvider>().getMarks;
    final decision = marks < widget.cutOff ? "Fail" : "Pass";
    final submitted = await _submitTestUpdate(
      testDecision: decision,
      questionIds: questionIds,
      selectedOptions: selectedOptions,
    );

    if (!mounted) return;
    if (!submitted) {
      setState(() => _isSubmitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
              "Time is up, but the test could not be submitted. Please use SUBMIT TEST to retry."),
        ),
      );
      return;
    }

    try {
      context.read<UserProvider>()
        ..setPercAndStatus()
        ..getOtherTrainingData();
    } catch (e) {
      debugPrint("Error refreshing after automatic submission: $e");
    }
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
          content: Text("Time is up. Test submitted automatically.")),
    );
    context.go('/home');
  }

  Future<bool> onFailUpdate() async {
    return _submitTestUpdate(testDecision: "Fail");
  }

  Future<bool> onPassUpdate() async {
    return _submitTestUpdate(testDecision: "Pass");
  }

  Future<bool> _submitTestUpdate({
    required String testDecision,
    List<int>? questionIds,
    List<int?>? selectedOptions,
  }) async {
    final userProvider = context.read<UserProvider>();
    final tabProvider = context.read<TabProvider>();

    if (tabProvider.isFromCompleted) {
      return true;
    }

    try {
      final transcriptId = await userProvider.updateTestTranscript(
        trainingId: widget.trainingId.toString(),
        testName: widget.screenTitle,
        testDecision: testDecision,
        testStatus: "Completed",
        bothStatus: "Completed",
        totalMarks: userProvider.getMarks.toString(),
      );
      debugPrint(
          "response add test ${testDecision.toLowerCase()} = $transcriptId");

      if (transcriptId <= 0) {
        debugPrint(
            "Test submission stopped: invalid transcript id $transcriptId");
        return false;
      }

      final detailsResponse = await userProvider.addUserTestTrancriptDetails(
        trainingId: transcriptId.toString(),
        OpSelected: selectedOptions ?? List<int?>.from(tabProvider.opSelected),
        Qid: questionIds ?? tabProvider.qId,
      );

      debugPrint(
          "options Selected ${tabProvider.opSelected} questions Selected ${tabProvider.qId}");
      return detailsResponse > 0;
    } catch (e) {
      debugPrint("Error submitting completed training test: $e");
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;
    final controller = PageController(viewportFraction: 1);

    return WillPopScope(
      onWillPop: () async {
        if (_isTimedTestActive || _isSubmitting) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(_isTimedTestActive
                  ? "You cannot exit until the assessment timer ends."
                  : "Your test is being submitted. Please wait."),
            ),
          );
          return false;
        }
        // return true;

        return await showDialog<bool>(
              context: context,
              builder: (dialogContext) => AlertDialog(
                title: const Text('Exit?'),
                content: const Text(
                    'Are you sure you want to quit. All your progress will be lost.'),
                actions: <Widget>[
                  ElevatedButton(
                    style:
                        ElevatedButton.styleFrom(backgroundColor: Colors.white),
                    onPressed: () => Navigator.of(dialogContext).pop(false),
                    child: const Text(
                      'Cancel',
                      style: TextStyle(color: Colors.black),
                    ),
                  ),
                  ElevatedButton(
                    style:
                        ElevatedButton.styleFrom(backgroundColor: Colors.red),
                    onPressed: () => Navigator.of(dialogContext).pop(true),
                    child: const Text(
                      'Yes',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ],
              ),
            ) ??
            false;
      },
      child: SafeArea(
        child: Scaffold(
          appBar: CustomAppBar(
            size: size,
            title: widget.screenTitle,
            automaticallyImplyLeading: true,
            showLogout: !_isTimedTestActive && !_isSubmitting,
          ),
          body: FutureBuilder(
            future: _trainingTestFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const LinearProgressIndicator();
              } else if (!snapshot.hasData) {
                return Center(
                  child: Text(
                    "Test in progress. Check back soon!",
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.w400,
                      fontSize: 20,
                    ),
                    textAlign: TextAlign.center,
                  ),
                );
              } else {
                return Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      if (widget.testTimer > 0) _buildTimerCard(),
                      Flexible(child: indicator(controller, snapshot)),
                      content(size, controller, snapshot, context),
                    ],
                  ),
                );
              }
            },
          ),
        ),
      ),
    );
  }

  SizedBox content(
    Size size,
    PageController controller,
    AsyncSnapshot<dynamic> snapshot,
    BuildContext context,
  ) {
    return SizedBox(
      height: size.height / 1.3,
      width: size.width,
      child: PageView.builder(
        controller: controller,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: snapshot.data.length,
        onPageChanged: (page) =>
            context.read<UserProvider>().setTrainingPageTrack = page,
        itemBuilder: (_, index) {
          D trainingTest = snapshot.data![index];

          return SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  margin:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                      color: ColorConstraints.cardColor(context),
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: ColorConstraints.cardShadowColor(context),
                          blurRadius: 16,
                          offset: const Offset(0, 8),
                        ),
                      ],
                      border: Border.all(
                        color: context.watch<ThemeChanger>().isNightMode
                            ? Colors.white.withOpacity(0.05)
                            : Colors.grey.withOpacity(0.08),
                        width: 1,
                      )),
                  child: Column(
                    mainAxisSize: MainAxisSize.max,
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Container(
                        height: size.height / 4.5,
                        width: size.width,
                        decoration: BoxDecoration(
                            color: ColorConstraints.testCardBackgroundColor(
                                context),
                            borderRadius: BorderRadius.circular(16)),
                        margin: const EdgeInsets.all(12.0),
                        padding: const EdgeInsets.all(16.0),
                        child: Scrollbar(
                          controller: scrollController,
                          child: SingleChildScrollView(
                            controller: scrollController,
                            child: Text(
                              trainingTest.questionDetails!,
                              style: GoogleFonts.plusJakartaSans(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: ColorConstraints.iconColor(context)),
                            ),
                          ),
                        ),
                      ),
                      trainingTest.opt1! > 0
                          ? OptionButtonWidget(
                              options: trainingTest.opt1Text!,
                              correctOption: trainingTest.wtopt1!,
                              questionIndex: index,
                              pageController: controller,
                              totalNumberOfPage: snapshot.data.length,
                              optionIndex: 0,
                              questionId: trainingTest.id!,
                            )
                          : Container(),
                      trainingTest.opt2! > 0
                          ? OptionButtonWidget(
                              options: trainingTest.opt2Text!,
                              correctOption: trainingTest.wtopt2!,
                              questionIndex: index,
                              pageController: controller,
                              totalNumberOfPage: snapshot.data.length,
                              optionIndex: 1,
                              questionId: trainingTest.id!,
                            )
                          : Container(),
                      trainingTest.opt3! > 0
                          ? OptionButtonWidget(
                              options: trainingTest.opt3Text!,
                              correctOption: trainingTest.wtopt3!,
                              questionIndex: index,
                              pageController: controller,
                              totalNumberOfPage: snapshot.data.length,
                              optionIndex: 2,
                              questionId: trainingTest.id!,
                            )
                          : Container(),
                      trainingTest.opt4! > 0
                          ? OptionButtonWidget(
                              options: trainingTest.opt4Text!,
                              correctOption: trainingTest.wtopt4!,
                              questionIndex: index,
                              pageController: controller,
                              totalNumberOfPage: snapshot.data.length,
                              optionIndex: 3,
                              questionId: trainingTest.id!,
                            )
                          : Container(),
                      trainingTest.opt5! > 0
                          ? OptionButtonWidget(
                              options: trainingTest.opt5Text!,
                              correctOption: trainingTest.wtopt5!,
                              questionIndex: index,
                              pageController: controller,
                              totalNumberOfPage: snapshot.data.length,
                              optionIndex: 4,
                              questionId: trainingTest.id!,
                            )
                          : Container(),
                      const SizedBox(height: 12),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 20.0, vertical: 12.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      index == 0
                          ? Container()
                          : OutlinedButton.icon(
                              style: OutlinedButton.styleFrom(
                                side: BorderSide(
                                    color: ColorConstraints.testControlsColor(
                                            context)
                                        .withOpacity(0.5)),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12)),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 12),
                              ),
                              onPressed: () {
                                controller.animateToPage(
                                    controller.page!.toInt() - 1,
                                    duration: const Duration(milliseconds: 100),
                                    curve: Curves.linear);
                              },
                              icon: Icon(Icons.arrow_back_rounded,
                                  color: ColorConstraints.testControlsColor(
                                      context),
                                  size: 18),
                              label: Text("Back",
                                  style: GoogleFonts.plusJakartaSans(
                                      color: ColorConstraints.testControlsColor(
                                          context),
                                      fontWeight: FontWeight.bold)),
                            ),
                      (context
                                  .read<TabProvider>()
                                  .qId
                                  .contains(trainingTest.id) ||
                              trainingTest.opt1Text!.isEmpty)
                          ? ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor:
                                    ColorConstraints.primaryColor(context),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12)),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 12),
                                elevation: 2,
                              ),
                              onPressed: () {
                                controller.animateToPage(
                                    controller.page!.toInt() + 1,
                                    duration: const Duration(milliseconds: 100),
                                    curve: Curves.linear);
                              },
                              icon: const Icon(Icons.arrow_forward_rounded,
                                  color: Colors.white, size: 18),
                              label: Text("Next",
                                  style: GoogleFonts.plusJakartaSans(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold)),
                            )
                          : Container(),
                    ],
                  ),
                ),
                index + 1 == snapshot.data.length
                    ? Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20.0, vertical: 12.0),
                        child: Container(
                          width: double.infinity,
                          height: 52,
                          decoration: BoxDecoration(
                            gradient: ColorConstraints.accentGradient(context),
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color:
                                    const Color(0xFFF15A24).withOpacity(0.35),
                                blurRadius: 12,
                                offset: const Offset(0, 6),
                              ),
                            ],
                          ),
                          child: ElevatedButton(
                              onPressed: () async {
                                if (_isTimedTestActive) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                          "The test will be submitted automatically when the timer ends."),
                                    ),
                                  );
                                  return;
                                }
                                if (_isSubmitting) {
                                  return;
                                }
                                _isSubmitting = true;

                                int percentage = (Provider.of<UserProvider>(
                                        context,
                                        listen: false)
                                    .getMarks);

                                TestDecision testDecision = TestDecision.Pass;
                                int cuttOffString =
                                    ((widget.cutOff / snapshot.data.length) *
                                            100)
                                        .round();
                                debugPrint("Marks = $percentage");
                                if (percentage < widget.cutOff) {
                                  testDecision = TestDecision.Fail;
                                }

                                final submissionSuccessful =
                                    testDecision == TestDecision.Fail
                                        ? await onFailUpdate()
                                        : await onPassUpdate();

                                if (!context.mounted) {
                                  return;
                                }
                                _isSubmitting = false;

                                if (!submissionSuccessful) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                          "Unable to submit the completed training. Please try again."),
                                    ),
                                  );
                                  return;
                                }

                                if (testDecision == TestDecision.Fail) {
                                  showDialog(
                                    context: context,
                                    builder: (context) {
                                      return AlertDialog(
                                        backgroundColor:
                                            ColorConstraints.cardColor(context),
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(24.0),
                                        ),
                                        title: Text(
                                          "Better luck next time",
                                          textAlign: TextAlign.center,
                                          style: GoogleFonts.plusJakartaSans(
                                            fontWeight: FontWeight.bold,
                                            color: Colors.red.shade400,
                                            fontSize: 20,
                                          ),
                                        ),
                                        content: SingleChildScrollView(
                                          child: ListBody(
                                            children: <Widget>[
                                              Image.asset(
                                                'assets/fail.gif',
                                                scale: 2,
                                              ),
                                              const SizedBox(
                                                height: 16,
                                              ),
                                              Text.rich(
                                                TextSpan(
                                                  text:
                                                      "Unfortunately, you didn't pass the quiz this time. You achieved a score of",
                                                  children: [
                                                    TextSpan(
                                                      text:
                                                          " ${((percentage / snapshot.data.length) * 100).round()}%",
                                                      style: const TextStyle(
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        fontSize: 18,
                                                        color: Colors.red,
                                                      ),
                                                    ),
                                                    const TextSpan(
                                                        text:
                                                            ", while the passing score is",
                                                        style: TextStyle(
                                                          fontWeight:
                                                              FontWeight.bold,
                                                          fontSize: 18,
                                                        )),
                                                    TextSpan(
                                                      text: " $cuttOffString%",
                                                      style: const TextStyle(
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        fontSize: 18,
                                                        color: Colors.green,
                                                      ),
                                                    ),
                                                    const TextSpan(
                                                      text:
                                                          ". But don't be disheartened! Keep learning and practicing, and you're sure to ace it next time!",
                                                    ),
                                                  ],
                                                  style: GoogleFonts
                                                      .plusJakartaSans(
                                                    fontWeight: FontWeight.w400,
                                                    fontSize: 15,
                                                    color: ColorConstraints
                                                        .iconColor(context),
                                                    height: 1.4,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        actions: <Widget>[
                                          TextButton(
                                            child: Text(
                                              'OK',
                                              style:
                                                  GoogleFonts.plusJakartaSans(
                                                fontWeight: FontWeight.bold,
                                                color: ColorConstraints
                                                    .secondaryColor(context),
                                              ),
                                            ),
                                            onPressed: () async {
                                              Navigator.of(context).pop();
                                              try {
                                                context.read<UserProvider>()
                                                  ..setPercAndStatus()
                                                  ..getOtherTrainingData();
                                              } catch (e) {
                                                debugPrint(
                                                    "Error refreshing : $e ");
                                              }
                                              context.go('/home');
                                            },
                                          ),
                                        ],
                                      );
                                    },
                                  );
                                } else {
                                  showDialog(
                                    context: context,
                                    builder: (context) {
                                      return AlertDialog(
                                        backgroundColor:
                                            ColorConstraints.cardColor(context),
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(24.0),
                                        ),
                                        title: Text(
                                          "Congratulations!",
                                          textAlign: TextAlign.center,
                                          style: GoogleFonts.plusJakartaSans(
                                            fontWeight: FontWeight.bold,
                                            color: Colors.green.shade400,
                                            fontSize: 20,
                                          ),
                                        ),
                                        content: SingleChildScrollView(
                                          child: ListBody(
                                            children: <Widget>[
                                              Image.asset(
                                                'assets/success.gif',
                                                scale: 2,
                                              ),
                                              const SizedBox(
                                                height: 16,
                                              ),
                                              Text.rich(
                                                TextSpan(
                                                  text:
                                                      "Fantastic job! You score",
                                                  children: [
                                                    TextSpan(
                                                      text:
                                                          " ${((percentage / snapshot.data.length) * 100).toStringAsFixed(1)}%",
                                                      style: const TextStyle(
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        fontSize: 18,
                                                        color: Colors.green,
                                                      ),
                                                    ),
                                                    const TextSpan(
                                                      text:
                                                          ", You've passed the quiz with flying colors. Keep shining!",
                                                    ),
                                                  ],
                                                  style: GoogleFonts
                                                      .plusJakartaSans(
                                                    fontWeight: FontWeight.w400,
                                                    fontSize: 15,
                                                    color: ColorConstraints
                                                        .iconColor(context),
                                                    height: 1.4,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        actions: <Widget>[
                                          TextButton(
                                            child: Text(
                                              'OK',
                                              style:
                                                  GoogleFonts.plusJakartaSans(
                                                fontWeight: FontWeight.bold,
                                                color: ColorConstraints
                                                    .secondaryColor(context),
                                              ),
                                            ),
                                            onPressed: () async {
                                              Navigator.of(context).pop();
                                              try {
                                                context.read<UserProvider>()
                                                  ..setPercAndStatus()
                                                  ..getOtherTrainingData();
                                              } catch (e) {
                                                debugPrint(
                                                    "Error refreshing : $e ");
                                              }
                                              context.go('/home');
                                            },
                                          ),
                                        ],
                                      );
                                    },
                                  );
                                }
                                try {
                                  context.read<UserProvider>()
                                    ..setPercAndStatus()
                                    ..getOtherTrainingData();
                                } catch (e) {
                                  debugPrint("Error refreshing : $e ");
                                }
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.transparent,
                                shadowColor: Colors.transparent,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                              child: Text(
                                "SUBMIT TEST",
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                  letterSpacing: 0.8,
                                ),
                              )),
                        ),
                      )
                    : Container(),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget indicator(PageController controller, AsyncSnapshot<dynamic> snapshot) {
    // return SmoothPageIndicator(
    //   controller: controller,
    //   count: snapshot.data.length,
    //   axisDirection: Axis.horizontal,
    //   onDotClicked: (value) {
    //     controller.animateToPage(value,
    //         duration: const Duration(milliseconds: 400),
    //         curve: Curves.bounceIn);
    //   },
    //   effect: const WormEffect(
    //     offset: 1,
    //     dotHeight: 8,
    //     dotWidth: 8,
    //     type: WormType.thinUnderground,
    //   ),
    //   // effect: const ScaleEffect(
    //   //   offset: 1,
    //   //   dotHeight: 3,
    //   //   dotWidth: 3,
    //   // ),
    // );
    return Selector<UserProvider, int>(
      selector: (_, provider) => provider.trainingPageTrack,
      builder: (_, trainingPageTrack, __) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: ColorConstraints.primaryColor(context).withOpacity(0.08),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          "Question ${trainingPageTrack + 1} of ${snapshot.data.length}",
          style: GoogleFonts.plusJakartaSans(
            fontWeight: FontWeight.bold,
            color: ColorConstraints.primaryColor(context),
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  Widget _buildTimerCard() {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: (_remainingSeconds <= 60 ? Colors.red : Colors.orange)
            .withOpacity(0.12),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.timer_outlined,
            color: _remainingSeconds <= 60 ? Colors.red : Colors.orange,
          ),
          const SizedBox(width: 8),
          Text(
            _formattedRemainingTime,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: _remainingSeconds <= 60 ? Colors.red : Colors.orange,
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _testCountdownTimer?.cancel();
    scrollController.dispose();
    _scrollController.dispose();
    super.dispose();
  }
}

class CustomImageAlert extends StatelessWidget {
  const CustomImageAlert(
      {super.key,
      required this.dialogImage,
      required this.dialogMessage,
      required this.dialogTitle,
      required this.onPress});

  final String dialogTitle;
  final String dialogMessage;
  final Widget dialogImage;
  final VoidCallback onPress;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 400,
      width: 300,
      child: AlertDialog(
        backgroundColor: Colors.white,
        title: Text(
          dialogTitle,
          style: GoogleFonts.inter(),
          textAlign: TextAlign.center,
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            dialogImage,
            Text(
              dialogMessage,
              style: GoogleFonts.inter(),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: <Widget>[
          TextButton(
            onPressed: onPress,
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}
