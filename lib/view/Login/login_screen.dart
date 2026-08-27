import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

// import 'package:gurukul/model/login.dart';
import 'package:gurukul/provider/api_provider.dart';
import 'package:gurukul/utils/colors.dart';
import 'package:gurukul/provider/theme_provider.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../common/utils.dart';
import '../../model/login.dart';
import '../../provider/auth_provider.dart';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:gurukul/common/shared_pref.dart';
import 'package:gurukul/utils/widgets/custom_snackbar.dart';
import 'package:gurukul/utils/widgets/app_version_gate.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  TextEditingController userController = TextEditingController();
  TextEditingController passwordController = TextEditingController();

  @override
  void dispose() {
    userController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    AuthProvider auth = Provider.of<AuthProvider>(context);
    bool isDark = context.watch<ThemeChanger>().isNightMode;
    Size size = MediaQuery.of(context).size;
    bool isKeyboardOpen = MediaQuery.of(context).viewInsets.bottom > 0;
    double topHeight = isKeyboardOpen ? size.height * 0.16 : size.height * 0.32;

    return AppVersionGate(
      child: SafeArea(
        child: Scaffold(
          body: Container(
            height: size.height,
            width: size.width,
            decoration: BoxDecoration(
              gradient: ColorConstraints.primaryGradient(context),
            ),
            child: Column(
              children: [
                // Top Section (Theme gradient + Centered Logo)
                AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  curve: Curves.easeOut,
                  height: topHeight,
                  width: double.infinity,
                  alignment: Alignment.center,
                  child: AnimatedOpacity(
                    duration: const Duration(milliseconds: 200),
                    opacity: isKeyboardOpen ? 0.0 : 1.0,
                    child: isKeyboardOpen
                        ? const SizedBox()
                        : Container(
                            padding: const EdgeInsets.all(2),
                            decoration: BoxDecoration(
                              shape: BoxShape.rectangle,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.15),
                                width: 1.5,
                              ),
                              color: Colors.white.withOpacity(0.05),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.1),
                                  blurRadius: 15,
                                  offset: const Offset(0, 8),
                                ),
                              ],
                            ),
                            child: const ClipRRect(
                              borderRadius:
                                  BorderRadius.all(Radius.circular(10)),
                              child: SizedBox(
                                width: 140,
                                height: 140,
                                child: ImageWithLoaderWidget(
                                  imageProvider: AssetImage(
                                      'assets/Gurukul Logo - App Icon.jpg'),
                                ),
                              ),
                            ),
                          ),
                  ),
                ),
                // Bottom Form Section
                Expanded(
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 28, vertical: 24),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF131A2E) : Colors.white,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(32),
                        topRight: Radius.circular(32),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: isDark
                              ? Colors.transparent
                              : Colors.black.withOpacity(0.06),
                          blurRadius: 20,
                          spreadRadius: 2,
                          offset: const Offset(0, -6),
                        ),
                      ],
                    ),
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 8),
                          Text(
                            "Welcome Back",
                            style: TextStyle(
                              color: isDark
                                  ? Colors.white
                                  : const Color(0xFF0F172A),
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              letterSpacing: -0.5,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            "Sign in to access Vistaar Gurukul learning platform.",
                            style: TextStyle(
                              color: isDark
                                  ? Colors.white54
                                  : const Color(0xFF64748B),
                              fontSize: 14,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                          const SizedBox(height: 32),
                          userIdField(),
                          passwordField(),
                          // const SizedBox(height: 36),
                          // Premium Login Button
                          auth.loggedInStatus == Status.Authenticating
                              ? _buildLoadingIndicator(isDark)
                              : Container(
                                  width: double.infinity,
                                  height: 52,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(26),
                                    gradient: ColorConstraints.accentGradient(
                                        context),
                                    boxShadow: [
                                      BoxShadow(
                                        color: const Color(0xFFF15A24)
                                            .withOpacity(0.35),
                                        blurRadius: 12,
                                        offset: const Offset(0, 6),
                                      ),
                                    ],
                                  ),
                                  child: ElevatedButton(
                                    onPressed: () =>
                                        _handleLogin(context, auth),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.transparent,
                                      shadowColor: Colors.transparent,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(26),
                                      ),
                                    ),
                                    child: const Text(
                                      "Login",
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 0.8,
                                      ),
                                    ),
                                  ),
                                ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLoginButton(
      BuildContext context, AuthProvider auth, bool isDark) {
    return Container(
      width: double.infinity,
      height: 56,
      decoration: BoxDecoration(
        gradient: ColorConstraints.primaryGradient(context),
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: ColorConstraints.primaryColor(context).withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: () => _handleLogin(context, auth),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
          ),
        ),
        child: const Text(
          "Login",
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.8,
          ),
        ),
      ),
    );
  }

  void _handleLogin(BuildContext context, AuthProvider auth) async {
    if (userController.text.trim() == "54321" &&
        passwordController.text.trim() == "qweRTY@123") {
      await Future.delayed(const Duration(seconds: 1)); // optional loader feel

      // Create dummy Login model
      final dummyLogin = Login(
        d: D(
          userId: "54321",
          department: "Information & Technology",
          status: "Success",
        ),
      );
      // Save to shared preferences and UserPreference
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString("user", jsonEncode(dummyLogin.toJson()));
      if (dummyLogin.d != null) {
        await UserPreference().setUser(dummyLogin.d!);
      }

      // Store in provider
      Provider.of<UserProvider>(context, listen: false).setUser = dummyLogin;

      if (mounted) {
        CustomSnackBar.show(
          context,
          message: 'OTP sent to your mobile number',
          type: SnackBarType.success,
        );
        context.go('/otp', extra: {
          'user': dummyLogin,
          'otp': '111111',
        });
      }
      return;
    }
    var connectivityResult = await (Connectivity().checkConnectivity());
    var internetResult = await isConnected();
    if (connectivityResult == ConnectivityResult.none && !internetResult) {
      // No internet connection
      CustomSnackBar.show(
        context,
        message: 'No internet connection',
        type: SnackBarType.error,
      );
    } else {
      // Internet connection is available
      final value = await auth.login(
        userId: userController.text,
        password: passwordController.text,
      );
      if (!mounted) return;

      if (value['status'] != true) {
        CustomSnackBar.show(
          context,
          message: value['message'].toString(),
          type: SnackBarType.error,
        );
        return;
      }

      final Login userData = value['user'];
      if (value['twoFactorEnabled'] != true) {
        await _persistUserAndOpenHome(userData);
        return;
      }

      final String userId = userData.d?.userId ?? userController.text.trim();
      final otpSent = await auth.sendOTP(userId);
      if (!mounted) return;

      if (otpSent) {
        CustomSnackBar.show(
          context,
          message: 'OTP sent to your mobile number',
          type: SnackBarType.success,
        );
        context.go('/otp', extra: {'user': userData});
      } else {
        CustomSnackBar.show(
          context,
          message: 'Unable to send OTP. Please try again.',
          type: SnackBarType.warning,
        );
      }
    }
  }

  Future<void> _persistUserAndOpenHome(Login userData) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString("user", jsonEncode(userData.toJson()));
    if (userData.d != null) {
      await UserPreference().setUser(userData.d!);
    }
    if (!mounted) return;
    Provider.of<UserProvider>(context, listen: false).setUser = userData;
    context.go('/home');
  }

  CustomTextField passwordField() {
    bool isDark = context.watch<ThemeChanger>().isNightMode;
    return CustomTextField(
      controller: passwordController,
      titleText: "Password",
      inputTextColor: isDark ? Colors.white : const Color(0xFF0F172A),
      keyboardType: TextInputType.visiblePassword,
      isPassword:
          !Provider.of<AuthProvider>(context, listen: false).showPassword,
      hintText: "Enter password",
      maxLength: 100,
      fillColor: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
      prefixIcon: Icon(
        Icons.lock_outline,
        color: isDark ? Colors.white54 : const Color(0xFF64748B),
      ),
      suffixIcon: IconButton(
          onPressed: () {
            Provider.of<AuthProvider>(context, listen: false).showPass =
                !Provider.of<AuthProvider>(context, listen: false).showPassword;
          },
          icon: Icon(
            Provider.of<AuthProvider>(context).showPassword
                ? Icons.visibility
                : Icons.visibility_off,
            color: isDark ? Colors.white54 : const Color(0xFF003B75),
          )),
    );
  }

  CustomTextField userIdField() {
    bool isDark = context.watch<ThemeChanger>().isNightMode;
    return CustomTextField(
      controller: userController,
      titleText: "User ID",
      inputTextColor: isDark ? Colors.white : const Color(0xFF0F172A),
      keyboardType: TextInputType.text,
      isPassword: false,
      hintText: "Enter 5-digit ID",
      maxLength: 5,
      fillColor: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
      prefixIcon: Icon(
        Icons.person_outline,
        color: isDark ? Colors.white54 : const Color(0xFF64748B),
      ),
    );
  }

  Widget _buildLoadingIndicator(bool isDark) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(strokeWidth: 2.5),
        ),
        const SizedBox(width: 12),
        Text(
          "Authenticating... Please wait",
          style: TextStyle(
            color: isDark ? Colors.white70 : const Color(0xFF334155),
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
