import 'package:flutter/material.dart';

import '../models/note.dart';
import '../models/user.dart';
import '../services/note_service.dart';
import '../utils/app_colors.dart';
import 'delete_confirmation_screen.dart';
import 'edit_note_screen.dart';

class NoteDetailScreen extends StatefulWidget {
  final Note note;
  final User user;

  const NoteDetailScreen({super.key, required this.note, required this.user});

  @override
  State<NoteDetailScreen> createState() => _NoteDetailScreenState();
}

class _NoteDetailScreenState extends State<NoteDetailScreen> {
  final NoteService _noteService = NoteService();

  late Note _note;

  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _note = widget.note;
  }

  String _formatDate(String date) {
    final parsedDate = DateTime.tryParse(date);

    if (parsedDate == null) {
      return date;
    }

    final day = parsedDate.day.toString().padLeft(2, '0');

    final month = parsedDate.month.toString().padLeft(2, '0');

    final year = parsedDate.year;

    final hour = parsedDate.hour.toString().padLeft(2, '0');

    final minute = parsedDate.minute.toString().padLeft(2, '0');

    return '$day/$month/$year à $hour:$minute';
  }

  Future<void> _toggleFavorite() async {
    if (_isProcessing) return;

    setState(() {
      _isProcessing = true;
    });

    try {
      final newValue = !_note.isFavorite;

      await _noteService.toggleFavorite(_note.id!, newValue);

      final updatedNote = await _noteService.getNote(_note.id!);

      if (!mounted || updatedNote == null) {
        return;
      }

      setState(() {
        _note = updatedNote;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            newValue
                ? 'Note ajoutée aux favoris.'
                : 'Note retirée des favoris.',
          ),
          duration: const Duration(seconds: 2),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Impossible de modifier le favori.'),
          backgroundColor: AppColors.error,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  Future<void> _toggleArchive() async {
    if (_isProcessing) return;

    setState(() {
      _isProcessing = true;
    });

    try {
      final newValue = !_note.isArchived;

      await _noteService.toggleArchive(_note.id!, newValue);

      if (!mounted) return;

      if (newValue) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Note archivée avec succès.'),
            backgroundColor: AppColors.success,
          ),
        );

        Navigator.pop(context, true);
        return;
      }

      final updatedNote = await _noteService.getNote(_note.id!);

      if (!mounted || updatedNote == null) {
        return;
      }

      setState(() {
        _note = updatedNote;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Note désarchivée.'),
          backgroundColor: AppColors.success,
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Impossible de modifier l’archive.'),
          backgroundColor: AppColors.error,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  Future<void> _editNote() async {
    if (_isProcessing) return;

    final result = await Navigator.push<Note>(
      context,
      MaterialPageRoute(
        builder: (_) => EditNoteScreen(note: _note, user: widget.user),
      ),
    );

    if (!mounted || result == null) {
      return;
    }

    setState(() {
      _note = result;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Note mise à jour.'),
        backgroundColor: AppColors.success,
        duration: Duration(seconds: 2),
      ),
    );
  }

  Future<void> _deleteNote() async {
    if (_isProcessing) return;

    final confirmed = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => DeleteConfirmationScreen(noteTitle: _note.title),
      ),
    );

    if (confirmed != true) {
      return;
    }

    setState(() {
      _isProcessing = true;
    });

    try {
      await _noteService.deleteNote(_note.id!);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Note supprimée avec succès.'),
          backgroundColor: AppColors.success,
        ),
      );

      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Impossible de supprimer la note.'),
          backgroundColor: AppColors.error,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ma note'),

        actions: [
          // Favori
          IconButton(
            tooltip: _note.isFavorite
                ? 'Retirer des favoris'
                : 'Ajouter aux favoris',
            onPressed: _isProcessing ? null : _toggleFavorite,
            icon: Icon(_note.isFavorite ? Icons.star : Icons.star_border),
          ),

          // Archive
          IconButton(
            tooltip: _note.isArchived ? 'Désarchiver' : 'Archiver',
            onPressed: _isProcessing ? null : _toggleArchive,
            icon: Icon(
              _note.isArchived
                  ? Icons.unarchive_outlined
                  : Icons.archive_outlined,
            ),
          ),

          // Modifier
          IconButton(
            tooltip: 'Modifier',
            onPressed: _isProcessing ? null : _editNote,
            icon: const Icon(Icons.edit_outlined),
          ),

          // Supprimer
          IconButton(
            tooltip: 'Supprimer',
            onPressed: _isProcessing ? null : _deleteNote,
            icon: const Icon(Icons.delete_outline),
          ),
        ],
      ),

      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 25, 20, 35),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _note.title,
                style: const TextStyle(
                  fontSize: 27,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                  height: 1.25,
                ),
              ),

              const SizedBox(height: 12),

              Row(
                children: [
                  const Icon(
                    Icons.update_outlined,
                    size: 17,
                    color: AppColors.textSecondary,
                  ),

                  const SizedBox(width: 6),

                  Expanded(
                    child: Text(
                      'Modifiée le '
                      '${_formatDate(_note.updatedAt)}',
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 15),

              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  if (_note.isFavorite)
                    _buildBadge(
                      icon: Icons.star,
                      label: 'Favori',
                      color: Colors.amber,
                    ),

                  if (_note.isArchived)
                    _buildBadge(
                      icon: Icons.archive_outlined,
                      label: 'Archivée',
                      color: AppColors.primary,
                    ),
                ],
              ),

              const SizedBox(height: 25),

              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.border),
                ),
                child: Text(
                  _note.content,
                  style: const TextStyle(
                    fontSize: 16,
                    height: 1.7,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),

              const SizedBox(height: 30),

              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _isProcessing ? null : _editNote,
                      icon: const Icon(Icons.edit_outlined),
                      label: const Text('Modifier'),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 50),
                      ),
                    ),
                  ),

                  const SizedBox(width: 12),

                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _isProcessing ? null : _deleteNote,
                      icon: const Icon(Icons.delete_outline),
                      label: const Text('Supprimer'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.error,
                        foregroundColor: Colors.white,
                        minimumSize: const Size(double.infinity, 50),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBadge({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
