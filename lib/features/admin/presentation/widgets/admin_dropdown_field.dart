import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_theme.dart';

class DropdownItem {
  final String id;
  final String displayName;

  const DropdownItem({required this.id, required this.displayName});
}

class AdminDropdownField extends StatelessWidget {
  final String label;
  final String? value;
  final List<DropdownItem> items;
  final ValueChanged<DropdownItem?> onChanged;
  final String? hint;

  const AdminDropdownField({
    super.key,
    required this.label,
    this.value,
    required this.items,
    required this.onChanged,
    this.hint,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.outfit(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: AppTheme.primaryColor,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFFFCFCFC),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: const Color(0xFFDDDFE5)),
          ),
          child: DropdownButtonFormField<String>(
            initialValue: value != null && items.any((i) => i.id == value)
                ? value
                : null,
            items: items
                .map((item) => DropdownMenuItem<String>(
                      value: item.id,
                      child: Text(
                        item.displayName,
                        style: GoogleFonts.outfit(
                          fontSize: 13,
                          fontWeight: FontWeight.w400,
                          color: AppTheme.primaryColor,
                        ),
                      ),
                    ))
                .toList(),
            onChanged: (id) {
              if (id == null) {
                onChanged(null);
              } else {
                final selected = items.firstWhere((i) => i.id == id);
                onChanged(selected);
              }
            },
            decoration: InputDecoration(
              border: InputBorder.none,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16),
              hintText: hint ?? 'Selecione...',
              hintStyle: GoogleFonts.outfit(
                fontSize: 13,
                fontWeight: FontWeight.w400,
                color: const Color(0xFF6D7F95),
              ),
            ),
            icon: const Icon(
              Icons.keyboard_arrow_down,
              color: Color(0xFF6D7F95),
              size: 20,
            ),
            dropdownColor: Colors.white,
            borderRadius: BorderRadius.circular(12),
            isExpanded: true,
          ),
        ),
      ],
    );
  }
}
