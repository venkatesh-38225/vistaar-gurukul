import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/material.dart';
// import 'package:flutter_jailbreak_detection/flutter_jailbreak_detection.dart';
import 'package:go_router/go_router.dart';
import 'package:gurukul/RootBlockedScreen.dart';
import 'package:gurukul/model/training.dart' as trainingD;
import 'package:gurukul/model/login.dart' as loginD;
import 'package:gurukul/utils/photo_viewer/photoViewer.dart';
import 'package:gurukul/view/HomeScreen/home_screen.dart';
// import 'package:gurukul/view/HomeScreen/home_screen.dart';
import 'package:gurukul/view/Login/login_screen.dart';
import 'package:gurukul/view/Login/otp_screen.dart';
import 'package:gurukul/view/Training/completed_screen.dart';
import 'package:gurukul/view/Training/explore_training_list_screen.dart';
import 'package:gurukul/view/Training/in_progress_screen.dart';
import 'package:gurukul/view/Training/onboarding_training_screen.dart';
import 'package:gurukul/view/Training/others_screen.dart';
import 'package:gurukul/view/Training/pdf_view_screen.dart';
import 'package:gurukul/view/Training/training_list_screen.dart';
import 'package:gurukul/view/Training/training_screen.dart';
import 'package:gurukul/view/Training/training_test_screen.dart';
import 'package:gurukul/view/no_internet_screen.dart';
import 'package:gurukul/view/rooted_block_screen.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../RootBlockedWrapper.dart';
import '../common/shared_pref.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

CustomTransitionPage buildPageWithDefaultTransition<T>({
  required BuildContext context,
  required GoRouterState state,
  required Widget child,
}) {
  return CustomTransitionPage<T>(
    key: state.pageKey,
    child: child,
    transitionsBuilder: (context, animation, secondaryAnimation, child) =>
        SlideTransition(
      position: Tween<Offset>(
        begin: const Offset(0, 1),
        end: Offset.zero,
      ).animate(animation),
      child: child,
    ),
  );
}

final rootNavigatorKey = GlobalKey<NavigatorState>();

final router = GoRouter(
  navigatorKey: rootNavigatorKey,
  initialLocation: '/',
  routes: [
    GoRoute(
      name: 'loginScreen',
      path: '/',
      builder: (context, state) => const LoginScreen(),
    ),
    GoRoute(
      name: 'otpScreen',
      path: '/otp',
      builder: (context, state) {
        if (state.extra is Map) {
          final Map args = state.extra as Map;
          final user = args['user'] as loginD.Login;
          final otp = args['otp'] as String?;
          return OtpVerificationScreen(user: user, initialOtp: otp);
        }
        final user = state.extra as loginD.Login;
        return OtpVerificationScreen(user: user);
      },
      pageBuilder: (context, state) {
        if (state.extra is Map) {
          final Map args = state.extra as Map;
          final user = args['user'] as loginD.Login;
          final otp = args['otp'] as String?;
          return buildPageWithDefaultTransition(
            context: context,
            state: state,
            child: OtpVerificationScreen(user: user, initialOtp: otp),
          );
        }
        final user = state.extra as loginD.Login;
        return buildPageWithDefaultTransition(
          context: context,
          state: state,
          child: OtpVerificationScreen(user: user),
        );
      },
    ),
    GoRoute(
      name: 'homeScreen',
      path: '/home',
      builder: (context, state) => const HomeScreen(),
      pageBuilder: (context, state) => buildPageWithDefaultTransition(
        context: context,
        state: state,
        child: const HomeScreen(),
      ),
    ),
    GoRoute(
      name: 'trainingScreen',
      path: '/training',
      builder: (context, state) {
        var args = state.extra as Map;
        String screenTitle = args['screenTitle'];
        Key hTag = args['heroTag'];
        int trainingId = args['trainingID'];
        String containsTest = args['containsTest'];
        int cutOff = args['cutOff'] ?? 0;
        bool fromCompleted = args['fromCompleted'] ?? false;
        trainingD.D? trainingDetails = args['trainingDetails'];
        int swipeTimer = args['swipeTimer'] ?? trainingDetails?.swipeTimer ?? 0;
        int testTimer = args['testTimer'] ?? trainingDetails?.testTimer ?? 0;
        debugPrint("containsTest = $containsTest");
        return TrainingScreen(
          screenTitle: screenTitle,
          heroTag: hTag,
          trainingId: trainingId,
          trainingType: containsTest,
          fromCompleted: fromCompleted,
          trainingDetails: trainingDetails,
          cutOff: cutOff,
          swipeTimer: swipeTimer,
          testTimer: testTimer,
        );
      },
      pageBuilder: (context, state) {
        var args = state.extra as Map;
        String screenTitle = args['screenTitle'];
        Key hTag = args['heroTag'];
        int trainingId = args['trainingID'];
        String containsTest = args['containsTest'];
        int cutOff = args['cutOff'] ?? 0;
        bool fromCompleted = args['fromCompleted'] ?? false;
        trainingD.D? trainingDetails = args['trainingDetails'];
        int swipeTimer = args['swipeTimer'] ?? trainingDetails?.swipeTimer ?? 0;
        int testTimer = args['testTimer'] ?? trainingDetails?.testTimer ?? 0;
        debugPrint("containsTest = $containsTest");

        return buildPageWithDefaultTransition(
            context: context,
            state: state,
            child: TrainingScreen(
              screenTitle: screenTitle,
              heroTag: hTag,
              trainingId: trainingId,
              trainingType: containsTest,
              fromCompleted: fromCompleted,
              trainingDetails: trainingDetails,
              cutOff: cutOff,
              swipeTimer: swipeTimer,
              testTimer: testTimer,
            ));
      },
    ),
    GoRoute(
      path: '/training-list-screen',
      builder: (context, state) => const TrainingListScreen(),
      pageBuilder: (context, state) => buildPageWithDefaultTransition(
        context: context,
        state: state,
        child: const TrainingListScreen(),
      ),
    ),
    GoRoute(
      path: '/onboardinig-training-list-screen',
      builder: (context, state) => const OnBoardingTrainingScreen(),
      pageBuilder: (context, state) => buildPageWithDefaultTransition(
          context: context,
          state: state,
          child: const OnBoardingTrainingScreen()),
    ),
    GoRoute(
      path: '/explore-training-list-screen',
      builder: (context, state) {
        var department = state.extra as String;
        return ExploreTrainingListScreen(
          department: department,
        );
      },
      pageBuilder: (context, state) {
        var department = state.extra as String;
        return buildPageWithDefaultTransition(
            context: context,
            state: state,
            child: ExploreTrainingListScreen(
              department: department,
            ));
      },
    ),
    GoRoute(
      path: '/training-list-screen',
      builder: (context, state) => const TrainingListScreen(),
      pageBuilder: (context, state) => buildPageWithDefaultTransition(
        context: context,
        state: state,
        child: const TrainingListScreen(),
      ),
    ),
    GoRoute(
      name: 'trainingTestScreen',
      path: '/training-test',
      builder: (context, state) {
        var args = state.extra as Map;
        String screenTitle = args['screenTitle'];
        Key hTag = args['heroTag'];
        int trainingId = args['trainingID'];
        String containsTest = args['containsTest'];
        int cutOff = args['cutOff'];
        int testTimer = args['testTimer'] ?? 0;

        return TrainingTestScreen(
          screenTitle: screenTitle,
          heroTag: hTag,
          trainingId: trainingId,
          trainingType: containsTest,
          cutOff: cutOff,
          testTimer: testTimer,
        );
      },
      pageBuilder: (context, state) {
        var args = state.extra as Map;
        String screenTitle = args['screenTitle'];
        Key hTag = args['heroTag'];
        int trainingId = args['trainingID'];
        String containsTest = args['containsTest'];
        int cutOff = args['cutOff'];
        int testTimer = args['testTimer'] ?? 0;

        return buildPageWithDefaultTransition(
            context: context,
            state: state,
            child: TrainingTestScreen(
              screenTitle: screenTitle,
              heroTag: hTag,
              trainingId: trainingId,
              trainingType: containsTest,
              cutOff: cutOff,
              testTimer: testTimer,
            ));
      },
    ),
    GoRoute(
      path: '/completed',
      name: 'completed',
      builder: (context, state) => const CompletedScreen(),
      pageBuilder: (context, state) => buildPageWithDefaultTransition(
          context: context, state: state, child: const CompletedScreen()),
    ),
    GoRoute(
      path: '/in-progress',
      name: 'inProgress',
      builder: (context, state) => const InProgressScreen(),
      pageBuilder: (context, state) => buildPageWithDefaultTransition(
          context: context, state: state, child: const InProgressScreen()),
    ),
    GoRoute(
      path: '/others',
      name: 'others',
      builder: (context, state) => const OthersScreen(),
      pageBuilder: (context, state) => buildPageWithDefaultTransition(
        context: context,
        state: state,
        child: const OthersScreen(),
      ),
    ),
    GoRoute(
        path: '/photo-viewer',
        name: 'photoViewer',
        builder: (context, state) {
          String url = state.extra as String;
          return PhotoViewer(imageUrl: url);
        },
        pageBuilder: (context, state) {
          String url = state.extra as String;
          return buildPageWithDefaultTransition(
              context: context,
              state: state,
              child: PhotoViewer(imageUrl: url));
        }),
    GoRoute(
      path: '/pdf-view-screen',
      name: 'pdfViewScreen',
      builder: (context, state) {
        Map args = state.extra as Map;
        final String filePath = args['filePath'];
        final PageController controller = args['controller'];
        final double previousPage = args['previousPage'];
        final List<int> pageTrack = args['pageTrack'];

        return PdfViewScreen(
          controller: controller,
          filePath: filePath,
          pageTrack: pageTrack,
          previousPage: previousPage,
        );
      },
      pageBuilder: (context, state) {
        Map args = state.extra as Map;
        final String filePath = args['filePath'];
        final PageController controller = args['controller'];
        final double previousPage = args['previousPage'];
        final List<int> pageTrack = args['pageTrack'];

        return buildPageWithDefaultTransition(
            context: context,
            state: state,
            child: PdfViewScreen(
              controller: controller,
              filePath: filePath,
              pageTrack: pageTrack,
              previousPage: previousPage,
            ));
      },
    ),
    GoRoute(
      path: '/no-internet-screen',
      name: 'no-internet-screen',
      builder: (context, state) => const NoInternetScreen(),
      pageBuilder: (context, state) => buildPageWithDefaultTransition(
        context: context,
        state: state,
        child: const NoInternetScreen(),
      ),
    ),
    GoRoute(
      path: '/rooted-error-screen',
      name: 'rooted-error-screen',
      builder: (context, state) => const RootedBlockScreen(),
      pageBuilder: (context, state) => buildPageWithDefaultTransition(
        context: context,
        state: state,
        child: const RootedBlockScreen(),
      ),
    ),
  ],
  observers: [
    GoRouterObserver(),
  ],
  /*redirect: (context, state) async {
    debugPrint("redirect called!");
    final connectivityResult = await (Connectivity().checkConnectivity());
    debugPrint("connectivity = $connectivityResult");
    try {
      String status = await UserPreference().getStatus();
      debugPrint("status = $status");
      if (connectivityResult == ConnectivityResult.none) {
        return '/no-internet-screen';
      } else if (status == "Success") {
        return state.fullPath == '/' ? '/home' : state.fullPath;
      } else {
        return null;
      }
    } catch (e) {
      debugPrint("error :$e");
    }
    return null;
  },*/
  redirect: (context, state) async {
    debugPrint("redirect called!");

    final connectivityResult = await Connectivity().checkConnectivity();
    debugPrint("connectivity = $connectivityResult");
    final isRooted = await isDeviceRooted();

    debugPrint("isRooted = $isRooted");

    try {
      if (isRooted) {
        return '/rooted-error-screen';
      }

      if (connectivityResult == ConnectivityResult.none) {
        return '/no-internet-screen';
      }

      final status = await UserPreference().getStatus();
      debugPrint("status = $status");

      if (status == "Success") {
        return state.fullPath == '/' ? '/home' : state.fullPath;
      } else {
        return null; // Stay on current path
      }
    } catch (e) {
      debugPrint("Redirect error: $e");
      return null;
    }
  },
);
Future<bool> isDeviceRooted() async {
  try {
    // final jailbroken = await FlutterJailbreakDetection.jailbroken;
    // final devMode = await FlutterJailbreakDetection.developerMode;

    final deviceInfo = DeviceInfoPlugin();
    bool isEmulator = false;
    if (Platform.isAndroid) {
      final android = await deviceInfo.androidInfo;
      isEmulator = !android.isPhysicalDevice;
    } else if (Platform.isIOS) {
      final ios = await deviceInfo.iosInfo;
      isEmulator = !ios.isPhysicalDevice;
    }

    final packageInfo = await PackageInfo.fromPlatform();
    const expectedPackage = 'com.vistaar.coachapplication';
    final tampered = packageInfo.packageName != expectedPackage;

    // return jailbroken || devMode || isEmulator || tampered;
    return false;
  } catch (e) {
    // Fail-safe: assume rooted if check fails
    return true;
  }
}

class GoRouterObserver extends NavigatorObserver {
  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    debugPrint('MyTest didPush: $route');
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    debugPrint('MyTest didPop: $route');
  }

  @override
  void didRemove(Route<dynamic> route, Route<dynamic>? previousRoute) {
    debugPrint('MyTest didRemove: $route');
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    debugPrint('MyTest didReplace: $newRoute');
  }
}
