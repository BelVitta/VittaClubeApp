import 'package:flutter/material.dart';

import '../../../../core/di/injection_container.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/primary_button.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../domain/usecases/update_password_usecase.dart';
import '../widgets/custom_text_field.dart';
import 'login_page.dart';

/// Define nova senha após o link de recovery do e-mail.
class ResetPasswordPage extends StatefulWidget {
  /// Sessão já estabelecida pelo deep link (fluxo correto do Supabase).
  final bool fromRecoveryLink;

  /// Legado — ignorado no fluxo real (Supabase não usa código de 6 dígitos).
  final String? email;
  final String? code;

  const ResetPasswordPage({
    super.key,
    this.fromRecoveryLink = false,
    this.email,
    this.code,
  });

  @override
  State<ResetPasswordPage> createState() => _ResetPasswordPageState();
}

class _ResetPasswordPageState extends State<ResetPasswordPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;
  bool _isLoading = false;
  String? _errorMessage;
  String? _successMessage;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _resetPassword() async {
    FocusScope.of(context).unfocus();
    setState(() {
      _errorMessage = null;
      _successMessage = null;
      _isLoading = true;
    });

    final result = await sl<UpdatePasswordUseCase>()(
      newPassword: _passwordController.text,
      confirmPassword: _confirmPasswordController.text,
    );

    if (!mounted) return;

    await result.fold(
      (failure) async {
        setState(() {
          _isLoading = false;
          _errorMessage = failure.message;
        });
      },
      (_) async {
        setState(() {
          _isLoading = false;
          _successMessage = 'Senha redefinida com sucesso!';
        });
        // Encerra sessão de recovery e manda para login limpo.
        try {
          await sl<AuthRepository>().logout();
        } catch (_) {}
        await Future<void>.delayed(const Duration(milliseconds: 900));
        if (!mounted) return;
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const LoginPage()),
          (route) => false,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        backgroundColor: AppTheme.backgroundColor,
        body: SafeArea(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: Stack(
              children: [
                Positioned(
                  top: -60,
                  left: -40,
                  right: -40,
                  child: Container(
                    height: 340,
                    decoration: BoxDecoration(
                      borderRadius: const BorderRadius.vertical(
                        bottom: Radius.circular(220),
                      ),
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          AppTheme.gradientLight.withValues(alpha: 0.65),
                          AppTheme.gradientLight.withValues(alpha: 0.32),
                          AppTheme.gradientLight.withValues(alpha: 0.0),
                        ],
                        stops: const [0.0, 0.55, 1.0],
                      ),
                    ),
                  ),
                ),
                Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
                      child: Row(
                        children: [
                          GestureDetector(
                            onTap: () {
                              if (Navigator.canPop(context)) {
                                Navigator.pop(context);
                              }
                            },
                            child: Container(
                              width: 39,
                              height: 39,
                              decoration: BoxDecoration(
                                color: const Color(0xFF01225B)
                                    .withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(19.5),
                              ),
                              child: const Icon(
                                Icons.arrow_back,
                                size: 20,
                                color: AppTheme.primaryColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 24),
                            Text(
                              'Nova senha',
                              style: AppTheme.headingMedium.copyWith(
                                fontWeight: FontWeight.w500,
                                letterSpacing: 0.12,
                              ),
                            ),
                            const SizedBox(height: 9),
                            Text(
                              'Defina uma nova senha para a conta (mínimo 6 caracteres). '
                              'Depois use e-mail e senha no login.',
                              style: AppTheme.bodyMedium.copyWith(
                                color: AppTheme.secondaryText,
                                fontSize: 14,
                                height: 1.5,
                              ),
                            ),
                            const SizedBox(height: 32),
                            CustomTextField(
                              label: 'Nova Senha',
                              controller: _passwordController,
                              obscureText: true,
                              showPassword: _isPasswordVisible,
                              onTogglePassword: () {
                                setState(() {
                                  _isPasswordVisible = !_isPasswordVisible;
                                });
                              },
                              autofillHints: const [AutofillHints.newPassword],
                            ),
                            const SizedBox(height: 7),
                            CustomTextField(
                              label: 'Confirme a Nova Senha',
                              controller: _confirmPasswordController,
                              obscureText: true,
                              showPassword: _isConfirmPasswordVisible,
                              onTogglePassword: () {
                                setState(() {
                                  _isConfirmPasswordVisible =
                                      !_isConfirmPasswordVisible;
                                });
                              },
                              autofillHints: const [AutofillHints.newPassword],
                            ),
                            if (_errorMessage != null) ...[
                              const SizedBox(height: 12),
                              _Banner(
                                message: _errorMessage!,
                                isError: true,
                              ),
                            ],
                            if (_successMessage != null) ...[
                              const SizedBox(height: 12),
                              _Banner(
                                message: _successMessage!,
                                isError: false,
                              ),
                            ],
                            const SizedBox(height: 24),
                            PrimaryButton(
                              text: _isLoading
                                  ? 'Redefinindo...'
                                  : 'Redefinir Senha',
                              onPressed: _isLoading ? null : _resetPassword,
                            ),
                            const SizedBox(height: 24),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Banner extends StatelessWidget {
  final String message;
  final bool isError;

  const _Banner({required this.message, required this.isError});

  @override
  Widget build(BuildContext context) {
    final color = isError ? AppTheme.errorColor : AppTheme.successColor;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Text(
        message,
        style: TextStyle(color: color, fontSize: 13, height: 1.35),
      ),
    );
  }
}
