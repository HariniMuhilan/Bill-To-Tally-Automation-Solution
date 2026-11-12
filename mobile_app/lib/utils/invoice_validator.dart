/// Utility to determine if extracted OCR text looks like a legitimate invoice, bill, or receipt.
class InvoiceValidator {
  static const Set<String> _strongKeywords = {
    'gstin',
    'invoice',
    'tax invoice',
    'bill of supply',
    'cgst',
    'sgst',
    'igst',
    'hsn',
    'hsn/sac',
    'sac code',
    'grand total',
    'subtotal',
    'sub total',
    'cash memo',
    'delivery challan',
    'taxable value',
    'taxable amount',
  };

  static const Set<String> _secondaryKeywords = {
    'total',
    'bill',
    'tax',
    'amount',
    'qty',
    'quantity',
    'rate',
    'date',
    'item',
    'particulars',
    'mrp',
    'balance',
    'rs.',
    'inr',
    '₹',
    'payable',
    'discount',
    'vendor',
    'supplier',
    'customer',
    'payment',
    'voucher',
    'charges',
    'round off',
  };

  /// Evaluates whether the OCR text contains sufficient density and billing keywords.
  /// Rejects photos of objects, people, landscapes, or random non-billing documents.
  static bool isLikelyInvoice(String? rawText) {
    if (rawText == null) return false;
    final cleaned = rawText.trim();
    if (cleaned.length < 20) return false;

    final lines = cleaned.split('\n').where((l) => l.trim().isNotEmpty).toList();
    if (lines.length < 3) return false;

    final lower = cleaned.toLowerCase();

    // 1. Match at least 1 strong invoice signal
    for (final kw in _strongKeywords) {
      if (lower.contains(kw)) {
        return true;
      }
    }

    // 2. Or match at least 2 secondary financial keywords
    int secondaryMatches = 0;
    for (final kw in _secondaryKeywords) {
      if (lower.contains(kw)) {
        secondaryMatches++;
        if (secondaryMatches >= 2) {
          return true;
        }
      }
    }

    return false;
  }
}
