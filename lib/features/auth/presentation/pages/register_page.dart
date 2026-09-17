import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/services/push_notification_service.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/input_formatters.dart';
import '../../../../shared/widgets/primary_button.dart';
import '../bloc/auth_bloc.dart';
import '../bloc/auth_event.dart';
import '../bloc/auth_state.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/google_logo.dart';
import '../widgets/social_button.dart';
import '../../../../core/utils/validators.dart';
import '../../../home/presentation/pages/home_page.dart';
import '../../../profile/presentation/pages/personal_data_page.dart';
import '../../../../shared/widgets/legal_document_page.dart';

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
  final _receptionistCodeController = TextEditingController();
  bool _acceptedLegal = false;

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
    _receptionistCodeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state.status == AuthStatus.success) {
          unawaited(sl<PushNotificationService>().start());
          final user = state.user;
          final needsCompletion = user == null ||
              !Validators.isValidCpf(user.cpf) ||
              !Validators.isValidPhone(user.phone);
          final destination = needsCompletion
              ? PersonalDataPage(
                  requiredCompletion: true,
                  initialName: user?.name ?? state.name,
                  initialEmail: user?.email ?? state.email,
                  initialCpf:
                      user?.cpf.isNotEmpty == true ? user!.cpf : state.cpf,
                  initialPhone: user?.phone.isNotEmpty == true
                      ? user!.phone
                      : state.phone,
                )
              : const HomePage();
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => destination),
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
                    // Decorative gradient wash across the top
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

                    // Secondary glow, bottom left, for depth
                    Positioned(
                      bottom: -90,
                      left: -90,
                      child: Container(
                        width: 240,
                        height: 240,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: RadialGradient(
                            colors: [
                              AppTheme.gradientLight.withValues(alpha: 0.28),
                              AppTheme.gradientLight.withValues(alpha: 0.12),
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
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
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
                                          color: AppTheme.primaryText
                                              .withValues(alpha: 0.5),
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
                                        onChanged: (value) => context
                                            .read<AuthBloc>()
                                            .add(NameChanged(value)),
                                        keyboardType: TextInputType.name,
                                        autofillHints: const [
                                          AutofillHints.name
                                        ],
                                        errorText: state.nameErrorMessage,
                                      ),

                                      const SizedBox(height: 7),

                                      CustomTextField(
                                        label: 'CPF',
                                        controller: _cpfController,
                                        onChanged: (value) => context
                                            .read<AuthBloc>()
                                            .add(CpfChanged(value)),
                                        keyboardType: TextInputType.number,
                                        inputFormatters: [
                                          FilteringTextInputFormatter
                                              .digitsOnly,
                                          CpfInputFormatter(),
                                        ],
                                        errorText: state.cpfErrorMessage,
                                      ),

                                      const SizedBox(height: 7),

                                      CustomTextField(
                                        label: 'Telefone',
                                        controller: _phoneController,
                                        onChanged: (value) => context
                                            .read<AuthBloc>()
                                            .add(PhoneChanged(value)),
                                        keyboardType: TextInputType.phone,
                                        inputFormatters: [
                                          FilteringTextInputFormatter
                                              .digitsOnly,
                                          PhoneInputFormatter(),
                                        ],
                                        autofillHints: const [
                                          AutofillHints.telephoneNumber
                                        ],
                                        errorText: state.phoneErrorMessage,
                                      ),

                                      const SizedBox(height: 7),

                                      CustomTextField(
                                        label: 'E-mail',
                                        controller: _emailController,
                                        onChanged: (value) => context
                                            .read<AuthBloc>()
                                            .add(EmailChanged(value)),
                                        keyboardType:
                                            TextInputType.emailAddress,
                                        autofillHints: const [
                                          AutofillHints.email
                                        ],
                                        errorText: state.emailErrorMessage,
                                      ),

                                      const SizedBox(height: 7),

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
                                          AutofillHints.newPassword
                                        ],
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
                                        showPassword:
                                            state.isConfirmPasswordVisible,
                                        onTogglePassword: () => context
                                            .read<AuthBloc>()
                                            .add(
                                                ToggleConfirmPasswordVisibility()),
                                        autofillHints: const [
                                          AutofillHints.newPassword
                                        ],
                                        errorText:
                                            state.confirmPasswordErrorMessage,
                                      ),

                                      const SizedBox(height: 7),

                                      CustomTextField(
                                        label:
                                            'Código de quem te indicou (opcional)',
                                        controller: _receptionistCodeController,
                                        onChanged: (value) => context
                                            .read<AuthBloc>()
                                            .add(
                                                ReceptionistCodeChanged(value)),
                                        keyboardType: TextInputType.text,
                                      ),

                                      const SizedBox(height: 19),

                                      // Create Account button
                                      PrimaryButton(
                                        text: state.status == AuthStatus.loading
                                            ? 'Criando...'
                                            : 'Criar Conta',
                                        onPressed: state.status ==
                                                    AuthStatus.loading ||
                                                !_acceptedLegal
                                            ? null
                                            : () => context
                                                .read<AuthBloc>()
                                                .add(RegisterSubmitted()),
                                      ),

                                      if (state.serverError != null)
                                        Padding(
                                          padding:
                                              const EdgeInsets.only(top: 8),
                                          child: Text(
                                            state.serverError!,
                                            textAlign: TextAlign.center,
                                            style: TextStyle(
                                              color: Theme.of(context)
                                                  .colorScheme
                                                  .error,
                                              fontSize: 13,
                                              height: 1.4,
                                            ),
                                          ),
                                        ),

                                      const SizedBox(height: 16),

                                      CheckboxListTile(
                                        value: _acceptedLegal,
                                        onChanged: (value) => setState(
                                          () => _acceptedLegal = value ?? false,
                                        ),
                                        controlAffinity:
                                            ListTileControlAffinity.leading,
                                        contentPadding: EdgeInsets.zero,
                                        title: RichText(
                                          text: TextSpan(
                                            style: AppTheme.bodyMedium.copyWith(
                                              fontSize: 13,
                                              height: 1.4,
                                              color: const Color(0xFF7D8899),
                                            ),
                                            children: [
                                              const TextSpan(
                                                text: 'Li e concordo com os ',
                                              ),
                                              TextSpan(
                                                text: 'Termos de Uso',
                                                style: const TextStyle(
                                                  color: AppTheme.primaryColor,
                                                  decoration:
                                                      TextDecoration.underline,
                                                ),
                                                recognizer:
                                                    TapGestureRecognizer()
                                                      ..onTap = () =>
                                                          LegalDocumentPage
                                                              .openTerms(
                                                                  context),
                                              ),
                                              const TextSpan(text: ' e a '),
                                              TextSpan(
                                                text: 'Política de Privacidade',
                                                style: const TextStyle(
                                                  color: AppTheme.primaryColor,
                                                  decoration:
                                                      TextDecoration.underline,
                                                ),
                                                recognizer:
                                                    TapGestureRecognizer()
                                                      ..onTap = () =>
                                                          LegalDocumentPage
                                                              .openPrivacy(
                                                                  context),
                                              ),
                                              const TextSpan(
                                                text:
                                                    '. Tenho 18 anos ou mais.',
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
                                              color: const Color(0xFF778497)
                                                  .withValues(alpha: 0.3),
                                            ),
                                          ),
                                          Padding(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 8),
                                            child: Text(
                                              'ou',
                                              style:
                                                  AppTheme.bodyMedium.copyWith(
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

                                      // Google Sign-in button
                                      SocialButton(
                                        text: 'Continuar com o Google',
                                        leading: const GoogleLogo(size: 20),
                                        onPressed: state.status ==
                                                    AuthStatus.loading ||
                                                !_acceptedLegal
                                            ? null
                                            : () => context
                                                .read<AuthBloc>()
                                                .add(GoogleSignInPressed()),
                                      ),

                                      if (state.socialError != null) ...[
                                        const SizedBox(height: 12),
                                        Container(
                                          width: double.infinity,
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 14,
                                            vertical: 12,
                                          ),
                                          decoration: BoxDecoration(
                                            color: AppTheme.errorColor
                                                .withValues(alpha: 0.08),
                                            borderRadius:
                                                BorderRadius.circular(12),
                                            border: Border.all(
                                              color: AppTheme.errorColor
                                                  .withValues(alpha: 0.35),
                                            ),
                                          ),
                                          child: Text(
                                            state.socialError!,
                                            textAlign: TextAlign.center,
                                            style: TextStyle(
                                              color: AppTheme.errorColor,
                                              fontSize: 13,
                                              height: 1.4,
                                            ),
                                          ),
                                        ),
                                      ],

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
