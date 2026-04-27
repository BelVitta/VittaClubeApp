import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_theme.dart';

/// Card de profissional com avatar, nome, especialidade, dias e botão WhatsApp.
/// [isLarge] = true exibe a foto grande à direita (card principal).
/// [isLarge] = false exibe a foto pequena (44px) e layout compacto.
class ProfessionalCard extends StatelessWidget {
  final String name;
  final String specialty;
  final String availableDays;
  final String? avatarUrl;
  final Color avatarBgColor;
  final bool isLarge;
  final VoidCallback? onWhatsApp;

  const ProfessionalCard({
    super.key,
    required this.name,
    required this.specialty,
    required this.availableDays,
    this.avatarUrl,
    this.avatarBgColor = const Color(0xFFFFCD66),
    this.isLarge = true,
    this.onWhatsApp,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(isLarge ? 16 : 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFEBEEF2)),
      ),
      child: isLarge ? _buildLargeLayout() : _buildCompactLayout(),
    );
  }

  Widget _buildLargeLayout() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Left: text content
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildTextInfo(titleSize: 14, specialtySize: 12, daysSize: 10),
              const SizedBox(height: 8),
              _buildWhatsAppButton(),
            ],
          ),
        ),
        const SizedBox(width: 12),
        // Right: large avatar
        _buildAvatar(size: 90, borderRadius: 20),
      ],
    );
  }

  Widget _buildCompactLayout() {
    return Row(
      children: [
        // Small avatar
        _buildAvatar(size: 44, borderRadius: 29),
        const SizedBox(width: 8),
        // Text
        Expanded(
          child: _buildTextInfo(titleSize: 10, specialtySize: 10, daysSize: 10),
        ),
        // WhatsApp button
        _buildWhatsAppButton(),
      ],
    );
  }

  Widget _buildTextInfo({
    required double titleSize,
    required double specialtySize,
    required double daysSize,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          name,
          style: GoogleFonts.outfit(
            fontSize: titleSize,
            fontWeight: FontWeight.w500,
            color: AppTheme.primaryColor,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          specialty,
          style: GoogleFonts.outfit(
            fontSize: specialtySize,
            fontWeight: FontWeight.w400,
            color: AppTheme.primaryColor.withValues(alpha: 0.7),
          ),
        ),
        const SizedBox(height: 2),
        Text(
          availableDays,
          style: GoogleFonts.outfit(
            fontSize: daysSize,
            fontWeight: FontWeight.w400,
            color: AppTheme.primaryColor.withValues(alpha: 0.7),
          ),
        ),
      ],
    );
  }

  Widget _buildAvatar({required double size, required double borderRadius}) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: avatarBgColor,
        borderRadius: BorderRadius.circular(borderRadius),
      ),
      child: avatarUrl != null
          ? ClipRRect(
              borderRadius: BorderRadius.circular(borderRadius),
              child: Image.network(
                avatarUrl!,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _buildAvatarFallback(size),
              ),
            )
          : _buildAvatarFallback(size),
    );
  }

  Widget _buildAvatarFallback(double size) {
    return Center(
      child: Icon(
        Icons.person,
        size: size * 0.5,
        color: Colors.white.withValues(alpha: 0.8),
      ),
    );
  }

  Widget _buildWhatsAppButton() {
    return GestureDetector(
      onTap: onWhatsApp,
      child: Container(
        padding: EdgeInsets.all(isLarge ? 8 : 7),
        decoration: BoxDecoration(
          color: const Color(0xFFA3FFAC).withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.chat_outlined,
              size: 14,
              color: const Color(0xFF34933E),
            ),
            const SizedBox(width: 4),
            Text(
              'Agendar via Whatsapp',
              style: GoogleFonts.outfit(
                fontSize: 10,
                fontWeight: FontWeight.w500,
                color: const Color(0xFF34933E),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
