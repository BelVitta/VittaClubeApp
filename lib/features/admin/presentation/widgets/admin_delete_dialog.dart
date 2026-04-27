import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_theme.dart';

/// Diálogo de confirmação de exclusão para o módulo admin.
/// Uso: `final confirmed = await AdminDeleteDialog.show(context, 'Nome do item');`
class AdminDeleteDialog extends StatelessWidget {
  final String itemName;

  const AdminDeleteDialog({
    super.key,
    required this.itemName,
  });

  /// Exibe o diálogo e retorna true se o usuário confirmar a exclusão.
  static Future<bool?> show(BuildContext context, String itemName) {
    return showDialog<bool>(
      context: context,
      builder: (_) => AdminDeleteDialog(itemName: itemName),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      title: Text(
        'Confirmar exclusão',
        style: GoogleFonts.outfit(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: AppTheme.primaryColor,
        ),
      ),
      content: Text(
        'Tem certeza que deseja excluir $itemName?',
        style: GoogleFonts.outfit(
          fontSize: 13,
          fontWeight: FontWeight.w400,
          color: AppTheme.primaryColor,
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(
            'Cancelar',
            style: GoogleFonts.outfit(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: const Color(0xFF6D7F95),
            ),
          ),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: Text(
            'Excluir',
            style: GoogleFonts.outfit(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: const Color(0xFFFF5963),
            ),
          ),
        ),
      ],
    );
  }
}
