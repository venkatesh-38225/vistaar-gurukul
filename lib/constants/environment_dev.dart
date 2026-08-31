import 'package:gurukul/common/environment.dart';

class DevEnv implements Environment {
  @override
  bool get isProduction => false;

  @override
  String get baseUrl =>
      "https://vistaarapis.vistaarfinance.net.in:469/VisAPIs.svc";

  @override
  String get authBaseUrl =>
      "https://vistaarapis.vistaarfinance.net.in:480/api";

  @override
  String get assetUrl =>
      "https://productivity.vistaarfinance.net.in:469/Gurukul_docs";

  @override
  String get productivityBaseUrl =>
      "https://productivity.vistaarfinance.net.in:480";
}
