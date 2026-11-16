import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:test/test.dart';

import 'package:mobile_app/services/api_service.dart';
import 'package:mobile_app/services/storage_service.dart';

Future<StorageService> _makeStorage() async {
  SharedPreferences.setMockInitialValues({});
  return StorageService.init();
}

void main() {
  final root = Directory.current.path.endsWith('mobile_app')
      ? Directory.current
      : Directory('${Directory.current.path}/mobile_app');

  group('Phase 2 Request Access API & LoginScreen Safety Checks', () {
    test('submitAccessRequest posts trimmed payload and succeeds on 201', () async {
      final storage = await _makeStorage();
      Map<String, dynamic>? sentBody;

      final client = MockClient((request) async {
        expect(request.method, 'POST');
        expect(request.url.path, '/api/access-requests');
        sentBody = jsonDecode(request.body) as Map<String, dynamic>;
        return http.Response(jsonEncode({'status': 'pending'}), 201);
      });

      final api = ApiService(storage, httpClient: client);
      final res = await api.submitAccessRequest(
        fullName: '  Arjun S  ',
        businessName: '  Raga Pvt Ltd ',
        email: ' arjun@raga.in ',
        phone: ' +91 9876543210 ',
      );

      expect(res.success, isTrue);
      expect(sentBody, {
        'full_name': 'Arjun S',
        'business_name': 'Raga Pvt Ltd',
        'email': 'arjun@raga.in',
        'phone': '+91 9876543210',
      });
    });

    test('submitAccessRequest handles 404 gracefully until backend endpoint deploys', () async {
      final storage = await _makeStorage();
      final client = MockClient((_) async => http.Response('Not Found', 404));
      final api = ApiService(storage, httpClient: client);

      final res = await api.submitAccessRequest(
        fullName: 'Arjun',
        businessName: 'Raga',
        email: 'arjun@raga.in',
        phone: '9876543210',
      );

      expect(res.success, isFalse);
      expect(res.error, 'ACCESS_REQUEST_ENDPOINT_UNAVAILABLE');
    });

    test('submitAccessRequest surfaces server validation/rate-limit errors cleanly', () async {
      final storage = await _makeStorage();
      final client = MockClient(
        (_) async => http.Response(jsonEncode({'detail': 'Too many requests'}), 429),
      );
      final api = ApiService(storage, httpClient: client);

      final res = await api.submitAccessRequest(
        fullName: 'Arjun',
        businessName: 'Raga',
        email: 'arjun@raga.in',
        phone: '9876543210',
      );

      expect(res.success, isFalse);
      expect(res.error, 'Too many requests');
    });

    test('LoginScreen removes Create Account, keeps Forgot Password, and disposes all controllers', () {
      final src = File('${root.path}/lib/screens/login_screen.dart').readAsStringSync();

      expect(src, isNot(contains('CREATE ACCOUNT')));
      expect(src, isNot(contains('SupabaseService.signUp')));
      expect(src, contains('REQUEST ACCESS'));
      expect(src, contains('SIGN IN'));
      expect(src, contains('Forgot Password?'));
      expect(src, contains('if (!mounted) return;'));
      expect(src, contains('_reqNameController.dispose();'));
      expect(src, contains('_reqBusinessController.dispose();'));
      expect(src, contains('_reqEmailController.dispose();'));
      expect(src, contains('_reqPhoneController.dispose();'));
    });
  });
}
