/// Domain model for a single vault entry.
class VaultEntry {
  final String id;
  final String userId;
  final String title;
  final String? url;
  final String content;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;
  final int serverRev;

  const VaultEntry({
    required this.id,
    required this.userId,
    required this.title,
    this.url,
    required this.content,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
    this.serverRev = 0,
  });

  bool get isDeleted => deletedAt != null;

  VaultEntry copyWith({
    String? title,
    String? url,
    String? content,
    DateTime? updatedAt,
    DateTime? deletedAt,
    int? serverRev,
  }) {
    return VaultEntry(
      id: id,
      userId: userId,
      title: title ?? this.title,
      url: url ?? this.url,
      content: content ?? this.content,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      serverRev: serverRev ?? this.serverRev,
    );
  }

  @override
  String toString() => 'VaultEntry(id: $id, title: $title)';
}
