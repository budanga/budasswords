/// Represents the authenticated in-memory session.
class UserSession {
  final String userId;
  final String email;
  final DateTime unlockedAt;
  final int lockTimeoutMinutes;
  final String role;

  const UserSession({
    required this.userId,
    required this.email,
    required this.unlockedAt,
    this.lockTimeoutMinutes = 5,
    this.role = 'user',
  });

  DateTime get lockAt =>
      unlockedAt.add(Duration(minutes: lockTimeoutMinutes));

  bool get isExpired => DateTime.now().isAfter(lockAt);

  bool get isAdmin => role.trim().toLowerCase() == 'admin';

  UserSession copyWith({
    String? userId,
    String? email,
    DateTime? unlockedAt,
    int? lockTimeoutMinutes,
    String? role,
  }) {
    return UserSession(
      userId: userId ?? this.userId,
      email: email ?? this.email,
      unlockedAt: unlockedAt ?? this.unlockedAt,
      lockTimeoutMinutes: lockTimeoutMinutes ?? this.lockTimeoutMinutes,
      role: role ?? this.role,
    );
  }
}
