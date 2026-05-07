import 'package:supabase_flutter/supabase_flutter.dart';

/// Thin wrapper around the Supabase client for vault entry CRUD.
class SupabaseVaultApi {
  final SupabaseClient _client;

  SupabaseVaultApi(this._client);

  static const _table = 'vault_entries';

  // ────────── Fetch ──────────

  Future<List<Map<String, dynamic>>> fetchAll(String userId, {DateTime? since}) async {
    var query = _client
        .from(_table)
        .select()
        .eq('user_id', userId);

    if (since != null) {
      query = query.gte('updated_at', since.toIso8601String());
    }

    final data = await query.order('updated_at', ascending: false);
    return List<Map<String, dynamic>>.from(data);
  }

  // ────────── Upsert ──────────

  Future<Map<String, dynamic>> upsert(Map<String, dynamic> payload) async {
    final result = await _client
        .from(_table)
        .upsert(payload, onConflict: 'id')
        .select()
        .single();
    return result;
  }

  // ────────── Delete ──────────

  Future<void> softDelete(String id) async {
    await _client.from(_table).update({
      'deleted_at': DateTime.now().toIso8601String(),
    }).eq('id', id);
  }

  // ────────── Realtime ──────────

  RealtimeChannel watchChanges(
    String userId,
    void Function(List<Map<String, dynamic>>) onData,
  ) {
    return _client
        .channel('vault_changes_$userId')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: _table,
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'user_id',
            value: userId,
          ),
          callback: (payload) {
            // Trigger a full re-fetch on any change event
            fetchAll(userId).then(onData).catchError((_) {});
          },
        )
        .subscribe();
  }
}
