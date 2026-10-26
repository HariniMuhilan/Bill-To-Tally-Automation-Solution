import 'invoice.dart';

class DraftSheet {
  final String id;
  String fileName;
  String createdAt;
  String updatedAt;
  double totalAmount;
  List<Invoice> invoices;

  DraftSheet({
    required this.id,
    required this.fileName,
    required this.createdAt,
    required this.updatedAt,
    required this.totalAmount,
    required this.invoices,
  });

  factory DraftSheet.fromJson(Map<String, dynamic> json) {
    var rawInvs = json['invoices'] as List? ?? [];
    List<Invoice> invList = rawInvs.map((i) => Invoice.fromJson(i as Map<String, dynamic>)).toList();
    if (invList.isEmpty && json['invoice'] != null) {
      invList = [Invoice.fromJson(json['invoice'])];
    }

    return DraftSheet(
      id: json['id'] ?? '',
      fileName: json['fileName'] ?? 'Voucher_Sheet.xlsx',
      createdAt: json['createdAt'] ?? '',
      updatedAt: json['updatedAt'] ?? '',
      totalAmount: (json['totalAmount'] ?? 0.0).toDouble(),
      invoices: invList,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'fileName': fileName,
    'createdAt': createdAt,
    'updatedAt': updatedAt,
    'totalAmount': totalAmount,
    'invoices': invoices.map((i) => i.toJson()).toList(),
  };
}
