import '../database/database_helper.dart';
import '../models/note.dart';

class NoteService {
  final DatabaseHelper _databaseHelper = DatabaseHelper.instance;

  Future<int> addNote(Note note) async {
    final db = await _databaseHelper.database;

    return db.insert('notes', note.toMap());
  }

  Future<List<Note>> getNotes(int userId) async {
    final db = await _databaseHelper.database;

    final result = await db.query(
      'notes',
      where: 'user_id = ? AND is_archived = 0',
      whereArgs: [userId],
      orderBy: 'updated_at DESC',
    );

    return result.map((map) => Note.fromMap(map)).toList();
  }

  Future<Note?> getNote(int id) async {
    final db = await _databaseHelper.database;

    final result = await db.query(
      'notes',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );

    if (result.isEmpty) {
      return null;
    }

    return Note.fromMap(result.first);
  }

  Future<int> updateNote(Note note) async {
    final db = await _databaseHelper.database;

    return db.update(
      'notes',
      note.toMap(),
      where: 'id = ?',
      whereArgs: [note.id],
    );
  }

  Future<int> deleteNote(int id) async {
    final db = await _databaseHelper.database;

    return db.delete('notes', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<Note>> searchNotes(int userId, String query) async {
    final db = await _databaseHelper.database;

    final result = await db.query(
      'notes',
      where: '''
        user_id = ?
        AND is_archived = 0
        AND (
          title LIKE ?
          OR content LIKE ?
        )
      ''',
      whereArgs: [userId, '%$query%', '%$query%'],
      orderBy: 'updated_at DESC',
    );

    return result.map((map) => Note.fromMap(map)).toList();
  }

  Future<List<Note>> getFavorites(int userId) async {
    final db = await _databaseHelper.database;

    final result = await db.query(
      'notes',
      where: 'user_id = ? AND is_favorite = 1',
      whereArgs: [userId],
      orderBy: 'updated_at DESC',
    );

    return result.map((map) => Note.fromMap(map)).toList();
  }

  Future<List<Note>> getArchives(int userId) async {
    final db = await _databaseHelper.database;

    final result = await db.query(
      'notes',
      where: 'user_id = ? AND is_archived = 1',
      whereArgs: [userId],
      orderBy: 'updated_at DESC',
    );

    return result.map((map) => Note.fromMap(map)).toList();
  }

  Future<int> toggleFavorite(int noteId, bool value) async {
    final db = await _databaseHelper.database;

    return db.update(
      'notes',
      {'is_favorite': value ? 1 : 0},
      where: 'id = ?',
      whereArgs: [noteId],
    );
  }

  Future<int> toggleArchive(int noteId, bool value) async {
    final db = await _databaseHelper.database;

    return db.update(
      'notes',
      {'is_archived': value ? 1 : 0},
      where: 'id = ?',
      whereArgs: [noteId],
    );
  }
}
