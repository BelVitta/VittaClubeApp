import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/primary_button.dart';
import '../widgets/custom_text_field.dart';
import 'login_page.dart';

/// Tela de Redefinir Senha - Define nova senha
class ResetPasswordPage extends StatefulWidget {
  final String email;
  final String code;

  const ResetPasswordPage({
    super.key,
    required this.email,
    required this.code,
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

  void _resetPassword() async {
    if (_passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor, insira sua nova senha')),
      );
      return;
    }

    if (_passwordController.text.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('A senha deve ter no mínimo 6 caracteres')),
      );
      return;
    }

    if (_passwordController.text != _confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('As senhas não coincidem')),
      );
      return;
    }

    setState(() => _isLoading = true);

    // Simula redefinição de senha (TODO: integrar com API)
    await Future.delayed(const Duration(seconds: 2));

    setState(() => _isLoading = false);

    if (mounted) {
      // Mostra mensagem de sucesso
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Senha redefinida com sucesso!'),
          backgroundColor: AppTheme.successColor,
        ),
      );

      // Aguarda um pouco e navega para login
      await Future.delayed(const Duration(seconds: 1));

      if (mounted) {
        // Remove todas as rotas e vai para login
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const LoginPage()),
          (route) => false,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
      },
      child: Scaffold(
        backgroundColor: AppTheme.backgroundColor,
        body: SafeArea(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: Stack(
              children: [
                // Decorative gradient circle in top right
                Positioned(
                  top: -100,
                  right: -100,
                  child: Container(
                    width: 300,
                    height: 300,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          AppTheme.gradientLight.withValues(alpha: 0.4),
                          AppTheme.gradientLight.withValues(alpha: 0.2),
                          AppTheme.gradientLight.withValues(alpha: 0.0),
                        ],
                        stops: const [0.0, 0.5, 1.0],
                      ),
                    ),
                  ),
                ),

                // Main content
                Column(
                  children: [
                    // Top bar with back button
                    Padding(
                      padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
                      child: Row(
                        children: [
                          // Back button
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

                    // Scrollable content
                    Expanded(
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          return SingleChildScrollView(
                            padding: const EdgeInsets.all(24),
                            child: ConstrainedBox(
                              constraints: BoxConstraints(
                                minHeight: constraints.maxHeight - 48,
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                            // Title
                            Text(
                              'Nova Senha,',
                              style: AppTheme.headingMedium.copyWith(
                                fontWeight: FontWeight.w500,
                                letterSpacing: 0.12,
                              ),
                            ),

                            const SizedBox(height: 9),

                            // Subtitle
                            Text(
                              'Defina uma nova senha segura para sua conta. A senha deve ter no mínimo 8 caracteres, com letras e números.',
                              style: AppTheme.bodyMedium.copyWith(
                                color: AppTheme.secondaryText,
                                fontSize: 14,
                                letterSpacing: 0.07,
                                height: 1.5,
                              ),
                            ),

                            const SizedBox(height: 32),

                            // Password field
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

                            // Confirm Password field
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

                            const SizedBox(height: 24),

                            // Reset Password button
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
                          );
                        },
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
