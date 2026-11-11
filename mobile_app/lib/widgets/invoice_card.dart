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

  String _formatDate(String rawDate) {
    try {
      final parsed = DateTime.tryParse(rawDate);
      if (parsed != null) {
        return DateFormat('d MMM yyyy').format(parsed);
      }
    } catch (_) {}
    return rawDate;
  }

  @override
  Widget build(BuildContext context) {
    final currencyFormatter = NumberFormat.currency(locale: 'en_IN', symbol: '₹ ', decimalDigits: 2);
    final isNeedsReview = invoice.status == 'NEEDS_REVIEW' || invoice.status == 'NEEDS_CORRECTION';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderSubtle, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onReview,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Section: Thumbnail + Meta & Status
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Left Thumbnail Box
                    Container(
                      width: 48,
                      height: 48,
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
                                child: Icon(Icons.receipt_long_rounded, color: AppColors.softSage, size: 22),
                              ),
                            )
                          : const Center(
                              child: Icon(Icons.receipt_long_rounded, color: AppColors.softSage, size: 22),
                            ),
                    ),
                    const SizedBox(width: 10),

                    // Middle Info Block
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Tags Row: INV-ID, Confidence & Status Badge (Zero Overflow)
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Flexible(
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2.5),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFF3EBF0),
                                        borderRadius: BorderRadius.circular(5),
                                      ),
                                      child: Text(
                                        invoice.id,
                                        style: const TextStyle(
                                          color: AppColors.plumSlate,
                                          fontWeight: FontWeight.w800,
                                          fontSize: 10.5,
                                        ),
                                      ),
                                    ),
                                    if (invoice.confidence.isNotEmpty && invoice.confidence != '—') ...[
                                      const SizedBox(width: 4),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2.5),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFF0EFF2),
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        child: Text(
                                          invoice.confidence,
                                          style: const TextStyle(
                                            color: AppColors.textMuted,
                                            fontSize: 9.5,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                              const SizedBox(width: 6),
                              StatusBadge(status: invoice.status),
                            ],
                          ),
                          const SizedBox(height: 5),

                          // Supplier Name
                          Text(
                            invoice.supplierRaw,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              color: AppColors.inkNavy,
                              letterSpacing: -0.2,
                            ),
                          ),
                          const SizedBox(height: 3),

                          // Bill Metadata: Number and Date
                          Row(
                            children: [
                              const Icon(Icons.receipt_outlined, size: 12, color: AppColors.textMuted),
                              const SizedBox(width: 3),
                              Flexible(
                                child: Text(
                                  'Bill #${invoice.invoiceNo}',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 6),
                              const Text('•', style: TextStyle(color: AppColors.textMuted, fontSize: 11)),
                              const SizedBox(width: 6),
                              const Icon(Icons.calendar_today_outlined, size: 11, color: AppColors.textMuted),
                              const SizedBox(width: 3),
                              Text(
                                _formatDate(invoice.invoiceDate),
                                style: const TextStyle(
                                  fontSize: 11.5,
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

                // Divider
                const Divider(height: 1, color: AppColors.borderSubtle),
                const SizedBox(height: 10),

                // Bottom Row: Total Amount & Review Button with Arrow
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
                            fontSize: 9.5,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.6,
                            color: AppColors.textMuted,
                          ),
                        ),
                        const SizedBox(height: 1),
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

                    // Action Button matching reference mockup
                    ElevatedButton(
                      onPressed: onReview,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.plumSlate,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        elevation: 1,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.remove_red_eye_outlined, size: 15, color: Colors.white),
                          const SizedBox(width: 5),
                          Text(
                            isNeedsReview ? 'Review Now' : 'View Bill',
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 11.5,
                            ),
                          ),
                          const SizedBox(width: 3),
                          const Icon(Icons.chevron_right_rounded, size: 16, color: Colors.white70),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
