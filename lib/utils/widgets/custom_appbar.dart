import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:gurukul/common/shared_pref.dart';
import 'package:gurukul/provider/api_provider.dart';
import 'package:gurukul/provider/tab_provider.dart';
import 'package:gurukul/provider/theme_provider.dart';
import 'package:gurukul/utils/colors.dart';
import 'package:gurukul/utils/widgets/loading_error_widgets.dart';
import 'package:gurukul/utils/widgets/logout_dialog.dart';
import 'package:provider/provider.dart';

import '../../model/login.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  @override
  Size get preferredSize => const Size.fromHeight(65.0);

  const CustomAppBar({
    super.key,
    required this.size,
    required this.title,
    // required this.onPress,
    this.automaticallyImplyLeading = false,
    this.showLogout = true,
  });

  final Size size;
  final String title;
  final bool automaticallyImplyLeading;
  final bool showLogout;
  // final Function onPress;

  @override
  Widget build(BuildContext context) {
    bool isDark = Theme.of(context).brightness == Brightness.dark;
    return AppBar(
      backgroundColor: Colors.transparent,
      automaticallyImplyLeading: automaticallyImplyLeading,
      iconTheme: IconThemeData(color: ColorConstraints.iconColor(context)),
      elevation: 0.0,
      toolbarHeight: 60.0,
      title: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          !automaticallyImplyLeading
              ? IconButton(
                  icon: const Icon(Icons.menu_rounded),
                  iconSize: 26,
                  color: ColorConstraints.iconColor(context),
                  onPressed: () {
                    Scaffold.of(context).openDrawer();
                  },
                )
              : const SizedBox.shrink(),
          Flexible(
            flex: 2,
            child: Text(
              title,
              style: GoogleFonts.plusJakartaSans(
                fontWeight: FontWeight.w800,
                fontSize: 20,
                letterSpacing: 0.5,
              ),
            ),
          ),
          if (showLogout)
            Container(
              decoration: BoxDecoration(
                color: ColorConstraints.cardColor(context),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: ColorConstraints.cardShadowColor(context),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: IconButton(
                iconSize: 22,
                constraints: const BoxConstraints(
                  minWidth: 40,
                  minHeight: 40,
                ),
                padding: EdgeInsets.zero,
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (context) => const LogoutDialog(),
                  );
                },
                icon: Icon(
                  Icons.power_settings_new,
                  color: Colors.red.shade400,
                ),
              ),
            )
          else
            const SizedBox(width: 40),
        ],
      ),
      centerTitle: true,
    );
  }
}

class NightModeSwitch extends StatelessWidget {
  const NightModeSwitch({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Icon(Icons.dark_mode_outlined,
                color: ColorConstraints.secondaryColor(context), size: 22),
            const SizedBox(width: 14),
            Text(
              'Night Mode',
              style: GoogleFonts.plusJakartaSans(
                  fontWeight: FontWeight.w600, fontSize: 16),
            ),
          ],
        ),
        Switch(
            activeColor: ColorConstraints.secondaryColor(context),
            value: context.watch<ThemeChanger>().isNightMode,
            onChanged: (val) {
              debugPrint("val = $val");
              context.read<ThemeChanger>().setIsNightMode = val;
            }),
      ],
    );
  }
}

class UserProfileDetails extends StatelessWidget {
  const UserProfileDetails({
    super.key,
    required this.fieldName,
    required this.fieldData,
    required this.icon,
  });

  final String fieldName;
  final String fieldData;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6.0),
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      decoration: BoxDecoration(
        color: ColorConstraints.topicCardColor(context),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, color: ColorConstraints.secondaryColor(context), size: 22),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  fieldName,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    color: Theme.of(context)
                            .textTheme
                            .bodySmall
                            ?.color
                            ?.withOpacity(0.6) ??
                        Colors.grey,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  fieldData,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
