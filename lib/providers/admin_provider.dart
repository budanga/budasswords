import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/remote/firebase_vault_api.dart';
import 'auth_provider.dart';

class AdminUserItem {
  final String uid;
  final String email;
  final String role;
  final DateTime? createdAt;
  final DateTime? lastActiveAt;
  final int entriesCount;
  final bool hasVaultMeta;
  final Map<String, dynamic>? vaultMeta;

  const AdminUserItem({
    required this.uid,
    required this.email,
    required this.role,
    this.createdAt,
    this.lastActiveAt,
    this.entriesCount = 0,
    this.hasVaultMeta = false,
    this.vaultMeta,
  });

  bool get isAdmin => role.toLowerCase() == 'admin';

  AdminUserItem copyWith({
    String? uid,
    String? email,
    String? role,
    DateTime? createdAt,
    DateTime? lastActiveAt,
    int? entriesCount,
    bool? hasVaultMeta,
    Map<String, dynamic>? vaultMeta,
  }) {
    return AdminUserItem(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      role: role ?? this.role,
      createdAt: createdAt ?? this.createdAt,
      lastActiveAt: lastActiveAt ?? this.lastActiveAt,
      entriesCount: entriesCount ?? this.entriesCount,
      hasVaultMeta: hasVaultMeta ?? this.hasVaultMeta,
      vaultMeta: vaultMeta ?? this.vaultMeta,
    );
  }
}

class AdminStats {
  final int totalUsers;
  final int totalEntries;
  final int activeLast24h;
  final int activeLast7d;
  final int? pingLatencyMs;
  final bool isOnline;

  const AdminStats({
    this.totalUsers = 0,
    this.totalEntries = 0,
    this.activeLast24h = 0,
    this.activeLast7d = 0,
    this.pingLatencyMs,
    this.isOnline = true,
  });
}

class AdminState {
  final bool isLoading;
  final bool isDiagnosing;
  final AdminStats stats;
  final List<AdminUserItem> users;
  final String searchQuery;
  final AdminUserItem? selectedUser;
  final String? error;

  const AdminState({
    this.isLoading = false,
    this.isDiagnosing = false,
    this.stats = const AdminStats(),
    this.users = const [],
    this.searchQuery = '',
    this.selectedUser,
    this.error,
  });

  List<AdminUserItem> get filteredUsers {
    if (searchQuery.trim().isEmpty) return users;
    final q = searchQuery.toLowerCase().trim();
    return users.where((u) {
      return u.email.toLowerCase().contains(q) || u.uid.toLowerCase().contains(q);
    }).toList();
  }

  AdminState copyWith({
    bool? isLoading,
    bool? isDiagnosing,
    AdminStats? stats,
    List<AdminUserItem>? users,
    String? searchQuery,
    AdminUserItem? selectedUser,
    bool clearSelectedUser = false,
    String? error,
    bool clearError = false,
  }) {
    return AdminState(
      isLoading: isLoading ?? this.isLoading,
      isDiagnosing: isDiagnosing ?? this.isDiagnosing,
      stats: stats ?? this.stats,
      users: users ?? this.users,
      searchQuery: searchQuery ?? this.searchQuery,
      selectedUser: clearSelectedUser ? null : (selectedUser ?? this.selectedUser),
      error: clearError ? null : (error ?? this.error),
    );
  }
}

class AdminNotifier extends StateNotifier<AdminState> {
  final FirebaseVaultApi _remoteApi;
  final String? _currentUserId;
  final String? _currentUserEmail;
  final String? _currentUserRole;

  AdminNotifier([
    FirebaseVaultApi? remoteApi,
    this._currentUserId,
    this._currentUserEmail,
    this._currentUserRole,
  ])  : _remoteApi = remoteApi ?? FirebaseVaultApi(),
        super(const AdminState()) {
    loadData();
  }

  Future<void> loadData() async {
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      // 1. Ensure current user profile is synced in Firestore
      if (_currentUserId != null && _currentUserEmail != null && _currentUserId.isNotEmpty) {
        try {
          await _remoteApi.saveUserProfile(_currentUserId, email: _currentUserEmail);
        } catch (_) {}
      }

      // 2. Measure ping latency
      int? latency;
      try {
        latency = await _remoteApi.pingConnection(_currentUserId);
      } catch (_) {}

      // 3. Fetch all users from Firestore
      final rawUsers = await _remoteApi.fetchAllUsers();
      final now = DateTime.now();

      int totalVaultEntries = 0;
      int active24h = 0;
      int active7d = 0;

      final List<AdminUserItem> parsedUsers = [];

      for (final raw in rawUsers) {
        final uid = raw['uid'] as String? ?? '';
        final email = raw['email'] as String? ?? '';
        final role = raw['role'] as String? ?? 'user';

        DateTime? createdAt;
        if (raw['created_at'] != null) {
          createdAt = DateTime.tryParse(raw['created_at'].toString());
        }

        DateTime? lastActiveAt;
        if (raw['last_active_at'] != null) {
          lastActiveAt = DateTime.tryParse(raw['last_active_at'].toString());
        }

        if (lastActiveAt != null) {
          final diff = now.difference(lastActiveAt);
          if (diff.inHours <= 24) active24h++;
          if (diff.inDays <= 7) active7d++;
        }

        // Fetch user stats (entry count & metadata)
        final stats = await _remoteApi.fetchUserVaultStats(uid);
        final count = stats['entries_count'] as int? ?? 0;
        final hasMeta = stats['has_vault_meta'] as bool? ?? false;
        final vaultMeta = stats['vault_meta'] as Map<String, dynamic>?;

        totalVaultEntries += count;

        parsedUsers.add(AdminUserItem(
          uid: uid,
          email: email,
          role: role,
          createdAt: createdAt,
          lastActiveAt: lastActiveAt,
          entriesCount: count,
          hasVaultMeta: hasMeta,
          vaultMeta: vaultMeta,
        ));
      }

      // Fallback: If current admin user was not returned in collection list, add them directly
      if (_currentUserId != null &&
          _currentUserId.isNotEmpty &&
          !parsedUsers.any((u) => u.uid == _currentUserId)) {
        final stats = await _remoteApi.fetchUserVaultStats(_currentUserId);
        final count = stats['entries_count'] as int? ?? 0;
        final hasMeta = stats['has_vault_meta'] as bool? ?? false;
        final vaultMeta = stats['vault_meta'] as Map<String, dynamic>?;

        totalVaultEntries += count;
        active24h++;
        active7d++;

        parsedUsers.add(AdminUserItem(
          uid: _currentUserId,
          email: _currentUserEmail ?? '',
          role: _currentUserRole ?? 'admin',
          createdAt: DateTime.now(),
          lastActiveAt: DateTime.now(),
          entriesCount: count,
          hasVaultMeta: hasMeta,
          vaultMeta: vaultMeta,
        ));
      }

      // Sort by last active descending
      parsedUsers.sort((a, b) {
        final aDate = a.lastActiveAt ?? a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        final bDate = b.lastActiveAt ?? b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        return bDate.compareTo(aDate);
      });

      state = state.copyWith(
        isLoading: false,
        users: parsedUsers,
        stats: AdminStats(
          totalUsers: parsedUsers.length,
          totalEntries: totalVaultEntries,
          activeLast24h: active24h,
          activeLast7d: active7d,
          isOnline: true,
          pingLatencyMs: latency ?? state.stats.pingLatencyMs,
        ),
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
        stats: AdminStats(
          totalUsers: state.users.length,
          totalEntries: state.stats.totalEntries,
          activeLast24h: state.stats.activeLast24h,
          activeLast7d: state.stats.activeLast7d,
          isOnline: true,
          pingLatencyMs: state.stats.pingLatencyMs,
        ),
      );
    }
  }

  void setSearchQuery(String query) {
    state = state.copyWith(searchQuery: query);
  }

  void selectUser(AdminUserItem? user) {
    state = state.copyWith(selectedUser: user, clearSelectedUser: user == null);
  }

  Future<void> runDiagnostics() async {
    state = state.copyWith(isDiagnosing: true, clearError: true);

    try {
      final latency = await _remoteApi.pingConnection(_currentUserId);
      state = state.copyWith(
        isDiagnosing: false,
        stats: AdminStats(
          totalUsers: state.stats.totalUsers,
          totalEntries: state.stats.totalEntries,
          activeLast24h: state.stats.activeLast24h,
          activeLast7d: state.stats.activeLast7d,
          isOnline: true,
          pingLatencyMs: latency,
        ),
      );
    } catch (e) {
      state = state.copyWith(
        isDiagnosing: false,
        error: e.toString(),
        stats: AdminStats(
          totalUsers: state.stats.totalUsers,
          totalEntries: state.stats.totalEntries,
          activeLast24h: state.stats.activeLast24h,
          activeLast7d: state.stats.activeLast7d,
          isOnline: false,
          pingLatencyMs: null,
        ),
      );
    }
  }
}

final adminProvider = StateNotifierProvider<AdminNotifier, AdminState>((ref) {
  final authState = ref.watch(authProvider);
  final session = authState.session;
  return AdminNotifier(null, session?.userId, session?.email, session?.role);
});
