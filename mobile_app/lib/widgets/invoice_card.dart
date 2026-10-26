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
    final isNeedsReview = invoice.status == 'NEEDS_REVIEW' || invoice.status == 'NEEDS_CORRECTION';

    return Card(
      elevation: isNeedsReview ? 2 : 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(
          color: isNeedsReview ? AppColors.errorRed.withOpacity(0.4) : AppColors.borderSubtle,
          width: isNeedsReview ? 1.5 : 1,
        ),
      ),
      child: InkWell(
        onTap: onReview,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Row: Bill Tag, Confidence & Status Badge
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColors.blushIvory,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: AppColors.borderSubtle),
                        ),
                        child: Text(
                          invoice.id,
                          style: const TextStyle(
                            color: AppColors.plumSlate,
                            fontWeight: FontWeight.w800,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      if (invoice.confidence.isNotEmpty && invoice.confidence != '—') ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppColors.borderSubtle,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            invoice.confidence,
                            style: const TextStyle(
                              color: AppColors.textMuted,
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
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

              // Middle: Thumbnail and Supplier Info with Strong Hierarchy
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Document Thumbnail
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: AppColors.inkNavy,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.borderSubtle),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: invoice.imageUrl != null && invoice.imageUrl!.isNotEmpty
                        ? Image.network(
                            invoice.imageUrl!,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => const Center(
                              child: Icon(Icons.receipt_long, color: AppColors.softSage, size: 24),
                            ),
                          )
                        : const Center(
                            child: Icon(Icons.receipt_long, color: AppColors.softSage, size: 24),
                          ),
                  ),
                  const SizedBox(width: 12),

                  // Supplier & Bill details (unmapped supplier removed)
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          invoice.supplierRaw,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: AppColors.inkNavy,
                            letterSpacing: -0.2,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(Icons.receipt_outlined, size: 13, color: AppColors.textMuted),
                            const SizedBox(width: 4),
                            Text(
                              'Bill #${invoice.invoiceNo}',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Text('•', style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
                            const SizedBox(width: 8),
                            const Icon(Icons.calendar_today_outlined, size: 12, color: AppColors.textMuted),
                            const SizedBox(width: 4),
                            Text(
                              invoice.invoiceDate,
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.textMuted,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Bottom Row: Total Amount & High-Visibility Emergency Action Button
              const Divider(height: 1, color: AppColors.borderSubtle),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'TOTAL AMOUNT',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.6,
                          color: AppColors.textMuted,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        currencyFormatter.format(invoice.grandTotal),
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          color: AppColors.inkNavy,
                        ),
                      ),
                    ],
                  ),
                  if (isNeedsReview)
                    ElevatedButton.icon(
                      onPressed: onReview,
                      icon: const Icon(Icons.priority_high_rounded, size: 16),
                      label: const Text('REVIEW NOW'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.errorRed,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        elevation: 2,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        textStyle: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 12,
                          letterSpacing: 0.6,
                        ),
                      ),
                    )
                  else
                    OutlinedButton.icon(
                      onPressed: onReview,
                      icon: const Icon(Icons.check_circle_outline_rounded, size: 16, color: AppColors.plumSlate),
                      label: const Text('View Bill'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.plumSlate,
                        side: const BorderSide(color: AppColors.plumSlate, width: 1.2),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        textStyle: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                        ),
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
