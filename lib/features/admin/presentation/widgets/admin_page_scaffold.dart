import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_theme.dart';

/// Scaffold reutilizável para páginas do módulo admin.
/// Inclui fundo branco, botão voltar (condicional),
/// título, área scrollável e widget inferior opcional.
class AdminPageScaffold extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget body;
  final Widget? floatingBottom;
  final List<Widget>? actions;

  const AdminPageScaffold({
    super.key,
    required this.title,
    this.subtitle,
    required this.body,
    this.floatingBottom,
    this.actions,
  });

  @override
  Widget build(BuildContext context) {
    final canPop = Navigator.of(context).canPop();
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // Conteúdo principal
          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header: botão voltar + título
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Botão voltar (só aparece se há rota anterior)
                      if (canPop) ...[
                        GestureDetector(
                          onTap: () => Navigator.of(context).pop(),
                          child: Container(
                            width: 39,
                            height: 39,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: const Color(0xFF01225B)
                                  .withValues(alpha: 0.2),
                            ),
                            child: const Icon(
                              Icons.arrow_back_ios_new,
                              size: 16,
                              color: AppTheme.primaryColor,
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                      ],
                      // Título + Actions
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              title,
                              style: GoogleFonts.outfit(
                                fontSize: 24,
                                fontWeight: FontWeight.w500,
                                color: AppTheme.primaryColor,
                              ),
                            ),
                          ),
                          if (actions != null) ...actions!,
                        ],
                      ),
                      // Subtítulo opcional
                      if (subtitle != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          subtitle!,
                          style: GoogleFonts.outfit(
                            fontSize: 13,
                            fontWeight: FontWeight.w400,
                            color: const Color(0xFF6D7F95),
                          ),
                        ),
                      ],
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
                // Corpo scrollável
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                    child: body,
                  ),
                ),
              ],
            ),
          ),
          // Widget inferior flutuante (ex: botão de salvar)
          if (floatingBottom != null)
            Positioned(
              left: 20,
              right: 20,
              bottom: MediaQuery.of(context).padding.bottom + 16,
              child: floatingBottom!,
            ),
        ],
      ),
    );
  }
}
