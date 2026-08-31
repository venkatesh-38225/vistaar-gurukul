import 'dart:async';
import 'dart:io';
import 'package:adaptive_dialog/adaptive_dialog.dart';
import 'package:flutter/foundation.dart';

// import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:gurukul/common/utils.dart';
import 'package:gurukul/constants/app_constants.dart';
import 'package:gurukul/model/training_content.dart';
import 'package:gurukul/model/training.dart' as traininD;
import 'package:gurukul/provider/api_provider.dart';
import 'package:gurukul/provider/tab_provider.dart';
import 'package:gurukul/utils/colors.dart';
import 'package:gurukul/utils/widgets/custom_appbar.dart';
import 'package:gurukul/utils/widgets/loading_error_widgets.dart';
import 'package:gurukul/utils/widgets/lottie_widgets.dart';
import 'package:gurukul/utils/widgets/video_player.dart';
import 'package:gurukul/view/Training/web_pdf_screen.dart';
import 'package:path_provider/path_provider.dart';

// import 'package:photo_view/photo_view.dart';
import 'package:provider/provider.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';

import 'package:http/http.dart' as http;
import 'dart:math' as math;

class TrainingScreen extends StatefulWidget {
  const TrainingScreen({
    super.key,
    required this.heroTag,
    required this.screenTitle,
    required this.trainingId,
    required this.trainingType,
    required this.cutOff,
    this.swipeTimer = 0,
    this.testTimer = 0,
    this.trainingDetails,
    this.fromCompleted = false,
  });

  final Key heroTag;
  final String screenTitle;

  //fetched from api
  final int trainingId;
  final String trainingType;
  final int cutOff;
  final int swipeTimer;
  final int testTimer;
  final bool fromCompleted;
  final traininD.D? trainingDetails;

  @override
  State<TrainingScreen> createState() => _TrainingScreenState();
}

class _TrainingScreenState extends State<TrainingScreen>
    with SingleTickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  final List<int> _pageTrack = [-1];
  AnimationController? _animationController;
  UserProvider? _userProvider;
  late Future<dynamic> _trainingContentFuture;

  // bool _isScrollable = true;
  // bool _pdfLoaded = false;
  final int _latestPdfPage = 0;
  final controller = PageController(viewportFraction: 1);
  final List<Timer> _timers = [];
  final Map<String, Future<String>> _pdfLoadFutures = {};
  final Map<String, PDFViewController> _pdfControllers = {};
  final Map<String, Set<int>> _completedPdfTimerPages = {};
  Timer? _pageMoveTimer;
  String? _activeTimedPdfName;
  int? _activeTimedPdfPage;
  Future<int>? _contentCompletionUpdate;
  bool _beginTestPageJumpScheduled = false;

  bool get _shouldOpenBeginTestPage {
    final details = widget.trainingDetails;
    final completedPercentage =
        double.tryParse(details?.completedPercentage?.trim() ?? '');
    final trainingStatus = details?.trainingStatus?.trim().toLowerCase();

    return widget.trainingType.trim().toUpperCase() == "C+T" &&
        completedPercentage != null &&
        completedPercentage >= 50 &&
        completedPercentage < 100 &&
        trainingStatus == "inprogress";
  }

  void _startPageMoveTimer({String? pdfName, int? pdfPage}) {
    final isPdfPage = pdfName != null && pdfPage != null;
    final completedPdfPages =
        isPdfPage ? _completedPdfTimerPages[pdfName] : null;
    if (isPdfPage && completedPdfPages?.contains(pdfPage) == true) {
      _pageMoveTimer?.cancel();
      context.read<TabProvider>().startCountdown(0);
      context.read<TabProvider>().setCanMovePage = true;
      return;
    }
    if (isPdfPage &&
        _activeTimedPdfName == pdfName &&
        _activeTimedPdfPage == pdfPage &&
        (_pageMoveTimer?.isActive ?? false)) {
      return;
    }

    _pageMoveTimer?.cancel();
    _activeTimedPdfName = pdfName;
    _activeTimedPdfPage = pdfPage;
    if (widget.swipeTimer <= 0) {
      if (isPdfPage) {
        _completedPdfTimerPages
            .putIfAbsent(pdfName, () => <int>{})
            .add(pdfPage);
      }
      context.read<TabProvider>().startCountdown(0);
      context.read<TabProvider>().setCanMovePage = true;
      return;
    }
    context.read<TabProvider>().setCanMovePage = false;
    context.read<TabProvider>().startCountdown(widget.swipeTimer);
    _pageMoveTimer = Timer(Duration(seconds: widget.swipeTimer), () {
      if (mounted) {
        if (isPdfPage) {
          _completedPdfTimerPages
              .putIfAbsent(pdfName, () => <int>{})
              .add(pdfPage);
        }
        context.read<TabProvider>().setCanMovePage = true;
      }
    });
  }

  Future<void> _showResumeDialog(int desiredPageIndex) async {
    if (!mounted) return;
    final resume = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Resume?'),
        content: const Text('Do you want to resume from where you left off?'),
        actions: <Widget>[
          TextButton(
            child: const Text('No'),
            onPressed: () => Navigator.of(dialogContext).pop(false),
          ),
          TextButton(
            child: const Text('Yes'),
            onPressed: () => Navigator.of(dialogContext).pop(true),
          ),
        ],
      ),
    );
    if (!mounted) return;

    final targetPage = resume == true ? desiredPageIndex : 0;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !controller.hasClients) return;
      controller.jumpToPage(targetPage);
      context.read<UserProvider>().setTrainingPageTrack = targetPage;
      _startPageMoveTimer();
    });
  }

  Future<String> _pdfFutureFor(D trainingContent) {
    final fileName = trainingContent.pDFName!;
    return _pdfLoadFutures.putIfAbsent(
      fileName,
      () => loadPdf(
        "$trainingContentAssetsUrl/$fileName",
        fileName,
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _userProvider = Provider.of<UserProvider>(context, listen: false);

    _trainingContentFuture =
        _userProvider!.getTrainingContent(trainingId: widget.trainingId);
    _trainingContentFuture.then((value) {
      if (mounted && value != null) {
        final length = value.length;
        bool resumeDialogScheduled = false;

        // Set initial complete track percentage only when content is available.
        if (length > 0) {
          context
              .read<UserProvider>()
              .setContentCompleteTrackPerc(1, length + 1);
        }

        // Add photos to TabProvider if they are empty
        final tabProv = context.read<TabProvider>();
        if (tabProv.getPhotos.isEmpty) {
          debugPrint("adding photos from initState future resolution");
          for (var i = 0; i < length; i++) {
            var trainingContents = value[i];
            if (trainingContents.imageName != null &&
                trainingContents.imageName!.isNotEmpty) {
              tabProv.addPhotos = {
                "index": i,
                "image": trainingContents.imageName!,
              };
            }
          }
        }

        // Resume from last viewed page logic. A C+T training whose content is
        // already complete opens on its test-introduction page instead.
        final details = widget.trainingDetails;
        if (details != null && !_shouldOpenBeginTestPage) {
          final completedPercentageStr = details.completedPercentage;
          if (completedPercentageStr != null &&
              completedPercentageStr.isNotEmpty &&
              completedPercentageStr != "0") {
            final double? completedPercentage =
                double.tryParse(completedPercentageStr);
            // Progress includes one terminal page (success/test), but resuming
            // must always land on an actual content page. Otherwise a high or
            // stale in-progress percentage can open the terminal page and mark
            // the training as completed without the user finishing it.
            final int totalPage = length + 1;
            if (completedPercentage != null && length > 0) {
              final contentPercentage = widget.trainingType == "C+T"
                  ? (completedPercentage * 2).clamp(0, 100).toDouble()
                  : completedPercentage;
              final calculatedPageIndex =
                  ((contentPercentage / 100) * totalPage).round() - 1;
              final desiredPageIndex =
                  calculatedPageIndex.clamp(0, length - 1).toInt();
              debugPrint(
                  "Resume logic: desiredPage = $desiredPageIndex, content pages = $length, total page = $totalPage, % completed = $completedPercentage");

              // Page zero is already the initial page, so asking to resume
              // there makes Yes and No appear to do the same thing.
              if (desiredPageIndex > 0) {
                resumeDialogScheduled = true;
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  _showResumeDialog(desiredPageIndex);
                });
              }
            }
          }
        }

        if (length > 0 && !resumeDialogScheduled && !_shouldOpenBeginTestPage) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) _startPageMoveTimer();
          });
        }
      }
    });

    if (!widget.fromCompleted) {
      context
          .read<UserProvider>()
          .addTranscript(trainingId: widget.trainingId, trainingType: "C");
    }
    // debugPrint("allowing all rotations");
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
      DeviceOrientation.portraitDown,
      DeviceOrientation.portraitUp,
    ]);

    Provider.of<UserProvider>(context, listen: false)
        .setPageTrack(_pageTrack, 0);
    context.read<UserProvider>()
      ..setIsScrollable = true
      ..setLatestPdfPage = 0
      ..setCompletedPdfPages = 0
      ..setPdfLoaded = false
      ..setTrainingPageTrack = 0;
    _animationController = AnimationController(
      duration: const Duration(seconds: 1),
      vsync: this,
    )..repeat(reverse: true);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<TabProvider>().clearPhotos();
      }
    });
  }

  Future<int> calculateContentProgress() async {
    debugPrint(
        "totalPage = ${_userProvider!.contentCompleteTrackPerc['totalPage']}");
    int? onPage = _userProvider!.contentCompleteTrackPerc['onPage'];
    int? totalPage = _userProvider!.contentCompleteTrackPerc['totalPage'];
    if (onPage != null && totalPage != null && totalPage > 0) {
      final contentPercentage = (onPage / totalPage) * 100;
      final percentage = widget.trainingType == "C+T"
          ? contentPercentage / 2
          : contentPercentage;
      debugPrint(
          "onpage = $onPage, total = $totalPage, perc = ${percentage.toStringAsFixed(2)}");
      if (contentPercentage >= 100) {
        if (widget.trainingType == "C+T") {
          debugPrint("Content completed; combined training is 50% complete");
          return _userProvider!.updateTranscript(
              trainingId: widget.trainingId,
              contentName: widget.screenTitle,
              completedPerc: "50",
              contentStatus: "Completed",
              bothStatus: "");
        } else {
          return _userProvider!.updateTranscript(
              trainingId: widget.trainingId,
              contentName: widget.screenTitle,
              completedPerc: "100",
              contentStatus: "Completed",
              bothStatus: "Completed");
        }
      } else {
        debugPrint("Initiated");
        return _userProvider!.updateTranscript(
            trainingId: widget.trainingId,
            contentName: widget.screenTitle,
            completedPerc: percentage.toStringAsFixed(2),
            contentStatus: "Initiated",
            bothStatus: "");
      }
    }
    return 0;
  }

  Stream<int> counter() {
    return Stream.periodic(const Duration(seconds: 1), (i) => i).take(4);
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    Size size = MediaQuery.of(context).size;
    debugPrint("contains => ${widget.trainingDetails}");
    bool isPortrait =
        (MediaQuery.of(context).orientation == Orientation.portrait || kIsWeb);

    return WillPopScope(
      onWillPop: () async {
        final bool? result = await showDialog<bool>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            backgroundColor: ColorConstraints.cardColor(dialogContext),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
            contentPadding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.amber.shade100,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.warning_amber_rounded,
                    color: Colors.amber.shade800,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Text(
                  'Exit Training?',
                  style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                  ),
                ),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Are you sure you want to exit this training? Your current progress will be saved.',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 15,
                    height: 1.5,
                    color: Theme.of(dialogContext)
                        .textTheme
                        .bodyMedium
                        ?.color
                        ?.withOpacity(0.8),
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.of(dialogContext).pop(false),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: Text(
                        'Cancel',
                        style: GoogleFonts.plusJakartaSans(
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[600],
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue.shade600,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      onPressed: () => Navigator.of(dialogContext).pop(true),
                      child: Text(
                        'Yes, Exit',
                        style: GoogleFonts.plusJakartaSans(
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
        if (result != true || !context.mounted) {
          return false;
        }

        if (!widget.fromCompleted) {
          calculateContentProgress();
          context.read<UserProvider>().setPercAndStatus();
        }
        try {
          context.read<UserProvider>()
            ..setIsScrollable = true
            ..setLatestPdfPage = 0
            ..setCompletedPdfPages = 0;
        } catch (e) {
          debugPrint("Error refreshing : $e ");
        }
        return true;
      },
      child: FutureBuilder(
        future: _trainingContentFuture,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Scaffold(
              body: Center(
                child: LottieLoadingWidget(
                  size: 150,
                  message: "Loading training content...",
                ),
              ),
            );
          }
          final data = snapshot.data as List;
          if (data.isEmpty) {
            return const Scaffold(
              body: Center(
                child: NoTrainingWidget(
                  message: "No content is available for this training.",
                ),
              ),
            );
          }
          final totalPages = data.length + 1;

          if (_shouldOpenBeginTestPage && !_beginTestPageJumpScheduled) {
            _beginTestPageJumpScheduled = true;
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (!mounted || !controller.hasClients) {
                _beginTestPageJumpScheduled = false;
                return;
              }

              final beginTestPage = data.length;
              context.read<UserProvider>()
                ..setContentCompleteTrackPerc(beginTestPage + 1, totalPages)
                ..setTrainingPageTrack = beginTestPage;
              context.read<TabProvider>()
                ..startCountdown(0)
                ..setCanMovePage = true;
              controller.jumpToPage(beginTestPage);
            });
          }

          return SafeArea(
            child: Scaffold(
              appBar: PreferredSize(
                preferredSize: const Size.fromHeight(kToolbarHeight),
                child: AnimatedOpacity(
                  duration: const Duration(milliseconds: 300),
                  opacity: isPortrait ? 1.0 : 0.0,
                  child: isPortrait
                      ? CustomAppBar(
                          size: size,
                          title: "",
                          automaticallyImplyLeading: true,
                        )
                      : const SizedBox.shrink(),
                ),
              ),
              body: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    AnimatedOpacity(
                      duration: const Duration(milliseconds: 300),
                      opacity: isPortrait ? 1.0 : 0.0,
                      child: isPortrait
                          ? Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8.0, vertical: 4.0),
                              child: Selector<UserProvider, int>(
                                selector: (_, provider) =>
                                    provider.trainingPageTrack,
                                builder: (_, trainingPageTrack, __) =>
                                    progressHeader(
                                  trainingPageTrack,
                                  totalPages,
                                ),
                              ),
                            )
                          : const SizedBox.shrink(),
                    ),
                    Expanded(
                      child: Container(
                        child: content(size, controller, snapshot, context),
                      ),
                    ),
                  ],
                ),
              ),
              bottomNavigationBar: isPortrait
                  ? Selector<UserProvider, int>(
                      selector: (_, provider) => provider.trainingPageTrack,
                      builder: (context, trainingPageTrack, _) {
                        if (trainingPageTrack >= totalPages - 1) {
                          // Hide on the last page (Test/Success Screen)
                          return const SizedBox.shrink();
                        }
                        final bool isPdfContentPage = trainingPageTrack >= 0 &&
                            trainingPageTrack < data.length &&
                            (data[trainingPageTrack] as D).pDFName!.isNotEmpty;
                        return Container(
                          padding: const EdgeInsets.only(
                            left: 20,
                            right: 20,
                            bottom: 24,
                            top: 16,
                          ),
                          decoration: BoxDecoration(
                            color: ColorConstraints.cardColor(context),
                            border: Border(
                              top: BorderSide(
                                color: Colors.grey.withOpacity(0.15),
                                width: 1,
                              ),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              // Previous Button
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: trainingPageTrack > 0
                                      ? () {
                                          context
                                              .read<UserProvider>()
                                              .setPageTrack([-1], -1);
                                          controller.animateToPage(
                                            trainingPageTrack - 1,
                                            duration: const Duration(
                                                milliseconds: 400),
                                            curve: Curves.easeInOut,
                                          );
                                        }
                                      : null,
                                  icon: const Icon(
                                      Icons.arrow_back_ios_new_rounded,
                                      size: 16),
                                  label: const Text("Previous"),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor:
                                        Theme.of(context).primaryColor,
                                    side: BorderSide(
                                        color: Theme.of(context)
                                            .primaryColor
                                            .withOpacity(0.5)),
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 14),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                ),
                              ),
                              if (!isPdfContentPage) const SizedBox(width: 16),
                              // Next / Progress Button
                              if (!isPdfContentPage)
                                Expanded(
                                  child: Consumer<TabProvider>(
                                    builder: (context, tabProvider, _) {
                                      final isReady =
                                          tabProvider.countdownValue == 0;
                                      final canMovePage =
                                          tabProvider.canMovePage;
                                      final bool isCountdownPending =
                                          !isReady && !canMovePage;

                                      VoidCallback? onPressed;
                                      String btnText = "Next";
                                      IconData iconData =
                                          Icons.arrow_forward_ios_rounded;
                                      Color btnColor =
                                          Theme.of(context).primaryColor;

                                      if (isCountdownPending) {
                                        btnText =
                                            "Next (${tabProvider.countdownValue}s)";
                                        iconData =
                                            Icons.hourglass_empty_rounded;
                                        btnColor = Colors.grey[500]!;
                                        onPressed = null;
                                      } else {
                                        onPressed = () {
                                          controller.animateToPage(
                                            trainingPageTrack + 1,
                                            duration: const Duration(
                                                milliseconds: 400),
                                            curve: Curves.easeInOut,
                                          );
                                        };
                                      }

                                      return ElevatedButton.icon(
                                        onPressed: onPressed,
                                        icon: Icon(iconData,
                                            size: 16, color: Colors.white),
                                        label: Text(
                                          btnText,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white,
                                          ),
                                        ),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: btnColor,
                                          disabledBackgroundColor:
                                              Colors.grey[300],
                                          padding: const EdgeInsets.symmetric(
                                              vertical: 14),
                                          elevation: onPressed != null ? 3 : 0,
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(12),
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                            ],
                          ),
                        );
                      },
                    )
                  : null,
            ),
          );
        },
      ),
    );
  }

  SizedBox content(Size size, PageController controller,
      AsyncSnapshot<dynamic> snapshot, BuildContext context) {
    // Key pdfKey = const Key("pdfKey");

//Provider.of<ProvideName>(context, listen: false).addValue() //Selector Widget
//Provider.of<ProvideName>(context).addValue() //Consumer WIdget
    return SizedBox(
      height: size.height,
      width: size.width,
      child: Selector<UserProvider, bool>(
        selector: (_, prov) {
          return prov.isScrollable;
        },
        builder: (_, isScrollable, __) {
          ScrollPhysics physics = isScrollable
              ? const PageScrollPhysics()
              : const NeverScrollableScrollPhysics();
          return Selector<TabProvider, bool>(
            selector: (_, provider) => provider.canMovePage,
            builder: (_, canMovePage, __) => PageView.builder(
              controller: controller,
              physics: _shouldOpenBeginTestPage
                  ? const NeverScrollableScrollPhysics()
                  : canMovePage
                      ? physics
                      : const NeverScrollableScrollPhysics(),
              itemCount: snapshot.data.length + 1,
              onPageChanged: (page) {
                debugPrint("data length = ${snapshot.data.length}");
                context.read<UserProvider>().setContentCompleteTrackPerc(
                    page + 1, snapshot.data.length + 1);

                if (widget.trainingType == "C+T" &&
                    !widget.fromCompleted &&
                    !_shouldOpenBeginTestPage &&
                    page == snapshot.data.length) {
                  _contentCompletionUpdate ??= calculateContentProgress();
                }

                context.read<UserProvider>().setTrainingPageTrack = page;
                if (snapshot.data.isNotEmpty && page < snapshot.data.length) {
                  final D currentContent = snapshot.data[page];
                  final isPdfContent = currentContent.pDFName!.isNotEmpty;
                  _pageTrack
                    ..clear()
                    ..add(isPdfContent ? 0 : -1);
                  context.read<UserProvider>()
                    ..setLatestPdfPage = 0
                    ..setTotalPdfPage = 0
                    ..setPageTrack(_pageTrack, 0);
                  _startPageMoveTimer();
                }
              },
              itemBuilder: (_, index) {
                if (index < snapshot.data.length) {
                  D trainingContent = snapshot.data![index];

                  return trainingContent.pDFName!.isEmpty
                      ? SingleChildScrollView(
                          child: Column(
                            children: [
                              contentAttach(
                                  docName: trainingContent, index: index),
                              Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Text(
                                  trainingContent.content!,
                                  style: GoogleFonts.inter(
                                    fontSize: 20,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 20),
                            ],
                          ),
                        )
                      : FutureBuilder<String>(
                          future: _pdfFutureFor(trainingContent),
                          builder: (ctx, snapshot) {
                            if (snapshot.connectionState ==
                                ConnectionState.waiting) {
                              return const Center(
                                child: LottieLoadingWidget(
                                  size: 120,
                                  message: "Loading PDF...",
                                ),
                              );
                            } else if (snapshot.hasError) {
                              return Text("Error: ${snapshot.error}");
                            } else {
                              String previousPageString =
                                  "${controller.page!.round()}.5";
                              double previousPage =
                                  double.parse(previousPageString);

                              return
                                  // kIsWeb
                                  //     ? Scaffold(
                                  //         body: ListView(
                                  //           shrinkWrap: true,
                                  //           scrollDirection: Axis.vertical,
                                  //           children: [
                                  //             WebPdfScreen(
                                  //               width: size.width / 1.2,
                                  //               height: size.height / 1.4,
                                  //               pdfUrl:
                                  //                   "$trainingContentAssetsUrl/${trainingContent.pDFName}",
                                  //             ),
                                  //             ElevatedButton(
                                  //               style: ElevatedButton.styleFrom(
                                  //                   backgroundColor: Colors.green),
                                  //               onPressed: () {
                                  //                 context
                                  //                     .read<UserProvider>()
                                  //                     .setIsScrollable = true;
                                  //                 controller.animateToPage(
                                  //                   controller.page!.toInt() + 1,
                                  //                   duration: const Duration(
                                  //                       milliseconds: 500),
                                  //                   curve: Curves.easeInOut,
                                  //                 );
                                  //               },
                                  //               child: const Text("Finish",
                                  //                   style: TextStyle(
                                  //                       color: Colors.white,
                                  //                       fontWeight: FontWeight.w600)),
                                  //             )
                                  //           ],
                                  //         ),
                                  //       )
                                  //     :
                                  Scaffold(
                                // backgroundColor: Colors.blue.shade100,
                                body: Column(
                                  children: [
                                    Expanded(
                                      child: Stack(
                                        children: [
                                          Center(
                                            child: PDFView(
                                              defaultPage: context
                                                          .read<UserProvider>()
                                                          .completedPdfPage >
                                                      0
                                                  ? context
                                                      .read<UserProvider>()
                                                      .completedPdfPage
                                                  : context
                                                      .read<UserProvider>()
                                                      .latestPdfPage,
                                              onPageError: (page, error) =>
                                                  const CircularProgressIndicator(),
                                              pageSnap: true,
                                              //ADD THIS TO ENABLE NIGHT MODE IN PDF AS WELL
                                              // nightMode: context
                                              //     .read<TabProvider>()
                                              //     .isNightMode,
                                              fitPolicy: MediaQuery.of(context)
                                                          .orientation ==
                                                      Orientation.portrait
                                                  ? FitPolicy.WIDTH
                                                  : FitPolicy.BOTH,
                                              fitEachPage: true,
                                              filePath: snapshot.data!,
                                              enableSwipe: false,
                                              swipeHorizontal: true,

                                              // onRender: (page) {
                                              //   debugPrint("page on Render called");
                                              // },
                                              onRender: (pages) {
                                                debugPrint("pdf onRender");
                                                // if (pages! > 1) {
                                                //   if (controller.page! >
                                                //       previousPage) {
                                                //     debugPrint(
                                                //         "page completely swiped");

                                                // if (!context
                                                //     .read<UserProvider>()
                                                //     .pdfLoaded) {
                                                // setState(() {
                                                context.read<UserProvider>()
                                                  ..setIsScrollable = false
                                                  ..setPdfLoaded = true;

                                                // _pdfLoaded = true;
                                                // });
                                                // }
                                                //   } else {
                                                //     debugPrint(
                                                //         "page incomplete swipe");
                                                //   }
                                                // }
                                              },
                                              onViewCreated: (pdfController) {
                                                debugPrint("pdf onViewCreated");
                                                _pdfControllers[trainingContent
                                                    .pDFName!] = pdfController;
                                              },
                                              onPageChanged: (page, total) {
                                                debugPrint("pdf onPageChanged");
                                                context.read<UserProvider>()
                                                  ..setLatestPdfPage = page!
                                                  ..setTotalPdfPage = total!;

                                                if (page == 2 &&
                                                    Provider.of<UserProvider>(
                                                                context,
                                                                listen: false)
                                                            .getPageTrack ==
                                                        1) {}
                                                _pageTrack.add(page);

                                                Provider.of<UserProvider>(
                                                        context,
                                                        listen: false)
                                                    .setPageTrack(
                                                        _pageTrack, total);
                                                _startPageMoveTimer(
                                                  pdfName:
                                                      trainingContent.pDFName!,
                                                  pdfPage: page,
                                                );
                                              },
                                            ),
                                          ),
                                          Positioned(
                                            bottom: 10,
                                            left: 5,
                                            right: 5,
                                            child: Consumer2<UserProvider,
                                                TabProvider>(
                                              builder: (_, userProvider,
                                                  tabProvider, __) {
                                                final currentPage =
                                                    userProvider.latestPdfPage;
                                                final totalPdfPages =
                                                    userProvider.totalPage;
                                                final isFirstPage =
                                                    currentPage == 0;
                                                final isLastPage =
                                                    totalPdfPages > 0 &&
                                                        currentPage ==
                                                            totalPdfPages - 1;
                                                final isCountdownPending =
                                                    tabProvider.countdownValue >
                                                            0 &&
                                                        !tabProvider
                                                            .canMovePage;
                                                final pdfController =
                                                    _pdfControllers[
                                                        trainingContent
                                                            .pDFName!];
                                                final canGoNext =
                                                    pdfController != null &&
                                                        totalPdfPages > 0 &&
                                                        !isCountdownPending;
                                                final nextLabel = isCountdownPending
                                                    ? "${isLastPage ? 'Finish' : 'Next'} (${tabProvider.countdownValue}s)"
                                                    : isLastPage
                                                        ? "Finish"
                                                        : "Next";

                                                return Row(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment
                                                          .spaceBetween,
                                                  children: [
                                                    ElevatedButton.icon(
                                                      onPressed: !isFirstPage &&
                                                              pdfController !=
                                                                  null
                                                          ? () => pdfController
                                                              .setPage(
                                                                  currentPage -
                                                                      1)
                                                          : null,
                                                      icon: const Icon(
                                                        Icons
                                                            .arrow_back_ios_new_rounded,
                                                        size: 16,
                                                      ),
                                                      label: const Text(
                                                          "Previous"),
                                                    ),
                                                    ElevatedButton.icon(
                                                      style: ElevatedButton
                                                          .styleFrom(
                                                        backgroundColor:
                                                            canGoNext
                                                                ? Colors.green
                                                                : Colors.grey,
                                                      ),
                                                      onPressed: canGoNext
                                                          ? () {
                                                              if (!isLastPage) {
                                                                pdfController
                                                                    .setPage(
                                                                        currentPage +
                                                                            1);
                                                                return;
                                                              }
                                                              context
                                                                  .read<
                                                                      UserProvider>()
                                                                  .setIsScrollable = true;
                                                              controller
                                                                  .animateToPage(
                                                                controller.page!
                                                                        .toInt() +
                                                                    1,
                                                                duration:
                                                                    const Duration(
                                                                        milliseconds:
                                                                            500),
                                                                curve: Curves
                                                                    .easeInOut,
                                                              );
                                                            }
                                                          : null,
                                                      icon: Icon(
                                                        isLastPage
                                                            ? Icons
                                                                .check_circle_outline_rounded
                                                            : Icons
                                                                .arrow_forward_ios_rounded,
                                                        size: 16,
                                                      ),
                                                      label: Text(nextLabel),
                                                    ),
                                                  ],
                                                );
                                              },
                                            ),
                                          )
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }
                          });
                } else {
                  if (widget.trainingType != "C+T") {
                    Stream<int> counter() {
                      return Stream.periodic(
                          const Duration(seconds: 1), (i) => i).take(4);
                    }

                    return StreamBuilder<int>(
                      stream: counter(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const LoadingWidget();
                        }

                        if (snapshot.connectionState == ConnectionState.done) {
                          Future.delayed(Duration.zero, () {
                            if (mounted) {
                              if (!widget.fromCompleted) {
                                calculateContentProgress();
                              }
                              Provider.of<UserProvider>(context, listen: false)
                                  .resetUserSelect();
                              context.go('/home', extra: {
                                'screenTitle': widget.screenTitle,
                                'heroTag': widget.heroTag,
                                'trainingID': widget.trainingId,
                              });
                            }
                          });
                        }

                        return Container(
                          height: size.height,
                          width: size.width,
                          alignment: Alignment.center,
                          padding: const EdgeInsets.all(24),
                          child: Card(
                            color: ColorConstraints.cardColor(context),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(28)),
                            elevation: 8,
                            shadowColor:
                                ColorConstraints.cardShadowColor(context),
                            child: Padding(
                              padding: const EdgeInsets.all(32.0),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Image.asset(
                                    'assets/success.gif',
                                    scale: 1.5,
                                  ),
                                  const SizedBox(height: 24),
                                  Text(
                                    "Congratulations!",
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 28,
                                      fontWeight: FontWeight.w800,
                                      color: const Color(0xFF10B981),
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    "You have completed your training for\n${widget.screenTitle}",
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      height: 1.4,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                  const SizedBox(height: 24),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 16, vertical: 8),
                                    decoration: BoxDecoration(
                                      color: ColorConstraints.topicCardColor(
                                          context),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      'Returning to home in ${3 - snapshot.data!} seconds...',
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                        color: Theme.of(context)
                                            .textTheme
                                            .bodySmall
                                            ?.color
                                            ?.withOpacity(0.6),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    );
                  } else {
                    return Container(
                        height: size.height,
                        width: size.width,
                        alignment: Alignment.center,
                        margin: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        // color: Colors.blue.shade100,
                        child: Column(
                          // mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text(
                              "Ready to Test Your Knowledge?",
                              style: TextStyle(
                                fontSize: 34,
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 20),
                            Image.asset('assets/test.png',
                                height: size.height / 6),
                            const SizedBox(height: 20),
                            const Text(
                              "Feel confident about what you've learned? Click below to start the test and showcase your understanding.",
                              style: TextStyle(fontSize: 20),
                              // textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 60),
                            ElevatedButton(
                                onPressed: () async {
                                  // var alertResult = await showOkCancelAlertDialog(
                                  //     context: context,
                                  //     title: "Are you ready to take the test?",
                                  //     message:
                                  //         "It’s time to put your knowledge to the test. Are you ready to take the test and see how much you’ve learned?");
                                  // if (alertResult == OkCancelResult.ok) {
                                  debugPrint(
                                      "cutoff trianing_screen: ${widget.cutOff}");
                                  Provider.of<UserProvider>(context,
                                          listen: false)
                                      .resetUserSelect();
                                  context.read<TabProvider>().resetSelection();

                                  // Ensure the content-side 50% update finishes
                                  // before the assessment can later promote the
                                  // combined training to 100%.
                                  if (!widget.fromCompleted &&
                                      !_shouldOpenBeginTestPage) {
                                    await (_contentCompletionUpdate ??=
                                        calculateContentProgress());
                                  }

                                  if (context.mounted) {
                                    context.read<UserProvider>()
                                      ..setIsScrollable = true
                                      ..setTrainingPageTrack = 0;
                                    context.replace('/training-test', extra: {
                                      'screenTitle': widget.screenTitle,
                                      'heroTag': widget.heroTag,
                                      'trainingID': widget.trainingId,
                                      'containsTest': widget.trainingType,
                                      'cutOff': widget.cutOff,
                                      'testTimer': widget.testTimer,
                                    });
                                  }
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.blue.shade300,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(50),
                                  ),
                                ),
                                child: Text(
                                  "BEGIN TEST",
                                  style: TextStyle(
                                      fontSize: 25,
                                      fontWeight: FontWeight.w600,
                                      color:
                                          ColorConstraints.iconColor(context)),
                                )),
                          ],
                        ));
                  }
                }
              },
            ),
          );
        },
      ),
    );
  }

  Future<String> downloadAndSavePdf(String sampleUrl, String fileName) async {
    final directory = await getApplicationDocumentsDirectory();
    final file = File('${directory.path}/$fileName');
    if (await file.exists()) {
      return file.path;
    }
    final response = await http.get(Uri.parse(sampleUrl));
    await file.writeAsBytes(response.bodyBytes);
    return file.path;
  }

  Future<String> loadPdf(String sampleUrl, String fileName) async {
    String pdfFlePath = await downloadAndSavePdf(sampleUrl, fileName);
    debugPrint("pdfFilePath = $pdfFlePath");
    return pdfFlePath;

    // setState(() {});
  }

  Widget contentAttach({required D docName, required int index}) {
    // debugPrint(
    //     "docName = ${docName.docName}, imageName = ${docName.imagePath},\n pdfName = ${docName.pDFName}, pptName = ${docName.pPTName}, videoName = ${docName.videoName}");
    if (docName.imageName!.isNotEmpty) {
      return GestureDetector(
        onTap: () {
          debugPrint("openinig image ${docName.imageName} at $index");

          context.push('/photo-viewer', extra: "${docName.imageName}").then(
              (value) => Future.delayed(const Duration(milliseconds: 200), () {
                    controller.animateToPage(
                      context.read<TabProvider>().photoPage,
                      duration: const Duration(milliseconds: 100),
                      curve: Curves.easeInOut,
                    );
                  }));
        },
        child: Hero(
          tag: imageHero,
          child: Container(
            height: MediaQuery.of(context).orientation == Orientation.landscape
                ? MediaQuery.of(context).size.height
                : MediaQuery.of(context).size.height / 2,
            // : null,
            width: MediaQuery.of(context).size.width,
            // constraints: BoxConstraints(
            //   minHeight: MediaQuery.of(context).size.height / 3,
            //   minWidth: MediaQuery.of(context).size.width,
            //   maxHeight: 400,
            //   maxWidth: 900,
            // ),
            margin: const EdgeInsets.all(0),
            decoration:
                // MediaQuery.of(context).orientation == Orientation.portrait
                //     ? BoxDecoration(
                //         border: Border.all(
                //           color: Colors.blue.shade300,
                //           width: 3,
                //         ),
                //       )
                //     :
                BoxDecoration(
              image: DecorationImage(
                fit: BoxFit.contain,
                onError: (err, stacktrace) {},
                image: NetworkImage(
                  "$trainingContentAssetsUrl/${docName.imageName}",
                ),
              ),
            ),
            // color: Colors.red,
            // child: MediaQuery.of(context).orientation == Orientation.portrait
            //     ? FadeInImage(
            //         imageErrorBuilder: (context, error, _) {
            //           return Image.asset(
            //             'assets/404-image.png',
            //             // fit: BoxFit.cover,
            //             // scale: 3,
            //           );
            //         },
            //         placeholder: const AssetImage(
            //           'assets/loading.gif',
            //         ),
            //         image: NetworkImage(
            //           "$trainingContentAssetsUrl/${docName.imageName}",
            //         ),
            //       )
            //     : Container(),

            // child: PhotoView(
            //   imageProvider: NetworkImage(
            //     "$trainingContentAssetsUrl/${docName.imageName}",
            //   ),
            //   loadingBuilder: (context, event) => Center(
            //     child: CircularProgressIndicator(
            //       value: event == null
            //           ? 0
            //           : event.cumulativeBytesLoaded / event.expectedTotalBytes!,
            //     ),
            //   ),
            //   errorBuilder: (context, error, stackTrace) => Center(
            //     child: Image.asset(
            //       'assets/404-image.png',
            //     ),
            //   ),
            // ),
          ),
        ),
      );
    } else if (docName.videoName!.isNotEmpty) {
      return Container(
        // width: MediaQuery.of(context).size.width,
        // height: MediaQuery.of(context).size.height / 3,
        constraints: kIsWeb
            ? BoxConstraints(
                minHeight: MediaQuery.of(context).size.height / 3,
                minWidth: MediaQuery.of(context).size.width,
                maxHeight: MediaQuery.of(context).size.height,
                maxWidth: MediaQuery.of(context).size.width,
              )
            : BoxConstraints(
                minHeight: MediaQuery.of(context).size.height / 3,
                minWidth: MediaQuery.of(context).size.width,
                maxHeight: 400,
                maxWidth: 900,
              ),
        // color: Colors.yellow,
        child: Container(
          color: Colors.black,
          child: VideoPlayerWidget(
              videoUrl: "$trainingContentAssetsUrl/${docName.videoName!}"),
        ),
      );
    } else {
      return Container();
    }
  }

  Widget progressHeader(int currentPage, int totalPages) {
    double progress = totalPages > 0 ? (currentPage + 1) / totalPages : 0.0;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      decoration: BoxDecoration(
        color: ColorConstraints.cardColor(context),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  widget.screenTitle,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                "${currentPage + 1} / $totalPages",
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: Colors.grey[200],
              valueColor:
                  AlwaysStoppedAnimation<Color>(Theme.of(context).primaryColor),
              minHeight: 6,
            ),
          ),
        ],
      ),
    );
  }

  @override
  bool get wantKeepAlive => true;

  @override
  void deactivate() {
    debugPrint("calling deactivate!");
    // WidgetsBinding.instance.addPostFrameCallback((_) {
    //   context.read<TabProvider>().clearPhotos();
    // });
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitDown,
      DeviceOrientation.portraitUp,
    ]);
    super.deactivate();
  }

  @override
  void dispose() {
    debugPrint("calling dispose!");
    _animationController?.dispose();
    _pageMoveTimer?.cancel();
    _pdfControllers.clear();
    _completedPdfTimerPages.clear();
    controller.dispose();

    for (var timer in _timers) {
      timer.cancel();
    }

    super.dispose();
  }
}
