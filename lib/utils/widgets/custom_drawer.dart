import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:gurukul/common/shared_pref.dart';
import 'package:gurukul/provider/api_provider.dart';
import 'package:gurukul/provider/tab_provider.dart';
import 'package:gurukul/provider/theme_provider.dart';
import 'package:gurukul/utils/colors.dart';
import 'package:gurukul/utils/widgets/custom_appbar.dart';
import 'package:gurukul/utils/widgets/loading_error_widgets.dart';
import 'package:gurukul/utils/widgets/logout_dialog.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:provider/provider.dart';
import '../../model/login.dart';

class CustomDrawer extends StatelessWidget {
  const CustomDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    bool isDark = Theme.of(context).brightness == Brightness.dark;
    Color drawerBg = isDark ? const Color(0xFF131A2E) : Colors.white;

    return Drawer(
      backgroundColor: drawerBg,
      child: FutureBuilder<D>(
        future: UserPreference().getUser(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError || !snapshot.hasData) {
            return const Center(child: Text("Error loading profile"));
          } else {
            D userData = snapshot.data!;
            return Column(
              children: [
                // Drawer Header
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.fromLTRB(
                    20,
                    MediaQuery.of(context).padding.top + 24,
                    20,
                    24,
                  ),
                  decoration: BoxDecoration(
                    gradient: ColorConstraints.primaryGradient(context),
                  ),
                  child: Column(
                    children: [
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          shape: BoxShape.rectangle,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.white24, width: 2),
                          color: Colors.white.withOpacity(0.1),
                        ),
                        padding: const EdgeInsets.all(8),
                        child: const Image(
                          fit: BoxFit.contain,
                          image: AssetImage('assets/vist_guru_nobg.png'),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        "Vistaar Gurukul",
                        textAlign: TextAlign.center,
                        style: GoogleFonts.plusJakartaSans(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                      FutureBuilder<PackageInfo>(
                        future: PackageInfo.fromPlatform(),
                        builder: (context, packageSnapshot) {
                          final versionStr = packageSnapshot.hasData
                              ? 'v${packageSnapshot.data!.version}'
                              : 'v2.0.0';
                          return Text(
                            versionStr,
                            style: GoogleFonts.plusJakartaSans(
                              color: Colors.white70,
                              fontSize: 14,
                            ),
                          );
                        },
                      ),
                      // Text(
                      //   userData.userName ?? "User Profile",
                      //   textAlign: TextAlign.center,
                      //   style: GoogleFonts.plusJakartaSans(
                      //     color: Colors.white,
                      //     fontWeight: FontWeight.bold,
                      //     fontSize: 18,
                      //   ),
                      // ),
                      // const SizedBox(height: 2),
                      // Text(
                      //   "ID: ${userData.userId}",
                      //   style: GoogleFonts.plusJakartaSans(
                      //     color: Colors.white70,
                      //     fontSize: 14,
                      //   ),
                      // ),
                    ],
                  ),
                ),

                // Drawer Body Options
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        UserProfileDetails(
                          fieldName: "Name",
                          fieldData: userData.userName ?? "N/A",
                          icon: Icons.person,
                        ),
                        UserProfileDetails(
                          fieldName: "Employee Id",
                          fieldData: userData.userId ?? "N/A",
                          icon: Icons.person,
                        ),
                        UserProfileDetails(
                          fieldName: "Branch",
                          fieldData: userData.branchname ?? "N/A",
                          icon: Icons.storefront_outlined,
                        ),
                        UserProfileDetails(
                          fieldName: "Department",
                          fieldData: userData.department ?? "N/A",
                          icon: Icons.business_outlined,
                        ),
                        const Divider(height: 32, thickness: 1),
                        const NightModeSwitch(),
                        const SizedBox(height: 16),
                      ],
                    ),
                  ),
                ),

                // Footer section with Logout & Close Buttons
                SafeArea(
                  top: false,
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      children: [
                        SizedBox(
                          width: double.infinity,
                          height: 48,
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red.shade400,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            icon: const Icon(Icons.logout_rounded,
                                color: Colors.white),
                            label: const Text(
                              "Logout",
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            onPressed: () {
                              // Close drawer first
                              Navigator.pop(context);
                              // Trigger logout dialog
                              _showLogoutDialog(context);
                            },
                          ),
                        ),
                        const SizedBox(height: 10),
                        SizedBox(
                          width: double.infinity,
                          height: 48,
                          child: OutlinedButton(
                            style: OutlinedButton.styleFrom(
                              side: BorderSide(
                                color: isDark
                                    ? Colors.white10
                                    : Colors.grey.shade300,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            onPressed: () => Navigator.pop(context),
                            child: Text(
                              "Close",
                              style: TextStyle(
                                color: ColorConstraints.iconColor(context),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          }
        },
      ),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const LogoutDialog(),
    );
  }
}
