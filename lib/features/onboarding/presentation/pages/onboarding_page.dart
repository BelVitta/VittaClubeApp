import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/primary_button.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/di/injection_container.dart';
import '../../../auth/presentation/pages/login_page.dart';
import '../bloc/onboarding_bloc.dart';
import '../bloc/onboarding_event.dart';
import '../bloc/onboarding_state.dart';
import '../models/onboarding_content.dart';
import '../widgets/page_indicator.dart';

class OnboardingPage extends StatelessWidget {
  const OnboardingPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => OnboardingBloc(),
      child: const OnboardingView(),
    );
  }
}

class OnboardingView extends StatefulWidget {
  const OnboardingView({super.key});

  @override
  State<OnboardingView> createState() => _OnboardingViewState();
}

class _OnboardingViewState extends State<OnboardingView> {
  final PageController _pageController = PageController();

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _navigateToLogin(BuildContext context) {
    sl<SharedPreferences>().setBool('HAS_SEEN_ONBOARDING', true);
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const LoginPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final isSmallScreen = screenHeight < 680;

    return BlocConsumer<OnboardingBloc, OnboardingState>(
      listener: (context, state) {
        if (state is OnboardingComplete) {
          _navigateToLogin(context);
        } else {
          _pageController.animateToPage(
            state.currentPage,
            duration: const Duration(milliseconds: 400),
            curve: Curves.easeInOut,
          );
        }
      },
      builder: (context, state) {
        return GestureDetector(
          onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
          child: Scaffold(
            backgroundColor: Colors.white,
            body: SafeArea(
              child: Stack(
                children: [
                  // Fundo fixo (não desliza com o swipe): gradiente azul->branco
                  // nos 390px superiores sobre uma base branca. Fica consistente
                  // entre as páginas, só o PNG+texto trocam.
                  const Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    child: SizedBox(
                      height: 390,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [Color(0xFF91BDEA), Color(0xFFFFFFFF)],
                          ),
                        ),
                      ),
                    ),
                  ),
                  Column(
                    children: [
                      Expanded(
                        child: PageView.builder(
                          controller: _pageController,
                          itemCount: onboardingPages.length,
                          onPageChanged: (index) {
                            final bloc = context.read<OnboardingBloc>();
                            if (state.currentPage != index) {
                              bloc.add(PageSwiped(index));
                            }
                          },
                          itemBuilder: (context, index) {
                            return _buildPage(onboardingPages[index]);
                          },
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.only(top: isSmallScreen ? 12 : 24),
                        child: PageIndicator(
                          totalPages: state.totalPages,
                          currentPage: state.currentPage,
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.fromLTRB(
                          32,
                          isSmallScreen ? 12 : 20,
                          32,
                          isSmallScreen ? 12 : 20,
                        ),
                        child: PrimaryButton(
                          text: state.isLastPage ? 'Começar Agora' : 'Próximo',
                          onPressed: () {
                            context
                                .read<OnboardingBloc>()
                                .add(NextPagePressed());
                          },
                        ),
                      ),
                    ],
                  ),
                  if (!state.isLastPage)
                    Positioned(
                      top: 8,
                      right: 16,
                      child: TextButton(
                        onPressed: () {
                          context.read<OnboardingBloc>().add(SkipPressed());
                        },
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 8),
                        ),
                        child: Text(
                          'Pular',
                          style: AppTheme.bodyMedium.copyWith(
                            color: AppTheme.primaryColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildPage(OnboardingContent content) {
    // Esta página é transparente; o fundo (branco + gradiente azul) está no
    // Stack pai, atrás do PageView, por isso não desliza com o swipe.
    return Stack(
      children: [
        // Imagem edge-to-edge no topo, altura natural (sem recorte).
        Align(
          alignment: Alignment.topCenter,
          child: Image.asset(
            content.imagePath,
            width: double.infinity,
            fit: BoxFit.fitWidth,
            errorBuilder: (context, error, stackTrace) => Icon(
              Icons.spa_outlined,
              size: 120,
              color: AppTheme.primaryColor.withValues(alpha: 0.3),
            ),
          ),
        ),
        // Texto ancorado ao rodapé. Se o PNG for mais alto que o espaço,
        // o texto sobrepõe a parte clara inferior da imagem.
        Positioned(
          left: 24,
          right: 24,
          bottom: 0,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text.rich(
                TextSpan(
                  children: [
                    TextSpan(
                      text: content.titlestart,
                      style: AppTheme.headingLarge,
                    ),
                    TextSpan(
                      text: content.titleHighlight,
                      style: AppTheme.headingLarge.copyWith(
                        color: AppTheme.secondaryColor,
                      ),
                    ),
                  ],
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                content.description,
                textAlign: TextAlign.center,
                style: AppTheme.bodyMedium,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
