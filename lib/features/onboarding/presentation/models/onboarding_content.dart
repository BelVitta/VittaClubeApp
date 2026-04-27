class OnboardingContent {
  final String titlestart;
  final String titleHighlight;
  final String description;
  final String imagePath;

  const OnboardingContent({
    required this.titlestart,
    required this.titleHighlight,
    required this.description,
    required this.imagePath,
  });
}

const List<OnboardingContent> onboardingPages = [
  OnboardingContent(
    titlestart: 'Simplicidade para o seu ',
    titleHighlight: 'dia',
    description:
        'Gerencie seus planos, consultas e benefícios em um só lugar. Tudo pensado para facilitar sua rotina de cuidados.',
    imagePath: 'assets/images/line-3.png',
  ),
  OnboardingContent(
    titlestart: 'No alcance da ',
    titleHighlight: 'sua mão',
    description:
        'Acesse seu histórico, agende consultas e mantenha sua saúde em dia direto pelo app.',
    imagePath: 'assets/images/line-10.png',
  ),
  OnboardingContent(
    titlestart: 'Junte-se ao ',
    titleHighlight: 'Vita Clube',
    description:
        'Assine um plano e tenha acesso a descontos, vantagens e benefícios exclusivos.',
    imagePath: 'assets/images/line-4.png',
  ),
];
