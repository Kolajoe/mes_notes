import 'package:flutter/material.dart';

import '../models/note.dart';
import '../models/user.dart';
import '../services/auth_service.dart';
import '../services/note_service.dart';
import '../utils/app_colors.dart';
import 'login_screen.dart';
import 'note_detail_screen.dart';

class MenuScreen extends StatefulWidget {
  final User user;

  const MenuScreen({super.key, required this.user});

  @override
  State<MenuScreen> createState() => _MenuScreenState();
}

class _MenuScreenState extends State<MenuScreen> {
  final NoteService _noteService = NoteService();

  int _favoriteCount = 0;
  int _archiveCount = 0;

  @override
  void initState() {
    super.initState();
    _loadStatistics();
  }

  Future<void> _loadStatistics() async {
    try {
      final favorites = await _noteService.getFavorites(widget.user.id!);

      final archives = await _noteService.getArchives(widget.user.id!);

      if (!mounted) return;

      setState(() {
        _favoriteCount = favorites.length;
        _archiveCount = archives.length;
      });
    } catch (e) {
      if (!mounted) return;

      _showMessage(
        'Impossible de charger les informations du menu.',
        isError: true,
      );
    }
  }

  Future<void> _showFavorites() async {
    try {
      final notes = await _noteService.getFavorites(widget.user.id!);

      if (!mounted) return;

      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => NotesCategoryScreen(
            title: 'Favoris',
            notes: notes,
            user: widget.user,
            emptyMessage: 'Aucune note favorite.',
            emptyIcon: Icons.star_border_rounded,
          ),
        ),
      );

      await _loadStatistics();
    } catch (e) {
      if (!mounted) return;

      _showMessage('Impossible de charger les favoris.', isError: true);
    }
  }

  Future<void> _showArchives() async {
    try {
      final notes = await _noteService.getArchives(widget.user.id!);

      if (!mounted) return;

      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => NotesCategoryScreen(
            title: 'Archives',
            notes: notes,
            user: widget.user,
            emptyMessage: 'Aucune note archivée.',
            emptyIcon: Icons.archive_outlined,
          ),
        ),
      );

      await _loadStatistics();
    } catch (e) {
      if (!mounted) return;

      _showMessage('Impossible de charger les archives.', isError: true);
    }
  }

  Future<void> _logout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text(
            'Déconnexion',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          content: const Text(
            'Voulez-vous vraiment vous déconnecter de votre compte ?',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context, false);
              },
              child: const Text('Annuler'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.error,
                foregroundColor: Colors.white,
              ),
              onPressed: () {
                Navigator.pop(context, true);
              },
              child: const Text('Se déconnecter'),
            ),
          ],
        );
      },
    );

    if (confirmed != true || !mounted) {
      return;
    }

    await _logoutFromSession();
  }

  Future<void> _logoutFromSession() async {
    try {
      final authService = AuthService();

      await authService.logout();

      if (!mounted) return;

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false,
      );
    } catch (e) {
      if (!mounted) return;

      _showMessage('Impossible de fermer la session.', isError: true);
    }
  }

  void _showMessage(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? AppColors.error : AppColors.success,
      ),
    );
  }

  void _goBackToNotes() {
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,

      appBar: AppBar(
        title: const Text(
          'Menu',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),

      body: RefreshIndicator(
        onRefresh: _loadStatistics,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 35),
          children: [
            _buildProfileHeader(),

            const SizedBox(height: 25),

            _buildSectionTitle('Mes notes'),

            const SizedBox(height: 10),

            _buildMenuItem(
              icon: Icons.note_alt_outlined,
              title: 'Toutes les notes',
              subtitle: 'Retourner à la liste de vos notes',
              onTap: _goBackToNotes,
            ),

            _buildMenuItem(
              icon: Icons.star_outline_rounded,
              title: 'Favoris',
              subtitle: 'Consulter vos notes favorites',
              trailing: _buildCountBadge(
                _favoriteCount,
                color: Colors.amber.shade700,
              ),
              onTap: _showFavorites,
            ),

            _buildMenuItem(
              icon: Icons.archive_outlined,
              title: 'Archives',
              subtitle: 'Consulter vos notes archivées',
              trailing: _buildCountBadge(
                _archiveCount,
                color: AppColors.primary,
              ),
              onTap: _showArchives,
            ),

            const SizedBox(height: 25),

            _buildSectionTitle('Compte'),

            const SizedBox(height: 10),

            _buildMenuItem(
              icon: Icons.person_outline_rounded,
              title: 'Mon profil',
              subtitle: 'Informations de votre compte',
              onTap: _showProfileInformation,
            ),

            const SizedBox(height: 18),

            _buildLogoutButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.primary, AppColors.primaryDark],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.18),
            blurRadius: 15,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 31,
            backgroundColor: Colors.white.withValues(alpha: 0.20),
            child: Text(
              _initials(widget.user.fullName),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 19,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),

          const SizedBox(width: 15),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Bonjour 👋',
                  style: TextStyle(color: Colors.white70, fontSize: 13),
                ),

                const SizedBox(height: 4),

                Text(
                  widget.user.fullName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 19,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 4),

                Text(
                  '@${widget.user.username}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.white70, fontSize: 13),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w700,
        color: AppColors.textSecondary,
      ),
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    Widget? trailing,
    Color? iconColor,
  }) {
    final color = iconColor ?? AppColors.primary;

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppColors.border),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
          child: Row(
            children: [
              Container(
                width: 47,
                height: 47,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(icon, color: color, size: 24),
              ),

              const SizedBox(width: 14),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),

                    const SizedBox(height: 4),

                    Text(
                      subtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 8),

              ?trailing,

              const SizedBox(width: 5),

              const Icon(
                Icons.chevron_right_rounded,
                color: AppColors.textSecondary,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCountBadge(int count, {required Color color}) {
    return Container(
      constraints: const BoxConstraints(minWidth: 30),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        '$count',
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
  }

  Widget _buildLogoutButton() {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: OutlinedButton.icon(
        onPressed: _logout,
        icon: const Icon(Icons.logout_rounded),
        label: const Text(
          'Se déconnecter',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.error,
          side: const BorderSide(color: AppColors.error),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  void _showProfileInformation() {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      backgroundColor: Colors.white,
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 10, 24, 25),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircleAvatar(
                  radius: 32,
                  backgroundColor: AppColors.primary.withValues(alpha: 0.10),
                  child: Text(
                    _initials(widget.user.fullName),
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),

                const SizedBox(height: 15),

                Text(
                  widget.user.fullName,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),

                const SizedBox(height: 5),

                Text(
                  '@${widget.user.username}',
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                  ),
                ),

                const SizedBox(height: 20),

                _buildProfileRow(
                  Icons.phone_outlined,
                  'Téléphone',
                  widget.user.phone,
                ),

                const SizedBox(height: 10),

                _buildProfileRow(
                  Icons.person_outline_rounded,
                  'Nom d’utilisateur',
                  widget.user.username,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildProfileRow(IconData icon, String label, String value) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, size: 21, color: AppColors.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _initials(String name) {
    final parts = name
        .trim()
        .split(RegExp(r'\s+'))
        .where((element) => element.isNotEmpty)
        .toList();

    if (parts.isEmpty) {
      return '?';
    }

    if (parts.length == 1) {
      return parts.first[0].toUpperCase();
    }

    return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
  }
}

// ============================================================
// Écran commun pour les catégories Favoris / Archives
// ============================================================

class NotesCategoryScreen extends StatefulWidget {
  final String title;
  final List<Note> notes;
  final User user;
  final String emptyMessage;
  final IconData emptyIcon;

  const NotesCategoryScreen({
    super.key,
    required this.title,
    required this.notes,
    required this.user,
    required this.emptyMessage,
    required this.emptyIcon,
  });

  @override
  State<NotesCategoryScreen> createState() => _NotesCategoryScreenState();
}

class _NotesCategoryScreenState extends State<NotesCategoryScreen> {
  late List<Note> _notes;

  @override
  void initState() {
    super.initState();
    _notes = List<Note>.from(widget.notes);
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

  Future<void> _openNote(Note note) async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => NoteDetailScreen(note: note, user: widget.user),
      ),
    );

    if (!mounted) return;

    if (result == true) {
      Navigator.pop(context, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,

      appBar: AppBar(
        title: Text(
          widget.title,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ),

      body: _notes.isEmpty
          ? _buildEmptyState()
          : ListView.builder(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 30),
              itemCount: _notes.length,
              itemBuilder: (context, index) {
                final note = _notes[index];

                return _buildNoteCard(note);
              },
            ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(30),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 95,
              height: 95,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.10),
                shape: BoxShape.circle,
              ),
              child: Icon(widget.emptyIcon, size: 48, color: AppColors.primary),
            ),

            const SizedBox(height: 22),

            Text(
              widget.emptyMessage,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),

            const SizedBox(height: 8),

            const Text(
              'Les notes que vous ajouterez ici apparaîtront dans cette section.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                height: 1.5,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
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
}
