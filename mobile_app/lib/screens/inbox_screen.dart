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
  State<InboxScreen> createState() => _InboxScreenState();
}

class _InboxScreenState extends State<InboxScreen> {
  String _activeFilter = 'ALL';
  bool _isUploading = false;
  String _uploadStatusText = '';

  Future<void> _handleCaptureCamera() async {
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
        allowedExtensions: ['jpg', 'jpeg', 'png', 'pdf', 'webp'],
        withData: true,
      );

      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;
        if (file.bytes != null) {
          await _processBillUpload(file.bytes!, file.name, null);
        }
      }
    } catch (e) {
      _showSnackbar('File picker error: $e', isError: true);
    }
  }

  Future<void> _processBillUpload(Uint8List bytes, String filename, String? mimeType) async {
    setState(() {
      _isUploading = true;
      _uploadStatusText = 'Uploading & Extracting with PaddleOCR + Gemini...';
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

      _showSnackbar('Extracted ${newInvoice.id}: ${newInvoice.supplierRaw}');
      widget.onSelectInvoice(newInvoice);
    } else {
      _showSnackbar(res.error ?? 'Upload failed. Check backend connection.', isError: true);
    }
  }

  void _showSnackbar(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: isError ? AppColors.errorRed : AppColors.successGreen,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  List<Invoice> get _filteredInvoices {
    if (_activeFilter == 'NEEDS_REVIEW') {
      return widget.invoices.where((i) => i.status == 'NEEDS_REVIEW' || i.status == 'NEEDS_CORRECTION').toList();
    } else if (_activeFilter == 'APPROVED') {
      return widget.invoices.where((i) => i.status == 'APPROVED').toList();
    } else if (_activeFilter == 'POSTED') {
      return widget.invoices.where((i) => i.status == 'POSTED').toList();
    }
    return widget.invoices;
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredInvoices;

    return Stack(
      children: [
        Scaffold(
          backgroundColor: AppColors.blushIvory,
          body: RefreshIndicator(
            onRefresh: () async {
              setState(() {});
            },
            child: ListView(
              padding: const EdgeInsets.only(bottom: 24),
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
                          child: const Icon(Icons.crop_free_rounded, color: Colors.white70, size: 22),
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
                        'Direct camera capture or PDF document upload',
                        style: TextStyle(color: Colors.white70, fontSize: 11),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: _isUploading ? null : _handleCaptureCamera,
                              icon: const Icon(Icons.camera_alt_rounded, size: 18),
                              label: const Text('Scan Bill'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.accentOrange,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: _isUploading ? null : _handlePickFile,
                              icon: const Icon(Icons.upload_file_rounded, size: 18, color: Colors.white),
                              label: const Text('Upload File', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
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

                // Horizontal Filter Chips
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    children: [
                      _buildFilterChip('ALL', 'All Invoices (${widget.invoices.length})'),
                      const SizedBox(width: 8),
                      _buildFilterChip(
                        'NEEDS_REVIEW',
                        'Needs Review (${widget.invoices.where((i) => i.status == 'NEEDS_REVIEW').length})',
                      ),
                      const SizedBox(width: 8),
                      _buildFilterChip(
                        'APPROVED',
                        'Approved (${widget.invoices.where((i) => i.status == 'APPROVED').length})',
                      ),
                      const SizedBox(width: 8),
                      _buildFilterChip(
                        'POSTED',
                        'Posted (${widget.invoices.where((i) => i.status == 'POSTED').length})',
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
                            'Tap "Scan Bill" or "Upload File" above to process your first invoice.',
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

        // Uploading Loading Overlay
        if (_isUploading)
          Container(
            color: Colors.black.withOpacity(0.6),
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                decoration: BoxDecoration(
                  color: AppColors.surfaceWhite,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const CircularProgressIndicator(color: AppColors.accentOrange),
                    const SizedBox(height: 16),
                    Text(
                      _uploadStatusText,
                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildFilterChip(String value, String label) {
    final isSelected = _activeFilter == value;
    return ChoiceChip(
      avatar: isSelected ? const Icon(Icons.check, size: 14, color: Colors.white) : null,
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        if (selected) setState(() => _activeFilter = value);
      },
      selectedColor: AppColors.plumSlate,
      backgroundColor: AppColors.surfaceWhite,
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : AppColors.textPrimary,
        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
        fontSize: 12,
      ),
      side: BorderSide(
        color: isSelected ? AppColors.plumSlate : AppColors.borderSubtle,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    );
  }
}
