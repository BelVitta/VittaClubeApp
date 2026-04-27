import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../../../shared/widgets/primary_button.dart';
import '../../../../admin/presentation/widgets/admin_page_scaffold.dart';
import 'parceiro_register_page.dart';

class SejaParcerioPage extends StatelessWidget {
  const SejaParcerioPage({super.key});

  @override
  Widget build(BuildContext context) {
    return AdminPageScaffold(
      title: 'Seja Parceiro',
      subtitle: 'Faca parte da rede Vita Clube',
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),

          // Hero banner
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppTheme.gradientDark, AppTheme.gradientLight],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              children: [
                const Icon(
                  Icons.handshake,
                  size: 48,
                  color: Colors.white,
                ),
                const SizedBox(height: 12),
                Text(
                  'Cresça com a gente',
                  style: GoogleFonts.outfit(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Conecte seu estabelecimento a milhares\nde membros do Vita Clube e aumente\nseu fluxo de clientes.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                    color: Colors.white.withValues(alpha: 0.9),
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Como funciona
          Text(
            'Como funciona',
            style: GoogleFonts.outfit(
              fontSize: 17,
              fontWeight: FontWeight.w600,
              color: AppTheme.primaryColor,
            ),
          ),
          const SizedBox(height: 12),

          _buildStep(
            number: '1',
            title: 'Cadastre-se',
            description:
                'Preencha os dados do seu estabelecimento e escolha a categoria.',
            icon: Icons.app_registration_outlined,
          ),
          const SizedBox(height: 8),
          _buildStep(
            number: '2',
            title: 'Configure seus servicos',
            description:
                'Adicione exames, consultas ou produtos com precos e descontos exclusivos para membros.',
            icon: Icons.medical_services_outlined,
          ),
          const SizedBox(height: 8),
          _buildStep(
            number: '3',
            title: 'Receba clientes',
            description:
                'Membros do Vita Clube encontram seu estabelecimento no app e fazem check-in na hora.',
            icon: Icons.people_outlined,
          ),
          const SizedBox(height: 8),
          _buildStep(
            number: '4',
            title: 'Valide descontos',
            description:
                'O cliente gera um token no app, voce informa seu codigo e o desconto e validado com seguranca.',
            icon: Icons.verified_outlined,
          ),
          const SizedBox(height: 24),

          // Beneficios
          Text(
            'Beneficios para parceiros',
            style: GoogleFonts.outfit(
              fontSize: 17,
              fontWeight: FontWeight.w600,
              color: AppTheme.primaryColor,
            ),
          ),
          const SizedBox(height: 12),

          _buildBenefit(
            icon: Icons.trending_up,
            title: 'Mais visibilidade',
            description:
                'Seu estabelecimento aparece para todos os membros ativos do Vita Clube.',
          ),
          const SizedBox(height: 8),
          _buildBenefit(
            icon: Icons.attach_money,
            title: 'Aumento de receita',
            description:
                'Atraia novos clientes que buscam descontos e fidelidade.',
          ),
          const SizedBox(height: 8),
          _buildBenefit(
            icon: Icons.dashboard_outlined,
            title: 'Painel exclusivo',
            description:
                'Gerencie servicos, veja validacoes e acompanhe metricas em tempo real.',
          ),
          const SizedBox(height: 8),
          _buildBenefit(
            icon: Icons.security_outlined,
            title: 'Validacao segura',
            description:
                'Sistema de dois fatores (token + codigo) garante que apenas membros usem os descontos.',
          ),
          const SizedBox(height: 32),

          // CTA - Parceiro
          PrimaryButton(
            text: 'Quero ser parceiro',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const ParceiroRegisterPage(),
                ),
              );
            },
          ),
          const SizedBox(height: 24),

          // Divider
          Row(
            children: [
              Expanded(
                child: Container(
                  height: 1,
                  color: const Color(0xFFEBEEF2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Text(
                  'ou',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    color: const Color(0xFF9EAAB8),
                  ),
                ),
              ),
              Expanded(
                child: Container(
                  height: 1,
                  color: const Color(0xFFEBEEF2),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // CTA - Especialista
          _buildSpecialistCard(context),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildSpecialistCard(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFEBEEF2)),
      ),
      child: Column(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFF4CAF50).withValues(alpha: 0.1),
            ),
            child: const Icon(
              Icons.medical_services_outlined,
              size: 28,
              color: Color(0xFF4CAF50),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Sou especialista',
            style: GoogleFonts.outfit(
              fontSize: 17,
              fontWeight: FontWeight.w600,
              color: AppTheme.primaryColor,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Voce e profissional de saude e quer atender\npacientes do Vita Clube? Entre em contato\ncom a clinica parceira mais proxima para\nse cadastrar como especialista.',
            textAlign: TextAlign.center,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              fontWeight: FontWeight.w400,
              color: const Color(0xFF6D7F95),
              height: 1.5,
            ),
          ),
          const SizedBox(height: 16),
          GestureDetector(
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'Em breve voce podera entrar em contato diretamente pelo app.',
                    style: GoogleFonts.plusJakartaSans(fontSize: 13),
                  ),
                  backgroundColor: AppTheme.primaryColor,
                ),
              );
            },
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: AppTheme.primaryColor.withValues(alpha: 0.2),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.chat_outlined,
                    size: 18,
                    color: AppTheme.primaryColor,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Entrar em contato',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStep({
    required String number,
    required String title,
    required String description,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFEBEEF2)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppTheme.primaryColor.withValues(alpha: 0.1),
            ),
            child: Center(
              child: Text(
                number,
                style: GoogleFonts.outfit(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.primaryColor,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.outfit(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.primaryColor,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  description,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                    color: const Color(0xFF6D7F95),
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBenefit({
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.primaryColor.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppTheme.primaryColor.withValues(alpha: 0.1),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppTheme.primaryColor.withValues(alpha: 0.1),
            ),
            child: Icon(icon, size: 18, color: AppTheme.primaryColor),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.outfit(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.primaryColor,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  description,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                    color: const Color(0xFF6D7F95),
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
