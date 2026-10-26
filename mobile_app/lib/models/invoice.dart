double toDoubleSafe(dynamic value, [double defaultValue = 0.0]) {
  if (value == null) return defaultValue;
  if (value is num) return value.toDouble();
  if (value is String) {
    final cleaned = value.replaceAll(RegExp(r'[^0-9.-]'), '');
    return double.tryParse(cleaned) ?? defaultValue;
  }
  return defaultValue;
}

class LineItem {
  final int lineNo;
  String descRaw;
  String hsn;
  String stockItem;
  double qty;
  String unit;
  double rate;
  double taxable;
  double taxRate;
  double taxAmount;
  double total;
  double confidence;

  LineItem({
    required this.lineNo,
    required this.descRaw,
    this.hsn = '',
    this.stockItem = '',
    this.qty = 1.0,
    this.unit = 'NOS',
    this.rate = 0.0,
    this.taxable = 0.0,
    this.taxRate = 0.0,
    this.taxAmount = 0.0,
    this.total = 0.0,
    this.confidence = 95.0,
  });

  factory LineItem.fromJson(Map<String, dynamic> json) {
    return LineItem(
      lineNo: json['lineNo'] is int ? json['lineNo'] : int.tryParse(json['lineNo']?.toString() ?? '1') ?? 1,
      descRaw: json['descRaw'] ?? json['item_description'] ?? 'Item',
      hsn: json['hsn'] ?? json['hsn_sac_code'] ?? '',
      stockItem: json['stockItem'] ?? json['tally_item_name'] ?? '',
      qty: toDoubleSafe(json['qty'] ?? json['quantity'], 1.0),
      unit: json['unit'] ?? json['unit_of_measure'] ?? 'NOS',
      rate: toDoubleSafe(json['rate'] ?? json['unit_price'], 0.0),
      taxable: toDoubleSafe(json['taxable'] ?? json['taxable_amount'], 0.0),
      taxRate: toDoubleSafe(json['taxRate'] ?? json['gst_rate_percent'], 0.0),
      taxAmount: toDoubleSafe(json['taxAmount'] ?? (toDoubleSafe(json['cgst_amount']) + toDoubleSafe(json['sgst_amount']) + toDoubleSafe(json['igst_amount'])), 0.0),
      total: toDoubleSafe(json['total'] ?? json['total_line_amount'], 0.0),
      confidence: toDoubleSafe(json['confidence'] ?? json['confidence_score'], 95.0),
    );
  }

  Map<String, dynamic> toJson() => {
    'lineNo': lineNo,
    'descRaw': descRaw,
    'hsn': hsn,
    'stockItem': stockItem,
    'qty': qty,
    'unit': unit,
    'rate': rate,
    'taxable': taxable,
    'taxRate': taxRate,
    'taxAmount': taxAmount,
    'total': total,
    'confidence': confidence,
  };
}

class Invoice {
  final String id;
  final String sourceFilename;
  String? imageUrl;
  String? localPath;
  String? sha256;
  String supplierRaw;
  String supplierMapped;
  String invoiceNo;
  String invoiceDate;
  String tallyDate;
  String gstin;
  String type;
  double subtotal;
  double discount;
  double cgst;
  double sgst;
  double igst;
  double grandTotal;
  String status; // 'NEEDS_REVIEW', 'APPROVED', 'POSTED', 'POST_FAILED'
  String tallyRef;
  String confidence;
  String rawOcrText;
  List<String> warnings;
  List<LineItem> lines;

  Invoice({
    required this.id,
    required this.sourceFilename,
    this.imageUrl,
    this.localPath,
    this.sha256,
    required this.supplierRaw,
    this.supplierMapped = '',
    required this.invoiceNo,
    required this.invoiceDate,
    this.tallyDate = '',
    this.gstin = '',
    this.type = 'Accounting Purchase',
    this.subtotal = 0.0,
    this.discount = 0.0,
    this.cgst = 0.0,
    this.sgst = 0.0,
    this.igst = 0.0,
    this.grandTotal = 0.0,
    this.status = 'NEEDS_REVIEW',
    this.tallyRef = '—',
    this.confidence = '—',
    this.rawOcrText = '',
    this.warnings = const [],
    this.lines = const [],
  });

  factory Invoice.fromJson(Map<String, dynamic> json) {
    var rawLines = json['lines'] as List? ?? [];
    List<LineItem> parsedLines = rawLines.map((i) => LineItem.fromJson(i as Map<String, dynamic>)).toList();

    return Invoice(
      id: json['id'] ?? '',
      sourceFilename: json['sourceFilename'] ?? 'invoice.jpg',
      imageUrl: json['imageUrl'],
      localPath: json['localPath'],
      sha256: json['sha256'],
      supplierRaw: json['supplierRaw'] ?? 'Unknown Supplier',
      supplierMapped: json['supplierMapped'] ?? '',
      invoiceNo: json['invoiceNo'] ?? '—',
      invoiceDate: json['invoiceDate'] ?? '',
      tallyDate: json['tallyDate'] ?? '',
      gstin: json['gstin'] ?? '',
      subtotal: toDoubleSafe(json['subtotal'] ?? json['subtotal_amount']),
      discount: toDoubleSafe(json['discount'] ?? json['discount_amount']),
      cgst: toDoubleSafe(json['cgst'] ?? json['cgst_amount']),
      sgst: toDoubleSafe(json['sgst'] ?? json['sgst_amount']),
      igst: toDoubleSafe(json['igst'] ?? json['igst_amount']),
      grandTotal: toDoubleSafe(json['grandTotal'] ?? json['total_amount']),
      status: json['status'] ?? 'NEEDS_REVIEW',
      tallyRef: json['tallyRef'] ?? '—',
      confidence: json['confidence'] ?? '—',
      rawOcrText: json['rawOcrText'] ?? '',
      warnings: (json['warnings'] as List? ?? []).map((e) => e.toString()).toList(),
      lines: parsedLines,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'sourceFilename': sourceFilename,
    'imageUrl': imageUrl,
    'localPath': localPath,
    'sha256': sha256,
    'supplierRaw': supplierRaw,
    'supplierMapped': supplierMapped,
    'invoiceNo': invoiceNo,
    'invoiceDate': invoiceDate,
    'tallyDate': tallyDate,
    'gstin': gstin,
    'type': type,
    'subtotal': subtotal,
    'discount': discount,
    'cgst': cgst,
    'sgst': sgst,
    'igst': igst,
    'grandTotal': grandTotal,
    'status': status,
    'tallyRef': tallyRef,
    'confidence': confidence,
    'rawOcrText': rawOcrText,
    'warnings': warnings,
    'lines': lines.map((l) => l.toJson()).toList(),
  };
}
