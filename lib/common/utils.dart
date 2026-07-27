import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'package:gurukul/provider/theme_provider.dart';
import 'package:gurukul/utils/widgets/lottie_widgets.dart';

final List<Map<String, dynamic>> gridCardData = [
  {
    "cardName": "Business",
    "cardImage": "assets/explore_apps/business.png",
    "cardColor": 0xFFFFADAD,
  },

  {
    "cardName": "Credit & Risk",
    "cardImage": "assets/explore_apps/credit_risk.png",
    "cardColor": 0xFFCAFFBF,
  },
  {
    "cardName": "Collections",
    "cardImage": "assets/explore_apps/collections.png",
    "cardColor": 0xFFFDFFB6,
  },
  {
    "cardName": "Operations",
    "cardImage": "assets/explore_apps/operations.png",
    "cardColor": 0xFFBDE4A7,
  },
  {
    "cardName": "Information & Technology",
    "cardImage": "assets/explore_apps/information_technology.png",
    "cardColor": 0xFFFFC6FF,
  },
  // {
  //   "cardName": "Central Operations",
  //   "cardImage": "assets/explore_apps/central_operations.png",
  //   "cardColor": 0xFFFFD6A5,
  // },

  // {
  //   "cardName": "Director",
  //   "cardImage": "assets/explore_apps/director.png",
  //   "cardColor": 0xFF9BF6FF,
  // },
  {
    "cardName": "Finance & Accounts",
    "cardImage": "assets/explore_apps/finance_accounts.png",
    "cardColor": 0xFFA0C4FF,
  },
  {
    "cardName": "Human Resource",
    "cardImage": "assets/explore_apps/human_resource.png",
    "cardColor": 0xFFBDB2FF,
  },

  {
    "cardName": "Internal Audit",
    "cardImage": "assets/explore_apps/internal_audit.png",
    "cardColor": 0xFFA2BED3,
  },
  // {
  //   "cardName": "Legal & Collections",
  //   "cardImage": "assets/explore_apps/legal_collections.png",
  //   "cardColor": 0xFFE0E0E0,
  // },
  {
    "cardName": "Legal & Compliance",
    "cardImage": "assets/explore_apps/legal_compliance.png",
    "cardColor": 0xFFFFBA92,
  },
  // {
  //   "cardName": "Office of MD & CEO",
  //   "cardImage": "assets/explore_apps/office_md_ceo.png",
  //   "cardColor": 0xFFD8A7CA,
  // },

  {
    "cardName": "Products",
    "cardImage": "assets/explore_apps/products.png",
    "cardColor": 0xFFA7BED3,
  },
  {
    "cardName": "Administration",
    "cardImage": "assets/explore_apps/admin.png",
    "cardColor": 0xFFa2fbe5,
  },
];

class CustomTextField extends StatelessWidget {
  const CustomTextField({
    super.key,
    required this.controller,
    required this.titleText,
    required this.keyboardType,
    required this.hintText,
    required this.fillColor,
    required this.isPassword,
    required this.inputTextColor,
    required this.maxLength,
    this.suffixIcon,
    this.prefixIcon,
  });

  final TextEditingController controller;
  final String titleText;
  final TextInputType keyboardType;
  final String hintText;
  final Color fillColor;
  final bool isPassword;
  final Color inputTextColor;
  final int maxLength;
  final Widget? suffixIcon;
  final Widget? prefixIcon;

  @override
  Widget build(BuildContext context) {
    bool isDark = context.watch<ThemeChanger>().isNightMode;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 8.0, bottom: 6.0),
          child: Text(
            titleText,
            style: TextStyle(
              color: isDark ? Colors.white70 : const Color(0xFF334155),
              fontSize: 14,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16.0),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: TextFormField(
            controller: controller,
            obscureText: isPassword,
            style: TextStyle(
              color: inputTextColor,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
            keyboardType: keyboardType,
            maxLength: maxLength,
            decoration: InputDecoration(
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
              counterStyle: const TextStyle(color: Colors.transparent),
              hintText: hintText,
              hintStyle: TextStyle(
                color: isDark
                    ? Colors.white.withOpacity(0.3)
                    : Colors.black.withOpacity(0.35),
                fontSize: 16,
                fontWeight: FontWeight.w400,
              ),
              filled: true,
              fillColor: fillColor,
              prefixIcon: prefixIcon,
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16.0),
                borderSide: const BorderSide(
                  color: Color(0xFF005BB5), // Royal Blue glow
                  width: 1.8,
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16.0),
                borderSide: BorderSide(
                  color: isDark
                      ? Colors.white.withOpacity(0.12)
                      : Colors.black.withOpacity(0.08),
                  width: 1.0,
                ),
              ),
              suffixIcon: suffixIcon,
            ),
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}

class ImageWithLoaderWidget extends StatelessWidget {
  const ImageWithLoaderWidget({super.key, required this.imageProvider});
  final ImageProvider<Object> imageProvider;
  @override
  Widget build(BuildContext context) {
    return FadeInImage(
      placeholder: const AssetImage('assets/loading.gif'),
      image: imageProvider,
    );
  }
}

class CustomErrorWidget extends StatelessWidget {
  const CustomErrorWidget({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Image.asset('assets/error.png'),
    );
  }
}

Future<bool> isConnected() async {
  try {
    final result = await InternetAddress.lookup('google.com');
    if (result.isNotEmpty && result[0].rawAddress.isNotEmpty) {
      print('connectivity: connected');
      return true;
    }
  } on SocketException catch (_) {
    print('connectivity: not connected');
    return false;
  }
  return false;
}

class NoTrainingWidget extends StatelessWidget {
  const NoTrainingWidget({
    super.key,
    required this.message,
  });

  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Image.asset(
            'assets/book-loading.gif',
            width: 100,
            height: 100,
          ),
          const SizedBox(height: 12),
          Center(
            child: Text(
              "$message",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.white60
                    : const Color(0xFF64748B),
              ),
              textAlign: TextAlign.center,
            ),
          )
        ],
      ),
    );
  }
}
