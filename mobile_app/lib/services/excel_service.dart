import 'dart:io';
import 'package:excel/excel.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_filex/open_filex.dart';
import '../models/invoice.dart';

class ExcelService {
  /// Builds an Excel workbook for one or multiple approved invoices
  static Uint8List generateDraftWorkbook({
    required String sheetTitle,
    required List<Invoice> invoices,
  }) {
    final excel = Excel.createExcel();
    
    // Rename default sheet
    final defaultSheetName = excel.getDefaultSheet() ?? 'Sheet1';
    excel.rename(defaultSheetName, 'Vouchers_Summary');

    final Sheet summarySheet = excel['Vouchers_Summary'];
    final Sheet itemsSheet = excel['Line_Items_Detail'];

    // 1. Headers for Vouchers Summary
    final summaryHeaders = [
      'Voucher ID',
      'Original File',
      'Supplier (Raw)',
      'Mapped Ledger',
      'Invoice No',
      'Invoice Date',
      'Voucher Type',
      'GSTIN',
      'Subtotal (₹)',
      'CGST (₹)',
      'SGST (₹)',
      'IGST (₹)',
      'Grand Total (₹)',
      'Status',
      'Tally Ref'
    ];

    summarySheet.appendRow(summaryHeaders.map((h) => TextCellValue(h)).toList());

    for (var inv in invoices) {
      summarySheet.appendRow([
        TextCellValue(inv.id),
        TextCellValue(inv.sourceFilename),
        TextCellValue(inv.supplierRaw),
        TextCellValue(inv.supplierMapped.isNotEmpty ? inv.supplierMapped : 'Standard Purchase'),
        TextCellValue(inv.invoiceNo),
        TextCellValue(inv.invoiceDate),
        TextCellValue(inv.type),
        TextCellValue(inv.gstin),
        DoubleCellValue(inv.subtotal),
        DoubleCellValue(inv.cgst),
        DoubleCellValue(inv.sgst),
        DoubleCellValue(inv.igst),
        DoubleCellValue(inv.grandTotal),
        TextCellValue(inv.status),
        TextCellValue(inv.tallyRef),
      ]);
    }

    // 2. Headers for Line Items Detail
    final itemHeaders = [
      'Voucher ID',
      'Line #',
      'Description / Item Raw',
      'HSN / SAC Code',
      'Tally Stock Item',
      'Quantity',
      'Unit',
      'Rate (₹)',
      'Taxable Value (₹)',
      'GST %',
      'Tax Amount (₹)',
      'Line Total (₹)',
      'Confidence %'
    ];

    itemsSheet.appendRow(itemHeaders.map((h) => TextCellValue(h)).toList());

    for (var inv in invoices) {
      for (var line in inv.lines) {
        itemsSheet.appendRow([
          TextCellValue(inv.id),
          IntCellValue(line.lineNo),
          TextCellValue(line.descRaw),
          TextCellValue(line.hsn),
          TextCellValue(line.stockItem.isNotEmpty ? line.stockItem : line.descRaw),
          DoubleCellValue(line.qty),
          TextCellValue(line.unit),
          DoubleCellValue(line.rate),
          DoubleCellValue(line.taxable),
          DoubleCellValue(line.taxRate),
          DoubleCellValue(line.taxAmount),
          DoubleCellValue(line.total),
          DoubleCellValue(line.confidence),
        ]);
      }
    }

    final bytes = excel.save();
    return Uint8List.fromList(bytes ?? []);
  }

  /// Returns user-scoped Excel filename
  static String getWorkbookFileName(String? username) {
    final clean = (username ?? 'user').trim().toLowerCase().replaceAll(RegExp(r'[^a-zA-Z0-9]'), '_');
    return 'BillBooks_${clean}_Vouchers.xlsx';
  }

  /// Appends an approved invoice and its line items directly to the user's local Excel workbook on disk.
  static Future<String?> appendInvoiceToWorkbook({
    required String? username,
    required Invoice invoice,
  }) async {
    if (kIsWeb) return null;

    try {
      final dir = await getApplicationDocumentsDirectory();
      final fileName = getWorkbookFileName(username);
      final file = File('${dir.path}/$fileName');

      Excel excel;
      if (await file.exists()) {
        final existingBytes = await file.readAsBytes();
        excel = Excel.decodeBytes(existingBytes);
      } else {
        final initialBytes = generateDraftWorkbook(
          sheetTitle: fileName,
          invoices: [invoice],
        );
        await file.writeAsBytes(initialBytes);
        return file.path;
      }

      final Sheet summarySheet = excel['Vouchers_Summary'];
      final Sheet itemsSheet = excel['Line_Items_Detail'];

      // Append row to Vouchers_Summary
      summarySheet.appendRow([
        TextCellValue(invoice.id),
        TextCellValue(invoice.sourceFilename),
        TextCellValue(invoice.supplierRaw),
        TextCellValue(invoice.supplierMapped.isNotEmpty ? invoice.supplierMapped : 'Standard Purchase'),
        TextCellValue(invoice.invoiceNo),
        TextCellValue(invoice.invoiceDate),
        TextCellValue(invoice.type),
        TextCellValue(invoice.gstin),
        DoubleCellValue(invoice.subtotal),
        DoubleCellValue(invoice.cgst),
        DoubleCellValue(invoice.sgst),
        DoubleCellValue(invoice.igst),
        DoubleCellValue(invoice.grandTotal),
        TextCellValue(invoice.status),
        TextCellValue(invoice.tallyRef),
      ]);

      // Append rows to Line_Items_Detail
      for (var line in invoice.lines) {
        itemsSheet.appendRow([
          TextCellValue(invoice.id),
          IntCellValue(line.lineNo),
          TextCellValue(line.descRaw),
          TextCellValue(line.hsn),
          TextCellValue(line.stockItem.isNotEmpty ? line.stockItem : line.descRaw),
          DoubleCellValue(line.qty),
          TextCellValue(line.unit),
          DoubleCellValue(line.rate),
          DoubleCellValue(line.taxable),
          DoubleCellValue(line.taxRate),
          DoubleCellValue(line.taxAmount),
          DoubleCellValue(line.total),
          DoubleCellValue(line.confidence),
        ]);
      }

      final updatedBytes = excel.save();
      if (updatedBytes != null) {
        await file.writeAsBytes(updatedBytes);
      }
      return file.path;
    } catch (e) {
      debugPrint('Error appending to Excel workbook: $e');
      return null;
    }
  }

  /// Opens the user's Excel file in external viewer
  static Future<void> openUserExcel(String? username) async {
    if (kIsWeb) return;
    try {
      final dir = await getApplicationDocumentsDirectory();
      final fileName = getWorkbookFileName(username);
      final file = File('${dir.path}/$fileName');
      if (await file.exists()) {
        await OpenFilex.open(file.path);
      }
    } catch (e) {
      debugPrint('Error opening Excel file: $e');
    }
  }

  /// Saves the workbook locally and opens/shares it
  static Future<String?> saveAndOpenExcel({
    required String fileName,
    required List<Invoice> invoices,
  }) async {
    final bytes = generateDraftWorkbook(
      sheetTitle: fileName,
      invoices: invoices,
    );

    if (kIsWeb) {
      // In web, browser handles download
      return null;
    }

    try {
      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/$fileName');
      await file.writeAsBytes(bytes);
      await OpenFilex.open(file.path);
      return file.path;
    } catch (e) {
      debugPrint('Error saving Excel: $e');
      return null;
    }
  }
}
