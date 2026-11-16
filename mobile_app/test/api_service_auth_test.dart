import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:test/test.dart';

import 'package:mobile_app/services/api_service.dart';
import 'package:mobile_app/services/storage_service.dart';
import 'package:mobile_app/services/supabase_service.dart';

Future<StorageService> _makeStorage() async {
  SharedPreferences.setMockInitialValues({});
  return StorageService.init();
}

void main() {
  group('ApiService Authentication & Error Handling', () {
    test('uploadInvoiceBytes sends Bearer token and parses extracted invoice', () async {
      final storage = await _makeStorage();
      String? seenAuth;

      final client = MockClient((request) async {
        seenAuth = request.headers['Authorization'];
        expect(request.url.path, '/api/invoices/ocr');
        return http.Response(
          jsonEncode({
            'id': 'INV-100001',
            'filename': 'bill.png',
            'file_hash_sha256': 'a' * 64,
            'image_url': '/api/invoices/file/abc_bill.png',
            'ocr_result': {'raw_text': 'TAX INVOICE\nTOTAL 500'},
            'extracted_data': {
              'supplier_name': 'RAGA PVT LTD',
              'invoice_number': 'SR2',
              'invoice_date': '2026-10-20',
              'supplier_gstin': '33AAAGP0685F1ZH',
              'subtotal_amount': '500.00',
              'total_amount': '500.00',
              'invoice_mode': 'inventory',
              'line_items': [
                {'item_description': 'Item A', 'taxable_amount': '500.00'}
              ],
            },
          }),
          201,
        );
      });

      final api = ApiService(
        storage,
        tokenProvider: () => 'jwt-abc-123',
        httpClient: client,
      );

      final result = await api.uploadInvoiceBytes(
        bytes: Uint8List.fromList([1, 2, 3]),
        filename: 'bill.png',
      );

      expect(seenAuth, 'Bearer jwt-abc-123');
      expect(result.success, isTrue);
      expect(result.requiresReauth, isFalse);
      expect(result.data?.supplierRaw, 'RAGA PVT LTD');
      expect(result.data?.imageUrl, endsWith('/api/invoices/file/abc_bill.png'));
    });

    test('uploadInvoiceBytes refreshes session once on 401 and retries', () async {
      final storage = await _makeStorage();
      final seenTokens = <String?>[];
      var attempts = 0;

      final client = MockClient((request) async {
        attempts++;
        seenTokens.add(request.headers['Authorization']);
        if (attempts == 1) {
          return http.Response(jsonEncode({'detail': 'Expired'}), 401);
        }
        return http.Response(
          jsonEncode({
            'id': 'INV-100002',
            'filename': 'bill.jpg',
            'extracted_data': {'supplier_name': 'RETRY OK', 'total_amount': '100.00'},
          }),
          201,
        );
      });

      final api = ApiService(
        storage,
        tokenProvider: () => 'stale-token',
        tokenRefresher: () async => 'fresh-token',
        httpClient: client,
      );

      final result = await api.uploadInvoiceBytes(
        bytes: Uint8List.fromList([1, 2, 3]),
        filename: 'bill.jpg',
      );

      expect(attempts, 2);
      expect(seenTokens, ['Bearer stale-token', 'Bearer fresh-token']);
      expect(result.success, isTrue);
      expect(result.data?.supplierRaw, 'RETRY OK');
    });

    test('missing access token returns requiresReauth without issuing network request', () async {
      final storage = await _makeStorage();
      var networkCalled = false;

      final client = MockClient((_) async {
        networkCalled = true;
        return http.Response('{}', 200);
      });

      final api = ApiService(
        storage,
        tokenProvider: () => null,
        httpClient: client,
      );

      final result = await api.extractFromRawOcr(
        ocrResult: {'raw_text': 'TAX INVOICE'},
        filename: 'bill.jpg',
      );

      expect(networkCalled, isFalse);
      expect(result.success, isFalse);
      expect(result.requiresReauth, isTrue);
    });

    test('checkTallyHealth sends Bearer token and propagates 401 reauth flag', () async {
      final storage = await _makeStorage();

      final client = MockClient((request) async {
        expect(request.headers['Authorization'], 'Bearer expired-token');
        return http.Response(jsonEncode({'detail': 'Unauthorized'}), 401);
      });

      final api = ApiService(
        storage,
        tokenProvider: () => 'expired-token',
        tokenRefresher: () async => null,
        httpClient: client,
      );

      final res = await api.checkTallyHealth();
      expect(res['connected'], isFalse);
      expect(res['requires_reauth'], isTrue);
    });

    test('extractFromRawOcr surfaces backend 413/422 detail cleanly', () async {
      final storage = await _makeStorage();

      final client = MockClient((request) async {
        expect(request.headers['Authorization'], 'Bearer valid-tok');
        return http.Response(
          jsonEncode({'detail': 'Uploaded file exceeds maximum allowed size.'}),
          413,
        );
      });

      final api = ApiService(
        storage,
        tokenProvider: () => 'valid-tok',
        httpClient: client,
      );

      final result = await api.extractFromRawOcr(
        ocrResult: {'raw_text': 'TAX INVOICE'},
        filename: 'bill.jpg',
      );

      expect(result.success, isFalse);
      expect(result.requiresReauth, isFalse);
      expect(result.error, contains('Uploaded file exceeds maximum allowed size.'));
    });

    test('SupabaseService.authHeaders builds Bearer header cleanly', () {
      expect(SupabaseService.authHeaders(null), isEmpty);
      expect(SupabaseService.authHeaders(''), isEmpty);
      expect(
        SupabaseService.authHeaders('abc.def.ghi'),
        {'Authorization': 'Bearer abc.def.ghi'},
      );
    });
  });
}
