import '../../core/constants/app_constants.dart';

/// Represents the authenticated in-memory session.
class UserSession {
  final String userId;
  final String email;
  final DateTime unlockedAt;
  final int lockTimeoutMinutes;

  const UserSession({
    required this.userId,
    required this.email,
    required this.unlockedAt,
    this.lockTimeoutMinutes = 5,
  });

  DateTime get lockAt =>
      unlockedAt.add(Duration(minutes: lockTimeoutMinutes));

  bool get isExpired => DateTime.now().isAfter(lockAt);

  bool get isAdmin => AppConstants.kAdminEmails.contains(email.trim().toLowerCase());
}
