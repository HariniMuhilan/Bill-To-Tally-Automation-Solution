import 'dart:io';
import 'package:test/test.dart';

void main() {
  final root = Directory.current.path.endsWith('mobile_app')
      ? Directory.current
      : Directory('${Directory.current.path}/mobile_app');

  File projectFile(String relativePath) => File('${root.path}/$relativePath');

  group('Android Play Store & Security Config', () {
    test('main AndroidManifest enforces networkSecurityConfig and disables backups & global cleartext', () {
      final manifest = projectFile('android/app/src/main/AndroidManifest.xml');
      expect(manifest.existsSync(), isTrue);
      final xml = manifest.readAsStringSync();

      expect(xml, isNot(contains('usesCleartextTraffic="true"')));
      expect(xml, contains('android:allowBackup="false"'));
      expect(xml, contains('android:networkSecurityConfig="@xml/network_security_config"'));
    });

    test('production network_security_config denies public cleartext HTTP and limits cleartext to loopback', () {
      final config = projectFile('android/app/src/main/res/xml/network_security_config.xml');
      expect(config.existsSync(), isTrue);
      final xml = config.readAsStringSync();

      expect(xml, contains('<base-config cleartextTrafficPermitted="false">'));
      expect(xml, contains('<domain includeSubdomains="false">127.0.0.1</domain>'));
      expect(xml, contains('<domain includeSubdomains="false">localhost</domain>'));
    });

    test('debug network_security_config override exists solely under src/debug', () {
      final debugConfig = projectFile('android/app/src/debug/res/xml/network_security_config.xml');
      expect(debugConfig.existsSync(), isTrue);
      expect(debugConfig.readAsStringSync(), contains('cleartextTrafficPermitted="true"'));
    });

    test('release build.gradle.kts never falls back to debug signing and enforces fail-closed guard', () {
      final gradle = projectFile('android/app/build.gradle.kts');
      expect(gradle.existsSync(), isTrue);
      final kts = gradle.readAsStringSync();

      expect(kts, isNot(contains('signingConfigs.getByName("debug")')));
      expect(kts, contains('create("release")'));
      expect(kts, contains('gradle.taskGraph.whenReady'));
      expect(kts, contains('throw GradleException'));
    });

    test('release signing secrets are gitignored and template has no populated secrets', () {
      final gitignore = projectFile('.gitignore').readAsStringSync();
      expect(gitignore, contains('/android/key.properties'));
      expect(gitignore, contains('**/*.keystore'));
      expect(gitignore, contains('**/*.jks'));

      final template = projectFile('android/key.properties.example');
      expect(template.existsSync(), isTrue);
      final templateText = template.readAsStringSync().replaceAll('\r\n', '\n');
      expect(templateText, contains('storePassword=\n'));
      expect(templateText, contains('keyPassword=\n'));
    });
  });
}
