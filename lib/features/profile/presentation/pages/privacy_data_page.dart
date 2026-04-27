import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_theme.dart';
import '../widgets/profile_menu_item.dart';

/// Página de Privacidade e Dados
class PrivacyDataPage extends StatelessWidget {
  const PrivacyDataPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Stack(
          children: [
            // Background gradient circle
            Positioned(
              top: -16,
              right: -180,
              child: Container(
                width: 503.5,
                height: 283.06,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      AppTheme.gradientLight.withValues(alpha: 0.3),
                      Colors.white.withValues(alpha: 0),
                    ],
                    stops: const [0, 1],
                  ),
                ),
              ),
            ),

            Column(
              children: [
                // Back button
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          width: 39,
                          height: 39,
                          decoration: BoxDecoration(
                            color:
                                const Color(0xFF01225B).withValues(alpha: 0.2),
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

                const SizedBox(height: 12),

                // Content
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Title
                        Text(
                          'Privacidade e Dados',
                          style: GoogleFonts.outfit(
                            fontSize: 24,
                            fontWeight: FontWeight.w500,
                            color: AppTheme.primaryColor,
                            letterSpacing: 0.12,
                          ),
                        ),
                        const SizedBox(height: 6),

                        // Subtitle
                        Text(
                          'Informações Básicas',
                          style: GoogleFonts.outfit(
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                            color: AppTheme.primaryColor,
                            letterSpacing: 0.075,
                          ),
                        ),
                        const SizedBox(height: 6),

                        // Menu items
                        ProfileMenuItem(
                          title: 'Política de Privacidade',
                          onTap: () {
                            // TODO: Open privacy policy
                          },
                        ),
                        const SizedBox(height: 8),
                        ProfileMenuItem(
                          title: 'Termos de Uso',
                          onTap: () {
                            // TODO: Open terms of use
                          },
                        ),
                        const SizedBox(height: 8),

                        // Delete account (red)
                        ProfileMenuItem(
                          title: 'Excluir minha conta',
                          textColor: const Color(0xFFE57373),
                          borderColor: const Color(0xFFE57373),
                          showChevron: false,
                          onTap: () => _showDeleteConfirmation(context),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Excluir conta',
          style: GoogleFonts.outfit(
            fontWeight: FontWeight.w500,
            color: AppTheme.primaryColor,
          ),
        ),
        content: Text(
          'Tem certeza que deseja excluir sua conta? Esta ação não pode ser desfeita.',
          style: GoogleFonts.outfit(
            fontSize: 14,
            color: const Color(0xFF6D7F95),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancelar',
              style: GoogleFonts.outfit(color: AppTheme.primaryColor),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              // TODO: Process account deletion
            },
            child: Text(
              'Excluir',
              style: GoogleFonts.outfit(color: const Color(0xFFE57373)),
            ),
          ),
        ],
      ),
    );
  }
}
