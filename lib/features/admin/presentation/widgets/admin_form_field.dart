import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_theme.dart';

/// Campo de formulário com label para o módulo admin.
/// Adapta o borderRadius para 12 quando multiline (maxLines > 1).
class AdminFormField extends StatelessWidget {
  final String label;
  final TextEditingController? controller;
  final TextInputType? keyboardType;
  final bool readOnly;
  final bool enabled;
  final int maxLines;
  final Widget? suffixIcon;
  final String? hintText;
  final String? Function(String?)? validator;
  final ValueChanged<String>? onChanged;

  const AdminFormField({
    super.key,
    required this.label,
    this.controller,
    this.keyboardType,
    this.readOnly = false,
    this.enabled = true,
    this.maxLines = 1,
    this.suffixIcon,
    this.hintText,
    this.validator,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isMultiline = maxLines > 1;
    final radius = isMultiline ? 12.0 : 24.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Label
        Text(
          label,
          style: GoogleFonts.outfit(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: AppTheme.primaryColor,
          ),
        ),
        const SizedBox(height: 6),
        // Campo de texto
        Container(
          decoration: BoxDecoration(
            color: enabled ? const Color(0xFFFCFCFC) : const Color(0xFFF0F0F0),
            borderRadius: BorderRadius.circular(radius),
            border: Border.all(color: const Color(0xFFDDDFE5)),
          ),
          child: TextFormField(
            controller: controller,
            keyboardType: keyboardType,
            readOnly: readOnly,
            enabled: enabled,
            maxLines: maxLines,
            onChanged: onChanged,
            validator: enabled ? validator : null,
            style: GoogleFonts.outfit(
              fontSize: 13,
              fontWeight: FontWeight.w400,
              color: AppTheme.primaryColor,
            ),
            decoration: InputDecoration(
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(
                horizontal: 16,
                vertical: isMultiline ? 12 : 0,
              ),
              suffixIcon: suffixIcon,
              hintText: hintText,
              hintStyle: GoogleFonts.outfit(
                fontSize: 13,
                fontWeight: FontWeight.w400,
                color: const Color(0xFF6D7F95),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
