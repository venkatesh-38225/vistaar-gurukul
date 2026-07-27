import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:gurukul/common/shared_pref.dart';
import 'package:gurukul/model/login.dart';
import 'package:gurukul/utils/colors.dart';
import 'package:gurukul/utils/widgets/loading_error_widgets.dart';
import 'package:gurukul/utils/widgets/lottie_widgets.dart';

import '../../../common/utils.dart';

class ExploreTabWidget extends StatefulWidget {
  const ExploreTabWidget({super.key});

  @override
  State<ExploreTabWidget> createState() => _ExploreTabWidgetState();
}

class _ExploreTabWidgetState extends State<ExploreTabWidget> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = "";
  late Future<String> _userDeptFuture;

  @override
  void initState() {
    super.initState();
    _userDeptFuture = getUserDept();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<String> getUserDept() async {
    D userData = await UserPreference().getUser();
    debugPrint("dept == ${userData.department}");
    return userData.department!.toLowerCase();
  }

  Color _getAdjustedColor(Color color, bool isDark) {
    if (isDark) {
      return color;
    } else {
      HSLColor hsl = HSLColor.fromColor(color);
      return hsl
          .withLightness((hsl.lightness - 0.22).clamp(0.0, 1.0))
          .toColor();
    }
  }

  @override
  Widget build(BuildContext context) {
    bool isDark = Theme.of(context).brightness == Brightness.dark;

    return FutureBuilder<String>(
        future: _userDeptFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const LoadingWidget();
          } else if (snapshot.hasError) {
            return const CustomErrorWidget();
          } else {
            final userDept = snapshot.data ?? "";
            // Filter out user's own department and filter by search query
            final filteredGridCardData = gridCardData.where((item) {
              final nameMatches = item['cardName']
                  .toString()
                  .toLowerCase()
                  .contains(_searchQuery.toLowerCase());
              final isNotUserDept = item['cardName'].toString().toLowerCase() !=
                  userDept.toLowerCase();
              return nameMatches && isNotUserDept;
            }).toList();

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Header Section
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 4),
                      Text(
                        "Select a department to browse and assign training courses.",
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color:
                              isDark ? Colors.white60 : const Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ),

                // Search Bar Section
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  child: Container(
                    decoration: BoxDecoration(
                      color: isDark
                          ? const Color(0xFF1E293B)
                          : const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isDark
                            ? Colors.white.withOpacity(0.05)
                            : Colors.grey.withOpacity(0.15),
                        width: 1,
                      ),
                    ),
                    child: TextField(
                      controller: _searchController,
                      onChanged: (val) {
                        setState(() {
                          _searchQuery = val;
                        });
                      },
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14,
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                      ),
                      decoration: InputDecoration(
                        hintText: "Search departments...",
                        hintStyle: GoogleFonts.plusJakartaSans(
                          fontSize: 14,
                          color:
                              isDark ? Colors.white38 : const Color(0xFF94A3B8),
                        ),
                        prefixIcon: Icon(
                          Icons.search_rounded,
                          color:
                              isDark ? Colors.white38 : const Color(0xFF94A3B8),
                          size: 20,
                        ),
                        suffixIcon: _searchQuery.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear_rounded, size: 18),
                                color: isDark
                                    ? Colors.white38
                                    : const Color(0xFF94A3B8),
                                onPressed: () {
                                  _searchController.clear();
                                  setState(() {
                                    _searchQuery = "";
                                  });
                                },
                              )
                            : null,
                        border: InputBorder.none,
                        contentPadding:
                            const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 10),

                // Department List View
                Expanded(
                  child: filteredGridCardData.isEmpty
                      ? const Center(
                    child: LottieEmptyWidget(
                      message: "No departments found",
                      subtitle: "Try a different search term.",
                      size: 160,
                    ),
                  )
                      : ListView.separated(
                          padding: const EdgeInsets.fromLTRB(4, 0, 4, 24),
                          itemCount: filteredGridCardData.length,
                          separatorBuilder: (context, index) => Divider(
                            height: 1,
                            thickness: 0.8,
                            color: isDark
                                ? Colors.white.withOpacity(0.05)
                                : Colors.grey.withOpacity(0.15),
                            indent: 76,
                          ),
                          itemBuilder: (context, index) {
                            final item = filteredGridCardData[index];
                            final rawColor = Color(item['cardColor']);
                            final themeColor =
                                _getAdjustedColor(rawColor, isDark);

                            return InkWell(
                              onTap: () => context.push(
                                '/explore-training-list-screen',
                                extra: item['cardName'],
                              ),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16.0, vertical: 14.0),
                                child: Row(
                                  children: [
                                    // Spaced circular leading badge
                                    Container(
                                      width: 48,
                                      height: 48,
                                      decoration: BoxDecoration(
                                        color: themeColor.withOpacity(0.12),
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: themeColor.withOpacity(0.2),
                                          width: 1,
                                        ),
                                      ),
                                      padding: const EdgeInsets.all(10),
                                      child: Image(
                                        fit: BoxFit.contain,
                                        image: AssetImage(item['cardImage']),
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    // Department Name & Detail Subtitle
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            item['cardName'],
                                            style: GoogleFonts.plusJakartaSans(
                                              fontSize: 15,
                                              fontWeight: FontWeight.bold,
                                              color: isDark
                                                  ? Colors.white
                                                  : const Color(0xFF0F172A),
                                            ),
                                          ),
                                          const SizedBox(height: 3),
                                          Text(
                                            "Tap to explore modules",
                                            style: GoogleFonts.plusJakartaSans(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w600,
                                              color: isDark
                                                  ? Colors.white38
                                                  : const Color(0xFF64748B),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    // Simple trailing action indicator
                                    Icon(
                                      Icons.chevron_right_rounded,
                                      color: isDark
                                          ? Colors.white38
                                          : const Color(0xFF94A3B8),
                                      size: 24,
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            );
          }
        });
  }
}
