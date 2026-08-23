import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Thin wrapper around Firebase Cloud Firestore for encrypted vault entries and metadata CRUD.
class FirebaseVaultApi {
  final FirebaseFirestore _firestore;

  FirebaseVaultApi([FirebaseFirestore? firestore])
      : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> _entriesRef(String userId) =>
      _firestore.collection('users').doc(userId).collection('vault_entries');

  DocumentReference<Map<String, dynamic>> _metaRef(String userId) =>
      _firestore.collection('users').doc(userId).collection('meta').doc('vault');

  // ────────── Vault Metadata ──────────

  Future<void> saveVaultMetadata(
    String userId, {
    required String saltHex,
    required String proofHex,
  }) async {
    await _metaRef(userId).set({
      'vault_salt': saltHex,
      'vault_proof': proofHex,
      'updated_at': DateTime.now().toIso8601String(),
    }, SetOptions(merge: true));
  }

  Future<Map<String, dynamic>?> fetchVaultMetadata(String userId) async {
    final doc = await _metaRef(userId).get();
    if (!doc.exists) return null;
    return doc.data();
  }

  // ────────── Fetch Entries ──────────

  Future<List<Map<String, dynamic>>> fetchAll(
    String userId, {
    DateTime? since,
  }) async {
    Query<Map<String, dynamic>> query = _entriesRef(userId);

    if (since != null) {
      query = query.where('updated_at', isGreaterThanOrEqualTo: since.toIso8601String());
    }

    final snap = await query.orderBy('updated_at', descending: true).get();
    return snap.docs.map((d) => d.data()).toList();
  }

  // ────────── Upsert Entry ──────────

  Future<Map<String, dynamic>> upsert(Map<String, dynamic> payload) async {
    final userId = payload['user_id'] as String;
    final id = payload['id'] as String;

    await _entriesRef(userId).doc(id).set(payload, SetOptions(merge: true));
    return payload;
  }

  // ────────── Delete Entry ──────────

  Future<void> delete(String userId, String id) async {
    await _entriesRef(userId).doc(id).delete();
  }

  Future<void> softDelete(String userId, String id) async {
    await _entriesRef(userId).doc(id).delete();
  }

  // ────────── Realtime Listener ──────────

  StreamSubscription<QuerySnapshot<Map<String, dynamic>>> watchChanges(
    String userId,
    void Function(List<Map<String, dynamic>>) onData,
  ) {
    return _entriesRef(userId).snapshots().listen((snap) {
      final entries = snap.docs.map((d) => d.data()).toList();
      onData(entries);
    });
  }

  // ────────── User Profile & Directory ──────────

  Future<void> saveUserProfile(
    String userId, {
    required String email,
    String? role,
  }) async {
    final nowIso = DateTime.now().toIso8601String();
    final docRef = _firestore.collection('users').doc(userId);
    final doc = await docRef.get();

    final data = <String, dynamic>{
      'uid': userId,
      'email': email,
      'last_active_at': nowIso,
      if (role != null) 'role': role,
    };

    if (!doc.exists || doc.data()?['created_at'] == null) {
      data['created_at'] = nowIso;
    }

    await docRef.set(data, SetOptions(merge: true));
  }

  // ────────── Admin Operations ──────────

  Future<List<Map<String, dynamic>>> fetchAllUsers() async {
    try {
      final snap = await _firestore.collection('users').get();
      return snap.docs.map((d) {
        final data = d.data();
        return {
          'uid': d.id,
          ...data,
        };
      }).toList();
    } catch (_) {
      // In case Firestore security rules restrict listing the root /users collection
      return [];
    }
  }

  Future<Map<String, dynamic>> fetchUserVaultStats(String userId) async {
    try {
      final entriesSnap = await _entriesRef(userId).count().get();
      final meta = await fetchVaultMetadata(userId);

      return {
        'entries_count': entriesSnap.count ?? 0,
        'has_vault_meta': meta != null,
        'vault_meta': meta,
      };
    } catch (_) {
      // Fallback if aggregate count query is not supported
      try {
        final entriesSnap = await _entriesRef(userId).get();
        final meta = await fetchVaultMetadata(userId);
        return {
          'entries_count': entriesSnap.docs.length,
          'has_vault_meta': meta != null,
          'vault_meta': meta,
        };
      } catch (e) {
        return {
          'entries_count': 0,
          'has_vault_meta': false,
          'vault_meta': null,
          'error': e.toString(),
        };
      }
    }
  }

  Future<int> pingConnection([String? currentUserId]) async {
    final stopwatch = Stopwatch()..start();
    final uid = currentUserId;
    if (uid != null && uid.isNotEmpty && uid != 'offline') {
      await _firestore.collection('users').doc(uid).collection('meta').doc('ping').set({
        'ping_at': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } else {
      // Fallback ping
      await _firestore.collection('users').limit(1).get();
    }
    stopwatch.stop();
    return stopwatch.elapsedMilliseconds;
  }
}
