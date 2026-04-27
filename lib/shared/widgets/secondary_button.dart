import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

/// Botão secundário reutilizável do app (outline style)
/// Use em ações secundárias como "Criar Conta", "Cancelar", etc.
class SecondaryButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final double? width;
  final double height;

  const SecondaryButton({
    super.key,
    required this.text,
    this.onPressed,
    this.width,
    this.height = 48,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: width ?? double.infinity,
        height: height,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: AppTheme.primaryColor,
            width: 1.5,
          ),
        ),
        child: Center(
          child: Text(
            text,
            style: AppTheme.buttonText.copyWith(
              color: AppTheme.primaryColor,
            ),
          ),
        ),
      ),
    );
  }
}
