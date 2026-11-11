import 'dart:io' show File;
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import '../models/invoice.dart';
import '../services/api_service.dart';
import '../services/storage_service.dart';
import '../services/mlkit_service.dart';
import '../theme/app_theme.dart';
import '../widgets/liquid_glass.dart';
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
      final picker = ImagePicker();
      final photo = await picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 2048,
        maxHeight: 2048,
        imageQuality: 90,
      );
      if (photo != null) {
        final bytes = await photo.readAsBytes();
        await _processBillUpload(bytes, photo.name, 'image/jpeg', localPath: photo.path);
      }
    } catch (e) {
      _showSnackbar('Camera error: $e', isError: true);
    }
  }

  Future<void> _handlePickFile() async {
    try {
      final picker = ImagePicker();
      final photo = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 2048,
        maxHeight: 2048,
        imageQuality: 90,
      );
      if (photo != null) {
        final bytes = await photo.readAsBytes();
        await _processBillUpload(bytes, photo.name, 'image/jpeg', localPath: photo.path);
      }
    } catch (e) {
      // Fallback to FilePicker if gallery picker encounters an issue
      try {
        final result = await FilePicker.platform.pickFiles(
          type: FileType.custom,
          allowedExtensions: ['jpg', 'jpeg', 'png', 'webp'],
          withData: true,
        );
        if (result != null && result.files.isNotEmpty) {
          final file = result.files.first;
          Uint8List? bytes = file.bytes;
          if (bytes == null && file.path != null) {
            bytes = await File(file.path!).readAsBytes();
          }
          if (bytes != null) {
            await _processBillUpload(bytes, file.name, 'image/jpeg', localPath: file.path);
          }
        }
      } catch (err) {
        _showSnackbar('Gallery error: $err', isError: true);
      }
    }
  }

  Future<void> _processBillUpload(
    Uint8List bytes,
    String filename,
    String? mimeType, {
    String? localPath,
  }) async {
    setState(() {
      _isUploading = true;
      _uploadStatusText = 'Reading bill details...';
    });

    ApiResult<Invoice>? res;

    // 1. Primary: If running on device and local file is available, run Google ML Kit locally
    if (MLKitService.isSupported && localPath != null && localPath.isNotEmpty) {
      try {
        setState(() {
          _uploadStatusText = 'Scanning bill with Google ML Kit (on-device)...';
        });

        final ocrResult = await MLKitService.recognizeTextFromFile(localPath);

        setState(() {
          _uploadStatusText = 'Structuring voucher with AI...';
        });

        res = await widget.api.extractFromRawOcr(
          ocrResult: ocrResult,
          filename: filename,
          localPath: localPath,
        );
      } catch (e) {
        // Fallback to backend OCR if ML Kit fails
        res = null;
      }
    }

    // 2. Fallback: Backend OCR endpoint
    if (res == null || !res.success) {
      setState(() {
        _uploadStatusText = 'Uploading bill to backend...';
      });

      res = await widget.api.uploadInvoiceBytes(
        bytes: bytes,
        filename: filename,
        mimeType: mimeType,
      );
    }

    setState(() => _isUploading = false);

    if (res.success && res.data != null) {
      final newInvoice = res.data!;
      // Ensure localPath is attached if available
      if (localPath != null && (newInvoice.localPath == null || newInvoice.localPath!.isEmpty)) {
        newInvoice.localPath = localPath;
      }
      final updatedList = [newInvoice, ...widget.invoices];
      widget.onInvoicesChanged(updatedList);
      widget.storage.saveInvoices(updatedList);

      _showSnackbar('Scanned ${newInvoice.id}: ${newInvoice.supplierRaw}');
      widget.onSelectInvoice(newInvoice);
    } else {
      _showSnackbar(res.error ?? 'Processing failed. Check backend connection.', isError: true);
    }
  }

  void _showSnackbar(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          msg,
          style: AppTypography.fontM(color: Colors.white),
        ),
        backgroundColor: isError ? AppColors.errorRed : AppColors.successGreen,
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
    final allCount = widget.invoices.length;
    final needsReviewCount = widget.invoices.where((i) => i.status == 'NEEDS_REVIEW' || i.status == 'NEEDS_CORRECTION').length;
    final approvedCount = widget.invoices.where((i) => i.status == 'APPROVED' || i.status == 'POSTED').length;

    return Stack(
      children: [
        RefreshIndicator(
          onRefresh: () async {
            setState(() {});
          },
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 6, 16, 110),
            children: [
              // 1. "Fast Invoice Scanner" Card (Radius 28px, Dark Maroon Glass)
              LiquidGlass(
                isDarkMaroon: true,
                borderRadius: 28,
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Top row: Scan icon, Title + Subtitle, Document outline icon
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Rounded-square scan icon on the left
                        Container(
                          width: 46,
                          height: 46,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.22),
                              width: 1,
                            ),
                          ),
                          child: const Center(
                            child: Icon(
                              Icons.crop_free_rounded,
                              color: Colors.white,
                              size: 22,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        // Title + Subtitle in DM Sans
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Fast Invoice Scanner',
                                style: AppTypography.fontL(
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                'Capture a bill or choose a file to begin',
                                style: AppTypography.fontS(
                                  fontWeight: FontWeight.w500,
                                  color: Colors.white.withValues(alpha: 0.85),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        // Sleek frosted receipt/bill badge top right
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.22),
                              width: 1,
                            ),
                          ),
                          child: const Center(
                            child: Icon(
                              Icons.receipt_long_rounded,
                              color: Colors.white,
                              size: 22,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Two pill buttons across the bottom
                    Row(
                      children: [
                        // Orange "Take Photo" button
                        Expanded(
                          child: LiquidGlass(
                            isOrangeGloss: true,
                            borderRadius: 22,
                            height: 44,
                            onTap: _isUploading ? null : handleCaptureCamera,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(
                                  Icons.camera_alt_outlined,
                                  color: Colors.white,
                                  size: 17,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Take Photo',
                                  style: AppTypography.fontM(
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        // Frosted "Upload Photo" button
                        Expanded(
                          child: LiquidGlass(
                            isDarkMaroon: false,
                            borderRadius: 22,
                            height: 44,
                            onTap: _isUploading ? null : _handlePickFile,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.upload_rounded,
                                  color: Colors.white.withValues(alpha: 0.95),
                                  size: 17,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Upload Photo',
                                  style: AppTypography.fontM(
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white.withValues(alpha: 0.95),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // 2. Three Equal Stat Tiles in a Row (Radius ~22px)
              Row(
                children: [
                  // All Bills (Maroon, white text - active state)
                  Expanded(
                    child: LiquidGlass(
                      isDarkMaroon: _activeFilter == 'ALL',
                      borderRadius: 22,
                      height: 74,
                      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                      onTap: () => setState(() => _activeFilter = 'ALL'),
                      child: SizedBox(
                        width: double.infinity,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Text(
                              '$allCount',
                              textAlign: TextAlign.center,
                              style: AppTypography.fontNumber(
                                fontWeight: FontWeight.w800,
                                color: _activeFilter == 'ALL' ? Colors.white : AppColors.brandInk,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'All Bills',
                              textAlign: TextAlign.center,
                              style: AppTypography.fontS(
                                fontWeight: FontWeight.w600,
                                color: _activeFilter == 'ALL'
                                    ? Colors.white.withValues(alpha: 0.9)
                                    : AppColors.mutedText,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),

                  // Needs Review (Glass, orange number)
                  Expanded(
                    child: LiquidGlass(
                      isDarkMaroon: _activeFilter == 'NEEDS_REVIEW',
                      borderRadius: 22,
                      height: 74,
                      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                      onTap: () => setState(() => _activeFilter = 'NEEDS_REVIEW'),
                      child: SizedBox(
                        width: double.infinity,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Text(
                              '$needsReviewCount',
                              textAlign: TextAlign.center,
                              style: AppTypography.fontNumber(
                                fontWeight: FontWeight.w800,
                                color: _activeFilter == 'NEEDS_REVIEW' ? Colors.white : AppColors.orange,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Needs Review',
                              textAlign: TextAlign.center,
                              style: AppTypography.fontS(
                                fontWeight: FontWeight.w600,
                                color: _activeFilter == 'NEEDS_REVIEW'
                                    ? Colors.white.withValues(alpha: 0.9)
                                    : AppColors.mutedText,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),

                  // Approved (Glass, green number)
                  Expanded(
                    child: LiquidGlass(
                      isDarkMaroon: _activeFilter == 'APPROVED',
                      borderRadius: 22,
                      height: 74,
                      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                      onTap: () => setState(() => _activeFilter = 'APPROVED'),
                      child: SizedBox(
                        width: double.infinity,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Text(
                              '$approvedCount',
                              textAlign: TextAlign.center,
                              style: AppTypography.fontNumber(
                                fontWeight: FontWeight.w800,
                                color: _activeFilter == 'APPROVED' ? Colors.white : AppColors.successGreen,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Approved',
                              textAlign: TextAlign.center,
                              style: AppTypography.fontS(
                                fontWeight: FontWeight.w600,
                                color: _activeFilter == 'APPROVED'
                                    ? Colors.white.withValues(alpha: 0.9)
                                    : AppColors.mutedText,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // 3. Invoices List or Liquid Empty State Bubble
              if (filtered.isEmpty) ...[
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Centered frosted glass circle (~97px) with maroon receipt icon
                        LiquidGlass(
                          borderRadius: 50,
                          width: 96,
                          height: 96,
                          child: Center(
                            child: Icon(
                              Icons.receipt_long_rounded,
                              size: 40,
                              color: AppColors.maroonDark.withValues(alpha: 0.85),
                            ),
                          ),
                        ),
                        const SizedBox(height: 18),
                        // Title in DM Sans
                        Text(
                          'No Invoices Found',
                          style: AppTypography.fontL(
                            fontWeight: FontWeight.w700,
                            color: AppColors.brandInk,
                          ),
                        ),
                        const SizedBox(height: 8),
                        // Subtext in DM Sans
                        ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 280),
                          child: Text(
                            'Tap "Take Photo" or "Upload Photo" above to process your first invoice.',
                            textAlign: TextAlign.center,
                            style: AppTypography.fontS(
                              fontWeight: FontWeight.w500,
                              color: AppColors.mutedText,
                            ).copyWith(height: 1.4),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ] else ...[
                // Real invoice items
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

        // Simple Loading Overlay (Previous design - clean white card, not purple)
        if (_isUploading)
          Container(
            color: Colors.black.withValues(alpha: 0.55),
            child: Center(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 32),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
                decoration: BoxDecoration(
                  color: AppColors.surfaceWhite,
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.15),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(AppColors.plumSlate),
                      strokeWidth: 3,
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
}
