import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../admin/presentation/widgets/admin_page_scaffold.dart';

class BenefitsPage extends StatelessWidget {
  const BenefitsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return AdminPageScaffold(
      title: 'Beneficios',
      subtitle: 'Tudo que voce ganha sendo Vita Clube',
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
                  Icons.star_rounded,
                  size: 48,
                  color: Colors.white,
                ),
                const SizedBox(height: 12),
                Text(
                  'Seus beneficios',
                  style: GoogleFonts.outfit(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Aproveite descontos, atendimento\nprioritario e muito mais como\nmembro do Vita Clube.',
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

          // Saude
          _buildSectionTitle('Saude e Bem-estar'),
          const SizedBox(height: 12),
          _buildBenefit(
            icon: Icons.local_hospital_outlined,
            title: 'Consultas com desconto',
            description:
                'Ate 50% de desconto em consultas medicas com especialistas parceiros.',
          ),
          const SizedBox(height: 8),
          _buildBenefit(
            icon: Icons.science_outlined,
            title: 'Exames laboratoriais',
            description:
                'Precos exclusivos em hemograma, glicemia, colesterol e mais de 100 exames.',
          ),
          const SizedBox(height: 8),
          _buildBenefit(
            icon: Icons.visibility_outlined,
            title: 'Otica e lentes',
            description:
                'Descontos em armacoes, lentes de contato e consultas oftalmologicas.',
          ),
          const SizedBox(height: 8),
          _buildBenefit(
            icon: Icons.local_pharmacy_outlined,
            title: 'Farmacias parceiras',
            description:
                'Descontos em medicamentos e produtos de saude nas farmacias conveniadas.',
          ),
          const SizedBox(height: 24),

          // Rede de Parceiros
          _buildSectionTitle('Rede de Parceiros'),
          const SizedBox(height: 12),
          _buildBenefit(
            icon: Icons.handshake_outlined,
            title: 'Ampla rede credenciada',
            description:
                'Laboratorios, clinicas, farmacias e oticas em diversas cidades.',
          ),
          const SizedBox(height: 8),
          _buildBenefit(
            icon: Icons.qr_code_outlined,
            title: 'Check-in digital',
            description:
                'Valide seu desconto direto pelo app com token + codigo do parceiro.',
          ),
          const SizedBox(height: 24),

          // Programa de Fidelidade
          _buildSectionTitle('Programa de Fidelidade'),
          const SizedBox(height: 12),
          _buildBenefit(
            icon: Icons.emoji_events_outlined,
            title: 'Niveis de badge',
            description:
                'Suba de nivel (Bronze, Prata, Ouro, Diamante) e desbloqueie beneficios maiores.',
          ),
          const SizedBox(height: 8),
          _buildBenefit(
            icon: Icons.people_outlined,
            title: 'Indicacao premiada',
            description:
                'Indique amigos e ganhe pontos extras para subir de nivel mais rapido.',
          ),
          const SizedBox(height: 8),
          _buildBenefit(
            icon: Icons.card_giftcard_outlined,
            title: 'Sorteios exclusivos',
            description:
                'Participe de sorteios mensais disponiveis apenas para membros ativos.',
          ),
          const SizedBox(height: 8),
          _buildBenefit(
            icon: Icons.discount_outlined,
            title: 'Cupons de desconto',
            description:
                'Receba cupons especiais em datas comemorativas e campanhas exclusivas.',
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: GoogleFonts.outfit(
        fontSize: 17,
        fontWeight: FontWeight.w600,
        color: AppTheme.primaryColor,
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
