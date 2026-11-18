import 'dart:io';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final root = Directory.current.path.endsWith('mobile_app')
      ? Directory.current
      : Directory('${Directory.current.path}/mobile_app');

  group('UI Polish, Vector Footer Icons & Dialog Contrast Checks', () {
    test('SplashScreen animates logo with Hero and respects disableAnimations', () {
      final splashSrc = File('${root.path}/lib/screens/splash_screen.dart').readAsStringSync();
      final mainSrc = File('${root.path}/lib/main.dart').readAsStringSync();

      expect(splashSrc, contains("tag: 'billbooks_brand_logo'"));
      expect(splashSrc, contains('MediaQuery.disableAnimationsOf(context)'));
      expect(splashSrc, contains('AnimatedOpacity'));
      expect(splashSrc, contains('AnimatedScale'));
      expect(mainSrc, contains('SplashScreen('));
    });

    test('HomeShell footer uses AppVectorIcon for all nav items and camera FAB', () {
      final homeSrc = File('${root.path}/lib/screens/home_shell.dart').readAsStringSync();
      expect(homeSrc, contains('AppVectorIconType.inbox'));
      expect(homeSrc, contains('AppVectorIconType.review'));
      expect(homeSrc, contains('AppVectorIconType.camera'));
      expect(homeSrc, contains('AppVectorIconType.tallySync'));
      expect(homeSrc, contains('AppVectorIconType.account'));
      expect(homeSrc, contains('AnimatedSwitcher'));
    });

    test('Modal dialogs use solid Colors.white surfaces instead of translucent LiquidGlass', () {
      for (final rel in [
        'lib/widgets/forgot_password_dialog.dart',
        'lib/widgets/request_access_otp_dialog.dart',
        'lib/widgets/server_settings_dialog.dart',
      ]) {
        final src = File('${root.path}/$rel').readAsStringSync();
        expect(src, contains('color: Colors.white'), reason: '$rel must be solid white');
        expect(src, isNot(contains('child: LiquidGlass(')), reason: '$rel must not wrap dialog in translucent LiquidGlass');
      }
    });
  });
}
