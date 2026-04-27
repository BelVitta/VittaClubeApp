import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_theme.dart';

/// Card do usuário no topo da página de perfil
class ProfileUserCard extends StatelessWidget {
  final String name;
  final String email;
  final String memberSince;
  final String? badgeUrl;

  const ProfileUserCard({
    super.key,
    required this.name,
    required this.email,
    required this.memberSince,
    this.badgeUrl,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFEBEEF2)),
      ),
      child: Row(
        children: [
          // Avatar
          Container(
            width: 41,
            height: 41,
            decoration: BoxDecoration(
              color: const Color(0xFF4678CF).withValues(alpha: 0.09),
              borderRadius: BorderRadius.circular(20.5),
            ),
            child: const Icon(
              Icons.person_outline,
              size: 21,
              color: Color(0xFF4678CF),
            ),
          ),
          const SizedBox(width: 8),

          // User info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: GoogleFonts.outfit(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: AppTheme.primaryColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  email,
                  style: GoogleFonts.outfit(
                    fontSize: 10,
                    fontWeight: FontWeight.w400,
                    color: AppTheme.primaryColor.withValues(alpha: 0.4),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Membro desde: $memberSince',
                  style: GoogleFonts.outfit(
                    fontSize: 10,
                    fontWeight: FontWeight.w400,
                    color: AppTheme.primaryColor.withValues(alpha: 0.4),
                  ),
                ),
              ],
            ),
          ),

          // Plan badge
          if (badgeUrl != null)
            SizedBox(
              width: 38,
              height: 40,
              child: Image.network(
                badgeUrl!,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) {
                  return const Icon(
                    Icons.shield_outlined,
                    size: 24,
                    color: Color(0xFFC25C3C),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}
