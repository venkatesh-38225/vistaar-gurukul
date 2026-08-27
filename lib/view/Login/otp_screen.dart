import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:gurukul/common/shared_pref.dart';
import 'package:gurukul/common/utils.dart';
import 'package:gurukul/constants/app_constants.dart';
import 'package:gurukul/model/login.dart';
import 'package:gurukul/provider/api_provider.dart';
import 'package:gurukul/provider/auth_provider.dart';
import 'package:gurukul/utils/colors.dart';
import 'package:gurukul/provider/theme_provider.dart';
import 'package:gurukul/utils/widgets/custom_snackbar.dart';
import 'package:gurukul/utils/widgets/lottie_widgets.dart';
import 'package:pin_code_text_field/pin_code_text_field.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

class OtpVerificationScreen extends StatefulWidget {
  final Login user;
  final String? initialOtp;
  const OtpVerificationScreen({super.key, required this.user, this.initialOtp});

  @override
  _OtpVerificationScreenState createState() => _OtpVerificationScreenState();
}

class _OtpVerificationScreenState extends State<OtpVerificationScreen> {
  TextEditingController controller = TextEditingController(text: "");
  int pinLength = 6;
  bool hasError = false;
  String? mobileNumber;

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    mobileNumber = widget.user.d?.mobile;
    if (widget.initialOtp != null && widget.initialOtp != "0") {
      debugPrint("Test OTP flow initialized");
    }
  }

  Future sendOtp() async {
    setState(() {
      controller.clear();
      hasError = false;
    });

    // Show loading behavior
    LottieLoadingDialog.show(context, message: "Sending OTP...");

    try {
      final String userId = widget.user.d?.userId ?? "";
      final sent = await Provider.of<AuthProvider>(context, listen: false)
          .sendOTP(userId);

      if (!mounted) return;
      LottieLoadingDialog.dismiss(context);
      CustomSnackBar.show(
        context,
        message: sent
            ? "OTP sent to your mobile number"
            : "Unable to send OTP. Please try again.",
        type: sent ? SnackBarType.success : SnackBarType.error,
      );
    } catch (e) {
      if (mounted) LottieLoadingDialog.dismiss(context);
      debugPrint("Error sending OTP: $e");
    }
  }

  String _getMaskedMobileNumber(String? phone) {
    if (phone == null || phone.trim().isEmpty) {
      return 'registered mobile number';
    }
    final cleanPhone = phone.trim();
    if (cleanPhone.length > 4) {
      final lastDigits = cleanPhone.substring(cleanPhone.length - 4);
      final maskedLength = cleanPhone.length - 4;
      return '${'X' * maskedLength}$lastDigits';
    }
    return cleanPhone;
  }

  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;
    bool isDark = context.watch<ThemeChanger>().isNightMode;
    Color textColor = isDark ? Colors.white : const Color(0xFF0F172A);
    Color subtitleColor = isDark ? Colors.white70 : const Color(0xFF475569);
    Color cardBg = isDark
        ? Colors.black.withValues(alpha: 0.25)
        : Colors.white.withValues(alpha: 0.9);
    Color cardBorder = isDark
        ? Colors.white.withValues(alpha: 0.1)
        : Colors.black.withValues(alpha: 0.08);
    Color pinBoxBg = isDark
        ? Colors.white.withValues(alpha: 0.08)
        : Colors.black.withValues(alpha: 0.04);
    Color pinTextColor = isDark ? Colors.white : const Color(0xFF0F172A);
    Color pinBorderColor = isDark
        ? Colors.white.withValues(alpha: 0.15)
        : Colors.black.withValues(alpha: 0.1);

    return Scaffold(
      body: Container(
        height: size.height,
        width: size.width,
        decoration: BoxDecoration(
          gradient: ColorConstraints.primaryGradient(context),
        ),
        child: SafeArea(
          child: Stack(
            children: [
              // Floating Back Button
              Positioned(
                top: 12,
                left: 16,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.08),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.15),
                      width: 1,
                    ),
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.arrow_back_rounded,
                        color: Colors.white),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ),
              ),
              // Background glowing blobs
              Positioned(
                top: -size.height * 0.1,
                right: -size.width * 0.2,
                child: Container(
                  width: size.width * 0.8,
                  height: size.width * 0.8,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFFF15A24).withValues(alpha: 0.08),
                  ),
                ),
              ),
              Positioned(
                bottom: -size.height * 0.15,
                left: -size.width * 0.2,
                child: Container(
                  width: size.width * 0.9,
                  height: size.width * 0.9,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFF2E3192).withValues(alpha: 0.15),
                  ),
                ),
              ),
              Center(
                child: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24.0, vertical: 20),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Centered Gurukul Logo
                        Container(
                          margin: const EdgeInsets.only(bottom: 24),
                          padding: const EdgeInsets.all(2),
                          decoration: BoxDecoration(
                            shape: BoxShape.rectangle,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.15),
                              width: 1.5,
                            ),
                            color: Colors.white.withValues(alpha: 0.05),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.1),
                                blurRadius: 15,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: const ClipRRect(
                            borderRadius: BorderRadius.all(Radius.circular(10)),
                            child: SizedBox(
                              width: 100,
                              height: 100,
                              child: ImageWithLoaderWidget(
                                imageProvider: AssetImage(
                                    'assets/Gurukul Logo - App Icon.jpg'),
                              ),
                            ),
                          ),
                        ),
                        // The existing verification card
                        Container(
                          padding: const EdgeInsets.all(24.0),
                          decoration: BoxDecoration(
                            color: cardBg,
                            borderRadius: BorderRadius.circular(15),
                            border: Border.all(
                              color: cardBorder,
                              width: 1.0,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: isDark
                                    ? Colors.black.withValues(alpha: 0.3)
                                    : Colors.black.withValues(alpha: 0.05),
                                blurRadius: 30,
                                offset: const Offset(0, 15),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                "Verify your number",
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: textColor,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                "Please enter the OTP received at ${_getMaskedMobileNumber(mobileNumber)}.",
                                style: TextStyle(
                                    color: subtitleColor,
                                    fontSize: 14,
                                    height: 1.4),
                              ),
                              const SizedBox(height: 36),
                              Center(
                                child: Container(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 8),
                                  child: FittedBox(
                                    fit: BoxFit.scaleDown,
                                    child: SizedBox(
                                      width: 300,
                                      child: PinCodeTextField(
                                        autofocus: true,
                                        controller: controller,
                                        highlight: true,
                                        highlightColor: const Color(0xFFF15A24),
                                        defaultBorderColor: pinBorderColor,
                                        hasTextBorderColor: Colors.transparent,
                                        maxLength: pinLength,
                                        hasError: hasError,
                                        onTextChanged: (text) {
                                          setState(() {
                                            hasError = false;
                                          });
                                        },
                                        pinBoxWidth: 42,
                                        pinBoxHeight: 52,
                                        hasUnderline: false,
                                        wrapAlignment:
                                            WrapAlignment.spaceAround,
                                        pinBoxColor: pinBoxBg,
                                        pinBoxDecoration:
                                            ProvidedPinBoxDecoration
                                                .defaultPinBoxDecoration,
                                        pinBoxRadius: 6,
                                        pinTextStyle: TextStyle(
                                            fontSize: 20.0,
                                            color: pinTextColor,
                                            fontWeight: FontWeight.bold),
                                        highlightAnimation: true,
                                        highlightAnimationBeginColor: isDark
                                            ? Colors.white24
                                            : Colors.black12,
                                        highlightAnimationEndColor:
                                            const Color(0xFFF15A24),
                                        keyboardType: TextInputType.number,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 12),
                              Align(
                                alignment: Alignment.centerRight,
                                child: TextButton(
                                  onPressed: sendOtp,
                                  child: const Text(
                                    "Resend OTP",
                                    style: TextStyle(
                                        color: Color(0xFFF15A24),
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 16),
                              Container(
                                width: double.infinity,
                                height: 56,
                                decoration: BoxDecoration(
                                  gradient:
                                      ColorConstraints.accentGradient(context),
                                  borderRadius: BorderRadius.circular(16),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(0xFFF15A24)
                                          .withValues(alpha: 0.35),
                                      blurRadius: 16,
                                      offset: const Offset(0, 6),
                                    ),
                                  ],
                                ),
                                child: ElevatedButton(
                                  onPressed: () => validateOTP(controller.text),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.transparent,
                                    shadowColor: Colors.transparent,
                                    shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(16)),
                                  ),
                                  child: const Text(
                                    "Verify OTP",
                                    style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 0.8),
                                  ),
                                ),
                              ),
                            ],
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
    );
  }

  validateOTP(String otpText) async {
    if (otpText.isEmpty || otpText.length < pinLength) {
      CustomSnackBar.show(
        context,
        message: "Please enter a valid OTP",
        type: SnackBarType.warning,
      );
      return;
    }

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    LottieLoadingDialog.show(context, message: "Verifying OTP...");
    final isVerified = await authProvider.verifyOTP(
      userId: widget.user.d?.userId ?? "",
      otp: otpText,
    );
    if (!mounted) return;
    LottieLoadingDialog.dismiss(context);

    if (isVerified) {
      debugPrint("OTP Verified Successfully");

      CustomSnackBar.show(
        context,
        message: "OTP Verified Successfully",
        type: SnackBarType.success,
      );

      // Show non-dismissible loading spinner while registering keys/session
      LottieLoadingDialog.show(context, message: "Setting up your account...");

      await Future.delayed(const Duration(seconds: 1));
      // Perform app key mapping logic from Bandhu app
      String appKey = const Uuid().v4();

      try {
        final ip = await authProvider.getIpAddress();
        if (ip != null) {
          Map body = {
            "I/P": ip,
            "AppKey": appKey,
            "MobileNumber": mobileNumber,
            "Token": API_TOKEN,
          };
          await authProvider.addAppKey(body);
        }
      } catch (e) {
        debugPrint("AppKey mapping failed (optional): $e");
      }

      // Save user to shared preferences/Hive
      await UserPreference().setUser(widget.user.d!);

      // Dismiss the loading dialog
      if (mounted) {
        LottieLoadingDialog.dismiss(context);
      }

      // Update UserProvider and save UserPreference
      if (widget.user.d != null) {
        await UserPreference().setUser(widget.user.d!);
      }
      if (mounted) {
        Provider.of<UserProvider>(context, listen: false).setUser = widget.user;
        context.go('/home');
      }
    } else {
      setState(() {
        hasError = true;
      });
      CustomSnackBar.show(
        context,
        message: "Invalid OTP. Please try again.",
        type: SnackBarType.error,
      );
    }
  }
}

class RoundedRectangleHeader extends OutlinedBorder {
  final BorderRadiusGeometry borderRadius;
  const RoundedRectangleHeader({this.borderRadius = BorderRadius.zero});

  @override
  OutlinedBorder copyWith(
      {BorderSide? side, BorderRadiusGeometry? borderRadius}) {
    return RoundedRectangleHeader(
        borderRadius: borderRadius ?? this.borderRadius);
  }

  @override
  Path getInnerPath(Rect rect, {TextDirection? textDirection}) {
    return Path()
      ..addRRect(borderRadius
          .resolve(textDirection)
          .toRRect(rect)
          .deflate(side.width));
  }

  @override
  Path getOuterPath(Rect rect, {TextDirection? textDirection}) {
    return Path()..addRRect(borderRadius.resolve(textDirection).toRRect(rect));
  }

  @override
  void paint(Canvas canvas, Rect rect, {TextDirection? textDirection}) {
    if (side.style == BorderStyle.solid) {
      canvas.drawRRect(
          borderRadius.resolve(textDirection).toRRect(rect), side.toPaint());
    }
  }

  @override
  ShapeBorder scale(double t) {
    return RoundedRectangleHeader(borderRadius: borderRadius * t);
  }
}
