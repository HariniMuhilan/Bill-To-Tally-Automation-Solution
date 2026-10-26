import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import '../models/invoice.dart';
import 'storage_service.dart';

class ApiResult<T> {
  final bool success;
  final T? data;
  final String? error;

  ApiResult({required this.success, this.data, this.error});
}

class ApiService {
  final StorageService storage;

  ApiService(this.storage);

  String get _baseUrl => storage.apiBaseUrl;

  Future<Map<String, dynamic>> checkSystemHealth() async {
    try {
      final res = await http.get(Uri.parse('$_baseUrl/api/health')).timeout(const Duration(seconds: 4));
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
      final res = await http.get(Uri.parse('$_baseUrl/api/tally/health')).timeout(const Duration(seconds: 4));
      if (res.statusCode == 200) {
        return jsonDecode(res.body) as Map<String, dynamic>;
      }
      return {'connected': false, 'error': 'Status ${res.statusCode}'};
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
      final request = http.MultipartRequest('POST', uri);

      MediaType? mediaType;
      if (mimeType != null && mimeType.contains('/')) {
        final parts = mimeType.split('/');
        mediaType = MediaType(parts[0], parts[1]);
      } else if (filename.toLowerCase().endsWith('.png')) {
        mediaType = MediaType('image', 'png');
      } else if (filename.toLowerCase().endsWith('.pdf')) {
        mediaType = MediaType('application', 'pdf');
      } else {
        mediaType = MediaType('image', 'jpeg');
      }

      request.files.add(
        http.MultipartFile.fromBytes(
          'file',
          bytes,
          filename: filename,
          contentType: mediaType,
        ),
      );

      final streamedResponse = await request.send().timeout(const Duration(seconds: 60));
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final Map<String, dynamic> ocrData = jsonDecode(response.body);
        final ext = (ocrData['extracted_data'] as Map<String, dynamic>?) ?? {};

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
        final cgst = toDoubleSafe(ext['cgst_amount']);
        final sgst = toDoubleSafe(ext['sgst_amount']);
        final igst = toDoubleSafe(ext['igst_amount']);
        final grandTotal = toDoubleSafe(
          ext['total_amount'],
          subtotal + cgst + sgst + igst,
        );

        String? imgUrl = ocrData['image_url'];
        if (imgUrl != null && imgUrl.startsWith('/')) {
          imgUrl = '$_baseUrl$imgUrl';
        }

        final invoice = Invoice(
          id: ocrData['id'] ?? 'INV-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}',
          sourceFilename: ocrData['filename'] ?? filename,
          imageUrl: imgUrl,
          sha256: ocrData['file_hash_sha256'],
          supplierRaw: ext['supplier_name'] ?? 'Unidentified Supplier',
          supplierMapped: '',
          invoiceNo: ext['invoice_number'] ?? '—',
          invoiceDate: ext['invoice_date'] ?? DateTime.now().toString().substring(0, 10),
          tallyDate: (ext['invoice_date'] ?? '').toString().replaceAll('-', ''),
          gstin: ext['supplier_gstin'] ?? '',
          type: ext['invoice_mode'] == 'inventory' ? 'Inventory Purchase' : 'Accounting Purchase',
          subtotal: subtotal,
          cgst: cgst,
          sgst: sgst,
          igst: igst,
          grandTotal: grandTotal,
          status: 'NEEDS_REVIEW',
          tallyRef: '—',
          confidence: ext['overall_confidence'] != null 
              ? '${((ext['overall_confidence'] as num) * 100).toStringAsFixed(1)}%'
              : '98.0%',
          rawOcrText: ocrData['ocr_result']?['raw_text'] ?? ext['raw_ocr_text'] ?? '',
          warnings: ((ext['warnings'] as List?) ?? []).map((e) => e.toString()).toList(),
          lines: lineItems,
        );

        return ApiResult(success: true, data: invoice);
      } else {
        String errMsg = 'Server error (${response.statusCode})';
        try {
          final errJson = jsonDecode(response.body);
          if (errJson['detail'] != null) errMsg = errJson['detail'];
        } catch (_) {}
        return ApiResult(success: false, error: errMsg);
      }
    } catch (e) {
      return ApiResult(success: false, error: 'Cannot connect to backend: $e');
    }
  }
}
