import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/services/auth_service.dart';
import '../../../routes/app_routes.dart';
import 'auth_widgets.dart';

/// Register screen — creates a new account via POST /api/auth/register.
class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  final _authService = AuthService();

  bool _loading = false;
  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  String? _errorMessage;

  // Password strength: letters + mixed case + numbers, min 8 chars.
  static final _passwordRe = RegExp(r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d).{8,}$');

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmCtrl.dispose();
    _authService.dispose();
    super.dispose();
  }

  // ── Submit ────────────────────────────────────────────────────────────────

  Future<void> _submit() async {
    setState(() => _errorMessage = null);
    if (!_formKey.currentState!.validate()) return;
    if (_loading) return;

    setState(() => _loading = true);
    FocusScope.of(context).unfocus();

    try {
      await _authService.register(
        name: _nameCtrl.text.trim(),
        email: _emailCtrl.text.trim(),
        password: _passwordCtrl.text,
        passwordConfirmation: _confirmCtrl.text,
      );

      if (!mounted) return;
      Navigator.of(context).pushNamedAndRemoveUntil(
        AppRoutes.home,
        (route) => false,
      );
    } on ValidationException catch (e) {
      final fields = e.errors ?? {};
      final msgs = fields.values.expand((v) => v).join('\n');
      setState(() => _errorMessage = msgs.isNotEmpty ? msgs : e.message);
    } on TooManyRequestsException {
      setState(() =>
          _errorMessage = 'Too many attempts. Please try again later.');
    } on NetworkException {
      setState(() =>
          _errorMessage = 'Unable to connect to server. Please check your connection.');
    } on ServerException {
      setState(() => _errorMessage = 'Something went wrong. Please try again.');
    } on ApiException catch (e) {
      setState(() => _errorMessage = e.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ));

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 48),

                const AuthHeader(
                  icon: Icons.person_add_rounded,
                  title: 'Create account',
                  subtitle: 'Join Tripromio and find your travel companion',
                ),
                const SizedBox(height: 36),

                if (_errorMessage != null) ...[
                  AuthErrorBanner(message: _errorMessage!),
                  const SizedBox(height: 16),
                ],

                // ── Name ────────────────────────────────────────────────────
                AuthField(
                  controller: _nameCtrl,
                  label: 'Full name',
                  hint: 'Arjun Sharma',
                  keyboardType: TextInputType.name,
                  textInputAction: TextInputAction.next,
                  enabled: !_loading,
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Name is required.';
                    if (v.trim().length > 100) {
                      return 'Name must be at most 100 characters.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // ── Email ───────────────────────────────────────────────────
                AuthField(
                  controller: _emailCtrl,
                  label: 'Email address',
                  hint: 'you@example.com',
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  enabled: !_loading,
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Email is required.';
                    final re = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
                    if (!re.hasMatch(v.trim())) return 'Enter a valid email.';
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // ── Password ────────────────────────────────────────────────
                AuthField(
                  controller: _passwordCtrl,
                  label: 'Password',
                  hint: '••••••••',
                  obscureText: _obscurePassword,
                  textInputAction: TextInputAction.next,
                  enabled: !_loading,
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility_off_rounded
                          : Icons.visibility_rounded,
                      color: AppColors.textSecondaryLight,
                      size: 20,
                    ),
                    onPressed: () =>
                        setState(() => _obscurePassword = !_obscurePassword),
                  ),
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Password is required.';
                    if (v.length < 8) {
                      return 'Password must be at least 8 characters.';
                    }
                    if (!_passwordRe.hasMatch(v)) {
                      return 'Password must contain uppercase, lowercase, and a number.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // ── Confirm password ─────────────────────────────────────────
                AuthField(
                  controller: _confirmCtrl,
                  label: 'Confirm password',
                  hint: '••••••••',
                  obscureText: _obscureConfirm,
                  textInputAction: TextInputAction.done,
                  enabled: !_loading,
                  onFieldSubmitted: (_) => _submit(),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscureConfirm
                          ? Icons.visibility_off_rounded
                          : Icons.visibility_rounded,
                      color: AppColors.textSecondaryLight,
                      size: 20,
                    ),
                    onPressed: () =>
                        setState(() => _obscureConfirm = !_obscureConfirm),
                  ),
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Please confirm your password.';
                    if (v != _passwordCtrl.text) return 'Passwords do not match.';
                    return null;
                  },
                ),
                const SizedBox(height: 28),

                AuthPrimaryButton(
                  label: 'Create Account',
                  loading: _loading,
                  onPressed: _submit,
                ),
                const SizedBox(height: 24),

                // ── Sign-in link ─────────────────────────────────────────────
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Already have an account? ',
                      style: GoogleFonts.nunito(
                        fontSize: 14,
                        color: AppColors.textSecondaryLight,
                      ),
                    ),
                    GestureDetector(
                      onTap: _loading
                          ? null
                          : () => Navigator.of(context)
                              .pushReplacementNamed(AppRoutes.login),
                      child: Text(
                        'Sign in',
                        style: GoogleFonts.nunito(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
