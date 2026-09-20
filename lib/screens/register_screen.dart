import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';

import '../models/user.dart';
import '../services/auth_service.dart';
import '../utils/app_colors.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();

  final _fullNameController = TextEditingController();

  final _phoneController = TextEditingController();

  final _usernameController = TextEditingController();

  final _passwordController = TextEditingController();

  final _confirmPasswordController = TextEditingController();

  final AuthService _authService = AuthService();

  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();

    _passwordController.addListener(_onPasswordChanged);
  }

  @override
  void dispose() {
    _passwordController.removeListener(_onPasswordChanged);

    _fullNameController.dispose();
    _phoneController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();

    super.dispose();
  }

  void _onPasswordChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  int get _passwordStrength {
    final password = _passwordController.text;

    if (password.isEmpty) {
      return 0;
    }

    int score = 0;

    if (password.length >= 8) {
      score++;
    }

    if (RegExp(r'[A-Z]').hasMatch(password)) {
      score++;
    }

    if (RegExp(r'[0-9]').hasMatch(password)) {
      score++;
    }

    if (RegExp(r'[!@#$%^&*(),.?":{}|<>_\-]').hasMatch(password)) {
      score++;
    }

    return score;
  }

  String get _passwordStrengthText {
    switch (_passwordStrength) {
      case 1:
        return 'Faible';
      case 2:
        return 'Moyenne';
      case 3:
        return 'Bonne';
      case 4:
        return 'Forte';
      default:
        return '';
    }
  }

  Color get _passwordStrengthColor {
    switch (_passwordStrength) {
      case 1:
        return AppColors.error;
      case 2:
        return Colors.orange;
      case 3:
        return Colors.blue;
      case 4:
        return AppColors.success;
      default:
        return AppColors.border;
    }
  }

  Future<void> _register() async {
    FocusScope.of(context).unfocus();

    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_isLoading) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final username = _usernameController.text.trim().toLowerCase();

      final exists = await _authService.usernameExists(username);

      if (!mounted) return;

      if (exists) {
        _showMessage(
          'Ce nom d’utilisateur existe déjà. '
          'Veuillez en choisir un autre.',
          isError: true,
        );
        return;
      }

      final user = User(
        fullName: _fullNameController.text.trim(),
        phone: _phoneController.text.trim(),
        username: username,
        password: _passwordController.text,
      );

      await _authService.register(user);

      if (!mounted) return;

      _showMessage('Compte créé avec succès.');

      await Future.delayed(const Duration(milliseconds: 500));

      if (!mounted) return;

      Navigator.pop(context);
    } on DatabaseException catch (e) {
      if (!mounted) return;

      if (e.isUniqueConstraintError()) {
        _showMessage('Ce nom d’utilisateur existe déjà.', isError: true);
      } else {
        _showMessage(
          'Impossible de créer le compte. '
          'Veuillez réessayer.',
          isError: true,
        );
      }
    } catch (e) {
      if (!mounted) return;

      _showMessage(
        'Une erreur est survenue. '
        'Veuillez réessayer.',
        isError: true,
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showMessage(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? AppColors.error : AppColors.success,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,

      appBar: AppBar(
        title: const Text(
          'Créer un compte',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),

      body: SafeArea(
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            padding: const EdgeInsets.fromLTRB(24, 25, 24, 35),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(),

                const SizedBox(height: 30),

                _buildFullNameField(),

                const SizedBox(height: 18),

                _buildPhoneField(),

                const SizedBox(height: 18),

                _buildUsernameField(),

                const SizedBox(height: 18),

                _buildPasswordField(),

                const SizedBox(height: 18),

                _buildConfirmPasswordField(),

                const SizedBox(height: 30),

                _buildRegisterButton(),

                const SizedBox(height: 20),

                _buildLoginLink(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        Center(
          child: Container(
            width: 82,
            height: 82,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(24),
            ),
            child: const Icon(
              Icons.person_add_alt_1_outlined,
              size: 45,
              color: AppColors.primary,
            ),
          ),
        ),

        const SizedBox(height: 20),

        const Center(
          child: Text(
            'Bienvenue !',
            style: TextStyle(
              fontSize: 27,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
        ),

        const SizedBox(height: 8),

        const Center(
          child: Text(
            'Créez votre compte pour commencer '
            'à organiser vos notes.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              height: 1.5,
              color: AppColors.textSecondary,
            ),
          ),
        ),

        const SizedBox(height: 15),

        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.info_outline, size: 18, color: AppColors.primary),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Les champs marqués d’un * sont obligatoires.',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFullNameField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _label('Nom complet'),

        TextFormField(
          controller: _fullNameController,
          textCapitalization: TextCapitalization.words,
          textInputAction: TextInputAction.next,
          decoration: const InputDecoration(
            hintText: 'Ex. Jonathan Kola',
            prefixIcon: Icon(Icons.person_outline),
          ),
          validator: (value) {
            final text = value?.trim() ?? '';

            if (text.isEmpty) {
              return 'Veuillez saisir votre nom complet.';
            }

            if (text.length < 3) {
              return 'Le nom doit contenir au moins 3 caractères.';
            }

            return null;
          },
        ),
      ],
    );
  }

  Widget _buildPhoneField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _label('Téléphone'),

        TextFormField(
          controller: _phoneController,
          keyboardType: TextInputType.phone,
          textInputAction: TextInputAction.next,
          decoration: const InputDecoration(
            hintText: 'Ex. +243 8XX XXX XXX',
            prefixIcon: Icon(Icons.phone_outlined),
          ),
          validator: (value) {
            final text = value?.trim() ?? '';

            if (text.isEmpty) {
              return 'Veuillez saisir votre numéro.';
            }

            final digits = text.replaceAll(RegExp(r'\D'), '');

            if (digits.length < 9) {
              return 'Veuillez saisir un numéro valide.';
            }

            return null;
          },
        ),
      ],
    );
  }

  Widget _buildUsernameField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _label('Nom d’utilisateur'),

        TextFormField(
          controller: _usernameController,
          textInputAction: TextInputAction.next,
          autocorrect: false,
          decoration: const InputDecoration(
            hintText: 'Ex. jonathan.kola',
            prefixIcon: Icon(Icons.account_circle_outlined),
          ),
          validator: (value) {
            final text = value?.trim() ?? '';

            if (text.isEmpty) {
              return 'Veuillez choisir un nom d’utilisateur.';
            }

            if (text.length < 3) {
              return 'Le nom d’utilisateur doit contenir au moins 3 caractères.';
            }

            if (text.contains(' ')) {
              return 'Le nom d’utilisateur ne doit pas contenir d’espace.';
            }

            if (!RegExp(r'^[a-zA-Z0-9._-]+$').hasMatch(text)) {
              return 'Utilisez uniquement des lettres, chiffres, . _ ou -.';
            }

            return null;
          },
        ),
      ],
    );
  }

  Widget _buildPasswordField() {
    final password = _passwordController.text;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _label('Mot de passe'),

        TextFormField(
          controller: _passwordController,
          obscureText: !_isPasswordVisible,
          textInputAction: TextInputAction.next,
          autocorrect: false,
          decoration: InputDecoration(
            hintText: 'Choisissez un mot de passe',
            prefixIcon: const Icon(Icons.lock_outline),
            suffixIcon: IconButton(
              tooltip: _isPasswordVisible
                  ? 'Masquer le mot de passe'
                  : 'Afficher le mot de passe',
              onPressed: () {
                setState(() {
                  _isPasswordVisible = !_isPasswordVisible;
                });
              },
              icon: Icon(
                _isPasswordVisible
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
              ),
            ),
          ),
          validator: (value) {
            final text = value ?? '';

            if (text.isEmpty) {
              return 'Veuillez saisir un mot de passe.';
            }

            if (text.length < 8) {
              return 'Le mot de passe doit contenir au moins 8 caractères.';
            }

            return null;
          },
        ),

        if (password.isNotEmpty) _buildPasswordStrength(),

        const SizedBox(height: 6),

        const Text(
          'Utilisez au moins 8 caractères, avec des chiffres et des lettres.',
          style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
        ),
      ],
    );
  }

  Widget _buildPasswordStrength() {
    return Padding(
      padding: const EdgeInsets.only(top: 9),
      child: Row(
        children: [
          Expanded(
            child: Row(
              children: List.generate(4, (index) {
                final active = index < _passwordStrength;

                return Expanded(
                  child: Container(
                    height: 4,
                    margin: EdgeInsets.only(right: index == 3 ? 0 : 4),
                    decoration: BoxDecoration(
                      color: active ? _passwordStrengthColor : AppColors.border,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                );
              }),
            ),
          ),

          const SizedBox(width: 10),

          Text(
            _passwordStrengthText,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: _passwordStrengthColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConfirmPasswordField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _label('Confirmer le mot de passe'),

        TextFormField(
          controller: _confirmPasswordController,
          obscureText: !_isConfirmPasswordVisible,
          textInputAction: TextInputAction.done,
          autocorrect: false,
          onFieldSubmitted: (_) {
            if (!_isLoading) {
              _register();
            }
          },
          decoration: InputDecoration(
            hintText: 'Confirmez votre mot de passe',
            prefixIcon: const Icon(Icons.lock_outline),
            suffixIcon: IconButton(
              tooltip: _isConfirmPasswordVisible
                  ? 'Masquer le mot de passe'
                  : 'Afficher le mot de passe',
              onPressed: () {
                setState(() {
                  _isConfirmPasswordVisible = !_isConfirmPasswordVisible;
                });
              },
              icon: Icon(
                _isConfirmPasswordVisible
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
              ),
            ),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Veuillez confirmer votre mot de passe.';
            }

            if (value != _passwordController.text) {
              return 'Les mots de passe ne correspondent pas.';
            }

            return null;
          },
        ),
      ],
    );
  }

  Widget _buildRegisterButton() {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton.icon(
        onPressed: _isLoading ? null : _register,
        icon: _isLoading
            ? const SizedBox(
                width: 21,
                height: 21,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: Colors.white,
                ),
              )
            : const Icon(Icons.person_add_alt_1),
        label: Text(
          _isLoading ? 'Création du compte...' : 'Créer mon compte',
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }

  Widget _buildLoginLink() {
    return Center(
      child: Wrap(
        alignment: WrapAlignment.center,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          const Text(
            'Vous avez déjà un compte ?',
            style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
          ),

          TextButton(
            onPressed: _isLoading
                ? null
                : () {
                    Navigator.pop(context);
                  },
            child: const Text(
              'Se connecter',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  Widget _label(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Text(
            text,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(width: 4),
          const Text(
            '*',
            style: TextStyle(
              color: AppColors.error,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
