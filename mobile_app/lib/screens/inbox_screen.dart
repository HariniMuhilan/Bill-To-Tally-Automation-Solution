import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../models/invoice.dart';
import '../services/api_service.dart';
import '../services/storage_service.dart';
import '../theme/app_theme.dart';
import '../widgets/invoice_card.dart';

class InboxScreen extends StatefulWidget {
  final StorageService storage;
  final ApiService api;
  final List<Invoice> invoices;
  final ValueChanged<List<Invoice>> onInvoicesChanged;
  final ValueChanged<Invoice> onSelectInvoice;

  const InboxScreen({
    super.key,
    required this.storage,
    required this.api,
    required this.invoices,
    required this.onInvoicesChanged,
    required this.onSelectInvoice,
  });

  @override
  State<InboxScreen> createState() => InboxScreenState();
}

class InboxScreenState extends State<InboxScreen> {
  String _activeFilter = 'ALL';
  bool _isUploading = false;
  String _uploadStatusText = '';

  Future<void> handleCaptureCamera() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['jpg', 'jpeg', 'png', 'webp'],
        withData: true,
      );
      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;
        if (file.bytes != null) {
          await _processBillUpload(file.bytes!, file.name, 'image/jpeg');
        }
      }
    } catch (e) {
      _showSnackbar('Image picker error: $e', isError: true);
    }
  }

  Future<void> _handlePickFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['jpg', 'jpeg', 'png', 'webp'],
        withData: true,
      );

      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;
        if (file.bytes != null) {
          await _processBillUpload(file.bytes!, file.name, 'image/jpeg');
        }
      }
    } catch (e) {
      _showSnackbar('Photo picker error: $e', isError: true);
    }
  }

  Future<void> _processBillUpload(Uint8List bytes, String filename, String? mimeType) async {
    setState(() {
      _isUploading = true;
      _uploadStatusText = 'Reading bill details...';
    });

    final res = await widget.api.uploadInvoiceBytes(
      bytes: bytes,
      filename: filename,
      mimeType: mimeType,
    );

    setState(() => _isUploading = false);

    if (res.success && res.data != null) {
      final newInvoice = res.data!;
      final updatedList = [newInvoice, ...widget.invoices];
      widget.onInvoicesChanged(updatedList);
      widget.storage.saveInvoices(updatedList);

      _showSnackbar('Scanned ${newInvoice.id}: ${newInvoice.supplierRaw}');
      widget.onSelectInvoice(newInvoice);
    } else {
      _showSnackbar(res.error ?? 'Upload failed. Check backend connection.', isError: true);
    }
  }

  void _showSnackbar(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: isError ? AppColors.errorRed : AppColors.softSage,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  List<Invoice> get _filteredInvoices {
    if (_activeFilter == 'NEEDS_REVIEW') {
      return widget.invoices.where((i) => i.status == 'NEEDS_REVIEW' || i.status == 'NEEDS_CORRECTION').toList();
    } else if (_activeFilter == 'APPROVED') {
      return widget.invoices.where((i) => i.status == 'APPROVED' || i.status == 'POSTED').toList();
    }
    return widget.invoices;
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredInvoices;
    final needsReviewCount = widget.invoices.where((i) => i.status == 'NEEDS_REVIEW' || i.status == 'NEEDS_CORRECTION').length;
    final approvedCount = widget.invoices.where((i) => i.status == 'APPROVED' || i.status == 'POSTED').length;

    return Stack(
      children: [
        Scaffold(
          backgroundColor: AppColors.blushIvory,
          body: RefreshIndicator(
            onRefresh: () async {
              setState(() {});
            },
            child: ListView(
              padding: const EdgeInsets.only(bottom: 32),
              children: [
                // Top Upload / Camera Action Banner with Plum Slate to Forest Charcoal Gradient
                Container(
                  margin: const EdgeInsets.fromLTRB(16, 14, 16, 8),
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppColors.plumSlate, AppColors.forestCharcoal],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.plumSlate.withOpacity(0.25),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Center(
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.crop_free_rounded, color: AppColors.softSage, size: 22),
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Fast Invoice Scanner',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Take a photo of your bill or pick from gallery',
                        style: TextStyle(color: Colors.white70, fontSize: 11),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: _isUploading ? null : handleCaptureCamera,
                              icon: const Icon(Icons.camera_alt_rounded, size: 18),
                              label: const Text('Take Photo'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.softSage,
                                foregroundColor: AppColors.inkNavy,
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                textStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: _isUploading ? null : _handlePickFile,
                              icon: const Icon(Icons.photo_library_rounded, size: 18, color: Colors.white),
                              label: const Text('Upload Photo', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
                              style: OutlinedButton.styleFrom(
                                backgroundColor: Colors.white.withOpacity(0.08),
                                side: BorderSide(color: Colors.white.withOpacity(0.25)),
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Symmetric Filter Tabs with equal margin on both sides
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: _buildFilterTab(
                          value: 'ALL',
                          label: 'All Bills',
                          count: widget.invoices.length,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildFilterTab(
                          value: 'NEEDS_REVIEW',
                          label: 'Needs Review',
                          count: needsReviewCount,
                          isUrgent: true,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildFilterTab(
                          value: 'APPROVED',
                          label: 'Approved',
                          count: approvedCount,
                        ),
                      ),
                    ],
                  ),
                ),

                // Invoices List or Empty State
                if (filtered.isEmpty) ...[
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 50, horizontal: 24),
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(22),
                            decoration: const BoxDecoration(
                              color: AppColors.mauveBg,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.inbox_outlined, size: 48, color: AppColors.mutedMauve),
                          ),
                          const SizedBox(height: 18),
                          const Text(
                            'No Invoices Found',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 6),
                          const Text(
                            'Tap "Take Photo" or "Upload Photo" above to process your first invoice.',
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 12, color: AppColors.textMuted),
                          ),
                        ],
                      ),
                    ),
                  ),
                ] else ...[
                  ...filtered.map((inv) {
                    return InvoiceCard(
                      invoice: inv,
                      onReview: () => widget.onSelectInvoice(inv),
                    );
                  }),
                ],
              ],
            ),
          ),
        ),

        // Simple, Jargon-Free Loading Overlay
        if (_isUploading)
          Container(
            color: Colors.black.withOpacity(0.55),
            child: Center(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 32),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
                decoration: BoxDecoration(
                  color: AppColors.surfaceWhite,
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.15),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(
                      width: 44,
                      height: 44,
                      child: CircularProgressIndicator(
                        color: AppColors.plumSlate,
                        strokeWidth: 3.5,
                      ),
                    ),
                    const SizedBox(height: 18),
                    Text(
                      _uploadStatusText,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                        color: AppColors.inkNavy,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Please wait while we read the bill details.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 12, color: AppColors.textMuted),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildFilterTab({
    required String value,
    required String label,
    required int count,
    bool isUrgent = false,
  }) {
    final isSelected = _activeFilter == value;
    return InkWell(
      onTap: () => setState(() => _activeFilter = value),
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 4),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.plumSlate : AppColors.surfaceWhite,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected
                ? AppColors.plumSlate
                : (isUrgent && count > 0 ? AppColors.errorRed.withOpacity(0.4) : AppColors.borderSubtle),
            width: isUrgent && count > 0 && !isSelected ? 1.2 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.plumSlate.withOpacity(0.2),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '$count',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w900,
                color: isSelected
                    ? Colors.white
                    : (isUrgent && count > 0 ? AppColors.errorRed : AppColors.inkNavy),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                color: isSelected ? Colors.white70 : AppColors.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
