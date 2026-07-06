import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/primary_button.dart';
import '../../../../shared/widgets/secondary_button.dart';
import '../../../admin/presentation/pages/admin_dashboard_page.dart';
import '../../../financeiro/presentation/pages/financeiro_dashboard_page.dart';
import '../../../home/presentation/pages/home_page.dart';
import '../../../parceiro/presentation/pages/parceiro_dashboard_page.dart';
import '../bloc/auth_bloc.dart';
import '../bloc/auth_event.dart';
import '../bloc/auth_state.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/google_logo.dart';
import '../widgets/social_button.dart';
import 'register_page.dart';
import 'forgot_password_page.dart';

class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<AuthBloc>(),
      child: const LoginView(),
    );
  }
}

class LoginView extends StatefulWidget {
  const LoginView({super.key});

  @override
  State<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

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
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state.status == AuthStatus.success) {
          final Widget destination;
          switch (state.user?.role) {
            case 'admin':
              destination = const AdminDashboardPage();
            case 'financeiro':
              destination = const FinanceiroDashboardPage();
            case 'parceiro':
              destination = const ParceiroDashboardPage();
            default:
              destination = const HomePage();
          }
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => destination),
            (route) => false,
          );
        } else if (state.status == AuthStatus.failure &&
            state.errorMessage != null) {
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(
              SnackBar(content: Text(state.errorMessage!)),
            );
        }
      },
      builder: (context, state) {
        return GestureDetector(
          onTap: () {
            FocusScope.of(context).unfocus();
          },
          child: PopScope(
            canPop: false,
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

                      LayoutBuilder(
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
                                  Text(
                                    'Seja Bem Vindo(a),',
                                    style: AppTheme.headingMedium.copyWith(
                                      fontWeight: FontWeight.w500,
                                      letterSpacing: 0.12,
                                    ),
                                  ),

                                  const SizedBox(height: 9),

                                  // Subtitle
                                  Text(
                                    'Ficamos felizes em ver você novamente! Insira os dados da sua conta e acesse o Vita Clube.',
                                    style: AppTheme.bodyMedium.copyWith(
                                      color: AppTheme.secondaryText,
                                      fontSize: 14,
                                      letterSpacing: 0.07,
                                      height: 1.5,
                                    ),
                                  ),

                                  const SizedBox(height: 17),

                                  // Email field
                                  CustomTextField(
                                    label: 'E-mail',
                                    controller: _emailController,
                                    onChanged: (value) => context
                                        .read<AuthBloc>()
                                        .add(EmailChanged(value)),
                                    keyboardType: TextInputType.emailAddress,
                                    autofillHints: const [AutofillHints.email],
                                    errorText: state.emailErrorMessage,
                                  ),

                                  const SizedBox(height: 7),

                                  // Password field
                                  CustomTextField(
                                    label: 'Senha',
                                    controller: _passwordController,
                                    onChanged: (value) => context
                                        .read<AuthBloc>()
                                        .add(PasswordChanged(value)),
                                    obscureText: true,
                                    showPassword: state.isPasswordVisible,
                                    onTogglePassword: () => context
                                        .read<AuthBloc>()
                                        .add(TogglePasswordVisibility()),
                                    autofillHints: const [
                                      AutofillHints.password
                                    ],
                                    errorText: state.passwordErrorMessage ??
                                        state.serverError,
                                  ),

                                  const SizedBox(height: 19),

                                  // Enter button
                                  PrimaryButton(
                                    text: state.status == AuthStatus.loading
                                        ? 'Entrando...'
                                        : 'Entrar',
                                    onPressed:
                                        state.status == AuthStatus.loading
                                            ? null
                                            : () => context
                                                .read<AuthBloc>()
                                                .add(LoginSubmitted()),
                                  ),

                                  const SizedBox(height: 16),

                                  // Forgot password link (centered)
                                  Center(
                                    child: GestureDetector(
                                      onTap: () {
                                        Navigator.of(context).push(
                                          MaterialPageRoute(
                                            builder: (_) =>
                                                const ForgotPasswordPage(),
                                          ),
                                        );
                                      },
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(
                                            vertical: 5),
                                        child: Text(
                                          'Esqueceu a senha?',
                                          style: AppTheme.bodyMedium.copyWith(
                                            color: AppTheme.primaryText
                                                .withValues(alpha: 0.5),
                                            fontWeight: FontWeight.w500,
                                            letterSpacing: 0.07,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),

                                  const SizedBox(height: 16),

                                  // Divider with "ou"
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Container(
                                          height: 1,
                                          color: const Color(0xFF778497)
                                              .withValues(alpha: 0.3),
                                        ),
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 8),
                                        child: Text(
                                          'ou',
                                          style: AppTheme.bodyMedium.copyWith(
                                            color: AppTheme.primaryText
                                                .withValues(alpha: 0.5),
                                            fontSize: 14,
                                            letterSpacing: 0.07,
                                          ),
                                        ),
                                      ),
                                      Expanded(
                                        child: Container(
                                          height: 1,
                                          color: const Color(0xFF778597)
                                              .withValues(alpha: 0.3),
                                        ),
                                      ),
                                    ],
                                  ),

                                  const SizedBox(height: 16),

                                  // Create Account button
                                  SecondaryButton(
                                    text: 'Criar Conta',
                                    onPressed: () {
                                      Navigator.of(context).push(
                                        MaterialPageRoute(
                                            builder: (_) =>
                                                const RegisterPage()),
                                      );
                                    },
                                  ),

                                  const SizedBox(height: 16),

                                  // Google Sign-in button
                                  SocialButton(
                                    text: 'Continuar com o Google',
                                    leading: const GoogleLogo(size: 20),
                                    onPressed:
                                        state.status == AuthStatus.loading
                                            ? null
                                            : () => context
                                                .read<AuthBloc>()
                                                .add(GoogleSignInPressed()),
                                  ),

                                  const SizedBox(height: 24),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
