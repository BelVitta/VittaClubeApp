import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Badge de status com cor de fundo e texto baseados no tipo de status.
/// Statuses pré-definidos: ativo, inativo, pendente, pago, cancelado.
/// Aceita cores customizadas via customColor e customBgColor.
class AdminStatusBadge extends StatelessWidget {
  final String status;
  final Color? customColor;
  final Color? customBgColor;

  const AdminStatusBadge({
    super.key,
    required this.status,
    this.customColor,
    this.customBgColor,
  });

  /// Retorna a cor do texto com base no status.
  Color get _textColor {
    if (customColor != null) return customColor!;
    switch (status.toLowerCase()) {
      case 'ativo':
      case 'pago':
        return const Color(0xFF249689);
      case 'inativo':
        return const Color(0xFF6D7F95);
      case 'pendente':
        return const Color(0xFFE8872B);
      case 'cancelado':
        return const Color(0xFFFF5963);
      default:
        return const Color(0xFF6D7F95);
    }
  }

  /// Retorna a cor de fundo com base no status.
  Color get _backgroundColor {
    if (customBgColor != null) return customBgColor!;
    return _textColor.withValues(alpha: 0.1);
  }

  /// Retorna o rótulo capitalizado para exibição.
  String get _label {
    if (status.isEmpty) return '';
    return status[0].toUpperCase() + status.substring(1).toLowerCase();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: _backgroundColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        _label,
        style: GoogleFonts.outfit(
          fontSize: 10,
          fontWeight: FontWeight.w500,
          color: _textColor,
        ),
      ),
    );
  }
}
