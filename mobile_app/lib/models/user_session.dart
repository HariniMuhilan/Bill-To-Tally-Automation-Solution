class UserSession {
  final String username;
  final String fullName;
  final String role;
  final String initials;

  UserSession({
    required this.username,
    required this.fullName,
    required this.role,
    required this.initials,
  });

  factory UserSession.fromJson(Map<String, dynamic> json) {
    return UserSession(
      username: json['username'] ?? 'accounts_user_01',
      fullName: json['fullName'] ?? 'Accounts User 01',
      role: json['role'] ?? 'Reviewer & Approver',
      initials: json['initials'] ?? 'AU',
    );
  }

  Map<String, dynamic> toJson() => {
    'username': username,
    'fullName': fullName,
    'role': role,
    'initials': initials,
  };

  static final UserSession defaultUser = UserSession(
    username: 'accounts_user_01',
    fullName: 'Accounts User 01',
    role: 'Reviewer & Approver',
    initials: 'AU',
  );

  static final List<UserSession> demoPresets = [
    UserSession(
      username: 'accounts_user_01',
      fullName: 'Accounts User 01',
      role: 'Reviewer & Approver',
      initials: 'AU',
    ),
    UserSession(
      username: 'admin',
      fullName: 'System Administrator',
      role: 'Administrator',
      initials: 'SA',
    ),
    UserSession(
      username: 'operator',
      fullName: 'Data Entry Operator',
      role: 'Data Entry Operator',
      initials: 'OP',
    ),
  ];
}
