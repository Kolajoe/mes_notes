class Note {
  final int? id;
  final int userId;
  final String title;
  final String content;
  final String createdAt;
  final String updatedAt;
  final bool isFavorite;
  final bool isArchived;

  Note({
    this.id,
    required this.userId,
    required this.title,
    required this.content,
    required this.createdAt,
    required this.updatedAt,
    this.isFavorite = false,
    this.isArchived = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'title': title,
      'content': content,
      'created_at': createdAt,
      'updated_at': updatedAt,
      'is_favorite': isFavorite ? 1 : 0,
      'is_archived': isArchived ? 1 : 0,
    };
  }

  factory Note.fromMap(Map<String, dynamic> map) {
    return Note(
      id: map['id'] as int?,
      userId: map['user_id'] as int,
      title: map['title'] as String,
      content: map['content'] as String,
      createdAt: map['created_at'] as String,
      updatedAt: map['updated_at'] as String,
      isFavorite: map['is_favorite'] == 1,
      isArchived: map['is_archived'] == 1,
    );
  }
}
