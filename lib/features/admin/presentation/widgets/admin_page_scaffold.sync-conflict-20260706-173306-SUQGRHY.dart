import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/config/supabase_config.dart';
import '../../../../core/theme/app_theme.dart';

/// Scaffold reutilizável para páginas do módulo admin.
/// Inclui fundo branco, botão voltar (condicional),
/// título, área scrollável e widget inferior opcional.
class AdminPageScaffold extends StatelessWidget {
  static const List<String> adminAndFinanceiroRoles = [
    'admin',
    'financeiro',
  ];

  final String title;
  final String? subtitle;
  final Widget body;
  final Widget? floatingBottom;
  final List<Widget>? actions;
  final List<String>? allowedRoles;

  const AdminPageScaffold({
    super.key,
    required this.title,
    this.subtitle,
    required this.body,
    this.floatingBottom,
    this.actions,
    this.allowedRoles = adminAndFinanceiroRoles,
  });

  @override
  Widget build(BuildContext context) {
    final roles = allowedRoles;
    if (roles != null && SupabaseConfig.isInitialized) {
      return FutureBuilder<String?>(
        future: _currentRole(),
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Scaffold(
              backgroundColor: Colors.white,
              body: Center(child: CircularProgressIndicator()),
            );
          }

          final role = snapshot.data;
          if (role == null || !roles.contains(role)) {
            return _buildUnauthorized(context);
          }

          return _buildScaffold(context);
        },
      );
    }

    return _buildScaffold(context);
  }

  Future<String?> _currentRole() async {
    final userId = SupabaseConfig.client.auth.currentUser?.id;
    if (userId == null) return null;

    final row = await SupabaseConfig.client
        .from('profiles')
        .select('role')
        .eq('id', userId)
        .maybeSingle();
    return row?['role'] as String?;
  }

  Widget _buildUnauthorized(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.lock_outline,
                  size: 40,
                  color: AppTheme.primaryColor,
                ),
                const SizedBox(height: 16),
                Text(
                  'Acesso restrito',
                  style: GoogleFonts.outfit(
                    fontSize: 22,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.primaryColor,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Seu perfil não tem permissão para acessar esta tela.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.outfit(
                    fontSize: 14,
                    color: const Color(0xFF6D7F95),
                  ),
                ),
                if (Navigator.of(context).canPop()) ...[
                  const SizedBox(height: 20),
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Voltar'),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildScaffold(BuildContext context) {
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
