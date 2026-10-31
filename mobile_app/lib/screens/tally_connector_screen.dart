import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/draft_sheet.dart';
import '../services/api_service.dart';
import '../services/storage_service.dart';
import '../services/excel_service.dart';
import '../theme/app_theme.dart';

class TallyConnectorScreen extends StatefulWidget {
  final StorageService storage;
  final ApiService api;
  final List<DraftSheet> draftSheets;
  final ValueChanged<List<DraftSheet>> onDraftSheetsChanged;

  const TallyConnectorScreen({
    super.key,
    required this.storage,
    required this.api,
    required this.draftSheets,
    required this.onDraftSheetsChanged,
  });

  @override
  State<TallyConnectorScreen> createState() => _TallyConnectorScreenState();
}

class _TallyConnectorScreenState extends State<TallyConnectorScreen> {
  final currencyFormatter = NumberFormat.currency(locale: 'en_IN', symbol: '₹ ', decimalDigits: 2);

  Future<void> _handleDownloadDraftSheet(DraftSheet sheet) async {
    final path = await ExcelService.saveAndOpenExcel(
      fileName: sheet.fileName,
      invoices: sheet.invoices,
    );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(path != null ? 'Excel saved & opened: ${sheet.fileName}' : 'Generating Excel: ${sheet.fileName}'),
          backgroundColor: AppColors.successGreen,
        ),
      );
    }
  }

  Future<void> _handleDownloadAllDrafts() async {
    if (widget.draftSheets.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No draft Excel sheets to download.')),
      );
      return;
    }

    final allInvoices = widget.draftSheets.expand((d) => d.invoices).toList();
    final fileName = 'Tally_Master_Drafts_${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}.xlsx';
    await ExcelService.saveAndOpenExcel(
      fileName: fileName,
      invoices: allInvoices,
    );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Master workbook exported with ${allInvoices.length} vouchers!'),
          backgroundColor: AppColors.successGreen,
        ),
      );
    }
  }

  void _handleDeleteSheet(String id) {
    final updated = widget.draftSheets.where((d) => d.id != id).toList();
    widget.onDraftSheetsChanged(updated);
    widget.storage.saveDraftSheets(updated);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Draft Excel sheet removed.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.blushIvory,
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Draft Excel Sheets Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Draft Excel Sheets',
                      style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: AppColors.inkNavy),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${widget.draftSheets.length} workbook(s) available for download',
                      style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              if (widget.draftSheets.isNotEmpty)
                ElevatedButton.icon(
                  onPressed: _handleDownloadAllDrafts,
                  icon: const Icon(Icons.download, size: 15),
                  label: const Text('Download All', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.plumSlate,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    elevation: 0,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),

          // 3. Draft Sheets List
          if (widget.draftSheets.isEmpty)
            Card(
              margin: EdgeInsets.zero,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
                child: Center(
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: AppColors.mauveBg,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Icon(Icons.table_view_rounded, size: 38, color: AppColors.mutedMauve),
                      ),
                      const SizedBox(height: 14),
                      const Text(
                        'No Draft Excel Sheets Yet',
                        style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: AppColors.inkNavy),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Approve an invoice in the Review tab to\nstore it in an Excel sheet.',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 12, color: AppColors.textMuted),
                      ),
                    ],
                  ),
                ),
              ),
            )
          else
            ...widget.draftSheets.map((draft) {
              return Card(
                margin: const EdgeInsets.only(bottom: 10),
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppColors.successBg,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(Icons.table_chart_rounded, color: AppColors.softSage, size: 20),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  draft.fileName,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: AppColors.inkNavy),
                                ),
                                Text(
                                  '${draft.invoices.length} Voucher(s) • Created ${draft.createdAt.split('T')[0]}',
                                  style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Total Value', style: TextStyle(fontSize: 10, color: AppColors.textMuted)),
                              Text(
                                currencyFormatter.format(draft.totalAmount),
                                style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: AppColors.inkNavy),
                              ),
                            ],
                          ),
                          Row(
                            children: [
                              IconButton(
                                icon: const Icon(Icons.delete_outline, color: AppColors.errorRed, size: 20),
                                onPressed: () => _handleDeleteSheet(draft.id),
                                tooltip: 'Delete sheet',
                              ),
                              ElevatedButton.icon(
                                onPressed: () => _handleDownloadDraftSheet(draft),
                                icon: const Icon(Icons.download_rounded, size: 15),
                                label: const Text('Download'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.plumSlate,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            }),
        ],
      ),
    );
  }
}
