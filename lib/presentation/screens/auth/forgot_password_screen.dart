import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/services/auth_service.dart';
import 'auth_widgets.dart';

/// Forgot-password screen — sends a password reset link via
/// POST /api/auth/forgot-password.
class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _authService = AuthService();

  bool _loading = false;
  bool _sent = false;
  String? _errorMessage;
  String? _successMessage;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _authService.dispose();
    super.dispose();
  }

  // ── Submit ────────────────────────────────────────────────────────────────

  Future<void> _submit() async {
    setState(() {
      _errorMessage = null;
      _successMessage = null;
    });

    if (!_formKey.currentState!.validate()) return;
    if (_loading) return;

    setState(() => _loading = true);
    FocusScope.of(context).unfocus();

    try {
      final message = await _authService.forgotPassword(
        email: _emailCtrl.text.trim(),
      );
      if (!mounted) return;
      setState(() {
        _sent = true;
        _successMessage = message.isNotEmpty
            ? message
            : 'If an account exists for this email, password reset instructions have been sent.';
      });
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
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          color: AppColors.textPrimaryLight,
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 16),

                const AuthHeader(
                  icon: Icons.lock_reset_rounded,
                  title: 'Reset password',
                  subtitle: "Enter your email and we'll send you a reset link",
                ),
                const SizedBox(height: 36),

                if (_sent && _successMessage != null) ...[
                  AuthSuccessBanner(message: _successMessage!),
                  const SizedBox(height: 24),
                ],

                if (_errorMessage != null) ...[
                  AuthErrorBanner(message: _errorMessage!),
                  const SizedBox(height: 16),
                ],

                if (!_sent) ...[
                  AuthField(
                    controller: _emailCtrl,
                    label: 'Email address',
                    hint: 'you@example.com',
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.done,
                    enabled: !_loading,
                    onFieldSubmitted: (_) => _submit(),
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) return 'Email is required.';
                      final re = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
                      if (!re.hasMatch(v.trim())) return 'Enter a valid email.';
                      return null;
                    },
                  ),
                  const SizedBox(height: 28),

                  AuthPrimaryButton(
                    label: 'Send Reset Link',
                    loading: _loading,
                    onPressed: _submit,
                  ),
                ] else ...[
                  ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Back to Sign In'),
                  ),
                ],
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
