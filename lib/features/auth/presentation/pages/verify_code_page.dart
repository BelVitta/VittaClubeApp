import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/primary_button.dart';
import '../widgets/pin_code_input.dart';
import 'reset_password_page.dart';

/// Tela de Verificação de Código - 6 dígitos
class VerifyCodePage extends StatefulWidget {
  final String email;

  const VerifyCodePage({
    super.key,
    required this.email,
  });

  @override
  State<VerifyCodePage> createState() => _VerifyCodePageState();
}

class _VerifyCodePageState extends State<VerifyCodePage>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  String _code = '';
  bool _isLoading = false;
  bool _canResend = false;
  int _resendTimer = 60;

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

    // Inicia timer para reenvio
    _startResendTimer();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _startResendTimer() {
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted && _resendTimer > 0) {
        setState(() => _resendTimer--);
        _startResendTimer();
      } else if (mounted) {
        setState(() => _canResend = true);
      }
    });
  }

  void _verifyCode() async {
    if (_code.length != 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor, insira o código de 6 dígitos')),
      );
      return;
    }

    setState(() => _isLoading = true);

    // Simula verificação de código (TODO: integrar com API)
    await Future.delayed(const Duration(seconds: 2));

    setState(() => _isLoading = false);

    if (mounted) {
      // TODO: Verificar se o código está correto
      // Por enquanto, aceita qualquer código de 6 dígitos
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => ResetPasswordPage(
            email: widget.email,
            code: _code,
          ),
        ),
      );
    }
  }

  void _resendCode() async {
    if (!_canResend) return;

    setState(() {
      _canResend = false;
      _resendTimer = 60;
    });

    _startResendTimer();

    // Simula reenvio de código (TODO: integrar com API)
    await Future.delayed(const Duration(seconds: 1));

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Código reenviado com sucesso!')),
      );
    }
  }

  String _getMaskedEmail() {
    final parts = widget.email.split('@');
    if (parts.length != 2) return widget.email;

    final username = parts[0];
    final domain = parts[1];

    if (username.length <= 2) {
      return '${username[0]}***@$domain';
    }

    final visibleChars = username.substring(0, 2);
    return '$visibleChars***@$domain';
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
                              'Insira o Código,',
                              style: AppTheme.headingMedium.copyWith(
                                fontWeight: FontWeight.w500,
                                letterSpacing: 0.12,
                              ),
                            ),

                            const SizedBox(height: 9),

                            // Subtitle with email
                            RichText(
                              text: TextSpan(
                                style: AppTheme.bodyMedium.copyWith(
                                  color: AppTheme.secondaryText,
                                  fontSize: 14,
                                  letterSpacing: 0.07,
                                  height: 1.5,
                                ),
                                children: [
                                  const TextSpan(
                                    text:
                                        'Enviamos um código de 6 dígitos para o seu email: ',
                                  ),
                                  TextSpan(
                                    text: _getMaskedEmail(),
                                    style: const TextStyle(
                                      color: AppTheme.primaryColor,
                                    ),
                                  ),
                                  const TextSpan(text: '.'),
                                ],
                              ),
                            ),

                            const SizedBox(height: 32),

                            // PIN Code Input (6 digits)
                            SizedBox(
                              height: 65,
                              child: PinCodeInput(
                                length: 6,
                                onChanged: (code) {
                                  setState(() => _code = code);
                                },
                                onCompleted: (code) {
                                  setState(() => _code = code);
                                  // Auto-submit quando completar
                                  // _verifyCode();
                                },
                              ),
                            ),

                            const SizedBox(height: 24),

                            // Verify button
                            PrimaryButton(
                              text: _isLoading ? 'Verificando...' : 'Continuar',
                              onPressed: _isLoading ? null : _verifyCode,
                            ),

                            const SizedBox(height: 16),

                            // Resend code link
                            Center(
                              child: RichText(
                                textAlign: TextAlign.center,
                                text: TextSpan(
                                  style: AppTheme.bodyMedium.copyWith(
                                    fontSize: 14,
                                    letterSpacing: 0.07,
                                    height: 1.5,
                                    color: AppTheme.secondaryText,
                                  ),
                                  children: [
                                    const TextSpan(
                                      text: 'Não recebeu o código? ',
                                    ),
                                    TextSpan(
                                      text: _canResend
                                          ? 'Reenviar'
                                          : 'Reenviar em ${_resendTimer}s',
                                      style: TextStyle(
                                        color: _canResend
                                            ? AppTheme.primaryColor
                                            : AppTheme.secondaryText,
                                        fontWeight: _canResend
                                            ? FontWeight.w600
                                            : FontWeight.normal,
                                      ),
                                      recognizer: _canResend
                                          ? (TapGestureRecognizer()
                                            ..onTap = _resendCode)
                                          : null,
                                    ),
                                  ],
                                ),
                              ),
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
