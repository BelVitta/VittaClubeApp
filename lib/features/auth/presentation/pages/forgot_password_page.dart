import 'package:flutter/material.dart';

import '../../../../core/di/injection_container.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/primary_button.dart';
import '../../domain/usecases/request_password_reset_usecase.dart';
import '../widgets/custom_text_field.dart';

/// Solicita e-mail de recuperação (Supabase Auth + SMTP/Resend).
/// O Supabase envia um **link**, não um código de 6 dígitos.
class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  final _emailController = TextEditingController();
  bool _isLoading = false;
  bool _emailSent = false;
  String? _errorMessage;

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
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _sendResetEmail() async {
    FocusScope.of(context).unfocus();
    setState(() {
      _errorMessage = null;
      _isLoading = true;
    });

    final result =
        await sl<RequestPasswordResetUseCase>()(_emailController.text);

    if (!mounted) return;

    result.fold(
      (failure) {
        setState(() {
          _isLoading = false;
          _errorMessage = failure.message;
        });
      },
      (_) {
        setState(() {
          _isLoading = false;
          _emailSent = true;
        });
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
                        child: _emailSent ? _buildSentState() : _buildForm(),
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

  Widget _buildForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 24),
        Text(
          'Esqueceu a senha?',
          style: AppTheme.headingMedium.copyWith(
            fontWeight: FontWeight.w500,
            letterSpacing: 0.12,
          ),
        ),
        const SizedBox(height: 9),
        Text(
          'Enviaremos um link de redefinição para o e-mail da conta. '
          'Contas que entram só com Google não têm senha — use “Continuar com o Google”.',
          style: AppTheme.bodyMedium.copyWith(
            color: AppTheme.secondaryText,
            fontSize: 14,
            letterSpacing: 0.07,
            height: 1.5,
          ),
        ),
        const SizedBox(height: 32),
        CustomTextField(
          label: 'E-mail',
          controller: _emailController,
          keyboardType: TextInputType.emailAddress,
          autofillHints: const [AutofillHints.email],
        ),
        if (_errorMessage != null) ...[
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.errorColor.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppTheme.errorColor.withValues(alpha: 0.35),
              ),
            ),
            child: Text(
              _errorMessage!,
              style: TextStyle(
                color: AppTheme.errorColor,
                fontSize: 13,
                height: 1.35,
              ),
            ),
          ),
        ],
        const SizedBox(height: 24),
        PrimaryButton(
          text: _isLoading ? 'Enviando...' : 'Enviar link',
          onPressed: _isLoading ? null : _sendResetEmail,
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildSentState() {
    final email = _emailController.text.trim();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 24),
        Icon(Icons.mark_email_read_outlined,
            size: 48, color: AppTheme.primaryColor),
        const SizedBox(height: 16),
        Text(
          'Verifique seu e-mail',
          style: AppTheme.headingMedium.copyWith(
            fontWeight: FontWeight.w500,
            letterSpacing: 0.12,
          ),
        ),
        const SizedBox(height: 9),
        Text(
          'Se existir uma conta com $email, enviamos um link para redefinir a senha. '
          'Abra o e-mail no celular e toque no link para voltar ao app.',
          style: AppTheme.bodyMedium.copyWith(
            color: AppTheme.secondaryText,
            fontSize: 14,
            height: 1.5,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'Não recebeu? Confira spam e se o e-mail é o mesmo do cadastro. '
          'Quem só usa Google deve entrar com Google.',
          style: AppTheme.bodyMedium.copyWith(
            color: AppTheme.secondaryText,
            fontSize: 13,
            height: 1.45,
          ),
        ),
        const SizedBox(height: 24),
        PrimaryButton(
          text: 'Voltar ao login',
          onPressed: () => Navigator.of(context).pop(),
        ),
        const SizedBox(height: 12),
        Center(
          child: TextButton(
            onPressed: _isLoading
                ? null
                : () {
                    setState(() => _emailSent = false);
                  },
            child: Text(
              'Usar outro e-mail',
              style: TextStyle(color: AppTheme.primaryColor),
            ),
          ),
        ),
      ],
    );
  }
}
