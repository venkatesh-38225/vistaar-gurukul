import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:gurukul/provider/tab_provider.dart';
import 'package:provider/provider.dart';
import 'dart:math' as math;

import '../../provider/api_provider.dart';
import '../../utils/widgets/custom_appbar.dart';

class PdfViewScreen extends StatefulWidget {
  const PdfViewScreen({
    super.key,
    required this.filePath,
    required this.controller,
    required this.previousPage,
    required this.pageTrack,
  });

  @override
  State<PdfViewScreen> createState() => _PdfViewScreenState();
  final String filePath;
  final PageController controller;
  final double previousPage;
  final List<int> pageTrack;
}

class _PdfViewScreenState extends State<PdfViewScreen> {
  @override
  void initState() {
    super.initState();
    SystemChrome.setPreferredOrientations(
        [DeviceOrientation.landscapeLeft, DeviceOrientation.landscapeRight]);
  }

  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;
    return SafeArea(
      child: Scaffold(
        appBar: PreferredSize(
          preferredSize: const Size.fromHeight(kToolbarHeight),
          child: AnimatedOpacity(
            duration: const Duration(milliseconds: 300),
            opacity: context.watch<TabProvider>().showAppBar ? 1.0 : 0.0,
            child: context.watch<TabProvider>().showAppBar
                ? CustomAppBar(

                    size: size,
                    title: "",
                    automaticallyImplyLeading: true,
                  )
                : const SizedBox.shrink(),
          ),
        ),
        body: Stack(
          children: [
            PDFView(
              onPageError: (page, error) => const CircularProgressIndicator(),
              pageSnap: true,

              // fitPolicy: FitPolicy.BOTH,
              fitPolicy: FitPolicy.WIDTH,
              fitEachPage: true,

              // fitEachPage: true,
              autoSpacing: true,
              filePath: widget.filePath,
              enableSwipe: true,
              swipeHorizontal: true,

              // onRender: (page) {
              //   debugPrint("page on Render called");
              // },
              onRender: (pages) {
                debugPrint("previous page = ${widget.controller.page!}");
                if (pages! > 1) {
                  if (widget.controller.page! > widget.previousPage) {
                    debugPrint("page completely swiped");

                    // if (!_pdfLoaded)
                    //   setState(() {
                    //     _isScrollable = false;
                    //     _pdfLoaded = true;
                    //   });
                  } else {
                    debugPrint("page incomplete swipe");
                  }
                }
              },
              onViewCreated: (pdfcontroller) {
                debugPrint("page = $widget.pageTrack");
                int gotoPage = widget.pageTrack.fold(0, math.max);

                Future.delayed(const Duration(seconds: 1), () async {
                  await pdfcontroller.setPage(gotoPage);
                });
              },
              onPageChanged: (page, total) {
                debugPrint("page Changed");

                // if (page == total! - 1) {
                //   Future.delayed(
                //       Duration(milliseconds: 100),
                //       () {
                //     // if (!_isScrollable)
                //     //   setState(() {
                //     //     _isScrollable = true;
                //     //     _latestPdfPage = page!;
                //     //   });
                //   });
                // }
                if (page == 2 &&
                    Provider.of<UserProvider>(context, listen: false)
                            .getPageTrack ==
                        1) {
                  // setState(() {});
                }
                widget.pageTrack.add(page!);

                Provider.of<UserProvider>(context, listen: false)
                    .setPageTrack(widget.pageTrack, total!);
              },
              // swipeHorizontal: true,
            ),
            IgnorePointer(
              ignoring: false,
              child: GestureDetector(
                onTap: () {
                  context.read<TabProvider>().setShowAppBar =
                      !context.read<TabProvider>().showAppBar;
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    SystemChrome.setPreferredOrientations(
        [DeviceOrientation.portraitUp, DeviceOrientation.portraitDown]);

    super.dispose();
  }
}
