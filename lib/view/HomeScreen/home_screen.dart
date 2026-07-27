import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:gurukul/provider/tab_provider.dart';
import 'package:gurukul/utils/widgets/custom_appbar.dart';
import 'package:gurukul/utils/widgets/custom_drawer.dart';
import 'package:gurukul/view/Training/onboarding_training_screen.dart';
import 'package:provider/provider.dart';
import 'package:gurukul/services/notification_service.dart';
import 'package:gurukul/utils/widgets/app_version_gate.dart';

import '../../provider/api_provider.dart';
import 'TabWidgets/explore_tab_widget.dart';
import 'TabWidgets/home_tab_widget.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String pageTitle() {
    switch (context.watch<TabProvider>().currentTab) {
      case 0:
        return "Home";
      case 1:
        return "Department";
      case 2:
        return "OnBoarding Training";
      default:
        return "Home";
    }
  }

  @override
  void initState() {
    super.initState();
    // context.read<UserProvider>()
    //   ..setPercAndStatus()
    //   ..getOtherTrainingStream();

    NotificationService().showNotification(
      scheduledNotificationDateTime: DateTime.now().add(
        const Duration(seconds: 15),
      ),
      body: "You have training pending, please complete your training!",
      id: 0,
      title: "Complete your training now!",
    );
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);

    context.read<UserProvider>()
      ..setPercAndStatus()
      ..getOtherTrainingData();
  }

  @override
  void didChangeDependencies() {
    // context.read<UserProvider>()
    //   ..setPercAndStatus()
    //   ..getOtherTrainingData();

    super.didChangeDependencies();
  }

  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;
    bool isDark = Theme.of(context).brightness == Brightness.dark;
    var appBar = CustomAppBar(
      size: size,
      title: pageTitle(),
    );

    return AppVersionGate(
      child: WillPopScope(
        onWillPop: () async {
          debugPrint("current tab is ${context.read<TabProvider>().currentTab}");
          if (context.read<TabProvider>().currentTab > 0) {
            context.read<TabProvider>().newTab = 0;
            context.read<UserProvider>()
              ..setPercAndStatus()
              ..getOtherTrainingData();

            return false;
          } else {
            return await showDialog(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text('Exit?'),
                content: const Text('Are you sure you want to quit.'),
                actions: <Widget>[
                  ElevatedButton(
                    style:
                        ElevatedButton.styleFrom(backgroundColor: Colors.white),
                    onPressed: () => Navigator.of(context).pop(false),
                    child: const Text(
                      'No',
                      style: TextStyle(color: Colors.black),
                    ),
                  ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0054a0)),
                    onPressed: () => Navigator.of(context).pop(true),
                    child: const Text(
                      'Yes',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ],
              ),
            );
          }
        },
        child: RefreshIndicator(
          onRefresh: () async {
            try {
              AppVersionGate.triggerCheck(context);
              debugPrint("height is ${size.height}");
              context.read<UserProvider>()
                ..setPercAndStatus()
                ..getOtherTrainingData();
            } catch (e) {
              debugPrint("Error refreshing : $e ");
            }
          },
          child: Scaffold(
            appBar: appBar,
            drawer: const CustomDrawer(),
            body: Consumer<UserProvider>(builder: (context, userProvider, child) {
              return bodyWidget(context.watch<TabProvider>().currentTab, size);
            }),
            bottomNavigationBar: _buildCustomBottomNavBar(context, isDark),
          ),
        ),
      ),
    );
  }

  Widget _buildCustomBottomNavBar(BuildContext context, bool isDark) {
    final currentTab = context.watch<TabProvider>().currentTab;
    Color activeColor = const Color(0xFF005BB5); // Royal Blue theme
    Color inactiveColor = isDark ? Colors.white38 : const Color(0xFF94A3B8);
    Color bgColor = isDark ? const Color(0xFF131A2E) : Colors.white;

    return Container(
      height: 72 + MediaQuery.of(context).padding.bottom,
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).padding.bottom,
        left: 16,
        right: 16,
      ),
      decoration: BoxDecoration(
        color: bgColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.35 : 0.05),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
        border: Border(
          top: BorderSide(
            color: isDark
                ? Colors.white.withOpacity(0.06)
                : Colors.grey.withOpacity(0.1),
            width: 1,
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildNavBarItem(
            index: 0,
            icon: Icons.home_rounded,
            label: "Home",
            currentTab: currentTab,
            activeColor: activeColor,
            inactiveColor: inactiveColor,
          ),
          _buildNavBarItem(
            index: 1,
            icon: Icons.apartment_rounded,
            label: "Department",
            currentTab: currentTab,
            activeColor: activeColor,
            inactiveColor: inactiveColor,
          ),
          _buildNavBarItem(
            index: 2,
            icon: Icons.menu_book_rounded,
            label: "OnBoarding",
            currentTab: currentTab,
            activeColor: activeColor,
            inactiveColor: inactiveColor,
          ),
        ],
      ),
    );
  }

  Widget _buildNavBarItem({
    required int index,
    required IconData icon,
    required String label,
    required int currentTab,
    required Color activeColor,
    required Color inactiveColor,
  }) {
    bool isActive = currentTab == index;
    return Expanded(
      child: InkWell(
        onTap: () {
          context.read<TabProvider>().newTab = index;
          if (index == 0) {
            context.read<UserProvider>()
              ..setPercAndStatus()
              ..getOtherTrainingData();
          }
        },
        splashColor: Colors.transparent,
        highlightColor: Colors.transparent,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              decoration: BoxDecoration(
                color: isActive
                    ? activeColor.withOpacity(0.08)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                icon,
                color: isActive ? activeColor : inactiveColor,
                size: 24,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: GoogleFonts.plusJakartaSans(
                color: isActive ? activeColor : inactiveColor,
                fontSize: 12,
                fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget bodyWidget(int tab, Size size) {
    debugPrint("building bodyWidget!");
    switch (tab) {
      case 0:
        return const HomeTabWidget();
      case 1:
        return const ExploreTabWidget();
      case 2:
        return const OnBoardingTrainingScreen();
      default:
        return Container();
    }
  }
}

enum Tabs { Home, Explore, OnBoarding }
