import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/primary_button.dart';
import '../bloc/auth_bloc.dart';
import '../bloc/auth_event.dart';
import '../bloc/auth_state.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/google_logo.dart';
import '../widgets/social_button.dart';
import '../../../home/presentation/pages/home_page.dart';

class RegisterPage extends StatelessWidget {
  const RegisterPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<AuthBloc>(),
      child: const RegisterView(),
    );
  }
}

class RegisterView extends StatefulWidget {
  const RegisterView({super.key});

  @override
  State<RegisterView> createState() => _RegisterViewState();
}

class _RegisterViewState extends State<RegisterView>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  final _nameController = TextEditingController();
  final _cpfController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

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
    _nameController.dispose();
    _cpfController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state.status == AuthStatus.success) {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => const HomePage()),
            (route) => false,
          );
        }
      },
      builder: (context, state) {
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
                                    color: const Color(0xFF01225B).withValues(alpha: 0.2),
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
                                  'Crie sua conta,',
                                  style: AppTheme.headingMedium.copyWith(
                                    fontWeight: FontWeight.w500,
                                    letterSpacing: 0.12,
                                  ),
                                ),

                                const SizedBox(height: 9),

                                // Subtitle
                                Text(
                                  'Cadastre-se e comece a aproveitar as vantagens exclusivas do Vita Clube.',
                                  style: AppTheme.bodyMedium.copyWith(
                                    color: AppTheme.primaryText.withValues(alpha: 0.5),
                                    fontSize: 14,
                                    letterSpacing: 0.07,
                                    height: 1.5,
                                  ),
                                ),

                                const SizedBox(height: 17),

                                // Form fields
                                CustomTextField(
                                  label: 'Nome Completo',
                                  controller: _nameController,
                                  onChanged: (value) =>
                                      context.read<AuthBloc>().add(NameChanged(value)),
                                  keyboardType: TextInputType.name,
                                  autofillHints: const [AutofillHints.name],
                                  errorText: state.nameErrorMessage,
                                ),

                                const SizedBox(height: 7),

                                CustomTextField(
                                  label: 'CPF',
                                  controller: _cpfController,
                                  onChanged: (value) =>
                                      context.read<AuthBloc>().add(CpfChanged(value)),
                                  keyboardType: TextInputType.number,
                                  errorText: state.cpfErrorMessage,
                                ),

                                const SizedBox(height: 7),

                                CustomTextField(
                                  label: 'Telefone',
                                  controller: _phoneController,
                                  onChanged: (value) =>
                                      context.read<AuthBloc>().add(PhoneChanged(value)),
                                  keyboardType: TextInputType.phone,
                                  autofillHints: const [AutofillHints.telephoneNumber],
                                  errorText: state.phoneErrorMessage,
                                ),

                                const SizedBox(height: 7),

                                CustomTextField(
                                  label: 'E-mail',
                                  controller: _emailController,
                                  onChanged: (value) =>
                                      context.read<AuthBloc>().add(EmailChanged(value)),
                                  keyboardType: TextInputType.emailAddress,
                                  autofillHints: const [AutofillHints.email],
                                  errorText: state.emailErrorMessage,
                                ),

                                const SizedBox(height: 7),

                                CustomTextField(
                                  label: 'Senha',
                                  controller: _passwordController,
                                  onChanged: (value) =>
                                      context.read<AuthBloc>().add(PasswordChanged(value)),
                                  obscureText: true,
                                  showPassword: state.isPasswordVisible,
                                  onTogglePassword: () =>
                                      context.read<AuthBloc>().add(TogglePasswordVisibility()),
                                  autofillHints: const [AutofillHints.newPassword],
                                  errorText: state.passwordErrorMessage,
                                ),

                                const SizedBox(height: 7),

                                CustomTextField(
                                  label: 'Confirme a senha',
                                  controller: _confirmPasswordController,
                                  onChanged: (value) => context
                                      .read<AuthBloc>()
                                      .add(ConfirmPasswordChanged(value)),
                                  obscureText: true,
                                  showPassword: state.isConfirmPasswordVisible,
                                  onTogglePassword: () => context
                                      .read<AuthBloc>()
                                      .add(ToggleConfirmPasswordVisibility()),
                                  autofillHints: const [AutofillHints.newPassword],
                                  errorText: state.confirmPasswordErrorMessage,
                                ),

                                const SizedBox(height: 19),

                                // Create Account button
                                PrimaryButton(
                                  text: state.status == AuthStatus.loading
                                      ? 'Criando...'
                                      : 'Criar Conta',
                                  onPressed: state.status == AuthStatus.loading
                                      ? null
                                      : () =>
                                          context.read<AuthBloc>().add(RegisterSubmitted()),
                                ),

                                if (state.serverError != null)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 8),
                                    child: Text(
                                      state.serverError!,
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        color: Theme.of(context).colorScheme.error,
                                        fontSize: 13,
                                        height: 1.4,
                                      ),
                                    ),
                                  ),

                                const SizedBox(height: 16),

                                // Terms and conditions
                                Center(
                                  child: RichText(
                                    textAlign: TextAlign.center,
                                    text: TextSpan(
                                      style: AppTheme.bodyMedium.copyWith(
                                        fontSize: 14,
                                        letterSpacing: 0.07,
                                        height: 1.5,
                                        color: const Color(0xFF7D8899),
                                      ),
                                      children: [
                                        const TextSpan(
                                          text: 'Ao se cadastrar, você concorda com nossos ',
                                        ),
                                        TextSpan(
                                          text: 'Termos e Condições de Uso.',
                                          style: const TextStyle(
                                            color: AppTheme.primaryColor,
                                          ),
                                          recognizer: TapGestureRecognizer()
                                            ..onTap = () {
                                              // TODO: Navigate to terms and conditions
                                              ScaffoldMessenger.of(context).showSnackBar(
                                                const SnackBar(
                                                  content: Text('Abrir Termos e Condições'),
                                                ),
                                              );
                                            },
                                        ),
                                      ],
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
                                        color: const Color(0xFF778497).withValues(alpha: 0.3),
                                      ),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 8),
                                      child: Text(
                                        'ou',
                                        style: AppTheme.bodyMedium.copyWith(
                                          color: AppTheme.primaryText.withValues(alpha: 0.5),
                                          fontSize: 14,
                                          letterSpacing: 0.07,
                                        ),
                                      ),
                                    ),
                                    Expanded(
                                      child: Container(
                                        height: 1,
                                        color: const Color(0xFF778597).withValues(alpha: 0.3),
                                      ),
                                    ),
                                  ],
                                ),

                                const SizedBox(height: 16),

                                // Google Sign-in button
                                SocialButton(
                                  text: 'Continuar com o Google',
                                  leading: const GoogleLogo(size: 20),
                                  onPressed: () =>
                                      context.read<AuthBloc>().add(GoogleSignInPressed()),
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
      },
    );
  }
}
