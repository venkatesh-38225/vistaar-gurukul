import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:gurukul/utils/widgets/lottie_widgets.dart';

import '../../../common/shared_pref.dart';
import '../../../model/login.dart';
import '../../../provider/api_provider.dart';
import '../../../utils/colors.dart';
import '../../../utils/widgets/grid_card_with_progress.dart';
import '../../../utils/widgets/topic_card_widget.dart';
import '../../../model/training.dart' as trainingD;

class HomeTabWidget extends StatefulWidget {
  const HomeTabWidget({
    super.key,
  });

  @override
  State<HomeTabWidget> createState() => _HomeTabWidgetState();
}

class _HomeTabWidgetState extends State<HomeTabWidget> {
  String? userName;

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    try {
      final user = await UserPreference().getUser();
      if (mounted) {
        setState(() {
          userName = user.userName;
        });
      }
    } catch (e) {
      debugPrint("Error loading user profile: $e");
    }
  }

  String getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) {
      return 'Good Morning';
    } else if (hour < 17) {
      return 'Good Afternoon';
    } else {
      return 'Good Evening';
    }
  }

  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;
    final userProvider = context.watch<UserProvider>();
    bool isDark = Theme.of(context).brightness == Brightness.dark;

    int completedCount =
        userProvider.trainingStatusAndProgress['Completed']?.length ?? 0;
    int inProgressCount =
        userProvider.trainingStatusAndProgress['InProgress']?.length ?? 0;
    int newCount = userProvider.trainingStatusAndProgress['New']?.length ?? 0;
    int totalCount = completedCount + inProgressCount + newCount;
    double overallProgress =
        totalCount > 0 ? (completedCount / totalCount) : 0.0;

    final List<Map<String, dynamic>> dynamicGridCardData = [
      {
        "cardName": "Completed",
        "cardProgress": completedCount > 0 ? 1.0 : 0.0,
        "numberOfTask": completedCount,
        "outerCircleColor": const Color(0xFF10B981).withOpacity(0.12),
        "progressIndicatorColor": const Color(0xFF10B981),
      },
      {
        "cardName": "In Progress",
        "cardProgress": inProgressCount > 0 ? 0.5 : 0.0,
        "numberOfTask": inProgressCount,
        "outerCircleColor": const Color(0xFF3B82F6).withOpacity(0.12),
        "progressIndicatorColor": const Color(0xFF3B82F6),
      },
      {
        "cardName": "Yet to Start",
        "cardProgress": newCount > 0 ? 0.1 : 0.0,
        "numberOfTask": newCount,
        "outerCircleColor": const Color(0xFFF59E0B).withOpacity(0.12),
        "progressIndicatorColor": const Color(0xFFF59E0B),
      },
      {
        "cardName": "Others",
        "cardProgress": 0.0,
        "numberOfTask": userProvider.otherTrainingListLength.toInt(),
        "outerCircleColor": const Color(0xFF8B5CF6).withOpacity(0.12),
        "progressIndicatorColor": const Color(0xFF8B5CF6),
      },
    ];

    // Determine the active course to resume or start
    final inProgressList = userProvider.trainingStatusAndProgress['InProgress'];
    final newList = userProvider.trainingStatusAndProgress['New'];
    dynamic activeCourse;
    bool isActiveCourseInProgress = false;

    if (inProgressList != null && inProgressList.isNotEmpty) {
      activeCourse = inProgressList.first;
      isActiveCourseInProgress = true;
    } else if (newList != null && newList.isNotEmpty) {
      activeCourse = newList.first;
    }

    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.only(bottom: 32.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Greeting & Welcome Section
          Padding(
            padding: const EdgeInsets.fromLTRB(20.0, 20.0, 20.0, 12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Text(
                //   "${getGreeting()}${userName != null ? ', $userName' : ''} 👋",
                //   style: GoogleFonts.plusJakartaSans(
                //     fontSize: 24,
                //     fontWeight: FontWeight.w800,
                //     letterSpacing: -0.5,
                //   ),
                // ),
                const SizedBox(height: 4),
                Text(
                  "Let's learn something new today!",
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    color: isDark ? Colors.white60 : const Color(0xFF64748B),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),

          // Overall Progress Card
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20.0),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color.fromARGB(255, 7, 72, 147), Color(0xFF00529B)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF003B75).withOpacity(0.2),
                    blurRadius: 15,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Learning Progress",
                        style: GoogleFonts.plusJakartaSans(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white24,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          "${(overallProgress * 100).toStringAsFixed(0)}% Done",
                          style: GoogleFonts.plusJakartaSans(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      value: overallProgress,
                      minHeight: 8,
                      backgroundColor: Colors.white.withOpacity(0.15),
                      valueColor:
                          const AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    "You have completed $completedCount out of $totalCount mandatory training modules.",
                    style: GoogleFonts.plusJakartaSans(
                      color: Colors.white70,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Active Course / Quick Resume Section
          // if (activeCourse != null) ...[
          //   Padding(
          //     padding: const EdgeInsets.fromLTRB(20.0, 20.0, 20.0, 8.0),
          //     child: Text(
          //       isActiveCourseInProgress
          //           ? "Resume Course"
          //           : "Recommended Course",
          //       style: GoogleFonts.plusJakartaSans(
          //         fontSize: 18,
          //         fontWeight: FontWeight.bold,
          //         letterSpacing: -0.3,
          //       ),
          //     ),
          //   ),
          //   Padding(
          //     padding: const EdgeInsets.symmetric(horizontal: 16.0),
          //     child: InkWell(
          //       onTap: () => _startTraining(context, activeCourse),
          //       borderRadius: BorderRadius.circular(16),
          //       child: Container(
          //         padding: const EdgeInsets.all(18.0),
          //         decoration: BoxDecoration(
          //           color: isDark ? const Color(0xFF131A2E) : Colors.white,
          //           borderRadius: BorderRadius.circular(16),
          //           border: Border.all(
          //             color: isDark
          //                 ? Colors.white.withOpacity(0.06)
          //                 : Colors.grey.withOpacity(0.12),
          //             width: 1,
          //           ),
          //           boxShadow: [
          //             BoxShadow(
          //               color: isDark
          //                   ? Colors.black38
          //                   : Colors.grey.withOpacity(0.05),
          //               blurRadius: 12,
          //               offset: const Offset(0, 6),
          //             ),
          //           ],
          //         ),
          //         child: Row(
          //           children: [
          //             Container(
          //               padding: const EdgeInsets.all(12),
          //               decoration: BoxDecoration(
          //                 color: const Color(0xFF003B75).withOpacity(0.1),
          //                 shape: BoxShape.circle,
          //               ),
          //               child: const Icon(
          //                 Icons.menu_book_rounded,
          //                 color: Color(0xFF003B75),
          //                 size: 24,
          //               ),
          //             ),
          //             const SizedBox(width: 16),
          //             Expanded(
          //               child: Column(
          //                 crossAxisAlignment: CrossAxisAlignment.start,
          //                 children: [
          //                   Text(
          //                     activeCourse.trainingName ?? "",
          //                     style: GoogleFonts.plusJakartaSans(
          //                       fontSize: 15,
          //                       fontWeight: FontWeight.bold,
          //                     ),
          //                     maxLines: 2,
          //                     overflow: TextOverflow.ellipsis,
          //                   ),
          //                   const SizedBox(height: 4),
          //                   Text(
          //                     isActiveCourseInProgress
          //                         ? "In Progress • Click to resume session"
          //                         : "Yet to Start • Click to begin session",
          //                     style: GoogleFonts.plusJakartaSans(
          //                       fontSize: 12,
          //                       fontWeight: FontWeight.w600,
          //                       color: isActiveCourseInProgress
          //                           ? const Color(0xFF3B82F6)
          //                           : const Color(0xFFF59E0B),
          //                     ),
          //                   ),
          //                 ],
          //               ),
          //             ),
          //             const SizedBox(width: 8),
          //             const Icon(
          //               Icons.chevron_right_rounded,
          //               color: Colors.grey,
          //             ),
          //           ],
          //         ),
          //       ),
          //     ),
          //   ),
          // ],

          // Stats / Categories Section
          Padding(
            padding: const EdgeInsets.fromLTRB(20.0, 24.0, 20.0, 12.0),
            child: Text(
              "Training Statistics",
              style: GoogleFonts.plusJakartaSans(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                letterSpacing: -0.3,
              ),
            ),
          ),

          // Stats Grid
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: GridView.builder(
              physics: const NeverScrollableScrollPhysics(),
              shrinkWrap: true,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: kIsWeb ? 8 : 2,
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
                childAspectRatio: 0.88,
              ),
              itemCount: dynamicGridCardData.length,
              itemBuilder: (context, index) {
                final data = dynamicGridCardData[index];
                return GridCardWithProgress(
                  cardName: data["cardName"],
                  progress: data["cardProgress"],
                  numberOfTask: data["numberOfTask"],
                  outerCircleColor: data["outerCircleColor"],
                  progressIndicatorColor: data["progressIndicatorColor"],
                );
              },
            ),
          ),

          // Refresh indicator instruction at bottom
          Padding(
            padding: const EdgeInsets.only(top: 24.0),
            child: Center(
              child: Text(
                kIsWeb
                    ? ""
                    : (Platform.isAndroid
                        ? "Swipe down to refresh ⬇️"
                        : "Swipe down to refresh"),
                style: GoogleFonts.plusJakartaSans(
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade400,
                  fontSize: 13,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _startTraining(BuildContext context, dynamic course) async {
    bool loaderShowing = true;
    LottieLoadingDialog.show(context, message: "Checking location...");

    try {
      var locationResponse =
          await Provider.of<UserProvider>(context, listen: false)
              .getLocation(context, trainingId: course.id!);

      if (loaderShowing && mounted) {
        LottieLoadingDialog.dismiss(context); // hide loading
        loaderShowing = false;
      }

      if (locationResponse != null) {
        if (locationResponse['d'] == 'Y') {
          if (mounted) {
            context.push('/training', extra: {
              'screenTitle': course.trainingName!,
              'heroTag': Key(course.id.toString()),
              'trainingID': course.id,
              'containsTest': course.trainingType,
              'cutOff': course.cutOffMarks,
              'trainingDetails': course,
            }).then((value) => context.read<UserProvider>()
              ..setPercAndStatus()
              ..getOtherTrainingData());
          }
        } else {
          if (mounted) {
            showDialog(
              context: context,
              builder: (context) => AlertDialog(
                title: Text(
                  'Notification',
                  style:
                      GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold),
                ),
                content: Text(
                  'Your training location is not matching in our branch location, Please try again later.',
                  style: GoogleFonts.plusJakartaSans(),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(
                      'Close',
                      style: GoogleFonts.plusJakartaSans(
                          fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            );
          }
        }
      } else {
        if (mounted) {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: Text(
                'Location Service Error',
                style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold),
              ),
              content: Text(
                'Unable to determine your current location. Please verify that Location Services are enabled on your device and permissions are granted to the app.',
                style: GoogleFonts.plusJakartaSans(),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(
                    'OK',
                    style: GoogleFonts.plusJakartaSans(
                        fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          );
        }
      }
    } catch (e) {
      if (loaderShowing && mounted) {
        LottieLoadingDialog.dismiss(context);
        loaderShowing = false;
      }
      debugPrint("Error launching training session: $e");
    }
  }
}
