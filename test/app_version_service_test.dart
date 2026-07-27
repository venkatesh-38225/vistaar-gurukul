import 'package:flutter_test/flutter_test.dart';
import 'package:gurukul/services/app_version_service.dart';

void main() {
  group('App version matching', () {
    test('matches the same installed and API versions', () {
      expect(AppVersionService.versionsMatch('2.0.0', '2.0.0'), isTrue);
    });

    test('ignores surrounding whitespace, v prefix, and build number', () {
      expect(AppVersionService.versionsMatch('2.0.0+45', ' v2.0.0 '), isTrue);
    });

    test('requires an update when the installed version is lower', () {
      expect(AppVersionService.versionsMatch('1.9.9', '2.0.0'), isFalse);
    });

    test('requires an update when the installed version is higher', () {
      expect(AppVersionService.versionsMatch('2.0.1', '2.0.0'), isFalse);
    });
  });
}
