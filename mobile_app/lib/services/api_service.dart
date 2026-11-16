import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import '../models/invoice.dart';
import 'storage_service.dart';
import 'supabase_service.dart';

class ApiResult<T> {
  final bool success;
  final T? data;
  final String? error;
  final bool requiresReauth;

  ApiResult({
    required this.success,
    this.data,
    this.error,
    this.requiresReauth = false,
  });
}

class ApiService {
  final StorageService storage;
  final String? Function() _tokenProvider;
  final Future<String?> Function() _tokenRefresher;
  final http.Client _httpClient;

  static const String _sessionExpiredMessage =
      'Session expired. Please sign in again.';

  ApiService(
    this.storage, {
    String? Function()? tokenProvider,
    Future<String?> Function()? tokenRefresher,
    http.Client? httpClient,
  })  : _tokenProvider = tokenProvider ?? (() => SupabaseService.currentAccessToken),
        _tokenRefresher = tokenRefresher ?? SupabaseService.refreshAccessToken,
        _httpClient = httpClient ?? http.Client();

  String get _baseUrl => storage.apiBaseUrl.replaceAll(RegExp(r'/+$'), '');

  String? _currentToken() {
    final token = _tokenProvider();
    if (token == null || token.trim().isEmpty) return null;
    return token.trim();
  }

  Future<http.Response?> _sendAuthorized(
    Future<http.Response> Function(String token) send,
  ) async {
    final token = _currentToken();
    if (token == null) return null;

    var response = await send(token);
    if (response.statusCode == 401) {
      final refreshed = await _tokenRefresher();
      if (refreshed != null && refreshed.trim().isNotEmpty) {
        response = await send(refreshed.trim());
      }
    }
    return response;
  }

  Future<Map<String, dynamic>> checkSystemHealth() async {
    try {
      final res = await _httpClient
          .get(Uri.parse('$_baseUrl/api/health'))
          .timeout(const Duration(seconds: 4));
      if (res.statusCode == 200) {
        return jsonDecode(res.body) as Map<String, dynamic>;
      }
      return {'status': 'error', 'code': res.statusCode};
    } catch (e) {
      return {'status': 'offline', 'error': e.toString()};
    }
  }

  Future<Map<String, dynamic>> checkTallyHealth() async {
    try {
      final res = await _sendAuthorized(
        (token) => _httpClient
            .get(
              Uri.parse('$_baseUrl/api/tally/health'),
              headers: {'Authorization': 'Bearer $token'},
            )
            .timeout(const Duration(seconds: 4)),
      );
      if (res == null) {
        return {
          'connected': false,
          'requires_reauth': true,
          'error': _sessionExpiredMessage,
        };
      }
      if (res.statusCode == 200) {
        return jsonDecode(res.body) as Map<String, dynamic>;
      }
      return {
        'connected': false,
        'requires_reauth': res.statusCode == 401,
        'error': res.statusCode == 401 ? _sessionExpiredMessage : 'Status ${res.statusCode}',
      };
    } catch (e) {
      return {
        'connected': false,
        'tally_host': storage.tallyHost,
        'tally_port': storage.tallyPort,
        'company': storage.tallyCompany,
        'error': e.toString(),
      };
    }
  }

  /// Upload bill file bytes (image or PDF) to FastAPI backend OCR extraction
  Future<ApiResult<Invoice>> uploadInvoiceBytes({
    required Uint8List bytes,
    required String filename,
    String? mimeType,
  }) async {
    try {
      final uri = Uri.parse('$_baseUrl/api/invoices/ocr');
      final mediaType = _resolveMediaType(filename, mimeType);

      final response = await _sendAuthorized((token) async {
        final request = http.MultipartRequest('POST', uri)
          ..headers['Authorization'] = 'Bearer $token'
          ..files.add(
            http.MultipartFile.fromBytes(
              'file',
              bytes,
              filename: filename,
              contentType: mediaType,
            ),
          );
        final streamed = await _httpClient
            .send(request)
            .timeout(const Duration(seconds: 60));
        return http.Response.fromStream(streamed);
      });

      if (response == null || response.statusCode == 401) {
        return ApiResult(
          success: false,
          requiresReauth: true,
          error: _sessionExpiredMessage,
        );
      }

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final Map<String, dynamic> ocrData = jsonDecode(response.body);
        final ext = (ocrData['extracted_data'] as Map<String, dynamic>?) ?? {};
        String? imgUrl = ocrData['image_url'];
        if (imgUrl != null && imgUrl.startsWith('/')) {
          imgUrl = '$_baseUrl$imgUrl';
        }

        final invoice = _buildInvoiceFromExtracted(
          ext: ext,
          id: ocrData['id'] ?? 'INV-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}',
          filename: ocrData['filename'] ?? filename,
          imageUrl: imgUrl,
          sha256: ocrData['file_hash_sha256'],
          rawOcrText: ocrData['ocr_result']?['raw_text'] ?? ext['raw_ocr_text'] ?? '',
        );

        return ApiResult(success: true, data: invoice);
      }

      return ApiResult(
        success: false,
        error: '${_parseErrorMessage(response)} [${uri.path}]',
      );
    } catch (e) {
      return ApiResult(success: false, error: 'Cannot connect to backend: $e');
    }
  }

  /// Send on-device extracted OCR JSON to FastAPI /api/invoices/extract-text
  Future<ApiResult<Invoice>> extractFromRawOcr({
    required Map<String, dynamic> ocrResult,
    required String filename,
    String? localPath,
  }) async {
    try {
      final uri = Uri.parse('$_baseUrl/api/invoices/extract-text');
      final response = await _sendAuthorized(
        (token) => _httpClient
            .post(
              uri,
              headers: {
                'Content-Type': 'application/json',
                'Authorization': 'Bearer $token',
              },
              body: jsonEncode(ocrResult),
            )
            .timeout(const Duration(seconds: 45)),
      );

      if (response == null || response.statusCode == 401) {
        return ApiResult(
          success: false,
          requiresReauth: true,
          error: _sessionExpiredMessage,
        );
      }

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final Map<String, dynamic> ext = jsonDecode(response.body);
        final invoice = _buildInvoiceFromExtracted(
          ext: ext,
          id: 'INV-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}',
          filename: filename,
          localPath: localPath,
          rawOcrText: ocrResult['raw_text'] ?? ext['raw_ocr_text'] ?? '',
        );
        return ApiResult(success: true, data: invoice);
      }

      return ApiResult(
        success: false,
        error: '${_parseErrorMessage(response)} [${uri.path}]',
      );
    } catch (e) {
      return ApiResult(success: false, error: 'Cannot connect to backend: $e');
    }
  }

  MediaType _resolveMediaType(String filename, String? mimeType) {
    if (mimeType != null && mimeType.contains('/')) {
      final parts = mimeType.split('/');
      return MediaType(parts[0], parts[1]);
    }
    final lower = filename.toLowerCase();
    if (lower.endsWith('.png')) return MediaType('image', 'png');
    if (lower.endsWith('.webp')) return MediaType('image', 'webp');
    if (lower.endsWith('.pdf')) return MediaType('application', 'pdf');
    return MediaType('image', 'jpeg');
  }

  String _parseErrorMessage(http.Response response) {
    String errMsg = 'Server error (${response.statusCode})';
    try {
      final errJson = jsonDecode(response.body);
      if (errJson is Map && errJson['detail'] != null) {
        errMsg = errJson['detail'].toString();
      }
    } catch (_) {}
    return errMsg;
  }

  Invoice _buildInvoiceFromExtracted({
    required Map<String, dynamic> ext,
    required String id,
    required String filename,
    String? imageUrl,
    String? localPath,
    String? sha256,
    required String rawOcrText,
  }) {
    final rawLines = (ext['line_items'] as List?) ?? [];
    final lineItems = rawLines.asMap().entries.map((entry) {
      final idx = entry.key;
      final l = entry.value as Map<String, dynamic>;
      final parsed = LineItem.fromJson(l);
      return LineItem(
        lineNo: idx + 1,
        descRaw: parsed.descRaw,
        hsn: parsed.hsn,
        stockItem: parsed.stockItem,
        qty: parsed.qty,
        unit: parsed.unit,
        rate: parsed.rate,
        taxable: parsed.taxable,
        taxRate: parsed.taxRate,
        taxAmount: parsed.taxAmount,
        total: parsed.total,
        confidence: parsed.confidence,
      );
    }).toList();

    final subtotal = toDoubleSafe(
      ext['subtotal_amount'],
      lineItems.fold<double>(0.0, (acc, l) => acc + l.taxable),
    );
    final discount = toDoubleSafe(ext['discount_amount'] ?? ext['discount']);
    final cgst = toDoubleSafe(ext['cgst_amount']);
    final sgst = toDoubleSafe(ext['sgst_amount']);
    final igst = toDoubleSafe(ext['igst_amount']);
    final grandTotal = toDoubleSafe(
      ext['total_amount'],
      subtotal - discount + cgst + sgst + igst,
    );

    return Invoice(
      id: id,
      sourceFilename: filename,
      imageUrl: imageUrl,
      localPath: localPath,
      sha256: sha256,
      supplierRaw: ext['supplier_name'] ?? 'Unidentified Supplier',
      supplierMapped: '',
      invoiceNo: ext['invoice_number'] ?? '—',
      invoiceDate: ext['invoice_date'] ?? DateTime.now().toString().substring(0, 10),
      tallyDate: (ext['invoice_date'] ?? '').toString().replaceAll('-', ''),
      gstin: ext['supplier_gstin'] ?? '',
      type: ext['invoice_mode'] == 'inventory' ? 'Inventory Purchase' : 'Accounting Purchase',
      subtotal: subtotal,
      discount: discount,
      cgst: cgst,
      sgst: sgst,
      igst: igst,
      grandTotal: grandTotal,
      status: 'NEEDS_REVIEW',
      tallyRef: '—',
      confidence: ext['overall_confidence'] != null
          ? '${((ext['overall_confidence'] as num) * 100).toStringAsFixed(1)}%'
          : '98.0%',
      rawOcrText: rawOcrText,
      warnings: ((ext['warnings'] as List?) ?? []).map((e) => e.toString()).toList(),
      lines: lineItems,
    );
  }
}
