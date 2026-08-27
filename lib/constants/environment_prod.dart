import 'package:gurukul/common/environment.dart';

class ProdEnv extends Environment {
  @override
  String get baseUrl =>
      "https://vistaarapis.vistaarfinance.net.in:469/VisAPIsProd.svc";

  @override
  String get authBaseUrl =>
      "https://vistaarapis.vistaarfinance.net.in:482/api";

  @override
  String get assetUrl =>
      "https://productivity.vistaarfinance.net.in:469/Gurukul_docsProd";

  @override
  String get productivityBaseUrl =>
      "https://productivity.vistaarfinance.net.in:482";
}
