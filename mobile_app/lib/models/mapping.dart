class MasterMapping {
  final String id;
  String raw;
  String tally;
  String category;
  String? guid;
  String status;
  String date;

  MasterMapping({
    required this.id,
    required this.raw,
    required this.tally,
    required this.category,
    this.guid,
    this.status = 'VERIFIED',
    required this.date,
  });

  factory MasterMapping.fromJson(Map<String, dynamic> json) {
    return MasterMapping(
      id: json['id'] ?? '',
      raw: json['raw'] ?? '',
      tally: json['tally'] ?? '',
      category: json['category'] ?? 'Ledger',
      guid: json['guid'],
      status: json['status'] ?? 'VERIFIED',
      date: json['date'] ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'raw': raw,
    'tally': tally,
    'category': category,
    'guid': guid,
    'status': status,
    'date': date,
  };
}
