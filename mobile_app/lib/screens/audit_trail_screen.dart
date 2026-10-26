import 'package:flutter/material.dart';
import '../services/storage_service.dart';
import '../theme/app_theme.dart';

class AuditTrailScreen extends StatelessWidget {
  final StorageService storage;

  const AuditTrailScreen({super.key, required this.storage});

  @override
  Widget build(BuildContext context) {
    final logs = storage.getAuditLogs();

    return Scaffold(
      backgroundColor: AppColors.blushIvory,
      body: logs.isEmpty
          ? const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.history_rounded, size: 48, color: AppColors.mutedMauve),
                  SizedBox(height: 12),
                  Text('No Audit Events Recorded', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: AppColors.inkNavy)),
                  SizedBox(height: 4),
                  Text('Voucher approvals and edits will appear here.', style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: logs.length,
              itemBuilder: (ctx, idx) {
                final log = logs[idx];
                return Card(
                  margin: const EdgeInsets.only(bottom: 10),
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppColors.mauveBg,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                log.action,
                                style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: AppColors.plumSlate),
                              ),
                            ),
                            Text(
                              log.time,
                              style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          log.summary,
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            const Icon(Icons.person_outline, size: 14, color: AppColors.textMuted),
                            const SizedBox(width: 4),
                            Text(
                              'Actor: ${log.actor}',
                              style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
