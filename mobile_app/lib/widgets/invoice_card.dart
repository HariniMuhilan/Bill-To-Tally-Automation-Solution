import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/invoice.dart';
import '../theme/app_theme.dart';
import 'status_badge.dart';

class InvoiceCard extends StatelessWidget {
  final Invoice invoice;
  final VoidCallback onReview;

  const InvoiceCard({
    super.key,
    required this.invoice,
    required this.onReview,
  });

  @override
  Widget build(BuildContext context) {
    final currencyFormatter = NumberFormat.currency(locale: 'en_IN', symbol: '₹ ', decimalDigits: 2);

    return Card(
      child: InkWell(
        onTap: onReview,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Row: ID, Confidence & Status Badge
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Text(
                        invoice.id,
                        style: const TextStyle(
                          color: AppColors.plumSlate,
                          fontWeight: FontWeight.w800,
                          fontSize: 13,
                        ),
                      ),
                      if (invoice.confidence.isNotEmpty && invoice.confidence != '—') ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.borderSubtle,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            invoice.confidence,
                            style: const TextStyle(
                              color: AppColors.textMuted,
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  StatusBadge(status: invoice.status),
                ],
              ),
              const SizedBox(height: 12),

              // Middle: Thumbnail and Supplier Info
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Document Thumbnail
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: AppColors.inkNavy,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.borderSubtle),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: invoice.imageUrl != null && invoice.imageUrl!.isNotEmpty
                        ? Image.network(
                            invoice.imageUrl!,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => const Center(
                              child: Icon(Icons.receipt_long, color: Colors.white70, size: 24),
                            ),
                          )
                        : const Center(
                            child: Icon(Icons.receipt_long, color: Colors.white70, size: 24),
                          ),
                  ),
                  const SizedBox(width: 12),

                  // Supplier & File details
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          invoice.supplierRaw,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Row(
                          children: [
                            Icon(
                              invoice.supplierMapped.isNotEmpty ? Icons.link : Icons.warning_amber_rounded,
                              size: 13,
                              color: invoice.supplierMapped.isNotEmpty ? AppColors.softSage : AppColors.mutedMauve,
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                invoice.supplierMapped.isNotEmpty ? invoice.supplierMapped : 'Unmapped Supplier',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: invoice.supplierMapped.isNotEmpty ? AppColors.plumSlate : AppColors.mutedMauve,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Inv #${invoice.invoiceNo} • ${invoice.invoiceDate}',
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Bottom Row: Total Amount & Review Action
              const Divider(height: 1, color: AppColors.borderSubtle),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Total Amount',
                        style: TextStyle(fontSize: 11, color: AppColors.textMuted),
                      ),
                      Text(
                        currencyFormatter.format(invoice.grandTotal),
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                  ElevatedButton.icon(
                    onPressed: onReview,
                    icon: const Icon(Icons.remove_red_eye_outlined, size: 16),
                    label: const Text('Review'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.plumSlate,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      minimumSize: Size.zero,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
