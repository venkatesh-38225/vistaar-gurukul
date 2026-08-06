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
    this.trainingDetails,
    this.fromCompleted = false,
  });

  final Key heroTag;
  final String screenTitle;

  //fetched from api
  final int trainingId;
  final String trainingType;
  final int cutOff;
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
  Timer? _pageMoveTimer;

  void _startPageMoveTimer() {
    _pageMoveTimer?.cancel();
    context.read<TabProvider>().setCanMovePage = false;
    context.read<TabProvider>().startCountdown();
    _pageMoveTimer = Timer(const Duration(seconds: 5), () {
      if (mounted) {
        context.read<TabProvider>().setCanMovePage = true;
      }
    });
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
        if (length > 1) {
          _startPageMoveTimer();
        }

        // Set initial complete track percentage: page 1 of (length + 1)
        context.read<UserProvider>().setContentCompleteTrackPerc(1, length + 1);

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

        // Resume from last viewed page logic
        final details = widget.trainingDetails;
        if (details != null) {
          final completedPercentageStr = details.completedPercentage;
          if (completedPercentageStr != null &&
              completedPercentageStr.isNotEmpty &&
              completedPercentageStr != "0") {
            final double? completedPercentage =
                double.tryParse(completedPercentageStr);
            // The total pages for progress calculation. Note that itemCount is length + 1
            final int totalPage = length + 1;
            if (completedPercentage != null) {
              int desiredPageIndex =
                  ((completedPercentage / 100) * totalPage).round() - 1;
              if (desiredPageIndex >= 0 && desiredPageIndex < totalPage) {
                debugPrint(
                    "Resume logic: desiredPage = $desiredPageIndex, total page = $totalPage, % completed = $completedPercentage");

                // Show a dialog asking the user whether they want to resume from the last viewed page
                showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Resume?'),
                    content: const Text(
                        'Do you want to resume from where you left off?'),
                    actions: <Widget>[
                      TextButton(
                        child: const Text('No'),
                        onPressed: () {
                          Navigator.of(context).pop(false);
                        },
                      ),
                      TextButton(
                        child: const Text('Yes'),
                        onPressed: () {
                          Navigator.of(context).pop(true);
                        },
                      ),
                    ],
                  ),
                ).then((resume) {
                  if (resume == true && mounted) {
                    Future.delayed(const Duration(milliseconds: 200), () {
                      if (mounted) {
                        controller.animateToPage(
                          desiredPageIndex,
                          duration: const Duration(milliseconds: 100),
                          curve: Curves.easeInOut,
                        );
                      }
                    });
                  }
                });
              }
            }
          }
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

    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) {
        Provider.of<UserProvider>(context, listen: false)
            .setPageTrack(_pageTrack, 0);
        context.read<UserProvider>()
          ..setIsScrollable = true
          ..setLatestPdfPage = 0
          ..setCompletedPdfPages = 0
          ..setIsScrollable = true
          ..setPdfLoaded = false
          ..setTrainingPageTrack = 0;

        context.read<UserProvider>().setCompletedPdfPages = 0;
      }
    });
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

  void calculateContentProgress() {
    debugPrint(
        "totalPage = ${_userProvider!.contentCompleteTrackPerc['totalPage']}");
    int? onPage = _userProvider!.contentCompleteTrackPerc['onPage'];
    int? totalPage = _userProvider!.contentCompleteTrackPerc['totalPage'];
    if (onPage != null && totalPage != null) {
      double percentage = (onPage / totalPage) * 100;
      debugPrint(
          "onpage = $onPage, total = $totalPage, perc = ${percentage.toStringAsFixed(2)}");
      if (percentage >= 100) {
        if (widget.trainingType == "C+T") {
          debugPrint("Completed");
          _userProvider!.updateTranscript(
              trainingId: widget.trainingId,
              contentName: widget.screenTitle,
              completedPerc: "100",
              contentStatus: "Completed",
              bothStatus: "");
        } else {
          _userProvider!.updateTranscript(
              trainingId: widget.trainingId,
              contentName: widget.screenTitle,
              completedPerc: "100",
              contentStatus: "Completed",
              bothStatus: "Completed");
        }
      } else {
        debugPrint("Initiated");
        _userProvider!.updateTranscript(
            trainingId: widget.trainingId,
            contentName: widget.screenTitle,
            completedPerc: percentage.toStringAsFixed(2),
            contentStatus: "Initiated",
            bothStatus: "");
      }
    }
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
                      onPressed: () =>
                          Navigator.of(dialogContext).pop(false),
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
                      onPressed: () =>
                          Navigator.of(dialogContext).pop(true),
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
          final totalPages = data.length + 1;

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
                              const SizedBox(width: 16),
                              // Next / Progress Button
                              Expanded(
                                child: Consumer2<TabProvider, UserProvider>(
                                  builder:
                                      (context, tabProvider, userProvider, _) {
                                    final isReady =
                                        tabProvider.countdownValue == 0;
                                    final canMovePage = tabProvider.canMovePage;
                                    final pageTrack = userProvider.getPageTrack;

                                    final bool isPdfPending = pageTrack != -1;
                                    final bool isCountdownPending =
                                        !isReady && !canMovePage;

                                    VoidCallback? onPressed;
                                    String btnText = "Next";
                                    IconData iconData =
                                        Icons.arrow_forward_ios_rounded;
                                    Color btnColor =
                                        Theme.of(context).primaryColor;

                                    if (isPdfPending) {
                                      btnText = "Read PDF";
                                      iconData = Icons.menu_book_rounded;
                                      btnColor = Colors.orange;
                                      onPressed = () {
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          const SnackBar(
                                            content: Text(
                                                "Wait a minute! The PDF is packed with knowledge. Don't miss out!"),
                                          ),
                                        );
                                      };
                                    } else if (isCountdownPending) {
                                      btnText =
                                          "Next (${tabProvider.countdownValue}s)";
                                      iconData = Icons.hourglass_empty_rounded;
                                      btnColor = Colors.grey[500]!;
                                      onPressed = null;
                                    } else {
                                      onPressed = () {
                                        controller.animateToPage(
                                          trainingPageTrack + 1,
                                          duration:
                                              const Duration(milliseconds: 400),
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
          // builder: (context, state) {
          return PageView.builder(
            controller: controller,
            physics: context.watch<TabProvider>().canMovePage
                ? physics
                : const NeverScrollableScrollPhysics(),
            itemCount: snapshot.data.length + 1,
            onPageChanged: (page) {
              debugPrint("data length = ${snapshot.data.length}");
              context.read<UserProvider>().setContentCompleteTrackPerc(
                  page + 1, snapshot.data.length + 1);

              if (snapshot.data.length > 1) {
                context.read<UserProvider>().setTrainingPageTrack = page;
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
                    : FutureBuilder(
                        future: loadPdf(
                            "$trainingContentAssetsUrl/${trainingContent.pDFName}",
                            "${trainingContent.pDFName}"),
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
                                            enableSwipe: true,
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
                                            },
                                            onPageChanged: (page, total) {
                                              debugPrint("pdf onPageChanged");
                                              if (page != 0) {
                                                context.read<UserProvider>()
                                                  ..setLatestPdfPage = page!
                                                  ..setTotalPdfPage = total!;
                                              }

                                              if (page == 2 &&
                                                  Provider.of<UserProvider>(
                                                              context,
                                                              listen: false)
                                                          .getPageTrack ==
                                                      1) {}
                                              _pageTrack.add(page!);

                                              Provider.of<UserProvider>(context,
                                                      listen: false)
                                                  .setPageTrack(
                                                      _pageTrack, total!);
                                            },
                                          ),
                                        ),
                                        Positioned(
                                          bottom: 10,
                                          right: 5,
                                          child: Selector<UserProvider, bool>(
                                            selector: (_, provider) =>
                                                provider.latestPdfPage ==
                                                provider.totalPage - 1,
                                            builder: (_, isLastPage, __) =>
                                                ElevatedButton(
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: isLastPage
                                                    ? Colors.green
                                                    : Colors.grey,
                                              ),
                                              onPressed: isLastPage
                                                  ? () {
                                                      context
                                                          .read<UserProvider>()
                                                          .setIsScrollable = true;
                                                      controller.animateToPage(
                                                        controller.page!
                                                                .toInt() +
                                                            1,
                                                        duration:
                                                            const Duration(
                                                                milliseconds:
                                                                    500),
                                                        curve: Curves.easeInOut,
                                                      );
                                                    }
                                                  : null,
                                              child: Text("Finish",
                                                  style: isLastPage
                                                      ? const TextStyle(
                                                          color: Colors.white,
                                                          fontWeight:
                                                              FontWeight.w600)
                                                      : TextStyle(
                                                          color:
                                                              Colors.grey[700],
                                                          fontWeight:
                                                              FontWeight.w100)),
                                            ),
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
                    return Stream.periodic(const Duration(seconds: 1), (i) => i)
                        .take(4);
                  }

                  return StreamBuilder<int>(
                    stream: counter(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
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
                  if (!widget.fromCompleted) {
                    calculateContentProgress();
                  }
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
                                // calculateContentProgress();

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
                                    color: ColorConstraints.iconColor(context)),
                              )),
                        ],
                      ));
                }
              }
            },
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
    controller.dispose();

    for (var timer in _timers) {
      timer.cancel();
    }

    super.dispose();
  }
}
