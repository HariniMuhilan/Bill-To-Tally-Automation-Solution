import 'package:flutter/material.dart';
import '../models/invoice.dart';
import '../models/draft_sheet.dart';
import '../theme/app_theme.dart';

enum ApproveExcelOption { newSheet, existingSheet }

class ApproveResult {
  final ApproveExcelOption option;
  final String? existingSheetId;
  final String? customFileName;

  ApproveResult({
    required this.option,
    this.existingSheetId,
    this.customFileName,
  });
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
  late TextEditingController _fileNameController;
  late String _defaultName;

  @override
  void initState() {
    super.initState();
    if (widget.existingDrafts.isNotEmpty) {
      _selectedSheetId = widget.existingDrafts.first.id;
    }

    final sanitizedSupplier = widget.invoice.supplierRaw
        .replaceAll(RegExp(r'[^a-zA-Z0-9]'), '_')
        .replaceAll(RegExp(r'_+'), '_');
    final ts = DateTime.now().millisecondsSinceEpoch.toString().substring(7);
    _defaultName = 'Tally_Draft_${sanitizedSupplier}_$ts';
    _fileNameController = TextEditingController(text: _defaultName);
  }

  @override
  void dispose() {
    _fileNameController.dispose();
    super.dispose();
  }

  void _onConfirm() {
    String finalName = _fileNameController.text.trim();
    if (finalName.isEmpty) {
      finalName = _defaultName;
    }
    if (!finalName.toLowerCase().endsWith('.xlsx')) {
      finalName = '$finalName.xlsx';
    }

    Navigator.pop(
      context,
      ApproveResult(
        option: _selectedOption,
        existingSheetId: _selectedSheetId,
        customFileName: finalName,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final hasExistingSheets = widget.existingDrafts.isNotEmpty;

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surfaceWhite,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        boxShadow: [
          BoxShadow(
            color: Color(0x334A1530),
            blurRadius: 30,
            offset: Offset(0, -6),
          ),
        ],
      ),
      padding: EdgeInsets.only(
        top: 14,
        left: 20,
        right: 20,
        bottom: bottomInset + 20,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Drag Handle
            Center(
              child: Container(
                width: 44,
                height: 4.5,
                decoration: BoxDecoration(
                  color: AppColors.borderSubtle,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),
            const SizedBox(height: 18),

            // Header Section
            Row(
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFE8F5E9), Color(0xFFC8E6C9)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFF81C784).withValues(alpha: 0.6)),
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.task_alt_rounded,
                      color: Color(0xFF1B5E20),
                      size: 26,
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Approve & Export Voucher',
                        style: AppTypography.fontL(
                          fontWeight: FontWeight.w800,
                          color: AppColors.brandInk,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Store in Tally Connector Excel Sheet',
                        style: AppTypography.fontS(
                          fontWeight: FontWeight.w500,
                          color: AppColors.mutedText,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Option 1: Create New Sheet Card
            InkWell(
              onTap: () {
                setState(() => _selectedOption = ApproveExcelOption.newSheet);
              },
              borderRadius: BorderRadius.circular(18),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _selectedOption == ApproveExcelOption.newSheet
                      ? const Color(0xFFFFF7F2)
                      : const Color(0xFFFAF7F9),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: _selectedOption == ApproveExcelOption.newSheet
                        ? AppColors.orange
                        : AppColors.borderSubtle,
                    width: _selectedOption == ApproveExcelOption.newSheet ? 2 : 1,
                  ),
                  boxShadow: _selectedOption == ApproveExcelOption.newSheet
                      ? [
                          BoxShadow(
                            color: AppColors.orange.withValues(alpha: 0.15),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ]
                      : [],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Card Top Header
                    Row(
                      children: [
                        Container(
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: _selectedOption == ApproveExcelOption.newSheet
                                  ? [AppColors.orangeStart, AppColors.orangeEnd]
                                  : [const Color(0xFFEFE9EE), const Color(0xFFE2D9E0)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(11),
                          ),
                          child: Icon(
                            Icons.post_add_rounded,
                            color: _selectedOption == ApproveExcelOption.newSheet
                                ? Colors.white
                                : AppColors.mutedText,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Create New Excel Sheet',
                                style: AppTypography.fontM(
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.brandInk,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Create a fresh workbook for this voucher',
                                style: AppTypography.fontS(
                                  fontWeight: FontWeight.w500,
                                  color: AppColors.mutedText,
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Selection Radio / Check Indicator
                        Container(
                          width: 22,
                          height: 22,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: _selectedOption == ApproveExcelOption.newSheet
                                ? AppColors.orange
                                : Colors.transparent,
                            border: Border.all(
                              color: _selectedOption == ApproveExcelOption.newSheet
                                  ? AppColors.orange
                                  : AppColors.mutedText.withValues(alpha: 0.4),
                              width: 2,
                            ),
                          ),
                          child: _selectedOption == ApproveExcelOption.newSheet
                              ? const Center(
                                  child: Icon(
                                    Icons.check,
                                    size: 14,
                                    color: Colors.white,
                                  ),
                                )
                              : null,
                        ),
                      ],
                    ),

                    // Editable Sheet Name Field (When Selected)
                    if (_selectedOption == ApproveExcelOption.newSheet) ...[
                      const SizedBox(height: 14),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: AppColors.orange.withValues(alpha: 0.45),
                            width: 1.2,
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.edit_note_rounded,
                              size: 20,
                              color: AppColors.orange,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: TextField(
                                controller: _fileNameController,
                                style: AppTypography.fontM(
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.brandInk,
                                ),
                                decoration: const InputDecoration(
                                  border: InputBorder.none,
                                  isDense: true,
                                  hintText: 'Enter sheet name',
                                  hintStyle: TextStyle(
                                    color: AppColors.mutedText,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFFF0E6),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Text(
                                '.xlsx',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.orange,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Tap the name above to edit your Excel sheet name.',
                        style: AppTypography.fontS(
                          fontWeight: FontWeight.w500,
                          color: AppColors.mutedText,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Option 2: Append to Existing Sheet Card
            InkWell(
              onTap: !hasExistingSheets
                  ? null
                  : () {
                      setState(() => _selectedOption = ApproveExcelOption.existingSheet);
                    },
              borderRadius: BorderRadius.circular(18),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _selectedOption == ApproveExcelOption.existingSheet
                      ? const Color(0xFFFFF7F2)
                      : hasExistingSheets
                          ? const Color(0xFFFAF7F9)
                          : const Color(0xFFF5F3F5),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: _selectedOption == ApproveExcelOption.existingSheet
                        ? AppColors.maroonMid
                        : AppColors.borderSubtle,
                    width: _selectedOption == ApproveExcelOption.existingSheet ? 2 : 1,
                  ),
                  boxShadow: _selectedOption == ApproveExcelOption.existingSheet
                      ? [
                          BoxShadow(
                            color: AppColors.maroonMid.withValues(alpha: 0.15),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ]
                      : [],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: _selectedOption == ApproveExcelOption.existingSheet
                                  ? [AppColors.maroonMid, AppColors.maroonDark]
                                  : [const Color(0xFFEFE9EE), const Color(0xFFE2D9E0)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(11),
                          ),
                          child: Icon(
                            Icons.layers_rounded,
                            color: _selectedOption == ApproveExcelOption.existingSheet
                                ? Colors.white
                                : AppColors.mutedText,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Append to Existing Sheet',
                                style: AppTypography.fontM(
                                  fontWeight: FontWeight.w800,
                                  color: hasExistingSheets
                                      ? AppColors.brandInk
                                      : AppColors.mutedText,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                hasExistingSheets
                                    ? 'Choose from ${widget.existingDrafts.length} existing draft sheets'
                                    : 'No existing draft sheets in Tally Connector yet',
                                style: AppTypography.fontS(
                                  fontWeight: FontWeight.w500,
                                  color: AppColors.mutedText,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          width: 22,
                          height: 22,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: _selectedOption == ApproveExcelOption.existingSheet
                                ? AppColors.maroonMid
                                : Colors.transparent,
                            border: Border.all(
                              color: _selectedOption == ApproveExcelOption.existingSheet
                                  ? AppColors.maroonMid
                                  : AppColors.mutedText.withValues(alpha: 0.4),
                              width: 2,
                            ),
                          ),
                          child: _selectedOption == ApproveExcelOption.existingSheet
                              ? const Center(
                                  child: Icon(
                                    Icons.check,
                                    size: 14,
                                    color: Colors.white,
                                  ),
                                )
                              : null,
                        ),
                      ],
                    ),

                    // Sheet Dropdown Selector (When Selected)
                    if (_selectedOption == ApproveExcelOption.existingSheet && hasExistingSheets) ...[
                      const SizedBox(height: 14),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: AppColors.maroonMid.withValues(alpha: 0.4),
                            width: 1.2,
                          ),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: _selectedSheetId,
                            isExpanded: true,
                            icon: const Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.maroonMid),
                            items: widget.existingDrafts.map((d) {
                              return DropdownMenuItem<String>(
                                value: d.id,
                                child: Row(
                                  children: [
                                    const Icon(
                                      Icons.table_chart_rounded,
                                      size: 16,
                                      color: AppColors.maroonMid,
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        d.fileName,
                                        overflow: TextOverflow.ellipsis,
                                        style: AppTypography.fontM(
                                          fontWeight: FontWeight.w700,
                                          color: AppColors.brandInk,
                                        ),
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFF3EBF0),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        '${d.invoices.length} bills',
                                        style: const TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w800,
                                          color: AppColors.plumSlate,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
                            onChanged: (val) => setState(() => _selectedSheetId = val),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Bottom Action Buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.brandInk,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      side: const BorderSide(color: AppColors.borderSubtle, width: 1.2),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    child: Text(
                      'Cancel',
                      style: AppTypography.fontM(
                        fontWeight: FontWeight.w700,
                        color: AppColors.mutedText,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [AppColors.orangeStart, AppColors.orangeEnd],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.orange.withValues(alpha: 0.35),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ElevatedButton.icon(
                      onPressed: _onConfirm,
                      icon: const Icon(Icons.check_rounded, size: 18, color: Colors.white),
                      label: Text(
                        'Confirm & Approve',
                        style: AppTypography.fontM(
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
