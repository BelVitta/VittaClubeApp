import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/theme/app_theme.dart';

class CustomTextField extends StatelessWidget {
  final String label;
  final TextEditingController? controller;
  final ValueChanged<String>? onChanged;
  final bool obscureText;
  final bool? showPassword;
  final VoidCallback? onTogglePassword;
  final TextInputType keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final String? Function(String?)? validator;
  final Iterable<String>? autofillHints;
  final String? errorText;

  const CustomTextField({
    super.key,
    required this.label,
    this.controller,
    this.onChanged,
    this.obscureText = false,
    this.showPassword,
    this.onTogglePassword,
    this.keyboardType = TextInputType.text,
    this.inputFormatters,
    this.validator,
    this.autofillHints,
    this.errorText,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      onChanged: onChanged,
      obscureText: obscureText && !(showPassword ?? false),
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      validator: validator,
      autofillHints: autofillHints,
      style: AppTheme.bodyLarge,
      cursorColor: AppTheme.primaryColor,
      decoration: AppTheme.inputDecoration(
        label: label,
        suffixIcon: obscureText
            ? IconButton(
                icon: Icon(
                  showPassword ?? false
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                  color: AppTheme.secondaryText,
                  size: 24,
                ),
                onPressed: onTogglePassword,
              )
            : null,
      ).copyWith(errorText: errorText),
    );
  }
}
