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

class _EditableItemRow {
  int lineNo;
  final TextEditingController nameController;
  final TextEditingController qtyController;
  final TextEditingController rateController;
  double taxRate;
  double taxAmount;

  _EditableItemRow({
    required this.lineNo,
    required String name,
    required double qty,
    required double rate,
    this.taxRate = 0.0,
    this.taxAmount = 0.0,
  })  : nameController = TextEditingController(text: name),
        qtyController = TextEditingController(
          text: qty % 1 == 0 ? qty.toInt().toString() : qty.toString(),
        ),
        rateController = TextEditingController(
          text: rate > 0
              ? (rate % 1 == 0 ? rate.toInt().toString() : rate.toStringAsFixed(2))
              : '0.00',
        );

  double get qty => double.tryParse(qtyController.text.trim()) ?? 0.0;
  double get rate => double.tryParse(rateController.text.trim()) ?? 0.0;
  double get total => qty * rate;

  void dispose() {
    nameController.dispose();
    qtyController.dispose();
    rateController.dispose();
  }
}

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
  final List<_EditableItemRow> _items = [];

  final currencyFormatter = NumberFormat.currency(locale: 'en_IN', symbol: '₹ ', decimalDigits: 2);

  @override
  void initState() {
    super.initState();
    _supplierRawController = TextEditingController(text: widget.invoice.supplierRaw);
    _invoiceNoController = TextEditingController(text: widget.invoice.invoiceNo);
    _invoiceDateController = TextEditingController(text: widget.invoice.invoiceDate);
    _supplierMapped = widget.invoice.supplierMapped;
    _voucherType = widget.invoice.type;

    // Initialize editable item lines
    for (final l in widget.invoice.lines) {
      _items.add(
        _EditableItemRow(
          lineNo: l.lineNo,
          name: l.descRaw,
          qty: l.qty,
          rate: l.rate,
          taxRate: l.taxRate,
          taxAmount: l.taxAmount,
        ),
      );
    }
  }

  @override
  void dispose() {
    _supplierRawController.dispose();
    _invoiceNoController.dispose();
    _invoiceDateController.dispose();
    for (final item in _items) {
      item.dispose();
    }
    super.dispose();
  }

  double get _calculatedSubtotal {
    if (_items.isEmpty) return widget.invoice.subtotal;
    return _items.fold<double>(0.0, (sum, i) => sum + i.total);
  }

  double get _calculatedGrandTotal {
    final sub = _calculatedSubtotal;
    final taxes = widget.invoice.cgst + widget.invoice.sgst + widget.invoice.igst;
    return sub + taxes;
  }

  void _addNewItem() {
    setState(() {
      final nextNo = _items.length + 1;
      _items.add(
        _EditableItemRow(
          lineNo: nextNo,
          name: 'Item $nextNo',
          qty: 1.0,
          rate: 0.0,
        ),
      );
    });
  }

  void _removeItem(int index) {
    setState(() {
      _items[index].dispose();
      _items.removeAt(index);
      for (int i = 0; i < _items.length; i++) {
        _items[i].lineNo = i + 1;
      }
    });
  }

  void _showFullScreenZoomModal(BuildContext context) {
    final inv = widget.invoice;
    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.85),
      builder: (ctx) {
        return Dialog(
          insetPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 24),
          backgroundColor: const Color(0xFF0F172A),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Column(
            children: [
              // Modal Header with Close Button
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 10, 12),
                child: Row(
                  children: [
                    const Icon(Icons.zoom_in_rounded, color: AppColors.softSage, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        inv.sourceFilename,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        'Pinch to zoom',
                        style: TextStyle(color: Colors.white70, fontSize: 11),
                      ),
                    ),
                    const SizedBox(width: 6),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, color: Colors.white, size: 22),
                      onPressed: () => Navigator.of(ctx).pop(),
                    ),
                  ],
                ),
              ),
              const Divider(color: Colors.white12, height: 1),

              // Interactive Zoomable Image
              Expanded(
                child: ClipRRect(
                  borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16)),
                  child: InteractiveViewer(
                    minScale: 0.8,
                    maxScale: 6.0,
                    child: Center(
                      child: inv.imageUrl != null && inv.imageUrl!.isNotEmpty
                          ? Image.network(
                              inv.imageUrl!,
                              fit: BoxFit.contain,
                              loadingBuilder: (_, child, progress) {
                                if (progress == null) return child;
                                return const Center(
                                  child: CircularProgressIndicator(color: AppColors.softSage),
                                );
                              },
                              errorBuilder: (_, __, ___) => const Center(
                                child: Text('Image not accessible', style: TextStyle(color: Colors.white70)),
                              ),
                            )
                          : const Center(
                              child: Text('No image available', style: TextStyle(color: Colors.white70)),
                            ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _handleApprove() async {
    final result = await ApproveDialog.show(
      context,
      invoice: widget.invoice,
      existingDrafts: widget.draftSheets,
    );

    if (result == null) return;

    // Convert editable items to LineItems
    final updatedLines = _items.asMap().entries.map((entry) {
      final idx = entry.key;
      final item = entry.value;
      final name = item.nameController.text.trim();
      return LineItem(
        lineNo: idx + 1,
        descRaw: name.isNotEmpty ? name : 'Item ${idx + 1}',
        qty: item.qty,
        rate: item.rate,
        total: item.total,
        taxRate: item.taxRate,
        taxAmount: item.taxAmount,
      );
    }).toList();

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
      subtotal: _calculatedSubtotal,
      cgst: widget.invoice.cgst,
      sgst: widget.invoice.sgst,
      igst: widget.invoice.igst,
      grandTotal: _calculatedGrandTotal,
      status: 'APPROVED',
      tallyRef: voucherRef,
      confidence: widget.invoice.confidence,
      rawOcrText: widget.invoice.rawOcrText,
      warnings: widget.invoice.warnings,
      lines: updatedLines,
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
          backgroundColor: const Color(0xFF2E7D32),
        ),
      );
      widget.onBack();
    }
  }

  @override
  Widget build(BuildContext context) {
    final inv = widget.invoice;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F6F8),
      body: Column(
        children: [
          // Sub-header with back button and Status badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: const BoxDecoration(
              color: AppColors.surfaceWhite,
              border: Border(bottom: BorderSide(color: AppColors.borderSubtle)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                InkWell(
                  onTap: widget.onBack,
                  borderRadius: BorderRadius.circular(8),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Icon(Icons.arrow_back_rounded, size: 18, color: AppColors.inkNavy),
                        SizedBox(width: 4),
                        Text(
                          'Back',
                          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: AppColors.inkNavy),
                        ),
                      ],
                    ),
                  ),
                ),
                Text(
                  'Bill #${inv.id}',
                  style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: AppColors.inkNavy),
                ),
                StatusBadge(status: inv.status),
              ],
            ),
          ),

          // Main Scrollable Content
          Expanded(
            child: ListView(
              padding: const EdgeInsets.only(bottom: 120),
              children: [
                // 1. Fixed Bill Document Preview Card (No gesture scroll capture, tap to zoom)
                Card(
                  margin: const EdgeInsets.fromLTRB(16, 14, 16, 8),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: const BorderSide(color: AppColors.borderSubtle),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: const [
                                Icon(Icons.receipt_rounded, size: 18, color: AppColors.plumSlate),
                                SizedBox(width: 8),
                                Text(
                                  'Original Bill',
                                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: AppColors.inkNavy),
                                ),
                              ],
                            ),
                            Text(
                              inv.sourceFilename,
                              style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                            ),
                          ],
                        ),
                      ),
                      InkWell(
                        onTap: () => _showFullScreenZoomModal(context),
                        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16)),
                        child: Container(
                          height: 220,
                          decoration: const BoxDecoration(
                            color: Color(0xFF0F172A),
                            borderRadius: BorderRadius.vertical(bottom: Radius.circular(16)),
                          ),
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              // Fixed image preview (non-interactive to allow smooth page scrolling)
                              inv.imageUrl != null && inv.imageUrl!.isNotEmpty
                                  ? Image.network(
                                      inv.imageUrl!,
                                      fit: BoxFit.contain,
                                      loadingBuilder: (_, child, progress) {
                                        if (progress == null) return child;
                                        return const Center(
                                          child: CircularProgressIndicator(color: AppColors.softSage),
                                        );
                                      },
                                      errorBuilder: (_, __, ___) => const Center(
                                        child: Text('Image not accessible', style: TextStyle(color: Colors.white70)),
                                      ),
                                    )
                                  : const Center(
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(Icons.description_outlined, color: Colors.white60, size: 44),
                                          SizedBox(height: 8),
                                          Text('Document Preview', style: TextStyle(color: Colors.white70, fontSize: 12)),
                                        ],
                                      ),
                                    ),

                              // Bottom Tap to Enlarge & Zoom Badge
                              Positioned(
                                bottom: 10,
                                right: 12,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withOpacity(0.70),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: Colors.white.withOpacity(0.25)),
                                  ),
                                  child: const Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.fullscreen_rounded, color: Colors.white, size: 14),
                                      SizedBox(width: 5),
                                      Text(
                                        'Tap to enlarge & zoom',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // 2. Voucher Header Fields Card (Mapped Tally Ledger removed as requested)
                Card(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: const BorderSide(color: AppColors.borderSubtle),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Voucher Header Fields',
                          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: AppColors.inkNavy),
                        ),
                        const SizedBox(height: 14),

                        // Supplier Name
                        const Text('Supplier Name', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.inkNavy)),
                        const SizedBox(height: 6),
                        TextField(
                          controller: _supplierRawController,
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: const Color(0xFFFDFBFD),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: const BorderSide(color: AppColors.borderSubtle),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: const BorderSide(color: AppColors.borderSubtle),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Invoice No & Date
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('Invoice Number', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.inkNavy)),
                                  const SizedBox(height: 6),
                                  TextField(
                                    controller: _invoiceNoController,
                                    decoration: InputDecoration(
                                      filled: true,
                                      fillColor: const Color(0xFFFDFBFD),
                                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(10),
                                        borderSide: const BorderSide(color: AppColors.borderSubtle),
                                      ),
                                      enabledBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(10),
                                        borderSide: const BorderSide(color: AppColors.borderSubtle),
                                      ),
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
                                  const Text('Invoice Date', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.inkNavy)),
                                  const SizedBox(height: 6),
                                  TextField(
                                    controller: _invoiceDateController,
                                    decoration: InputDecoration(
                                      filled: true,
                                      fillColor: const Color(0xFFFDFBFD),
                                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(10),
                                        borderSide: const BorderSide(color: AppColors.borderSubtle),
                                      ),
                                      enabledBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(10),
                                        borderSide: const BorderSide(color: AppColors.borderSubtle),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),

                        // Voucher Type
                        const Text('Voucher Type', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.inkNavy)),
                        const SizedBox(height: 6),
                        DropdownButtonFormField<String>(
                          value: _voucherType,
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: const Color(0xFFFDFBFD),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: const BorderSide(color: AppColors.borderSubtle),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: const BorderSide(color: AppColors.borderSubtle),
                            ),
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

                // 3. Extracted Items (Editable Format: Name, Quantity, and Price)
                Card(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: const BorderSide(color: AppColors.borderSubtle),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                const Text(
                                  'Extracted Items',
                                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: AppColors.inkNavy),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: AppColors.mauveBg,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Text(
                                    'Editable',
                                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.plumSlate),
                                  ),
                                ),
                              ],
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF3EDF2),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                '${_items.length} items',
                                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.inkNavy),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'Tap any item to edit name, quantity, or price if scanned incorrectly.',
                          style: TextStyle(fontSize: 11, color: AppColors.textMuted),
                        ),
                        const SizedBox(height: 14),

                        if (_items.isEmpty)
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFAF7F9),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: AppColors.borderSubtle),
                            ),
                            child: Column(
                              children: [
                                const Icon(Icons.inventory_2_outlined, size: 36, color: AppColors.textMuted),
                                const SizedBox(height: 8),
                                const Text(
                                  'No items extracted by OCR',
                                  style: TextStyle(fontWeight: FontWeight.w700, color: AppColors.inkNavy),
                                ),
                                const SizedBox(height: 4),
                                const Text(
                                  'Add items manually below to calculate and record voucher.',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(fontSize: 11, color: AppColors.textMuted),
                                ),
                              ],
                            ),
                          )
                        else
                          ..._items.asMap().entries.map((entry) {
                            final idx = entry.key;
                            final item = entry.value;

                            return Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFAF7F9),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: const Color(0xFFEADBEC)),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Line Header: Item Index & Delete Button
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: AppColors.plumSlate,
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: Text(
                                          'Item #${item.lineNo}',
                                          style: const TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w800,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.delete_outline_rounded, size: 18, color: Color(0xFFDC2626)),
                                        visualDensity: VisualDensity.compact,
                                        padding: EdgeInsets.zero,
                                        constraints: const BoxConstraints(),
                                        tooltip: 'Remove item',
                                        onPressed: () => _removeItem(idx),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),

                                  // 1. Item Name / Description Field
                                  const Text(
                                    'Item Name / Description',
                                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.inkNavy),
                                  ),
                                  const SizedBox(height: 4),
                                  TextField(
                                    controller: item.nameController,
                                    decoration: InputDecoration(
                                      filled: true,
                                      fillColor: AppColors.surfaceWhite,
                                      isDense: true,
                                      hintText: 'e.g. Paracetamol 500mg',
                                      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(8),
                                        borderSide: const BorderSide(color: AppColors.borderSubtle),
                                      ),
                                      enabledBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(8),
                                        borderSide: const BorderSide(color: AppColors.borderSubtle),
                                      ),
                                    ),
                                    onChanged: (_) => setState(() {}),
                                  ),
                                  const SizedBox(height: 8),

                                  // 2. Quantity & Price Fields Row
                                  Row(
                                    children: [
                                      // Quantity
                                      Expanded(
                                        flex: 2,
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            const Text(
                                              'Quantity',
                                              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.inkNavy),
                                            ),
                                            const SizedBox(height: 4),
                                            TextField(
                                              controller: item.qtyController,
                                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                              decoration: InputDecoration(
                                                filled: true,
                                                fillColor: AppColors.surfaceWhite,
                                                isDense: true,
                                                prefixText: 'Qty ',
                                                prefixStyle: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                                                contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                                border: OutlineInputBorder(
                                                  borderRadius: BorderRadius.circular(8),
                                                  borderSide: const BorderSide(color: AppColors.borderSubtle),
                                                ),
                                                enabledBorder: OutlineInputBorder(
                                                  borderRadius: BorderRadius.circular(8),
                                                  borderSide: const BorderSide(color: AppColors.borderSubtle),
                                                ),
                                              ),
                                              onChanged: (_) => setState(() {}),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: 10),

                                      // Price / Rate
                                      Expanded(
                                        flex: 3,
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            const Text(
                                              'Price / Rate (₹)',
                                              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.inkNavy),
                                            ),
                                            const SizedBox(height: 4),
                                            TextField(
                                              controller: item.rateController,
                                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                              decoration: InputDecoration(
                                                filled: true,
                                                fillColor: AppColors.surfaceWhite,
                                                isDense: true,
                                                prefixText: '₹ ',
                                                prefixStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.inkNavy),
                                                contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                                border: OutlineInputBorder(
                                                  borderRadius: BorderRadius.circular(8),
                                                  borderSide: const BorderSide(color: AppColors.borderSubtle),
                                                ),
                                                enabledBorder: OutlineInputBorder(
                                                  borderRadius: BorderRadius.circular(8),
                                                  borderSide: const BorderSide(color: AppColors.borderSubtle),
                                                ),
                                              ),
                                              onChanged: (_) => setState(() {}),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),

                                  // Line Total Indicator
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      const Text(
                                        'Line Total:',
                                        style: TextStyle(fontSize: 11, color: AppColors.textMuted, fontWeight: FontWeight.w600),
                                      ),
                                      Text(
                                        currencyFormatter.format(item.total),
                                        style: const TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w800,
                                          color: AppColors.plumSlate,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            );
                          }),

                        const SizedBox(height: 6),

                        // "+ Add Item" Button
                        OutlinedButton.icon(
                          onPressed: _addNewItem,
                          icon: const Icon(Icons.add_rounded, size: 18),
                          label: const Text('Add Item Manually'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.plumSlate,
                            side: const BorderSide(color: AppColors.plumSlate),
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // 4. Financial Summary Card (Dynamically Recalculated)
                Card(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: const BorderSide(color: AppColors.borderSubtle),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        _buildSummaryRow('Subtotal', _calculatedSubtotal),
                        if (inv.cgst > 0) _buildSummaryRow('CGST', inv.cgst),
                        if (inv.sgst > 0) _buildSummaryRow('SGST', inv.sgst),
                        if (inv.igst > 0) _buildSummaryRow('IGST', inv.igst),
                        const Divider(color: AppColors.borderSubtle, height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Grand Total',
                              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
                            ),
                            Text(
                              currencyFormatter.format(_calculatedGrandTotal),
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w900,
                                color: AppColors.inkNavy,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),

      // Sticky Bottom Approval Action Bar
      // Lifted with 34px bottom clearance so it NEVER collides with the 20px popped-out center camera button
      bottomSheet: Container(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 34),
        decoration: BoxDecoration(
          color: AppColors.surfaceWhite,
          border: const Border(top: BorderSide(color: AppColors.borderSubtle)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 10,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: SafeArea(
          top: false,
          child: Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _handleApprove,
                  icon: const Icon(Icons.check_circle_rounded, size: 20),
                  label: const Text(
                    'Approve Voucher',
                    style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2E7D32), // Distinct Forest Green
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    elevation: 0,
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
          Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
          Text(
            currencyFormatter.format(amount),
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.inkNavy),
          ),
        ],
      ),
    );
  }
}
