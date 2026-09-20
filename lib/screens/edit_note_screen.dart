import 'package:flutter/material.dart';

import '../models/note.dart';
import '../models/user.dart';
import '../services/note_service.dart';
import '../utils/app_colors.dart';

class EditNoteScreen extends StatefulWidget {
  final Note note;
  final User user;

  const EditNoteScreen({super.key, required this.note, required this.user});

  @override
  State<EditNoteScreen> createState() => _EditNoteScreenState();
}

class _EditNoteScreenState extends State<EditNoteScreen> {
  final _formKey = GlobalKey<FormState>();

  final _titleController = TextEditingController();
  final _contentController = TextEditingController();

  final NoteService _noteService = NoteService();

  bool _isSaving = false;

  static const int _maxTitleLength = 100;
  static const int _maxContentLength = 5000;

  @override
  void initState() {
    super.initState();

    _titleController.text = widget.note.title;
    _contentController.text = widget.note.content;

    _titleController.addListener(_onTextChanged);
    _contentController.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    _titleController.removeListener(_onTextChanged);
    _contentController.removeListener(_onTextChanged);

    _titleController.dispose();
    _contentController.dispose();

    super.dispose();
  }

  void _onTextChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  bool get _hasChanges {
    final titleChanged = _titleController.text.trim() != widget.note.title;

    final contentChanged =
        _contentController.text.trim() != widget.note.content;

    return titleChanged || contentChanged;
  }

  Future<void> _updateNote() async {
    FocusScope.of(context).unfocus();

    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_isSaving) {
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final updatedNote = Note(
        id: widget.note.id,
        userId: widget.note.userId,
        title: _titleController.text.trim(),
        content: _contentController.text.trim(),
        createdAt: widget.note.createdAt,
        updatedAt: DateTime.now().toIso8601String(),
        isFavorite: widget.note.isFavorite,
        isArchived: widget.note.isArchived,
      );

      await _noteService.updateNote(updatedNote);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Note modifiée avec succès.'),
          backgroundColor: AppColors.success,
          duration: Duration(seconds: 2),
        ),
      );

      Navigator.pop(context, updatedNote);
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Impossible de modifier la note. '
            'Veuillez réessayer.',
          ),
          backgroundColor: AppColors.error,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  Future<bool> _confirmExit() async {
    if (!_hasChanges) {
      return true;
    }

    FocusScope.of(context).unfocus();

    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text(
            'Quitter l’édition ?',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          content: const Text(
            'Les modifications non enregistrées '
            'seront perdues.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext, false);
              },
              child: const Text('Continuer l’édition'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.error,
                foregroundColor: Colors.white,
              ),
              onPressed: () {
                Navigator.pop(dialogContext, true);
              },
              child: const Text('Quitter'),
            ),
          ],
        );
      },
    );

    return result ?? false;
  }

  Future<void> _cancel() async {
    if (_isSaving) {
      return;
    }

    final shouldPop = await _confirmExit();

    if (shouldPop && mounted) {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) {
          return;
        }

        if (_isSaving) {
          return;
        }

        final navigator = Navigator.of(context);

        final shouldPop = await _confirmExit();

        if (!mounted) return;

        if (shouldPop) {
          navigator.pop();
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.background,

        appBar: AppBar(
          title: const Text(
            'Modifier la note',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          leading: IconButton(
            tooltip: 'Retour',
            onPressed: _isSaving ? null : _cancel,
            icon: const Icon(Icons.arrow_back_rounded),
          ),
        ),

        body: SafeArea(
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    keyboardDismissBehavior:
                        ScrollViewKeyboardDismissBehavior.onDrag,
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 25),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildInfoHeader(),

                        const SizedBox(height: 25),

                        _buildTitleField(),

                        const SizedBox(height: 22),

                        _buildContentField(),
                      ],
                    ),
                  ),
                ),

                _buildBottomActions(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.12)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.edit_note_outlined,
              color: AppColors.primary,
            ),
          ),

          const SizedBox(width: 12),

          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Modifier votre note',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Modifiez le titre ou le contenu, '
                  'puis enregistrez vos changements.',
                  style: TextStyle(
                    fontSize: 13,
                    height: 1.4,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTitleField() {
    final titleLength = _titleController.text.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text(
              'Titre',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(width: 5),
            const Text(
              '*',
              style: TextStyle(
                color: AppColors.error,
                fontWeight: FontWeight.bold,
              ),
            ),
            const Spacer(),
            Text(
              '$titleLength/$_maxTitleLength',
              style: TextStyle(
                fontSize: 11,
                color: titleLength >= _maxTitleLength
                    ? AppColors.error
                    : AppColors.textSecondary,
              ),
            ),
          ],
        ),

        const SizedBox(height: 8),

        TextFormField(
          controller: _titleController,
          textCapitalization: TextCapitalization.sentences,
          textInputAction: TextInputAction.next,
          maxLength: _maxTitleLength,
          decoration: const InputDecoration(
            hintText: 'Titre de la note',
            prefixIcon: Icon(Icons.title_outlined),
            counterText: '',
          ),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Veuillez saisir un titre.';
            }

            if (value.trim().length < 2) {
              return 'Le titre doit contenir au moins 2 caractères.';
            }

            return null;
          },
        ),
      ],
    );
  }

  Widget _buildContentField() {
    final contentLength = _contentController.text.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text(
              'Contenu',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(width: 5),
            const Text(
              '*',
              style: TextStyle(
                color: AppColors.error,
                fontWeight: FontWeight.bold,
              ),
            ),
            const Spacer(),
            Text(
              '$contentLength/$_maxContentLength',
              style: TextStyle(
                fontSize: 11,
                color: contentLength >= _maxContentLength
                    ? AppColors.error
                    : AppColors.textSecondary,
              ),
            ),
          ],
        ),

        const SizedBox(height: 8),

        TextFormField(
          controller: _contentController,
          textCapitalization: TextCapitalization.sentences,
          keyboardType: TextInputType.multiline,
          minLines: 12,
          maxLines: 20,
          maxLength: _maxContentLength,
          decoration: const InputDecoration(
            hintText: 'Modifiez le contenu de votre note...',
            alignLabelWithHint: true,
            prefixIcon: Padding(
              padding: EdgeInsets.only(bottom: 180),
              child: Icon(Icons.notes_outlined),
            ),
            counterText: '',
          ),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Veuillez saisir le contenu de la note.';
            }

            if (value.trim().length < 2) {
              return 'Le contenu doit contenir au moins 2 caractères.';
            }

            return null;
          },
        ),

        const SizedBox(height: 8),

        const Text(
          'Les modifications seront enregistrées dans votre note existante.',
          style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
        ),
      ],
    );
  }

  Widget _buildBottomActions() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: _isSaving ? null : _cancel,
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50),
                  foregroundColor: AppColors.textPrimary,
                  side: const BorderSide(color: AppColors.border),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text('Annuler'),
              ),
            ),

            const SizedBox(width: 12),

            Expanded(
              child: ElevatedButton.icon(
                onPressed: _isSaving ? null : _updateNote,
                icon: _isSaving
                    ? const SizedBox(
                        width: 19,
                        height: 19,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.save_outlined),
                label: Text(_isSaving ? 'Enregistrement...' : 'Enregistrer'),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
