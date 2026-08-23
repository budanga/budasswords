enum EntryCategory {
  login,
  note,
  card,
}

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

  /// Intelligent classification of the entry type based on tags, structure, and keywords.
  EntryCategory get category {
    final t = title.toLowerCase().trim();
    final c = content.trim();
    final cLower = c.toLowerCase();
    final u = url?.trim() ?? '';

    // 1. Explicit metadata prefix
    if (c.startsWith('[type:note]') || c.startsWith('type:note') || c.startsWith('[note]')) {
      return EntryCategory.note;
    }
    if (c.startsWith('[type:card]') || c.startsWith('type:card') || c.startsWith('[card]') || c.startsWith('type:tarjeta')) {
      return EntryCategory.card;
    }
    if (c.startsWith('[type:login]') || c.startsWith('type:login') || c.startsWith('[login]')) {
      return EntryCategory.login;
    }

    // 2. Card keywords
    if (t.contains('card') || t.contains('tarjeta') || t.contains('visa') || t.contains('mastercard') || t.contains('amex') ||
        cLower.contains('cvv') || cLower.contains('cardholder') || cLower.contains('titular:') || cLower.contains('número:')) {
      return EntryCategory.card;
    }

    // 3. Note title keywords
    if (t.contains('nota') || t.contains('note') || t.contains('memo') || t.contains('diario') || t.contains('journal') ||
        t.contains('idea') || t.contains('apunte') || t.contains('borrador') || t.contains('reflexion') || t.contains('reflexión') ||
        t.contains('recordatorio') || t.contains('frase') || t.contains('secret note')) {
      return EntryCategory.note;
    }

    // 4. If it has explicit login keys (like Bitwarden exports: "Username: ...", "Password: ...")
    if (cLower.contains('username:') || cLower.contains('usuario:') || cLower.contains('password:') || cLower.contains('contraseña:')) {
      return EntryCategory.login;
    }

    // 5. If it has a URL, it's a login
    if (u.isNotEmpty) {
      return EntryCategory.login;
    }

    // 6. Natural language text without URL: multiline, spaces, or sentences -> Note
    final wordCount = c.split(RegExp(r'\s+')).length;
    final lineCount = c.split('\n').where((l) => l.trim().isNotEmpty).length;
    if (lineCount > 1 || wordCount > 2 || (c.contains(' ') && c.length > 12)) {
      return EntryCategory.note;
    }

    return EntryCategory.login;
  }

  /// Returns content with type prefixes stripped if present.
  String get cleanContent {
    if (content.startsWith('[type:note]\n')) return content.substring(12);
    if (content.startsWith('[type:card]\n')) return content.substring(12);
    if (content.startsWith('[type:login]\n')) return content.substring(13);
    if (content.startsWith('[type:note]')) return content.substring(11);
    if (content.startsWith('[type:card]')) return content.substring(11);
    if (content.startsWith('[type:login]')) return content.substring(12);
    return content;
  }

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

