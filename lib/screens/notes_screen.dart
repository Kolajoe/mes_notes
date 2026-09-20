import 'package:flutter/material.dart';

import '../models/note.dart';
import '../models/user.dart';
import '../services/note_service.dart';
import '../utils/app_colors.dart';
import 'add_note_screen.dart';
import 'menu_screen.dart';
import 'note_detail_screen.dart';

class NotesScreen extends StatefulWidget {
  final User user;

  const NotesScreen({super.key, required this.user});

  @override
  State<NotesScreen> createState() => _NotesScreenState();
}

class _NotesScreenState extends State<NotesScreen> {
  final NoteService _noteService = NoteService();

  final TextEditingController _searchController = TextEditingController();

  List<Note> _notes = [];

  bool _isLoading = true;
  bool _isSearching = false;

  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadNotes();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadNotes({bool showLoader = true}) async {
    if (showLoader && mounted) {
      setState(() {
        _isLoading = true;
      });
    }

    try {
      final notes = await _noteService.getNotes(widget.user.id!);

      if (!mounted) return;

      setState(() {
        _notes = notes;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });

      _showMessage('Impossible de charger les notes.', isError: true);
    }
  }

  Future<void> _searchNotes(String query) async {
    setState(() {
      _searchQuery = query.trim();
      _isSearching = query.trim().isNotEmpty;
    });

    if (_searchQuery.isEmpty) {
      await _loadNotes();
      return;
    }

    try {
      final notes = await _noteService.searchNotes(
        widget.user.id!,
        _searchQuery,
      );

      if (!mounted) return;

      setState(() {
        _notes = notes;
      });
    } catch (e) {
      if (!mounted) return;

      _showMessage('Erreur lors de la recherche.', isError: true);
    }
  }

  void _clearSearch() {
    _searchController.clear();

    _searchNotes('');
  }

  Future<void> _openAddNote() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => AddNoteScreen(user: widget.user)),
    );

    await _loadNotes(showLoader: false);
  }

  Future<void> _openNote(Note note) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => NoteDetailScreen(note: note, user: widget.user),
      ),
    );

    await _loadNotes(showLoader: false);
  }

  Future<void> _openMenu() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => MenuScreen(user: widget.user)),
    );

    await _loadNotes(showLoader: false);
  }

  void _showMessage(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? AppColors.error : AppColors.success,
      ),
    );
  }

  String _formatDate(String date) {
    final parsedDate = DateTime.tryParse(date);

    if (parsedDate == null) {
      return '';
    }

    final now = DateTime.now();

    final today = DateTime(now.year, now.month, now.day);

    final noteDate = DateTime(
      parsedDate.year,
      parsedDate.month,
      parsedDate.day,
    );

    final difference = today.difference(noteDate).inDays;

    final hour = parsedDate.hour.toString().padLeft(2, '0');

    final minute = parsedDate.minute.toString().padLeft(2, '0');

    if (difference == 0) {
      return 'Aujourd’hui à $hour:$minute';
    }

    if (difference == 1) {
      return 'Hier à $hour:$minute';
    }

    final day = parsedDate.day.toString().padLeft(2, '0');

    final month = parsedDate.month.toString().padLeft(2, '0');

    return '$day/$month/${parsedDate.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,

      appBar: AppBar(
        automaticallyImplyLeading: false,

        titleSpacing: 20,

        title: const Text(
          'Mes Notes',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),

        actions: [
          IconButton(
            tooltip: 'Menu',
            onPressed: _openMenu,
            icon: const Icon(Icons.menu_rounded),
          ),

          const SizedBox(width: 8),
        ],
      ),

      body: RefreshIndicator(
        onRefresh: () => _loadNotes(showLoader: false),
        child: Column(
          children: [
            _buildWelcomeHeader(),
            _buildSearchBar(),

            Expanded(child: _buildNotesContent()),
          ],
        ),
      ),

      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openAddNote,
        tooltip: 'Ajouter une note',
        icon: const Icon(Icons.add),
        label: const Text('Nouvelle note'),
      ),
    );
  }

  Widget _buildWelcomeHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
      child: Row(
        children: [
          // Avatar
          CircleAvatar(
            radius: 27,
            backgroundColor: AppColors.primary.withValues(alpha: 0.12),
            child: Text(
              _getInitials(widget.user.fullName),
              style: const TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.bold,
                fontSize: 17,
              ),
            ),
          ),

          const SizedBox(width: 12),

          // Nom
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Bonjour 👋',
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                ),

                const SizedBox(height: 3),

                Text(
                  widget.user.fullName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: 10),

          // Compteur
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                Text(
                  '${_notes.length}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
                const Text(
                  'notes',
                  style: TextStyle(
                    fontSize: 11,
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

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 5, 20, 15),
      child: TextField(
        controller: _searchController,
        onChanged: _searchNotes,
        textInputAction: TextInputAction.search,
        decoration: InputDecoration(
          hintText: 'Rechercher une note...',
          prefixIcon: const Icon(Icons.search_rounded),
          suffixIcon: _isSearching
              ? IconButton(
                  tooltip: 'Effacer',
                  onPressed: _clearSearch,
                  icon: const Icon(Icons.close_rounded),
                )
              : null,
        ),
      ),
    );
  }

  Widget _buildNotesContent() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_notes.isEmpty) {
      return _buildEmptyState();
    }

    return ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 110),
      itemCount: _notes.length,
      itemBuilder: (context, index) {
        final note = _notes[index];

        return _buildNoteCard(note);
      },
    );
  }

  Widget _buildEmptyState() {
    final isSearching = _searchQuery.isNotEmpty;

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        SizedBox(height: MediaQuery.of(context).size.height * 0.22),

        Center(
          child: Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.10),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isSearching ? Icons.search_off_rounded : Icons.note_alt_outlined,
              size: 48,
              color: AppColors.primary,
            ),
          ),
        ),

        const SizedBox(height: 22),

        Center(
          child: Text(
            isSearching ? 'Aucune note trouvée' : 'Aucune note',
            style: const TextStyle(
              fontSize: 21,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
        ),

        const SizedBox(height: 8),

        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40),
          child: Text(
            isSearching
                ? 'Essayez avec un autre mot-clé ou effacez votre recherche.'
                : 'Commencez à organiser vos idées en créant votre première note.',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 14,
              height: 1.5,
              color: AppColors.textSecondary,
            ),
          ),
        ),

        if (!isSearching) ...[
          const SizedBox(height: 25),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 65),
            child: ElevatedButton.icon(
              onPressed: _openAddNote,
              icon: const Icon(Icons.add),
              label: const Text('Créer une note'),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildNoteCard(Note note) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppColors.border),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => _openNote(note),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ---------------------------------------------------------------
              // TITRE + FAVORI
              // ---------------------------------------------------------------

              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      note.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                        height: 1.3,
                      ),
                    ),
                  ),

                  if (note.isFavorite)
                    Container(
                      margin: const EdgeInsets.only(left: 8),
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.amber.withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.star,
                        size: 17,
                        color: Colors.amber,
                      ),
                    ),
                ],
              ),

              const SizedBox(height: 9),

              Text(
                note.content,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 14,
                  height: 1.5,
                  color: AppColors.textSecondary,
                ),
              ),

              const SizedBox(height: 13),

              Row(
                children: [
                  const Icon(
                    Icons.access_time_rounded,
                    size: 15,
                    color: AppColors.textSecondary,
                  ),

                  const SizedBox(width: 5),

                  Text(
                    _formatDate(note.updatedAt),
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),

                  const Spacer(),

                  const Icon(
                    Icons.chevron_right_rounded,
                    size: 21,
                    color: AppColors.textSecondary,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getInitials(String name) {
    final parts = name
        .trim()
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .toList();

    if (parts.isEmpty) {
      return '?';
    }

    if (parts.length == 1) {
      return parts.first[0].toUpperCase();
    }

    return '${parts.first[0]}'
            '${parts.last[0]}'
        .toUpperCase();
  }
}
