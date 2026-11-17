import 'dart:io';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final root = Directory.current.path.endsWith('mobile_app')
      ? Directory.current
      : Directory('${Directory.current.path}/mobile_app');

  File projectFile(String relativePath) => File('${root.path}/$relativePath');

  group('Phase 1 AccountScreen & Paywall Removal Checks', () {
    test('payment screens and upgrade paywall dialog are removed', () {
      expect(projectFile('lib/screens/upgrade_screen.dart').existsSync(), isFalse);
      expect(projectFile('lib/widgets/upgrade_paywall_dialog.dart').existsSync(), isFalse);
    });

    test('HomeShell wires AccountScreen as tab 4 with no Upgrade references', () {
      final homeShell = projectFile('lib/screens/home_shell.dart').readAsStringSync();
      expect(homeShell, contains("import 'account_screen.dart';"));
      expect(homeShell, contains('AccountScreen('));
      expect(homeShell, contains("label: 'Account'"));
      expect(homeShell, isNot(contains('UpgradeScreen')));
      expect(homeShell, isNot(contains('UpgradePaywallDialog')));
      expect(homeShell, isNot(contains("label: 'Upgrade'")));
    });

    test('StorageService has no client-side exempt-account or free-scan paywall logic', () {
      final storage = projectFile('lib/services/storage_service.dart').readAsStringSync();
      expect(storage, isNot(contains('_exemptAccounts')));
      expect(storage, isNot(contains('isUserPro')));
      expect(storage, isNot(contains('canUserScan')));
      expect(storage, contains('Future<void> clearActiveUserData()'));
    });

    test('AccountScreen implements mounted guards, deletion confirmation, and design tokens', () {
      final account = projectFile('lib/screens/account_screen.dart');
      expect(account.existsSync(), isTrue);
      final src = account.readAsStringSync();

      expect(src, contains('Delete Account'));
      expect(src, contains('Privacy Policy'));
      expect(src, contains('Terms of Service'));
      expect(src, contains('if (!mounted) return;'));
      expect(src, contains('clearActiveUserData()'));
      expect(src, isNot(contains('Color(0x')));
    });
  });
}
