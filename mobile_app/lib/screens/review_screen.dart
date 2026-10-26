import 'dart:math';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/invoice.dart';
import '../models/draft_sheet.dart';
import '../models/mapping.dart';
import '../models/audit_log.dart';
import '../services/storage_service.dart';
import '../theme/app_theme.dart';
import '../widgets/approve_dialog.dart';
import '../widgets/status_badge.dart';

class ReviewScreen extends StatefulWidget {
  final StorageService storage;
  final Invoice invoice;
  final List<DraftSheet> draftSheets;
  final List<MasterMapping> mappings;
  final ValueChanged<Invoice> onInvoiceUpdated;
  final ValueChanged<List<DraftSheet>> onDraftSheetsUpdated;
  final VoidCallback onBack;

  const ReviewScreen({
    super.key,
    required this.storage,
    required this.invoice,
    required this.draftSheets,
    required this.mappings,
    required this.onInvoiceUpdated,
    required this.onDraftSheetsUpdated,
    required this.onBack,
  });

  @override
  State<ReviewScreen> createState() => _ReviewScreenState();
}

class _ReviewScreenState extends State<ReviewScreen> {
  late TextEditingController _supplierRawController;
  late TextEditingController _invoiceNoController;
  late TextEditingController _invoiceDateController;
  late String _supplierMapped;
  late String _voucherType;

  final currencyFormatter = NumberFormat.currency(locale: 'en_IN', symbol: '₹ ', decimalDigits: 2);

  @override
  void initState() {
    super.initState();
    _supplierRawController = TextEditingController(text: widget.invoice.supplierRaw);
    _invoiceNoController = TextEditingController(text: widget.invoice.invoiceNo);
    _invoiceDateController = TextEditingController(text: widget.invoice.invoiceDate);
    _supplierMapped = widget.invoice.supplierMapped;
    _voucherType = widget.invoice.type;
  }

  @override
  void dispose() {
    _supplierRawController.dispose();
    _invoiceNoController.dispose();
    _invoiceDateController.dispose();
    super.dispose();
  }

  Future<void> _handleApprove() async {
    final result = await ApproveDialog.show(
      context,
      invoice: widget.invoice,
      existingDrafts: widget.draftSheets,
    );

    if (result == null) return;

    final voucherRef = 'PUR/${DateTime.now().year}/${(1000 + Random().nextInt(9000))}';
    final updatedInvoice = Invoice(
      id: widget.invoice.id,
      sourceFilename: widget.invoice.sourceFilename,
      imageUrl: widget.invoice.imageUrl,
      localPath: widget.invoice.localPath,
      sha256: widget.invoice.sha256,
      supplierRaw: _supplierRawController.text.trim(),
      supplierMapped: _supplierMapped,
      invoiceNo: _invoiceNoController.text.trim(),
      invoiceDate: _invoiceDateController.text.trim(),
      tallyDate: _invoiceDateController.text.trim().replaceAll('-', ''),
      gstin: widget.invoice.gstin,
      type: _voucherType,
      subtotal: widget.invoice.subtotal,
      cgst: widget.invoice.cgst,
      sgst: widget.invoice.sgst,
      igst: widget.invoice.igst,
      grandTotal: widget.invoice.grandTotal,
      status: 'APPROVED',
      tallyRef: voucherRef,
      confidence: widget.invoice.confidence,
      rawOcrText: widget.invoice.rawOcrText,
      warnings: widget.invoice.warnings,
      lines: widget.invoice.lines,
    );

    List<DraftSheet> newDraftList = List.from(widget.draftSheets);

    if (result.option == ApproveExcelOption.newSheet) {
      final sanitized = updatedInvoice.supplierRaw.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '_');
      final newSheet = DraftSheet(
        id: 'DRAFT-${DateTime.now().millisecondsSinceEpoch}',
        fileName: 'Tally_Draft_${sanitized}_${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}.xlsx',
        createdAt: DateTime.now().toString().substring(0, 19),
        updatedAt: DateTime.now().toString().substring(0, 19),
        totalAmount: updatedInvoice.grandTotal,
        invoices: [updatedInvoice],
      );
      newDraftList = [newSheet, ...newDraftList];
    } else {
      final targetId = result.existingSheetId;
      newDraftList = newDraftList.map((s) {
        if (s.id == targetId) {
          final existingInvs = List<Invoice>.from(s.invoices);
          final existingIdx = existingInvs.indexWhere((i) => i.id == updatedInvoice.id);
          if (existingIdx >= 0) {
            existingInvs[existingIdx] = updatedInvoice;
          } else {
            existingInvs.add(updatedInvoice);
          }
          final sum = existingInvs.fold<double>(0.0, (acc, i) => acc + i.grandTotal);
          return DraftSheet(
            id: s.id,
            fileName: s.fileName,
            createdAt: s.createdAt,
            updatedAt: DateTime.now().toString().substring(0, 19),
            totalAmount: sum,
            invoices: existingInvs,
          );
        }
        return s;
      }).toList();
    }

    // Save state
    widget.onInvoiceUpdated(updatedInvoice);
    widget.onDraftSheetsUpdated(newDraftList);
    widget.storage.saveDraftSheets(newDraftList);

    // Save Audit Log
    final user = widget.storage.getUser();
    final newAudit = AuditLog(
      time: DateTime.now().toString().substring(0, 19),
      actor: user?.username ?? 'accounts_user_01',
      action: 'VOUCHER_APPROVED_AND_STORED',
      summary: 'Approved voucher for ${updatedInvoice.supplierRaw} (Ref: $voucherRef) and saved into Tally Connector Excel sheet',
    );
    final auditLogs = [newAudit, ...widget.storage.getAuditLogs()];
    widget.storage.saveAuditLogs(auditLogs);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Voucher ${updatedInvoice.id} Approved! Saved to Tally Connector.'),
          backgroundColor: AppColors.successGreen,
        ),
      );
      widget.onBack();
    }
  }

  @override
  Widget build(BuildContext context) {
    final inv = widget.invoice;

    return Scaffold(
      backgroundColor: AppColors.appleBg,
      appBar: AppBar(
        title: Text('Review & Validate (${inv.id})'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: widget.onBack,
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(child: StatusBadge(status: inv.status)),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 90),
        children: [
          // 1. Zoomable Bill Document Preview Card
          Card(
            margin: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.zoom_in_rounded, size: 18, color: AppColors.amazonNavy),
                          const SizedBox(width: 8),
                          const Text(
                            'Original Bill (Pinch to Zoom)',
                            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                          ),
                        ],
                      ),
                      Text(
                        inv.sourceFilename,
                        style: const TextStyle(fontSize: 11, color: AppColors.appleGrey),
                      ),
                    ],
                  ),
                ),
                Container(
                  height: 240,
                  color: const Color(0xFF0F172A),
                  child: ClipRect(
                    child: InteractiveViewer(
                      minScale: 1.0,
                      maxScale: 4.0,
                      child: inv.imageUrl != null && inv.imageUrl!.isNotEmpty
                          ? Image.network(
                              inv.imageUrl!,
                              fit: BoxFit.contain,
                              loadingBuilder: (_, child, progress) {
                                if (progress == null) return child;
                                return const Center(child: CircularProgressIndicator(color: AppColors.amazonOrange));
                              },
                              errorBuilder: (_, __, ___) => const Center(
                                child: Text('Image not accessible', style: TextStyle(color: Colors.white70)),
                              ),
                            )
                          : const Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.description_outlined, color: Colors.white60, size: 48),
                                  SizedBox(height: 8),
                                  Text('Document Preview', style: TextStyle(color: Colors.white70)),
                                ],
                              ),
                            ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // 2. Extracted Header Fields Card
          Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Voucher Header Fields',
                    style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: AppColors.amazonNavy),
                  ),
                  const SizedBox(height: 14),

                  // Supplier Raw
                  const Text('Supplier Name (Raw OCR)', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _supplierRawController,
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: AppColors.appleBg,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Mapped Tally Ledger Dropdown
                  const Text('Mapped Tally Ledger', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 6),
                  DropdownButtonFormField<String>(
                    value: _supplierMapped.isNotEmpty ? _supplierMapped : null,
                    hint: const Text('Select Tally Ledger'),
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: AppColors.appleBg,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    items: [
                      const DropdownMenuItem(value: '', child: Text('Unmapped Supplier')),
                      ...widget.mappings.map((m) => DropdownMenuItem(value: m.tally, child: Text(m.tally))),
                    ],
                    onChanged: (val) => setState(() => _supplierMapped = val ?? ''),
                  ),
                  const SizedBox(height: 12),

                  // Invoice No & Date
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Invoice Number', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
                            const SizedBox(height: 6),
                            TextField(
                              controller: _invoiceNoController,
                              decoration: InputDecoration(
                                filled: true,
                                fillColor: AppColors.appleBg,
                                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Invoice Date', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
                            const SizedBox(height: 6),
                            TextField(
                              controller: _invoiceDateController,
                              decoration: InputDecoration(
                                filled: true,
                                fillColor: AppColors.appleBg,
                                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Voucher Type
                  const Text('Voucher Type', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 6),
                  DropdownButtonFormField<String>(
                    value: _voucherType,
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: AppColors.appleBg,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'Accounting Purchase', child: Text('Accounting Purchase')),
                      DropdownMenuItem(value: 'Inventory Purchase', child: Text('Inventory Purchase')),
                    ],
                    onChanged: (val) => setState(() => _voucherType = val ?? 'Accounting Purchase'),
                  ),
                ],
              ),
            ),
          ),

          // 3. Line Items Cards
          Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Extracted Items',
                        style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: AppColors.amazonNavy),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.appleBg,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '${inv.lines.length} items',
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (inv.lines.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 16),
                      child: Text('No itemized lines detected.', style: TextStyle(color: AppColors.appleGrey)),
                    )
                  else
                    ...inv.lines.map((l) {
                      return Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.appleBg,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppColors.borderSubtle),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    '${l.lineNo}. ${l.descRaw}',
                                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                                  ),
                                ),
                                Text(
                                  currencyFormatter.format(l.total),
                                  style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Qty: ${l.qty} ${l.unit} @ ${currencyFormatter.format(l.rate)}',
                                  style: const TextStyle(fontSize: 11, color: AppColors.appleGrey),
                                ),
                                if (l.taxAmount > 0)
                                  Text(
                                    'Tax: ${currencyFormatter.format(l.taxAmount)} (${l.taxRate}%)',
                                    style: const TextStyle(fontSize: 11, color: AppColors.appleGrey),
                                  ),
                              ],
                            ),
                          ],
                        ),
                      );
                    }),
                ],
              ),
            ),
          ),

          // 4. Financial Summary Card
          Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _buildSummaryRow('Subtotal', inv.subtotal),
                  if (inv.cgst > 0) _buildSummaryRow('CGST', inv.cgst),
                  if (inv.sgst > 0) _buildSummaryRow('SGST', inv.sgst),
                  if (inv.igst > 0) _buildSummaryRow('IGST', inv.igst),
                  const Divider(color: AppColors.borderSubtle),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Grand Total',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
                      ),
                      Text(
                        currencyFormatter.format(inv.grandTotal),
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          color: AppColors.amazonNavy,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // 5. Raw OCR Text Accordion
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            child: ExpansionTile(
              title: const Text(
                'Raw OCR Text & Extraction Data',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
              ),
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E293B),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    inv.rawOcrText.isNotEmpty ? inv.rawOcrText : 'No raw text stored.',
                    style: const TextStyle(fontFamily: 'monospace', fontSize: 11, color: Colors.white70),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),

      // Sticky Bottom Approval Action Bar
      bottomSheet: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surfaceWhite,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 10,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: SafeArea(
          child: Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _handleApprove,
                  icon: const Icon(Icons.check_circle_rounded, size: 20),
                  label: const Text('Approve'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.successGreen,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryRow(String label, double amount) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 12, color: AppColors.appleGrey)),
          Text(
            currencyFormatter.format(amount),
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}
