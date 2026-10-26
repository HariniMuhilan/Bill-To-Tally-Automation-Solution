import 'package:flutter/material.dart';
import '../models/invoice.dart';
import '../models/draft_sheet.dart';
import '../theme/app_theme.dart';

enum ApproveExcelOption { newSheet, existingSheet }

class ApproveResult {
  final ApproveExcelOption option;
  final String? existingSheetId;

  ApproveResult({required this.option, this.existingSheetId});
}

class ApproveDialog extends StatefulWidget {
  final Invoice invoice;
  final List<DraftSheet> existingDrafts;

  const ApproveDialog({
    super.key,
    required this.invoice,
    required this.existingDrafts,
  });

  static Future<ApproveResult?> show(
    BuildContext context, {
    required Invoice invoice,
    required List<DraftSheet> existingDrafts,
  }) {
    return showModalBottomSheet<ApproveResult>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => ApproveDialog(
        invoice: invoice,
        existingDrafts: existingDrafts,
      ),
    );
  }

  @override
  State<ApproveDialog> createState() => _ApproveDialogState();
}

class _ApproveDialogState extends State<ApproveDialog> {
  ApproveExcelOption _selectedOption = ApproveExcelOption.newSheet;
  String? _selectedSheetId;

  @override
  void initState() {
    super.initState();
    if (widget.existingDrafts.isNotEmpty) {
      _selectedSheetId = widget.existingDrafts.first.id;
    }
  }

  @override
  Widget build(BuildContext context) {
    final sanitizedSupplier = widget.invoice.supplierRaw.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '_');
    final suggestedFileName = 'Tally_Draft_${sanitizedSupplier}_${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}.xlsx';

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surfaceWhite,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        top: 20,
        left: 20,
        right: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag Handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.borderSubtle,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Title & Description
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.softSage.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check_circle_outline, color: Color(0xFF2E7D32), size: 24),
              ),
              const SizedBox(width: 14),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Approve Voucher',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      'Store in Tally Connector Excel Sheet',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Option 1: Create New Sheet
          InkWell(
            onTap: () {
              setState(() => _selectedOption = ApproveExcelOption.newSheet);
            },
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: _selectedOption == ApproveExcelOption.newSheet
                    ? AppColors.blushIvory
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _selectedOption == ApproveExcelOption.newSheet
                      ? AppColors.plumSlate
                      : AppColors.borderSubtle,
                  width: 1.5,
                ),
              ),
              child: Row(
                children: [
                  Radio<ApproveExcelOption>(
                    value: ApproveExcelOption.newSheet,
                    groupValue: _selectedOption,
                    activeColor: AppColors.plumSlate,
                    onChanged: (val) => setState(() => _selectedOption = val!),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Create New Excel Sheet',
                          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: AppColors.inkNavy),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          suggestedFileName,
                          style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Option 2: Append to Existing Sheet
          InkWell(
            onTap: widget.existingDrafts.isEmpty
                ? null
                : () {
                    setState(() => _selectedOption = ApproveExcelOption.existingSheet);
                  },
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: _selectedOption == ApproveExcelOption.existingSheet
                    ? AppColors.blushIvory
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _selectedOption == ApproveExcelOption.existingSheet
                      ? AppColors.plumSlate
                      : AppColors.borderSubtle,
                  width: 1.5,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Radio<ApproveExcelOption>(
                        value: ApproveExcelOption.existingSheet,
                        groupValue: _selectedOption,
                        activeColor: AppColors.plumSlate,
                        onChanged: widget.existingDrafts.isEmpty
                            ? null
                            : (val) => setState(() => _selectedOption = val!),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Append to Existing Excel Sheet',
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 14,
                                color: widget.existingDrafts.isEmpty ? AppColors.textMuted : AppColors.textPrimary,
                              ),
                            ),
                            Text(
                              widget.existingDrafts.isEmpty
                                  ? 'No existing draft sheets in Tally Connector'
                                  : 'Select one of ${widget.existingDrafts.length} existing sheets',
                              style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  if (_selectedOption == ApproveExcelOption.existingSheet && widget.existingDrafts.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceWhite,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppColors.borderSubtle),
                      ),
                      child: DropdownButton<String>(
                        value: _selectedSheetId,
                        isExpanded: true,
                        underline: const SizedBox(),
                        items: widget.existingDrafts.map((d) {
                          return DropdownMenuItem<String>(
                            value: d.id,
                            child: Text(
                              '${d.fileName} (${d.invoices.length} bills)',
                              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                            ),
                          );
                        }).toList(),
                        onChanged: (val) => setState(() => _selectedSheetId = val),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Actions
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.plumSlate,
                    side: const BorderSide(color: AppColors.borderSubtle),
                  ),
                  child: const Text('Cancel'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(
                      context,
                      ApproveResult(
                        option: _selectedOption,
                        existingSheetId: _selectedSheetId,
                      ),
                    );
                  },
                  icon: const Icon(Icons.check, size: 18),
                  label: const Text('Confirm & Approve'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.plumSlate,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
