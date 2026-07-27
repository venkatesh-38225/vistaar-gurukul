import 'package:flutter/material.dart';
import 'package:gurukul/constants/app_constants.dart';
import 'package:gurukul/routes/routes.dart';
import 'package:gurukul/services/app_version_service.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

class AppVersionGate extends StatefulWidget {
  const AppVersionGate({required this.child, super.key});

  final Widget child;

  static Future<void> triggerCheck(BuildContext context) async {
    final requiredVersion = await AppVersionService().fetchRequiredVersion();
    debugPrint('=== App Version Check ===');
    debugPrint('API (Required) Version: $requiredVersion');
    if (requiredVersion == null) {
      debugPrint('Version check aborted: API version is null (fetch failed).');
      return;
    }

    final packageInfo = await PackageInfo.fromPlatform();
    debugPrint('Local (Installed) Version: ${packageInfo.version}');
    
    final isMatch = AppVersionService.versionsMatch(packageInfo.version, requiredVersion);
    debugPrint('Versions Match: $isMatch');
    debugPrint('=========================');

    if (isMatch) {
      return;
    }

    final navigatorContext = rootNavigatorKey.currentContext ?? context;
    if (!navigatorContext.mounted) return;

    await showDialog<void>(
      context: navigatorContext,
      barrierDismissible: false,
      builder: (dialogContext) {
        final isDark = Theme.of(dialogContext).brightness == Brightness.dark;
        return PopScope(
          canPop: false,
          child: Dialog(
            backgroundColor: Colors.transparent,
            elevation: 0,
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF131A2E) : Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(isDark ? 0.4 : 0.1),
                    blurRadius: 24,
                    offset: const Offset(0, 12),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF15A24).withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.system_update_rounded,
                      size: 48,
                      color: Color(0xFFF15A24),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Update Required',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'A new version of Gurukul is available. Please update the app to the latest version to continue using it.',
                    style: TextStyle(
                      fontSize: 14,
                      color: isDark ? Colors.white70 : const Color(0xFF475569),
                      height: 1.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        Column(
                          children: [
                            Text(
                              'Installed',
                              style: TextStyle(
                                fontSize: 11,
                                color: isDark ? Colors.white38 : Colors.black38,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              packageInfo.version,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: isDark ? Colors.white70 : const Color(0xFF334155),
                              ),
                            ),
                          ],
                        ),
                        Icon(
                          Icons.arrow_forward_rounded,
                          color: isDark ? Colors.white24 : Colors.black26,
                        ),
                        Column(
                          children: [
                            Text(
                              'Latest',
                              style: TextStyle(
                                fontSize: 11,
                                color: isDark ? Colors.white38 : Colors.black38,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              requiredVersion,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFFF15A24),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  Container(
                    width: double.infinity,
                    height: 50,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(25),
                      gradient: const LinearGradient(
                        colors: [Color(0xFFF15A24), Color(0xFFFFA07A)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFF15A24).withOpacity(0.3),
                          blurRadius: 12,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: ElevatedButton(
                      onPressed: () => _openUpdateLink(dialogContext),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(25),
                        ),
                      ),
                      child: const Text(
                        'Update Now',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
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
  }

  static Future<void> _openUpdateLink(BuildContext dialogContext) async {
    final updateUri = Uri.tryParse(appStoreUrl);
    final hasExternalUrl = updateUri != null &&
        (updateUri.scheme == 'https' || updateUri.scheme == 'http');

    if (!hasExternalUrl ||
        !await launchUrl(updateUri, mode: LaunchMode.externalApplication)) {
      if (!dialogContext.mounted) return;
      ScaffoldMessenger.of(dialogContext).showSnackBar(
        const SnackBar(
          content: Text('The app update link is not configured yet.'),
        ),
      );
    }
  }

  @override
  State<AppVersionGate> createState() => _AppVersionGateState();
}

class _AppVersionGateState extends State<AppVersionGate> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        AppVersionGate.triggerCheck(context);
      }
    });
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
