import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

  group('Cross-Device Draft Excel Sync Tests', () {
    test('syncDraftSheets sends {"sheets": [...], "replace": true} with Bearer auth', () async {
      final storage = await _makeStorage();
      Map<String, dynamic>? sentBody;
      String? authHeader;

      final client = MockClient((request) async {
        expect(request.method, 'PUT');
        expect(request.url.path, '/api/me/draft-sheets');
        authHeader = request.headers['Authorization'];
        sentBody = jsonDecode(request.body) as Map<String, dynamic>;
        return http.Response(jsonEncode(sentBody!['sheets']), 200);
      });

      final api = ApiService(
        storage,
        tokenProvider: () => 'jwt-device-a',
        httpClient: client,
      );

      final res = await api.syncDraftSheets([
        {
          'sheet_id': 'XL-101',
          'sheet_name': 'Nov_Purchases.xlsx',
          'rows_json': [
            {'id': 'INV-1', 'grandTotal': 1499.0},
            {'id': 'INV-2', 'grandTotal': 2500.0},
          ],
        }
      ], replace: true);

      expect(res.success, isTrue);
      expect(authHeader, 'Bearer jwt-device-a');
      expect(sentBody!['replace'], isTrue);
      expect((sentBody!['sheets'] as List).length, 1);
    });

    test('fetchDraftSheets retrieves synced Excel workbooks with Bearer auth', () async {
      final storage = await _makeStorage();
      final client = MockClient((request) async {
        expect(request.method, 'GET');
        expect(request.url.path, '/api/me/draft-sheets');
        expect(request.headers['Authorization'], 'Bearer jwt-device-b');
        return http.Response(
          jsonEncode([
            {
              'sheet_id': 'XL-101',
              'sheet_name': 'Nov_Purchases.xlsx',
              'rows_json': [
                {'id': 'INV-1', 'grandTotal': 1499.0},
                {'id': 'INV-2', 'grandTotal': 2500.0},
              ],
              'updated_at': '2026-11-18T08:00:00Z',
            }
          ]),
          200,
        );
      });

      final api = ApiService(
        storage,
        tokenProvider: () => 'jwt-device-b',
        httpClient: client,
      );

      final res = await api.fetchDraftSheets();
      expect(res.success, isTrue);
      expect(res.data!.length, 1);
      expect(res.data!.first['sheet_name'], 'Nov_Purchases.xlsx');
      expect((res.data!.first['rows_json'] as List).length, 2);
    });

    test('HomeShell uses replace: true when syncing draft sheets to backend', () {
      final src = File('${root.path}/lib/screens/home_shell.dart').readAsStringSync();
      expect(src, contains('syncDraftSheets(payload, replace: true)'));
    });
  });
}
