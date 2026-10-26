class AuditLog {
  final String time;
  final String actor;
  final String action;
  final String summary;
  final Map<String, dynamic>? diff;

  AuditLog({
    required this.time,
    required this.actor,
    required this.action,
    required this.summary,
    this.diff,
  });

  factory AuditLog.fromJson(Map<String, dynamic> json) {
    return AuditLog(
      time: json['time'] ?? '',
      actor: json['actor'] ?? 'System',
      action: json['action'] ?? '',
      summary: json['summary'] ?? '',
      diff: json['diff'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toJson() => {
    'time': time,
    'actor': actor,
    'action': action,
    'summary': summary,
    'diff': diff,
  };
}
