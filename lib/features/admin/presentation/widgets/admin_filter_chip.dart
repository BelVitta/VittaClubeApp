import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_theme.dart';

class AdminFilterChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const AdminFilterChip({
    super.key,
    required this.icon,
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isActive
              ? AppTheme.primaryColor.withValues(alpha: 0.1)
              : const Color(0xFFF5F6FA),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isActive
                ? AppTheme.primaryColor.withValues(alpha: 0.3)
                : const Color(0xFFE0E4EC),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 14,
              color:
                  isActive ? AppTheme.primaryColor : const Color(0xFF6D7F95),
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                color:
                    isActive ? AppTheme.primaryColor : const Color(0xFF6D7F95),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static void showFilterBottomSheet(
    BuildContext context, {
    required String title,
    required List<String> options,
    required String? current,
    required ValueChanged<String?> onSelected,
    Map<String, String>? displayNames,
  }) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (bottomContext) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
                child: Text(
                  title,
                  style: GoogleFonts.outfit(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.primaryColor,
                  ),
                ),
              ),
              if (current != null)
                ListTile(
                  leading:
                      const Icon(Icons.clear, color: Colors.red, size: 20),
                  title: Text(
                    'Remover filtro',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14,
                      color: Colors.red,
                    ),
                  ),
                  onTap: () {
                    onSelected(null);
                    Navigator.pop(bottomContext);
                  },
                ),
              ...options.map((option) => ListTile(
                    leading: Icon(
                      current == option
                          ? Icons.check_circle
                          : Icons.circle_outlined,
                      color: current == option
                          ? AppTheme.primaryColor
                          : const Color(0xFF6D7F95),
                      size: 20,
                    ),
                    title: Text(
                      displayNames?[option] ?? (option[0].toUpperCase() + option.substring(1)),
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14,
                        fontWeight: current == option
                            ? FontWeight.w600
                            : FontWeight.w400,
                        color: AppTheme.primaryColor,
                      ),
                    ),
                    onTap: () {
                      onSelected(option);
                      Navigator.pop(bottomContext);
                    },
                  )),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }
}
